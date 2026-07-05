import Foundation

public struct MoodEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let timestamp: Date
    public let valence: Double // Range: 0.0 (worst) to 1.0 (best)
    public let tags: [String]
    public let freeText: String?
    public let isSynced: Bool

    public init(
        id: UUID = UUID(),
        userId: UUID,
        timestamp: Date = Date(),
        valence: Double,
        tags: [String] = [],
        freeText: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.valence = max(0.0, min(1.0, valence))
        self.tags = tags
        self.freeText = freeText
        self.isSynced = isSynced
    }
}
