import Foundation
import Combine
import SwiftData
import VitalisCore
import VitalisNetworking

public final class MoodRepository: MoodRepositoryProtocol {
    private let dataController = VitalisDataController.shared
    private let authRepository: AuthRepositoryProtocol
    private let moodEntriesSubject = CurrentValueSubject<[MoodEntry], Never>([])
    private var syncEngine: SyncEngine?
    private var cancellables = Set<AnyCancellable>()
    
    public var moodEntriesPublisher: AnyPublisher<[MoodEntry], Never> {
        moodEntriesSubject.eraseToAnyPublisher()
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
    
    // Injects the SyncEngine to avoid circular dependency
    public func setSyncEngine(_ syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }
    
    public func getMoodEntries() async throws -> [MoodEntry] {
        return moodEntriesSubject.value
    }
    
    @MainActor
    public func logMood(valence: Double, freeText: String?, tags: [String]) async throws {
        guard let currentUser = authRepository.currentUser else {
            throw NSError(domain: "VitalisError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let context = dataController.mainContext
        let userId = currentUser.id
        let timestamp = Date()
        
        let moodId = UUID()
        let eventId = UUID()
        
        // 1. Create and Save MoodEntry locally (Un-synced)
        let tagsData = try JSONEncoder().encode(tags)
        let tagsJSON = String(data: tagsData, encoding: .utf8) ?? "[]"
        
        let moodSD = MoodEntrySD(
            id: moodId,
            userId: userId,
            timestamp: timestamp,
            valence: valence,
            tagsJSON: tagsJSON,
            freeText: freeText,
            isSynced: false
        )
        context.insert(moodSD)
        
        // 2. Create and Save corresponding TimelineEvent locally (Un-synced)
        let eventPayload = [
            "valence": String(valence),
            "free_text": freeText ?? "",
            "tags": tags.joined(separator: ",")
        ]
        let payloadData = try JSONEncoder().encode(eventPayload)
        let payloadJSON = String(data: payloadData, encoding: .utf8) ?? "{}"
        
        let linkedIds = [moodId]
        let linkedIdsData = try JSONEncoder().encode(linkedIds)
        let linkedIdsJSON = String(data: linkedIdsData, encoding: .utf8) ?? "[]"
        
        let eventSD = TimelineEventSD(
            id: eventId,
            userId: userId,
            timestamp: timestamp,
            type: "mood_entry",
            payloadJSON: payloadJSON,
            linkedEntityIdsJSON: linkedIdsJSON,
            isSynced: false
        )
        context.insert(eventSD)
        
        // 3. Queue the Pair in the Sync Outbox for Atomic Sync
        let queueItem = SyncQueueItem(moodId: moodId, eventId: eventId)
        context.insert(queueItem)
        
        // Commit changes to SwiftData
        try context.save()
        
        // Publish update to UI locally
        fetchLocalCache()
        
        // Publish Event to shared timeline bus
        let domainEvent = TimelineEvent(
            id: eventId,
            userId: userId,
            timestamp: timestamp,
            type: "mood_entry",
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
            moodEntriesSubject.send([])
            return
        }
        
        let context = dataController.mainContext
        let currentUserId = currentUser.id
        let fetchDescriptor = FetchDescriptor<MoodEntrySD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let sds = try context.fetch(fetchDescriptor)
            let domainModels = sds.map { sd -> MoodEntry in
                let tagsData = sd.tagsJSON.data(using: .utf8) ?? Data()
                let tags = (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
                return MoodEntry(
                    id: sd.id,
                    userId: sd.userId,
                    timestamp: sd.timestamp,
                    valence: sd.valence,
                    tags: tags,
                    freeText: sd.freeText,
                    isSynced: sd.isSynced
                )
            }
            moodEntriesSubject.send(domainModels)
        } catch {
            print("Failed to fetch local mood cache: \(error.localizedDescription)")
        }
    }
}
