import Foundation
import SwiftData

@Model
public final class MealSD {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var timestamp: Date
    public var method: String
    public var macrosJSON: String
    public var microsJSON: String
    public var isSynced: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \FoodItemSD.meal)
    public var foodItems: [FoodItemSD]? = []
    
    public init(id: UUID, userId: UUID, timestamp: Date, method: String, macrosJSON: String, microsJSON: String, isSynced: Bool = false) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.method = method
        self.macrosJSON = macrosJSON
        self.microsJSON = microsJSON
        self.isSynced = isSynced
        self.foodItems = []
    }
}
