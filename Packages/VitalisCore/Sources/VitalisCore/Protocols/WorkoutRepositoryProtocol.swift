import Foundation

public protocol WorkoutRepositoryProtocol: AnyObject {
    func logWorkout(type: WorkoutType, sets: [SetLog], rpe: Double) async throws
}
