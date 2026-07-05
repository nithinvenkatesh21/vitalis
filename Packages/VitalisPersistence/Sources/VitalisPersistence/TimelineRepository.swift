import Foundation
import Combine
import SwiftData
import VitalisCore

public final class TimelineRepository: TimelineRepositoryProtocol {
    private let dataController = VitalisDataController.shared
    private let timelineSubject = CurrentValueSubject<[TimelineEvent], Never>([])
    private var cancellables = Set<AnyCancellable>()
    
    public var timelinePublisher: AnyPublisher<[TimelineEvent], Never> {
        timelineSubject.eraseToAnyPublisher()
    }
    
    public init() {
        // Load cache on init
        Task { @MainActor in
            self.fetchLocalCache()
        }
        
        // Listen to active events from the timeline event bus
        TimelineEventBus.shared.eventPublisher
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.fetchLocalCache()
                }
            }
            .store(in: &cancellables)
    }
    
    public func syncWithRemote() async throws {
        // Local-only: no remote synchronization needed.
    }
    
    @MainActor
    private func fetchLocalCache() {
        let context = dataController.mainContext
        let currentUserId = User.defaultId
        let fetchDescriptor = FetchDescriptor<TimelineEventSD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let sds = try context.fetch(fetchDescriptor)
            let domainModels = sds.map { sd -> TimelineEvent in
                let payloadData = sd.payloadJSON.data(using: .utf8) ?? Data()
                let payload = (try? JSONDecoder().decode([String: String].self, from: payloadData)) ?? [:]
                
                let linkedIdsData = sd.linkedEntityIdsJSON.data(using: .utf8) ?? Data()
                let linkedIds = (try? JSONDecoder().decode([UUID].self, from: linkedIdsData)) ?? []
                
                return TimelineEvent(
                    id: sd.id,
                    userId: sd.userId,
                    timestamp: sd.timestamp,
                    type: sd.type,
                    payload: payload,
                    linkedEntityIds: linkedIds
                )
            }
            timelineSubject.send(domainModels)
        } catch {
            print("Failed to fetch local timeline cache: \(error.localizedDescription)")
        }
    }
}
