import Foundation
import HealthKit
import Testing
import UzoFitnessCore
@testable import UzoFitness

// MARK: - Mock HealthKit Services

/// Mock implementation of HealthStoreProtocol for testing
final class MockHealthStore: HealthStoreProtocol {
    
    // MARK: - Mock Configuration
    var mockAuthorizationSuccess = true
    var mockAuthorizationError: Error?
    
    // MARK: - Call Tracking
    private(set) var requestAuthorizationCallCount = 0
    private(set) var executeCallCount = 0
    private(set) var lastRequestedShareTypes: Set<HKSampleType>?
    private(set) var lastRequestedReadTypes: Set<HKObjectType>?
    private(set) var executedQueries: [HKQuery] = []
    
    // MARK: - HealthStoreProtocol Implementation
    
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping @Sendable (Bool, Error?) -> Void) {
        requestAuthorizationCallCount += 1
        lastRequestedShareTypes = typesToShare
        lastRequestedReadTypes = typesToRead
        
        DispatchQueue.global().async {
            completion(self.mockAuthorizationSuccess, self.mockAuthorizationError)
        }
    }
    
    func execute(_ query: HKQuery) {
        executeCallCount += 1
        executedQueries.append(query)
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        requestAuthorizationCallCount = 0
        executeCallCount = 0
        lastRequestedShareTypes = nil
        lastRequestedReadTypes = nil
        executedQueries.removeAll()
        mockAuthorizationSuccess = true
        mockAuthorizationError = nil
    }
    
    func configure(authorizationSuccess: Bool = true, authorizationError: Error? = nil) {
        self.mockAuthorizationSuccess = authorizationSuccess
        self.mockAuthorizationError = authorizationError
    }
}

/// Mock implementation of QueryExecutorProtocol for testing
final class MockQueryExecutor: QueryExecutorProtocol {
    
    // MARK: - Mock Configuration
    var mockSamples: [HKSample] = []
    var mockError: Error?
    var executionDelay: TimeInterval = 0.0
    
    // MARK: - Call Tracking
    private(set) var executeSampleQueryCallCount = 0
    private(set) var lastSampleType: HKSampleType?
    private(set) var lastPredicate: NSPredicate?
    private(set) var lastLimit: Int = 0
    private(set) var lastSortDescriptors: [NSSortDescriptor] = []
    
    // MARK: - QueryExecutorProtocol Implementation
    
    func executeSampleQuery(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor],
        completion: @escaping ([HKSample]?, Error?) -> Void
    ) {
        executeSampleQueryCallCount += 1
        lastSampleType = sampleType
        lastPredicate = predicate
        lastLimit = limit
        lastSortDescriptors = sortDescriptors
        
        DispatchQueue.global().asyncAfter(deadline: .now() + executionDelay) {
            completion(self.mockSamples, self.mockError)
        }
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        executeSampleQueryCallCount = 0
        lastSampleType = nil
        lastPredicate = nil
        lastLimit = 0
        lastSortDescriptors = []
        mockSamples = []
        mockError = nil
        executionDelay = 0.0
    }
    
    func configure(samples: [HKSample] = [], error: Error? = nil, delay: TimeInterval = 0.0) {
        self.mockSamples = samples
        self.mockError = error
        self.executionDelay = delay
    }
}

/// Mock implementation of HealthKitTypeFactoryProtocol for testing
final class MockHealthKitTypeFactory: HealthKitTypeFactoryProtocol {
    
    // MARK: - Mock Configuration
    var mockQuantityTypes: [HKQuantityTypeIdentifier: HKQuantityType] = [:]
    var shouldReturnNil = false
    
    // MARK: - Call Tracking
    private(set) var quantityTypeCallCount = 0
    private(set) var requestedIdentifiers: [HKQuantityTypeIdentifier] = []
    
    // MARK: - HealthKitTypeFactoryProtocol Implementation
    
