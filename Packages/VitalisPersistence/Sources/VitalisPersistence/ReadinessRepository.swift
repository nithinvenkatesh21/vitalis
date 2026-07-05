import Foundation
import Combine
import SwiftData
import VitalisCore
import VitalisNetworking

public final class ReadinessRepository: ReadinessRepositoryProtocol {
    private let dataController = VitalisDataController.shared
    private let authRepository: AuthRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let readinessScoreSubject = CurrentValueSubject<ReadinessScore?, Never>(nil)
    private var syncEngine: SyncEngine?
    private var cancellables = Set<AnyCancellable>()
    
    public var readinessScorePublisher: AnyPublisher<ReadinessScore?, Never> {
        readinessScoreSubject.eraseToAnyPublisher()
    }
    
    public init(authRepository: AuthRepositoryProtocol, healthKitService: HealthKitServiceProtocol) {
        self.authRepository = authRepository
        self.healthKitService = healthKitService
        
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
    
    public func getReadinessScore(date: Date) async throws -> ReadinessScore? {
        // Find in cached subject values
        let calendar = Calendar.current
        return readinessScoreSubject.value
    }
    
    @MainActor
    public func computeAndSaveReadiness(date: Date) async throws -> ReadinessScore {
        guard let currentUser = authRepository.currentUser else {
            throw NSError(domain: "VitalisError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let context = dataController.mainContext
        let userId = currentUser.id
        
        // 1. Fetch from HealthKit (will gracefully handle missing/denied permissions)
        let hrvValue = try? await healthKitService.fetchHRV(date: date)
        let sleepValue = try? await healthKitService.fetchSleepDuration(date: date)
        
        // 2. Perform Graceful Degradation / Reweighting Algorithm
        var compositeScore: Double = 50.0 // Default baseline
        var components: [String: Double] = [:]
        var explanation: [String] = []
        
        let hrvScore: Double? = hrvValue.map { max(0.0, min(100.0, ($0 / 80.0) * 100.0)) }
        let sleepScore: Double? = sleepValue.map { max(0.0, min(100.0, ($0 / 8.0) * 100.0)) }
        
        if let hrv = hrvValue, let hrvSc = hrvScore, let sleep = sleepValue, let sleepSc = sleepScore {
            // Full metrics available
            compositeScore = (hrvSc * 0.5) + (sleepSc * 0.5)
            components = ["hrv": hrv, "sleep": sleep]
            explanation = [
                "Sleep was \(String(format: "%.1f", sleep)) hours.",
                "Average HRV was \(String(format: "%.0f", hrv)) ms."
            ]
        } else if let hrv = hrvValue, let hrvSc = hrvScore {
            // HRV only
            compositeScore = hrvSc
            components = ["hrv": hrv]
            explanation = [
                "Average HRV was \(String(format: "%.0f", hrv)) ms.",
                "Sleep data missing (reweighted 100% on HRV)."
            ]
        } else if let sleep = sleepValue, let sleepSc = sleepScore {
            // Sleep only
            compositeScore = sleepSc
            components = ["sleep": sleep]
            explanation = [
                "Sleep was \(String(format: "%.1f", sleep)) hours.",
                "HRV data missing (reweighted 100% on Sleep)."
            ]
        } else {
            // No data
            compositeScore = 50.0
            components = [:]
            explanation = [
                "No HealthKit biometrics available.",
                "Enable HealthKit permissions in iOS Settings."
            ]
        }
        
        let readinessId = UUID()
        let eventId = UUID()
        
        // 3. Create or Update SwiftData ReadinessScoreSD
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Fetch to check for existing record for user+date to enforce local uniqueness
        let fetchDescriptor = FetchDescriptor<ReadinessScoreSD>(
            predicate: #Predicate { $0.userId == userId && $0.date == startOfDay }
        )
        
        let existingScores = try? context.fetch(fetchDescriptor)
        let componentsJSON = String(data: try JSONEncoder().encode(components), encoding: .utf8) ?? "{}"
        let explanationJSON = String(data: try JSONEncoder().encode(explanation), encoding: .utf8) ?? "[]"
        
        if let existing = existingScores?.first {
            existing.compositeScore = compositeScore
            existing.componentsJSON = componentsJSON
            existing.explanationJSON = explanationJSON
            existing.isSynced = false
        } else {
            let scoreSD = ReadinessScoreSD(
                id: readinessId,
                userId: userId,
                date: startOfDay,
                compositeScore: compositeScore,
                componentsJSON: componentsJSON,
                explanationJSON: explanationJSON,
                isSynced: false
            )
            context.insert(scoreSD)
        }
        
        // 4. Create and Save TimelineEventSD
        let eventPayload = [
            "composite_score": String(format: "%.0f", compositeScore),
            "explanation": explanation.joined(separator: " | ")
        ]
        let payloadData = try JSONEncoder().encode(eventPayload)
        let payloadJSON = String(data: payloadData, encoding: .utf8) ?? "{}"
        
        let linkedIds = [readinessId]
        let linkedIdsData = try JSONEncoder().encode(linkedIds)
        let linkedIdsJSON = String(data: linkedIdsData, encoding: .utf8) ?? "[]"
        
        let eventSD = TimelineEventSD(
            id: eventId,
            userId: userId,
            timestamp: Date(),
            type: "readiness_score",
            payloadJSON: payloadJSON,
            linkedEntityIdsJSON: linkedIdsJSON,
            isSynced: false
        )
        context.insert(eventSD)
        
        // 5. Queue the Pair in the Sync Outbox
        let queueItem = SyncQueueItem(
            entityType: "readiness_score",
            moodId: readinessId, // Reuse moodId field for ReadinessID
            eventId: eventId
        )
        context.insert(queueItem)
        
        try context.save()
        
        // Publish update to UI
        fetchLocalCache()
        
        // Publish Event to shared timeline bus
        let domainEvent = TimelineEvent(
            id: eventId,
            userId: userId,
            timestamp: Date(),
            type: "readiness_score",
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
        
        return ReadinessScore(
            id: readinessId,
            userId: userId,
            date: startOfDay,
            compositeScore: compositeScore,
            components: components,
            explanation: explanation,
            isSynced: false
        )
    }
    
    public func syncWithRemote() async throws {
        // Local-only: no remote synchronization needed.
    }
    
    @MainActor
    private func fetchLocalCache() {
        guard let currentUser = authRepository.currentUser else {
            readinessScoreSubject.send(nil)
            return
        }
        
        let context = dataController.mainContext
        let currentUserId = currentUser.id
        
        // Fetch the most recent readiness score for the current user
        let fetchDescriptor = FetchDescriptor<ReadinessScoreSD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let sds = try context.fetch(fetchDescriptor)
            if let latestSD = sds.first {
                let componentsData = latestSD.componentsJSON.data(using: .utf8) ?? Data()
                let components = (try? JSONDecoder().decode([String: Double].self, from: componentsData)) ?? [:]
                
                let explanationData = latestSD.explanationJSON.data(using: .utf8) ?? Data()
                let explanation = (try? JSONDecoder().decode([String].self, from: explanationData)) ?? []
                
                let domainModel = ReadinessScore(
                    id: latestSD.id,
                    userId: latestSD.userId,
                    date: latestSD.date,
                    compositeScore: latestSD.compositeScore,
                    components: components,
                    explanation: explanation,
                    isSynced: latestSD.isSynced
                )
                readinessScoreSubject.send(domainModel)
            } else {
                readinessScoreSubject.send(nil)
            }
        } catch {
            print("Failed to fetch local readiness cache: \(error.localizedDescription)")
        }
    }
}
