import Foundation
import SwiftData

public final class VitalisDataController {
    public static let shared = VitalisDataController()
    
    public let container: ModelContainer
    
    private init() {
        let schema = Schema([
            UserSD.self,
            MoodEntrySD.self,
            TimelineEventSD.self,
            MealSD.self,
            FoodItemSD.self,
            ReadinessScoreSD.self,
            SyncQueueItem.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    public var mainContext: ModelContext {
        container.mainContext
    }
}