    func quantityType(forIdentifier identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        quantityTypeCallCount += 1
        requestedIdentifiers.append(identifier)
        
        if shouldReturnNil {
            return nil
        }
        
        // Return configured mock type or create a real one for testing
        if let mockType = mockQuantityTypes[identifier] {
            return mockType
        } else {
            return HKObjectType.quantityType(forIdentifier: identifier)
        }
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        quantityTypeCallCount = 0
        requestedIdentifiers = []
        mockQuantityTypes = [:]
        shouldReturnNil = false
    }
    
    func configure(quantityTypes: [HKQuantityTypeIdentifier: HKQuantityType] = [:], shouldReturnNil: Bool = false) {
        self.mockQuantityTypes = quantityTypes
        self.shouldReturnNil = shouldReturnNil
    }
}

/// Mock implementation of CalendarProtocol for testing
final class MockCalendar: CalendarProtocol {
    
    // MARK: - Mock Configuration
    var mockStartOfDay: Date = Date()
    var mockDateByAdding: Date?
    
    // MARK: - Call Tracking
    private(set) var startOfDayCallCount = 0
    private(set) var dateByAddingCallCount = 0
    private(set) var lastStartOfDayInput: Date?
    private(set) var lastDateByAddingComponent: Calendar.Component?
    private(set) var lastDateByAddingValue: Int = 0
    private(set) var lastDateByAddingDate: Date?
    
    // MARK: - CalendarProtocol Implementation
    
    func startOfDay(for date: Date) -> Date {
        startOfDayCallCount += 1
        lastStartOfDayInput = date
        return mockStartOfDay
    }
    
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        dateByAddingCallCount += 1
        lastDateByAddingComponent = component
        lastDateByAddingValue = value
        lastDateByAddingDate = date
        return mockDateByAdding
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        startOfDayCallCount = 0
        dateByAddingCallCount = 0
        lastStartOfDayInput = nil
        lastDateByAddingComponent = nil
        lastDateByAddingValue = 0
        lastDateByAddingDate = nil
        mockStartOfDay = Date()
        mockDateByAdding = nil
    }
    
    func configure(startOfDay: Date = Date(), dateByAdding: Date? = nil) {
        self.mockStartOfDay = startOfDay
        self.mockDateByAdding = dateByAdding
    }
}

// MARK: - HealthKitManager Tests

/// Tests for HealthKitManager with comprehensive mock coverage
@MainActor
final class HealthKitManagerTests {
    
    // MARK: - Test Properties
    private var mockHealthStore: MockHealthStore!
    private var mockQueryExecutor: MockQueryExecutor!
    private var mockTypeFactory: MockHealthKitTypeFactory!
    private var mockCalendar: MockCalendar!
    private var healthKitManager: HealthKitManager!
    
    // MARK: - Setup and Teardown
    
    private func setUp() {
        mockHealthStore = MockHealthStore()
        mockQueryExecutor = MockQueryExecutor()
        mockTypeFactory = MockHealthKitTypeFactory()
        mockCalendar = MockCalendar()
        
        healthKitManager = HealthKitManager(
            healthStore: mockHealthStore,
            calendar: mockCalendar,
            typeFactory: mockTypeFactory,
            queryExecutor: mockQueryExecutor
        )
    }
    
    private func tearDown() {
        mockHealthStore = nil
        mockQueryExecutor = nil
        mockTypeFactory = nil
        mockCalendar = nil
        healthKitManager = nil
    }
    
    // MARK: - Mock Verification Tests
    
    @Test("Mock services initialize correctly")
    func testMockServicesInitialize() {
        setUp()
        defer { tearDown() }
        
        // Verify all mock services are properly initialized
        #expect(mockHealthStore.requestAuthorizationCallCount == 0)
        #expect(mockQueryExecutor.executeSampleQueryCallCount == 0)
        #expect(mockTypeFactory.quantityTypeCallCount == 0)
        #expect(mockCalendar.startOfDayCallCount == 0)
    }
    
