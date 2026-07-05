import Foundation
import Combine

public protocol NutritionRepositoryProtocol {
    var mealsPublisher: AnyPublisher<[Meal], Never> { get }
    
    func getMeals(startDate: Date, endDate: Date) async throws -> [Meal]
    func logMeal(method: LoggingMethod, items: [FoodItem]) async throws
    func syncWithRemote() async throws
}
