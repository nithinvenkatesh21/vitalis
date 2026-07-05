import Foundation
import SwiftData

@Model
public final class MoodEntrySD {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var timestamp: Date
    public var valence: Double
    public var tagsJSON: String
    public var freeText: String?
    public var isSynced: Bool
    
    public init(id: UUID, userId: UUID, timestamp: Date, valence: Double, tagsJSON: String, freeText: String?, isSynced: Bool = false) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.valence = valence
        self.tagsJSON = tagsJSON
        self.freeText = freeText
        self.isSynced = isSynced
    }
}
