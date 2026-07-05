import Foundation
import Supabase
import VitalisCore

public final class NutritionNetworkService {
    private let supabase = VitalisSupabaseClient.shared.client
    
    public init() {}
    
    // Remote DTO mappings
    private struct FoodItemDTO: Codable {
        let id: UUID
        let name: String
        let brand: String?
        let macros_json: Macros
        let micros_json: [String: Double]
        let confidence_score: Double
        
        func toDomain() -> FoodItem {
            FoodItem(
                id: id,
                name: name,
                brand: brand,
                macros: macros_json,
                micros: micros_json,
                confidenceScore: confidence_score
            )
        }
    }
    
    private struct MealDTO: Codable {
        let id: UUID
        let user_id: UUID
        let timestamp: Date
        let method: String
        let macros_json: Macros
        let micros_json: [String: Double]
        let food_items: [FoodItemDTO]?
        
        func toDomain() -> Meal {
            let domainItems = food_items?.map { $0.toDomain() } ?? []
            let logMethod = LoggingMethod(rawValue: method) ?? .manual
            return Meal(
                id: id,
                userId: user_id,
                timestamp: timestamp,
                method: logMethod,
                items: domainItems,
                estimatedMacros: macros_json,
                estimatedMicros: micros_json,
                isSynced: true
            )
        }
    }
    
    private struct FoodItemRPC: Codable {
        let name: String
        let brand: String?
        let macros: Macros
        let micros: [String: Double]
        let confidenceScore: Double
    }
    
    private struct LogMealRPCRequest: Codable {
        let p_timestamp: Date
        let p_method: String
        let p_estimated_macros: Macros
        let p_estimated_micros: [String: Double]
        let p_items_json: [FoodItemRPC]
        let p_event_payload: [String: String]
    }
    
    /// Fetches meals and their associated food items from Supabase.
    public func fetchMeals() async throws -> [Meal] {
        let dtos: [MealDTO] = try await supabase
            .from("meals")
            .select("*, food_items(*)")
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return dtos.map { $0.toDomain() }
    }
    
    /// Pushes a meal log and its child food items atomically to Supabase.
    public func pushMealWithItems(meal: Meal, event: TimelineEvent) async throws {
        let rpcItems = meal.items.map { item in
            FoodItemRPC(
                name: item.name,
                brand: item.brand,
                macros: item.macros,
                micros: item.micros,
                confidenceScore: item.confidenceScore
            )
        }
        
        let request = LogMealRPCRequest(
            p_timestamp: meal.timestamp,
            p_method: meal.method.rawValue,
            p_estimated_macros: meal.estimatedMacros,
            p_estimated_micros: meal.estimatedMicros,
            p_items_json: rpcItems,
            p_event_payload: event.payload
        )
        
        _ = try await supabase
            .rpc("log_meal_with_items", params: request)
            .execute()
    }
}
