import Foundation
#if canImport(HealthKit)
import HealthKit
#endif
import VitalisCore

public final class HealthKitService: HealthKitServiceProtocol {
    #if canImport(HealthKit) && !os(macOS)
    private let healthStore = HKHealthStore()
    #endif
    
    public init() {}
    
    public func requestAuthorization() async throws {
        #if canImport(HealthKit) && !os(macOS)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "VitalisHealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"])
        }
        
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw NSError(domain: "VitalisHealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Biometric types not available"])
        }
        
        let typesToRead: Set<HKObjectType> = [hrvType, sleepType]
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        #else
        print("HealthKitService: Authorization completed on mock/macOS platform")
        #endif
    }
    
    public func isAuthorized() -> Bool {
        #if canImport(HealthKit) && !os(macOS)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return true
        #endif
    }
    
    public func fetchHRV(date: Date) async throws -> Double? {
        #if canImport(HealthKit) && !os(macOS)
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalHrv = quantitySamples.reduce(0.0) { sum, sample in
                    sum + sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                }
                let avgHrv = totalHrv / Double(quantitySamples.count)
                continuation.resume(returning: avgHrv)
            }
            healthStore.execute(query)
        }
        #else
        // Mock HRV values on simulators or macOS
        return Double.random(in: 45.0...115.0)
        #endif
    }
    
    public func fetchSleepDuration(date: Date) async throws -> Double? {
        #if canImport(HealthKit) && !os(macOS)
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var totalAsleepTime: TimeInterval = 0
                for sample in sleepSamples {
                    let isAsleep: Bool
                    if #available(iOS 16.0, *) {
                        isAsleep = sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    } else {
                        isAsleep = sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                    }
                    
                    if isAsleep {
                        totalAsleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                let hours = totalAsleepTime / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            healthStore.execute(query)
        }
        #else
        // Mock sleep duration on simulator or macOS
        return Double.random(in: 5.5...9.0)
        #endif
    }
}
