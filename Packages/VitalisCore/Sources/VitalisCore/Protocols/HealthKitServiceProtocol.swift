import Foundation

public protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func isAuthorized() -> Bool
    
    /// Fetches the heart rate variability (SDNN) in milliseconds for the given date.
    func fetchHRV(date: Date) async throws -> Double?
    
    /// Fetches the sleep duration in hours for the sleep session ending on the given date.
    func fetchSleepDuration(date: Date) async throws -> Double?
}
