import Foundation

public struct TimelineEvent: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let timestamp: Date
    public let type: String // e.g. "mood_entry", "nutrition_log", etc.
    public let payload: [String: String] // Simple string-based dictionary for metadata representation
    public let linkedEntityIds: [UUID]

    public init(
        id: UUID = UUID(),
        userId: UUID,
        timestamp: Date = Date(),
        type: String,
        payload: [String: String] = [:],
        linkedEntityIds: [UUID] = []
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.type = type
        self.payload = payload
        self.linkedEntityIds = linkedEntityIds
    }
}
