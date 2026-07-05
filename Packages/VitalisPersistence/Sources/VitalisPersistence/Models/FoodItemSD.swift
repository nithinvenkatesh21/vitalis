import Foundation
import SwiftData

@Model
public final class FoodItemSD {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var brand: String?
    public var macrosJSON: String
    public var microsJSON: String
    public var confidenceScore: Double
    
    public var meal: MealSD?
    
    public init(id: UUID, name: String, brand: String?, macrosJSON: String, microsJSON: String, confidenceScore: Double = 1.0) {
        self.id = id
        self.name = name
        self.brand = brand
        self.macrosJSON = macrosJSON
        self.microsJSON = microsJSON
        self.confidenceScore = confidenceScore
    }
}
