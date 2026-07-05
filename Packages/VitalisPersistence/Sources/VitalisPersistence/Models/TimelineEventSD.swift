import Foundation
import SwiftData

@Model
public final class TimelineEventSD {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var timestamp: Date
    public var type: String
    public var payloadJSON: String
    public var linkedEntityIdsJSON: String
    public var isSynced: Bool
    
    public init(id: UUID, userId: UUID, timestamp: Date, type: String, payloadJSON: String, linkedEntityIdsJSON: String, isSynced: Bool = false) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.type = type
        self.payloadJSON = payloadJSON
        self.linkedEntityIdsJSON = linkedEntityIdsJSON
        self.isSynced = isSynced
    }
}
