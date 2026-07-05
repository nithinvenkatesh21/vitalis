import Foundation
import Network
import SwiftData
import VitalisCore
import VitalisNetworking

public final class SyncEngine {
    private let dataController = VitalisDataController.shared
    private let authRepository: AuthRepositoryProtocol
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "VitalisSyncEngineNetworkMonitor")
    
    // Network services
    private let moodNetworkService = MoodNetworkService()
    private let nutritionNetworkService = NutritionNetworkService()
    private let readinessNetworkService = ReadinessNetworkService()
    
    private var isNetworkAvailable = false
    private var isSyncing = false
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isAvailable = path.status == .satisfied
            
            if isAvailable && !self.isNetworkAvailable {
                // Connection restored, trigger outbox processing
                Task {
                    await self.processOutbox()
                }
            }
            self.isNetworkAvailable = isAvailable
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    @MainActor
    public func processOutbox() async {
        guard isNetworkAvailable else {
            print("SyncEngine: Offline, postponing outbox processing")
            return
        }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let context = dataController.mainContext
        
        // Fetch all pending/failed queue items
        let descriptor = FetchDescriptor<SyncQueueItem>(
            predicate: #Predicate { $0.status != "syncing" },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        guard let queueItems = try? context.fetch(descriptor), !queueItems.isEmpty else {
            return
        }
        
        print("SyncEngine: Processing \(queueItems.count) queued sync pairs")
        
        for item in queueItems {
            item.status = "syncing"
            try? context.save()
            
            let primaryId = item.moodId // Stores moodId, mealId, or readinessId
            let eventId = item.eventId
            
            // Fetch TimelineEventSD
            let eventDescriptor = FetchDescriptor<TimelineEventSD>(predicate: #Predicate { $0.id == eventId })
            guard let localEvent = (try? context.fetch(eventDescriptor))?.first else {
                context.delete(item)
                try? context.save()
                continue
            }
            
            // Only sync items that belong to the currently logged in user
            guard let currentUser = authRepository.currentUser,
                  localEvent.userId == currentUser.id else {
                item.status = "pending"
                try? context.save()
                continue
            }
            
            // Map TimelineEventSD to domain
            let payloadData = localEvent.payloadJSON.data(using: .utf8) ?? Data()
            let payload = (try? JSONDecoder().decode([String: String].self, from: payloadData)) ?? [:]
            let linkedIdsData = localEvent.linkedEntityIdsJSON.data(using: .utf8) ?? Data()
            let linkedIds = (try? JSONDecoder().decode([UUID].self, from: linkedIdsData)) ?? []
            let domainEvent = TimelineEvent(
                id: localEvent.id,
                userId: localEvent.userId,
                timestamp: localEvent.timestamp,
                type: localEvent.type,
                payload: payload,
                linkedEntityIds: linkedIds
            )
            
            do {
                if item.entityType == "mood_with_timeline" {
                    // Mood entry sync
                    let moodDescriptor = FetchDescriptor<MoodEntrySD>(predicate: #Predicate { $0.id == primaryId })
                    guard let localMood = (try? context.fetch(moodDescriptor))?.first else {
                        context.delete(item)
                        try? context.save()
                        continue
                    }
                    
                    let tagsData = localMood.tagsJSON.data(using: .utf8) ?? Data()
                    let tags = (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
                    let domainMood = MoodEntry(
                        id: localMood.id,
                        userId: localMood.userId,
                        timestamp: localMood.timestamp,
                        valence: localMood.valence,
                        tags: tags,
                        freeText: localMood.freeText,
                        isSynced: localMood.isSynced
                    )
                    
                    try await moodNetworkService.pushMoodWithTimeline(mood: domainMood, event: domainEvent)
                    localMood.isSynced = true
                    
                } else if item.entityType == "meal_with_items" {
                    // Meal with child food items sync
                    let mealDescriptor = FetchDescriptor<MealSD>(predicate: #Predicate { $0.id == primaryId })
                    guard let localMeal = (try? context.fetch(mealDescriptor))?.first else {
                        context.delete(item)
                        try? context.save()
                        continue
                    }
                    
                    // Map Macros
                    let macrosData = localMeal.macrosJSON.data(using: .utf8) ?? Data()
                    let macros = (try? JSONDecoder().decode(Macros.self, from: macrosData)) ?? Macros.zero
                    
                    // Map child food items
                    let domainItems = localMeal.foodItems?.map { itemSD -> FoodItem in
                        let itemMacrosData = itemSD.macrosJSON.data(using: .utf8) ?? Data()
                        let itemMacros = (try? JSONDecoder().decode(Macros.self, from: itemMacrosData)) ?? Macros.zero
                        return FoodItem(
                            id: itemSD.id,
                            name: itemSD.name,
                            brand: itemSD.brand,
                            macros: itemMacros,
                            micros: [:],
                            confidenceScore: itemSD.confidenceScore
                        )
                    } ?? []
                    
                    let logMethod = LoggingMethod(rawValue: localMeal.method) ?? .manual
                    let domainMeal = Meal(
                        id: localMeal.id,
                        userId: localMeal.userId,
                        timestamp: localMeal.timestamp,
                        method: logMethod,
                        items: domainItems,
                        estimatedMacros: macros,
                        estimatedMicros: [:],
                        isSynced: localMeal.isSynced
                    )
                    
                    try await nutritionNetworkService.pushMealWithItems(meal: domainMeal, event: domainEvent)
                    localMeal.isSynced = true
                    
                } else if item.entityType == "readiness_score" {
                    // Readiness score sync
                    let scoreDescriptor = FetchDescriptor<ReadinessScoreSD>(predicate: #Predicate { $0.id == primaryId })
                    guard let localScore = (try? context.fetch(scoreDescriptor))?.first else {
                        context.delete(item)
                        try? context.save()
                        continue
                    }
                    
                    let componentsData = localScore.componentsJSON.data(using: .utf8) ?? Data()
                    let components = (try? JSONDecoder().decode([String: Double].self, from: componentsData)) ?? [:]
                    let explanationData = localScore.explanationJSON.data(using: .utf8) ?? Data()
                    let explanation = (try? JSONDecoder().decode([String].self, from: explanationData)) ?? []
                    
                    let domainScore = ReadinessScore(
                        id: localScore.id,
                        userId: localScore.userId,
                        date: localScore.date,
                        compositeScore: localScore.compositeScore,
                        components: components,
                        explanation: explanation,
                        isSynced: localScore.isSynced
                    )
                    
                    try await readinessNetworkService.pushReadinessScore(score: domainScore, event: domainEvent)
                    localScore.isSynced = true
                }
                
                // On Success: Mark event as synced, remove queue item
                localEvent.isSynced = true
                context.delete(item)
                try context.save()
                
                print("SyncEngine: Successfully synced \(item.entityType) \(primaryId) atomically")
            } catch {
                print("SyncEngine: Atomic sync failed for \(item.entityType) (Queue ID: \(item.id)): \(error.localizedDescription)")
                item.status = "failed"
                try? context.save()
                
                // Abort sync loop execution for remaining items until network connectivity is resolved
                break
            }
        }
    }
}
