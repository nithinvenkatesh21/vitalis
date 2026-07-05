import XCTest
import SwiftData
@testable import VitalisPersistence

final class VitalisPersistenceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let schema = Schema([
            UserSD.self,
            MoodEntrySD.self,
            TimelineEventSD.self,
            MealSD.self,
            FoodItemSD.self,
            ReadinessScoreSD.self,
            SyncQueueItem.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }
    
    @MainActor
    func testInsertUserSD() {
        let userId = UUID()
        let userSD = UserSD(id: userId, displayName: "Test User")
        context.insert(userSD)
        
        let descriptor = FetchDescriptor<UserSD>()
        let fetched = try! context.fetch(descriptor)
        
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, userId)
        XCTAssertEqual(fetched.first?.displayName, "Test User")
    }
    
    @MainActor
    func testInsertMoodEntrySD() {
        let moodId = UUID()
        let userId = UUID()
        let moodSD = MoodEntrySD(
            id: moodId,
            userId: userId,
            timestamp: Date(),
            valence: 0.8,
            tagsJSON: "[\"test\"]",
            freeText: "Feeling good",
            isSynced: false
        )
        context.insert(moodSD)
        
        let descriptor = FetchDescriptor<MoodEntrySD>()
        let fetched = try! context.fetch(descriptor)
        
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, moodId)
        XCTAssertEqual(fetched.first?.valence, 0.8)
        XCTAssertFalse(fetched.first!.isSynced)
    }
    
    @MainActor
    func testInsertMealAndFoodItems() {
        let mealId = UUID()
        let userId = UUID()
        let mealSD = MealSD(
            id: mealId,
            userId: userId,
            timestamp: Date(),
            method: "MANUAL",
            macrosJSON: "{\"calories\":350}",
            microsJSON: "{}",
            isSynced: false
        )
        context.insert(mealSD)
        
        let itemId = UUID()
        let foodItemSD = FoodItemSD(
            id: itemId,
            name: "Oatmeal",
            brand: "Quaker",
            macrosJSON: "{\"calories\":150}",
            microsJSON: "{}"
        )
        foodItemSD.meal = mealSD
        context.insert(foodItemSD)
        
        let mealDescriptor = FetchDescriptor<MealSD>()
        let fetchedMeals = try! context.fetch(mealDescriptor)
        
        XCTAssertEqual(fetchedMeals.count, 1)
        XCTAssertEqual(fetchedMeals.first?.id, mealId)
        XCTAssertEqual(fetchedMeals.first?.foodItems?.count, 1)
        XCTAssertEqual(fetchedMeals.first?.foodItems?.first?.name, "Oatmeal")
    }
    
    @MainActor
    func testInsertReadinessScore() {
        let scoreId = UUID()
        let userId = UUID()
        let readinessSD = ReadinessScoreSD(
            id: scoreId,
            userId: userId,
            date: Date(),
            compositeScore: 84.0,
            componentsJSON: "{\"hrv\":78,\"sleep\":88}",
            explanationJSON: "[\"Good sleep\", \"HRV matches baseline\"]",
            isSynced: false
        )
        context.insert(readinessSD)
        
        let descriptor = FetchDescriptor<ReadinessScoreSD>()
        let fetched = try! context.fetch(descriptor)
        
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, scoreId)
        XCTAssertEqual(fetched.first?.compositeScore, 84.0)
    }
    
    @MainActor
    func testSyncQueueItemInsertion() {
        let moodId = UUID()
        let eventId = UUID()
        let queueItem = SyncQueueItem(moodId: moodId, eventId: eventId)
        context.insert(queueItem)
        
        let descriptor = FetchDescriptor<SyncQueueItem>()
        let fetched = try! context.fetch(descriptor)
        
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.moodId, moodId)
        XCTAssertEqual(fetched.first?.eventId, eventId)
        XCTAssertEqual(fetched.first?.status, "pending")
    }
}
