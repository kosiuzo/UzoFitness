//
//  HealthKitError.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/18/25.
//


import HealthKit
import UzoFitnessCore

// MARK: - Protocols for Dependency Injection
// (HealthStoreProtocol removed; now in UzoFitnessCore)

// MARK: - Query Executor Protocol for Easier Testing
// (QueryExecutorProtocol removed; now in UzoFitnessCore)

// MARK: - Protocol Extensions for Real Implementations

extension HKHealthStore: HealthStoreProtocol {}

// Real implementation using HKHealthStore
struct HealthKitQueryExecutor: QueryExecutorProtocol {
    let healthStore: HKHealthStore
    
    func executeSampleQuery(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor],
        completion: @escaping ([HKSample]?, Error?) -> Void
    ) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { _, samples, error in
            completion(samples, error)
        }
        healthStore.execute(query)
    }
}

// Wrapper for Calendar to conform to CalendarProtocol
struct CalendarWrapper: CalendarProtocol {
    private let calendar: Calendar
    
    init(_ calendar: Calendar) {
        self.calendar = calendar
    }
    
    func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        return calendar.date(byAdding: component, value: value, to: date)
    }
}

// Default implementation for HealthKit type factory
struct HealthKitTypeFactory: HealthKitTypeFactoryProtocol {
    func quantityType(forIdentifier identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: identifier)
    }
}

enum HealthKitError: Error {
    case typeUnavailable
}

final class HealthKitManager {
    private let healthStore: HealthStoreProtocol
    private let calendar: CalendarProtocol
    private let typeFactory: HealthKitTypeFactoryProtocol
    private let queryExecutor: QueryExecutorProtocol
    
    /// Allows injection of dependencies for testing
    init(healthStore: HealthStoreProtocol = HKHealthStore(),
         calendar: CalendarProtocol = CalendarWrapper(Calendar.current),
         typeFactory: HealthKitTypeFactoryProtocol = HealthKitTypeFactory(),
         queryExecutor: QueryExecutorProtocol? = nil) {
        self.healthStore = healthStore
        self.calendar = calendar
        self.typeFactory = typeFactory
        
        // Use the provided queryExecutor or create a default one
        if let queryExecutor = queryExecutor {
            self.queryExecutor = queryExecutor
        } else if let hkStore = healthStore as? HKHealthStore {
            self.queryExecutor = HealthKitQueryExecutor(healthStore: hkStore)
        } else {
            // This should not happen in real scenarios, but provides a fallback for testing
            fatalError("QueryExecutor must be provided when using a mock HealthStore")
        }
    }
    
    /// 1. Request read permission for bodyMass & bodyFatPercentage
    func requestAuthorization(completion: @Sendable @escaping (Bool, Error?) -> Void) {
        guard
            let massType = typeFactory.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass),
            let fatType = typeFactory.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)
        else {
            return completion(false, HealthKitError.typeUnavailable)
        }
        
        let readTypes: Set<HKObjectType> = [massType, fatType]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            completion(success, error)
        }
    }
    
    /// 2a. Fetch most recent body-mass in pounds
    func fetchLatestBodyMassInPounds(completion: @escaping (Double?, Error?) -> Void) {
        fetchBodyMass(limit: 1, predicate: nil) { kg, err in
            guard let kg = kg else { return completion(nil, err) }
            completion(kg * 2.2046226218, nil)
        }
    }
    
    /// 2b. Fetch body-mass on a specific day (0–24 h) in pounds
    func fetchBodyMassInPounds(on date: Date,
                               completion: @escaping (Double?, Error?) -> Void) {
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        fetchBodyMass(limit: 1, predicate: predicate) { kg, err in
            guard let kg = kg else { return completion(nil, err) }
            completion(kg * 2.2046226218, nil)
        }
    }
    
    /// 3a. Fetch most recent body-fat fraction (0–1)
    func fetchLatestBodyFat(completion: @escaping (Double?, Error?) -> Void) {
        fetchBodyFat(limit: 1, predicate: nil, completion: completion)
    }
    
    /// 3b. Fetch body-fat on a specific day
    func fetchBodyFat(on date: Date,
                      completion: @escaping (Double?, Error?) -> Void) {
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        fetchBodyFat(limit: 1, predicate: predicate, completion: completion)
    }
}

// MARK: - Private Helpers
extension HealthKitManager {
    private func fetchBodyMass(limit: Int,
                               predicate: NSPredicate?,
                               completion: @escaping (Double?, Error?) -> Void) {
        guard let type = typeFactory.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) else {
            return completion(nil, HealthKitError.typeUnavailable)
        }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        queryExecutor.executeSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sort]) { samples, error in
            let kg = (samples?.first as? HKQuantitySample)?
                .quantity.doubleValue(for: .gramUnit(with: .kilo))
            completion(kg, error)
        }
    }
    
    private func fetchBodyFat(limit: Int,
                              predicate: NSPredicate?,
                              completion: @escaping (Double?, Error?) -> Void) {
        guard let type = typeFactory.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage) else {
            return completion(nil, HealthKitError.typeUnavailable)
        }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        queryExecutor.executeSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sort]) { samples, error in
            let fraction = (samples?.first as? HKQuantitySample)?
                .quantity.doubleValue(for: .percent())
            completion(fraction, error)
        }
    }
    
    /// Returns midnight-to-midnight bounds for a given date
    private func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: Calendar.Component.day, value: 1, to: start)!
        return (start, end)
    }
}
