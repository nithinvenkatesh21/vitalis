import Foundation
import Combine
import SwiftData
import VitalisCore
import VitalisNetworking

public final class NutritionRepository: NutritionRepositoryProtocol {
    private let dataController = VitalisDataController.shared
    private let authRepository: AuthRepositoryProtocol
    private let mealsSubject = CurrentValueSubject<[Meal], Never>([])
    private var syncEngine: SyncEngine?
    private var cancellables = Set<AnyCancellable>()
    
    public var mealsPublisher: AnyPublisher<[Meal], Never> {
        mealsSubject.eraseToAnyPublisher()
    }
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
        
        // Listen to auth changes to update cache
        authRepository.currentUserPublisher
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.fetchLocalCache()
                }
            }
            .store(in: &cancellables)
    }
    
    public func setSyncEngine(_ syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }
    
    public func getMeals(startDate: Date, endDate: Date) async throws -> [Meal] {
        // Filter local cache by date range
        return mealsSubject.value.filter { meal in
            meal.timestamp >= startDate && meal.timestamp <= endDate
        }
    }
    
    @MainActor
    public func logMeal(method: LoggingMethod, items: [FoodItem]) async throws {
        guard let currentUser = authRepository.currentUser else {
            throw NSError(domain: "VitalisError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let context = dataController.mainContext
        let userId = currentUser.id
        let timestamp = Date()
        
        let mealId = UUID()
        let eventId = UUID()
        
        // Calculate total macros
        let totalCalories = items.reduce(0.0) { $0 + $1.macros.calories }
        let totalCarbs = items.reduce(0.0) { $0 + $1.macros.carbs }
        let totalFat = items.reduce(0.0) { $0 + $1.macros.fat }
        let totalProtein = items.reduce(0.0) { $0 + $1.macros.protein }
        let estimatedMacros = Macros(calories: totalCalories, carbs: totalCarbs, fat: totalFat, protein: totalProtein)
        
        // 1. Create and Save MealSD
        let macrosData = try JSONEncoder().encode(estimatedMacros)
        let macrosJSON = String(data: macrosData, encoding: .utf8) ?? "{}"
        
        let mealSD = MealSD(
            id: mealId,
            userId: userId,
            timestamp: timestamp,
            method: method.rawValue,
            macrosJSON: macrosJSON,
            microsJSON: "{}",
            isSynced: false
        )
        context.insert(mealSD)
        
        // 2. Create and Save child FoodItemSDs
        for item in items {
            let itemMacrosData = try JSONEncoder().encode(item.macros)
            let itemMacrosJSON = String(data: itemMacrosData, encoding: .utf8) ?? "{}"
            
            let itemSD = FoodItemSD(
                id: item.id,
                name: item.name,
                brand: item.brand,
                macrosJSON: itemMacrosJSON,
                microsJSON: "{}",
                confidenceScore: item.confidenceScore
            )
            itemSD.meal = mealSD
            context.insert(itemSD)
        }
        
        // 3. Create and Save TimelineEventSD
        let eventPayload = [
            "meal_id": mealId.uuidString,
            "calories": String(format: "%.0f", totalCalories),
            "protein": String(format: "%.0f", totalProtein),
            "carbs": String(format: "%.0f", totalCarbs),
            "fat": String(format: "%.0f", totalFat),
            "items_count": String(items.count),
            "method": method.rawValue
        ]
        let payloadData = try JSONEncoder().encode(eventPayload)
        let payloadJSON = String(data: payloadData, encoding: .utf8) ?? "{}"
        
        let linkedIds = [mealId]
        let linkedIdsData = try JSONEncoder().encode(linkedIds)
        let linkedIdsJSON = String(data: linkedIdsData, encoding: .utf8) ?? "[]"
        
        let eventSD = TimelineEventSD(
            id: eventId,
            userId: userId,
            timestamp: timestamp,
            type: "nutrition_log",
            payloadJSON: payloadJSON,
            linkedEntityIdsJSON: linkedIdsJSON,
            isSynced: false
        )
        context.insert(eventSD)
        
        // 4. Queue the Pair in the Sync Outbox
        let queueItem = SyncQueueItem(
            entityType: "meal_with_items",
            moodId: mealId, // Reuse moodId field for MealID
            eventId: eventId
        )
        context.insert(queueItem)
        
        try context.save()
        
        // Publish update to UI locally
        fetchLocalCache()
        
        // Publish Event to shared timeline bus
        let domainEvent = TimelineEvent(
            id: eventId,
            userId: userId,
            timestamp: timestamp,
            type: "nutrition_log",
            payload: eventPayload,
            linkedEntityIds: linkedIds
        )
        TimelineEventBus.shared.publish(domainEvent)
        
        // Trigger Sync loop
        if let syncEngine = syncEngine {
            Task {
                await syncEngine.processOutbox()
            }
        }
    }
    
    public func syncWithRemote() async throws {
        // Local-only: no remote synchronization needed.
    }
    
    @MainActor
    private func fetchLocalCache() {
        guard let currentUser = authRepository.currentUser else {
            mealsSubject.send([])
            return
        }
        
        let context = dataController.mainContext
        let currentUserId = currentUser.id
        let fetchDescriptor = FetchDescriptor<MealSD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let sds = try context.fetch(fetchDescriptor)
            let domainModels = sds.map { sd -> Meal in
                // Map macros
                let macrosData = sd.macrosJSON.data(using: .utf8) ?? Data()
                let macros = (try? JSONDecoder().decode(Macros.self, from: macrosData)) ?? Macros.zero
                
                // Map items
                let domainItems = sd.foodItems?.map { itemSD -> FoodItem in
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
                
                let logMethod = LoggingMethod(rawValue: sd.method) ?? .manual
                
                return Meal(
                    id: sd.id,
                    userId: sd.userId,
                    timestamp: sd.timestamp,
                    method: logMethod,
                    items: domainItems,
                    estimatedMacros: macros,
                    estimatedMicros: [:],
                    isSynced: sd.isSynced
                )
            }
            mealsSubject.send(domainModels)
        } catch {
            print("Failed to fetch local meals cache: \(error.localizedDescription)")
        }
    }
}
