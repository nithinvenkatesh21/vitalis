import Foundation
import SwiftData

@Model
public final class UserSD {
    @Attribute(.unique) public var id: UUID
    public var displayName: String
    public var demographicsJSON: String?
    public var goalsJSON: String?
    public var familyGroupId: UUID?
    public var createdAt: Date
    
    public init(id: UUID, displayName: String, demographicsJSON: String? = nil, goalsJSON: String? = nil, familyGroupId: UUID? = nil, createdAt: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.demographicsJSON = demographicsJSON
        self.goalsJSON = goalsJSON
        self.familyGroupId = familyGroupId
        self.createdAt = createdAt
    }
}
