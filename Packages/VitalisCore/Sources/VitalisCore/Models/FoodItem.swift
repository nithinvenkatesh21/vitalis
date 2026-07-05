import Foundation

public struct Macros: Codable, Equatable {
    public let calories: Double
    public let carbs: Double
    public let fat: Double
    public let protein: Double
    
    public init(calories: Double, carbs: Double, fat: Double, protein: Double) {
        self.calories = calories
        self.carbs = carbs
        self.fat = fat
        self.protein = protein
    }
    
    public static var zero: Macros {
        Macros(calories: 0, carbs: 0, fat: 0, protein: 0)
    }
}

public struct FoodItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let brand: String?
    public let macros: Macros
    public let micros: [String: Double]
    public let confidenceScore: Double
    
    public init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        macros: Macros,
        micros: [String: Double] = [:],
        confidenceScore: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.macros = macros
        self.micros = micros
        self.confidenceScore = confidenceScore
    }
}
