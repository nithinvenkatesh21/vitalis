import Foundation
import SwiftData

@Model
public final class ReadinessScoreSD {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var date: Date
    public var compositeScore: Double
    public var componentsJSON: String
    public var explanationJSON: String
    public var isSynced: Bool
    
    public init(id: UUID, userId: UUID, date: Date, compositeScore: Double, componentsJSON: String, explanationJSON: String, isSynced: Bool = false) {
        self.id = id
        self.userId = userId
        self.date = date
        self.compositeScore = compositeScore
        self.componentsJSON = componentsJSON
        self.explanationJSON = explanationJSON
        self.isSynced = isSynced
    }
}
