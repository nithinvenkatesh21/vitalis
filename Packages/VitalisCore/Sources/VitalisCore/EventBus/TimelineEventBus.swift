import Foundation
import Combine

public final class TimelineEventBus {
    public static let shared = TimelineEventBus()
    
    private let eventSubject = PassthroughSubject<TimelineEvent, Never>()
    
    private init() {}
    
    public func publish(_ event: TimelineEvent) {
        eventSubject.send(event)
    }
    
    public var eventPublisher: AnyPublisher<TimelineEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
}
