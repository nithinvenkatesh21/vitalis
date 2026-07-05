import Foundation

public struct User: Identifiable, Codable, Equatable {
    public let id: UUID
    public let displayName: String
    public let demographics: [String: String]?
    public let goals: [String: String]?
    public let familyGroupId: UUID?
    public let createdAt: Date

    public init(
        id: UUID,
        displayName: String,
        demographics: [String: String]? = nil,
        goals: [String: String]? = nil,
        familyGroupId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.demographics = demographics
        self.goals = goals
        self.familyGroupId = familyGroupId
        self.createdAt = createdAt
    }
}
