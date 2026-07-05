import Foundation
import Combine

public protocol ReadinessRepositoryProtocol {
    var readinessScorePublisher: AnyPublisher<ReadinessScore?, Never> { get }
    
    func getReadinessScore(date: Date) async throws -> ReadinessScore?
    func computeAndSaveReadiness(date: Date) async throws -> ReadinessScore
    func syncWithRemote() async throws
}
