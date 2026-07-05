import Foundation
import SwiftData

@Model
public final class SyncQueueItem {
    @Attribute(.unique) public var id: UUID
    public var entityType: String
    public var moodId: UUID
    public var eventId: UUID
    public var createdAt: Date
    public var status: String // "pending" | "syncing" | "failed"
    
    public init(id: UUID = UUID(), entityType: String = "mood_with_timeline", moodId: UUID, eventId: UUID, createdAt: Date = Date(), status: String = "pending") {
        self.id = id
        self.entityType = entityType
        self.moodId = moodId
        self.eventId = eventId
        self.createdAt = createdAt
        self.status = status
    }
}
