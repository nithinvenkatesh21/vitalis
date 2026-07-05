import Foundation
import Combine

public protocol TimelineRepositoryProtocol: AnyObject {
    var timelinePublisher: AnyPublisher<[TimelineEvent], Never> { get }
    func syncWithRemote() async throws
}
