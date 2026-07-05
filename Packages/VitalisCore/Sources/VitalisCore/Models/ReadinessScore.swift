import Foundation

public struct ReadinessScore: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let date: Date
    public let compositeScore: Double // Range: 0.0 to 100.0
    public let components: [String: Double] // e.g. ["hrv": 0.5, "sleep": 0.5]
    public let explanation: [String]
    public let isSynced: Bool
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date = Date(),
        compositeScore: Double,
        components: [String: Double],
        explanation: [String] = [],
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.compositeScore = compositeScore
        self.components = components
        self.explanation = explanation
        self.isSynced = isSynced
    }
}
