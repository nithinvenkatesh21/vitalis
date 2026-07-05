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
