import XCTest
import Combine
@testable import VitalisCore

final class VitalisCoreTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testUserInitialization() {
        let userId = UUID()
        let displayName = "Test User"
        let user = User(id: userId, displayName: displayName)
        
        XCTAssertEqual(user.id, userId)
        XCTAssertEqual(user.displayName, displayName)
        XCTAssertNil(user.demographics)
    }
    
    func testMoodEntryValenceClamping() {
        let userId = UUID()
        
        // Test high value clamping
        let highMood = MoodEntry(userId: userId, valence: 1.5)
        XCTAssertEqual(highMood.valence, 1.0)
        
        // Test low value clamping
        let lowMood = MoodEntry(userId: userId, valence: -0.5)
        XCTAssertEqual(lowMood.valence, 0.0)
        
        // Test within range
        let normalMood = MoodEntry(userId: userId, valence: 0.75)
        XCTAssertEqual(normalMood.valence, 0.75)
    }
    
    func testTimelineEventBus() {
        let userId = UUID()
        let event = TimelineEvent(userId: userId, type: "test_event", payload: ["key": "value"])
        
        let expectation = XCTestExpectation(description: "Event Bus receives published event")
        
        TimelineEventBus.shared.eventPublisher
            .sink { receivedEvent in
                XCTAssertEqual(receivedEvent.id, event.id)
                XCTAssertEqual(receivedEvent.type, "test_event")
                XCTAssertEqual(receivedEvent.payload["key"], "value")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        TimelineEventBus.shared.publish(event)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
