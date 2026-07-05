import Foundation
import Combine
import Observation
import VitalisCore
import VitalisNetworking
import VitalisPersistence
import VitalisHealthKit

@Observable
public final class TodayViewModel {
    public let authRepository: AuthRepositoryProtocol
    public let readinessRepository: ReadinessRepositoryProtocol
    public let nutritionRepository: NutritionRepositoryProtocol
    public let healthKitService: HealthKitServiceProtocol
    
    public var currentUser: User? = nil
    public var readinessScore: ReadinessScore? = nil
    public var todayMeals: [Meal] = []
    
    // UI states
    public var isComputingReadiness = false
    public var errorMessage: String? = nil
    
    // Aggregated macros
    public var todayCalories: Double { todayMeals.reduce(0.0) { $0 + $1.estimatedMacros.calories } }
    public var todayCarbs: Double { todayMeals.reduce(0.0) { $0 + $1.estimatedMacros.carbs } }
    public var todayFat: Double { todayMeals.reduce(0.0) { $0 + $1.estimatedMacros.fat } }
    public var todayProtein: Double { todayMeals.reduce(0.0) { $0 + $1.estimatedMacros.protein } }
    
    // Standard targets
    public let calorieTarget: Double = 2200.0
    public let carbTarget: Double = 250.0
    public let fatTarget: Double = 70.0
    public let proteinTarget: Double = 140.0
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        authRepository: AuthRepositoryProtocol,
        readinessRepository: ReadinessRepositoryProtocol,
        nutritionRepository: NutritionRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.authRepository = authRepository
        self.readinessRepository = readinessRepository
        self.nutritionRepository = nutritionRepository
        self.healthKitService = healthKitService
        
        // Listen to auth
        authRepository.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                if user != nil {
                    self?.refreshAll()
                }
            }
            .store(in: &cancellables)
            
        // Listen to readiness
        readinessRepository.readinessScorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in
                self?.readinessScore = score
            }
            .store(in: &cancellables)
            
        // Listen to meals
        nutritionRepository.mealsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] meals in
                // Filter for meals logged today
                let calendar = Calendar.current
                self?.todayMeals = meals.filter { calendar.isDateInToday($0.timestamp) }
            }
            .store(in: &cancellables)
    }
    
    public func refreshAll() {
        Task {
            errorMessage = nil
            do {
                // Sync with remote
                try await readinessRepository.syncWithRemote()
                try await nutritionRepository.syncWithRemote()
                
                // Recompute readiness dynamically from local HealthKit data
                _ = try await readinessRepository.computeAndSaveReadiness(date: Date())
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func recomputeReadiness() {
        isComputingReadiness = true
        errorMessage = nil
        
        Task {
            do {
                // Request authorization if needed
                try await healthKitService.requestAuthorization()
                
                // Compute
                _ = try await readinessRepository.computeAndSaveReadiness(date: Date())
                
                await MainActor.run {
                    self.isComputingReadiness = false
                }
            } catch {
                await MainActor.run {
                    self.isComputingReadiness = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
