import Foundation

public enum LoggingMethod: String, Codable {
    case photo = "PHOTO"
    case barcode = "BARCODE"
    case voice = "VOICE"
    case manual = "MANUAL"
}

public struct Meal: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let timestamp: Date
    public let method: LoggingMethod
    public let items: [FoodItem]
    public let estimatedMacros: Macros
    public let estimatedMicros: [String: Double]
    public let isSynced: Bool
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        timestamp: Date = Date(),
        method: LoggingMethod,
        items: [FoodItem],
        estimatedMacros: Macros,
        estimatedMicros: [String: Double] = [:],
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.method = method
        self.items = items
        self.estimatedMacros = estimatedMacros
        self.estimatedMicros = estimatedMicros
        self.isSynced = isSynced
    }
}
