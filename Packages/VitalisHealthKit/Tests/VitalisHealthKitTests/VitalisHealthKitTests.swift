import XCTest
@testable import VitalisHealthKit

final class VitalisHealthKitTests: XCTestCase {
    
    func testHealthKitServiceMockValues() async throws {
        let service = HealthKitService()
        
        // requestAuthorization should complete successfully on mock/simulators
        try await service.requestAuthorization()
        
        XCTAssertTrue(service.isAuthorized())
        
        // HRV should return a random simulated value on mock/simulators
        let hrv = try await service.fetchHRV(date: Date())
        XCTAssertNotNil(hrv)
        if let val = hrv {
            XCTAssertGreaterThanOrEqual(val, 45.0)
            XCTAssertLessThanOrEqual(val, 115.0)
        }
        
        // Sleep duration should return a random simulated value on mock/simulators
        let sleep = try await service.fetchSleepDuration(date: Date())
        XCTAssertNotNil(sleep)
        if let val = sleep {
            XCTAssertGreaterThanOrEqual(val, 5.5)
            XCTAssertLessThanOrEqual(val, 9.0)
        }
    }
}