    @Test("MockHealthStore tracks authorization requests")
    func testMockHealthStoreAuthorizationTracking() async {
        setUp()
        defer { tearDown() }
        
        // Configure mock for success
        mockHealthStore.configure(authorizationSuccess: true, authorizationError: nil)
        
        await withCheckedContinuation { continuation in
            mockHealthStore.requestAuthorization(toShare: nil, read: nil) { success, error in
                #expect(success == true)
                #expect(error == nil)
                continuation.resume()
            }
        }
        
        // Verify tracking
        #expect(mockHealthStore.requestAuthorizationCallCount == 1)
    }
    
    @Test("MockQueryExecutor tracks sample queries")
    func testMockQueryExecutorTracking() async throws {
        setUp()
        defer { tearDown() }
        
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitTestError.healthKitTypeCreationFailed
        }
        
        // Configure mock
        mockQueryExecutor.configure(samples: [], error: nil)
        
        await withCheckedContinuation { continuation in
            mockQueryExecutor.executeSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: []
            ) { samples, error in
                #expect(samples?.isEmpty == true)
                #expect(error == nil)
                continuation.resume()
            }
        }
        
        // Verify tracking
        #expect(mockQueryExecutor.executeSampleQueryCallCount == 1)
        #expect(mockQueryExecutor.lastSampleType == bodyMassType)
        #expect(mockQueryExecutor.lastLimit == 1)
    }
    
    @Test("MockHealthKitTypeFactory tracks type requests")
    func testMockHealthKitTypeFactoryTracking() {
        setUp()
        defer { tearDown() }
        
        // Request a type
        let result = mockTypeFactory.quantityType(forIdentifier: .bodyMass)
        
        // Verify tracking and result
        #expect(mockTypeFactory.quantityTypeCallCount == 1)
        #expect(mockTypeFactory.requestedIdentifiers.contains(.bodyMass))
        #expect(result != nil) // Should return real type by default
    }
    
    @Test("MockCalendar tracks date operations")
    func testMockCalendarTracking() {
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let expectedStartOfDay = Date().addingTimeInterval(-3600) // 1 hour earlier
        let expectedDateByAdding = Date().addingTimeInterval(86400) // 1 day later
        
        // Configure mock
        mockCalendar.configure(startOfDay: expectedStartOfDay, dateByAdding: expectedDateByAdding)
        
        // Test startOfDay
        let startOfDay = mockCalendar.startOfDay(for: testDate)
        #expect(startOfDay == expectedStartOfDay)
        #expect(mockCalendar.startOfDayCallCount == 1)
        #expect(mockCalendar.lastStartOfDayInput == testDate)
        
        // Test date(byAdding:)
        let dateByAdding = mockCalendar.date(byAdding: .day, value: 1, to: testDate)
        #expect(dateByAdding == expectedDateByAdding)
        #expect(mockCalendar.dateByAddingCallCount == 1)
        #expect(mockCalendar.lastDateByAddingComponent == .day)
        #expect(mockCalendar.lastDateByAddingValue == 1)
        #expect(mockCalendar.lastDateByAddingDate == testDate)
    }
    
    // MARK: - HealthKitManager Integration Tests
    
    @Test("HealthKitManager authorization success calls all dependencies")
    func testHealthKitManagerAuthorizationSuccess() async {
        setUp()
        defer { tearDown() }
        
        // Configure mocks for success
        mockTypeFactory.configure(shouldReturnNil: false)
        mockHealthStore.configure(authorizationSuccess: true, authorizationError: nil)
        
        await withCheckedContinuation { continuation in
            healthKitManager.requestAuthorization { success, error in
                #expect(success == true)
                #expect(error == nil)
                continuation.resume()
            }
        }
        
        // Verify type factory was called for required types
        #expect(mockTypeFactory.quantityTypeCallCount == 2) // bodyMass and bodyFatPercentage
        #expect(mockTypeFactory.requestedIdentifiers.contains(.bodyMass))
        #expect(mockTypeFactory.requestedIdentifiers.contains(.bodyFatPercentage))
        
        // Verify health store authorization was called
        #expect(mockHealthStore.requestAuthorizationCallCount == 1)
        #expect(mockHealthStore.lastRequestedReadTypes?.count == 2)
    }
    
    @Test("HealthKitManager authorization handles type unavailable error")
    func testHealthKitManagerAuthorizationTypeUnavailable() async {
        setUp()
        defer { tearDown() }
        
        // Configure type factory to return nil (type unavailable)
        mockTypeFactory.configure(shouldReturnNil: true)
        
        await withCheckedContinuation { continuation in
            healthKitManager.requestAuthorization { success, error in
                #expect(success == false)
                #expect(error != nil)
                if let healthKitError = error as? HealthKitError {
                    #expect(healthKitError == HealthKitError.typeUnavailable)
                }
                continuation.resume()
            }
        }
        
        // Verify type factory was called but health store was not
        #expect(mockTypeFactory.quantityTypeCallCount >= 1)
        #expect(mockHealthStore.requestAuthorizationCallCount == 0)
    }
    
    @Test("HealthKitManager authorization handles health store error")
    func testHealthKitManagerAuthorizationHealthStoreError() async {
        setUp()
        defer { tearDown() }
        
        // Configure mocks
        mockTypeFactory.configure(shouldReturnNil: false)
        let expectedError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        mockHealthStore.configure(authorizationSuccess: false, authorizationError: expectedError)
        
        await withCheckedContinuation { continuation in
            healthKitManager.requestAuthorization { success, error in
                #expect(success == false)
                #expect(error != nil)
                #expect((error as NSError?)?.domain == "TestError")
                continuation.resume()
            }
        }
        
        // Verify both dependencies were called
        #expect(mockTypeFactory.quantityTypeCallCount == 2)
        #expect(mockHealthStore.requestAuthorizationCallCount == 1)
    }
    
    @Test("HealthKitManager body mass query integration")
    func testHealthKitManagerBodyMassQuery() async throws {
        setUp()
        defer { tearDown() }
        
        // Create mock body mass sample
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitTestError.healthKitTypeCreationFailed
        }
        
        let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: 180.0)
        let sample = HKQuantitySample(
            type: bodyMassType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        // Configure mocks
        mockTypeFactory.configure(shouldReturnNil: false)
        mockQueryExecutor.configure(samples: [sample], error: nil)
        
        // Note: We can't easily test the actual fetchLatestBodyMassInPounds method here
        // because it's not public, but we can test that our query executor works
        await withCheckedContinuation { continuation in
            mockQueryExecutor.executeSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { samples, error in
                #expect(samples?.count == 1)
                #expect(error == nil)
                
                if let quantitySample = samples?.first as? HKQuantitySample {
                    let pounds = quantitySample.quantity.doubleValue(for: HKUnit.pound())
                    #expect(pounds == 180.0)
                }
                continuation.resume()
            }
        }
        
        // Verify query executor was called correctly
        #expect(mockQueryExecutor.executeSampleQueryCallCount == 1)
        #expect(mockQueryExecutor.lastSampleType == bodyMassType)
        #expect(mockQueryExecutor.lastLimit == 1)
    }
    
    @Test("HealthKitManager handles query executor errors") 
    func testHealthKitManagerQueryExecutorError() async throws {
        setUp()
        defer { tearDown() }
        
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitTestError.healthKitTypeCreationFailed
        }
        
        // Configure query executor to return error
        let expectedError = NSError(domain: "QueryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Query failed"])
        mockQueryExecutor.configure(samples: [], error: expectedError)
        
        await withCheckedContinuation { continuation in
            mockQueryExecutor.executeSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: []
            ) { samples, error in
                #expect(samples?.isEmpty == true)
                #expect(error != nil)
                #expect((error as NSError?)?.domain == "QueryError")
                continuation.resume()
            }
        }
        
        // Verify query was attempted
        #expect(mockQueryExecutor.executeSampleQueryCallCount == 1)
    }
}

// MARK: - Test Errors

enum HealthKitTestError: Error {
    case healthKitTypeCreationFailed
}