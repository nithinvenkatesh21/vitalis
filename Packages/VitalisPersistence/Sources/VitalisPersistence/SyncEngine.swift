import Foundation
import Network
import SwiftData
import VitalisCore
import VitalisNetworking

public final class SyncEngine {
    private let dataController = VitalisDataController.shared
    private let networkService = MoodNetworkService()
    private let authRepository: AuthRepositoryProtocol
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "VitalisSyncEngineNetworkMonitor")
    
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
            
            let moodId = item.moodId
            let eventId = item.eventId
            
            // 1. Fetch corresponding local models from database context
            let moodDescriptor = FetchDescriptor<MoodEntrySD>(predicate: #Predicate { $0.id == moodId })
            let eventDescriptor = FetchDescriptor<TimelineEventSD>(predicate: #Predicate { $0.id == eventId })
            
            guard let localMood = (try? context.fetch(moodDescriptor))?.first,
                  let localEvent = (try? context.fetch(eventDescriptor))?.first else {
                // Clean up orphaned queue item to prevent blockage
                context.delete(item)
                try? context.save()
                continue
            }
            
            // 2. Only sync items that belong to the currently logged in user
            guard let currentUser = authRepository.currentUser,
                  localMood.userId == currentUser.id else {
                item.status = "pending"
                try? context.save()
                continue
            }
            
            // 3. Map local SwiftData models back to pure domain models
            let tagsData = localMood.tagsJSON.data(using: .utf8) ?? Data()
            let tags = (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
            let domainMood = MoodEntry(
                id: localMood.id,
                userId: localMood.userId,
                timestamp: localMood.timestamp,
                valence: localMood.valence,
                tags: tags,
                freeText: localMood.freeText
            )
            
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
            
            // 3. Atomically sync both to database using the database RPC transaction
            do {
                try await networkService.pushMoodWithTimeline(mood: domainMood, event: domainEvent)
                
                // SUCCESS: Mark local cached entities as synced, remove outbox queue item
                localMood.isSynced = true
                localEvent.isSynced = true
                context.delete(item)
                
                try context.save()
                print("SyncEngine: Successfully synced Mood \(moodId) & TimelineEvent \(eventId) atomically")
            } catch {
                print("SyncEngine: Atomic sync failed for pair \(item.id): \(error.localizedDescription)")
                // FAILURE: Reset state to failed so it will be retried in the next sync trigger
                item.status = "failed"
                try? context.save()
                
                // Abort sync loop execution for remaining items until network connectivity is resolved
                break
            }
        }
    }
}
