import Foundation
import Combine

public protocol MoodRepositoryProtocol {
    func getMoodEntries() async throws -> [MoodEntry]
    func logMood(valence: Double, freeText: String?, tags: [String]) async throws
    func syncWithRemote() async throws
    
    // Publisher to notify UI of mood updates
    var moodEntriesPublisher: AnyPublisher<[MoodEntry], Never> { get }
}
