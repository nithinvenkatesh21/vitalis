import Foundation
import Combine
import Observation
import VitalisCore
import VitalisPersistence

@Observable
public final class TimelineViewModel {
    private let timelineRepository: TimelineRepositoryProtocol
    
    public var events: [TimelineEvent] = []
    public var selectedFilter: String = "All"
    public var isLoading = false
    public var errorMessage: String? = nil
    
    public let filters = ["All", "Mood", "Nutrition", "Workout", "Readiness"]
    private var cancellables = Set<AnyCancellable>()
    
    public init(timelineRepository: TimelineRepositoryProtocol) {
        self.timelineRepository = timelineRepository
        
        // Listen to timeline cache changes
        timelineRepository.timelinePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.events = events
            }
            .store(in: &cancellables)
    }
    
    public var filteredEvents: [TimelineEvent] {
        switch selectedFilter {
        case "Mood":
            return events.filter { $0.type == "mood_entry" }
        case "Nutrition":
            return events.filter { $0.type == "nutrition_log" }
        case "Workout":
            return events.filter { $0.type == "workout_session" }
        case "Readiness":
            return events.filter { $0.type == "readiness_score" }
        default:
            return events
        }
    }
    
    public func refreshTimeline() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await timelineRepository.syncWithRemote()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
