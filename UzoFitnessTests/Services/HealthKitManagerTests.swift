import XCTest
import HealthKit
@testable import UzoFitness

final class HealthKitManagerTests: XCTestCase {
    
    var healthKitManager: HealthKitManager!
    var mockHealthStore: MockHealthStore!
    var mockQueryExecutor: MockQueryExecutor!
    var mockTypeFactory: MockHealthKitTypeFactory!
    
    override func setUp() {
        super.setUp()
        mockHealthStore = MockHealthStore()
        mockQueryExecutor = MockQueryExecutor()
        mockTypeFactory = MockHealthKitTypeFactory()
        
        healthKitManager = HealthKitManager(
            healthStore: mockHealthStore,
            calendar: CalendarWrapper(Calendar.current), // Using real calendar for date calculations
            typeFactory: mockTypeFactory,
            queryExecutor: mockQueryExecutor
        )
    }
    
    override func tearDown() {
        healthKitManager = nil
        mockHealthStore = nil
        mockQueryExecutor = nil
        mockTypeFactory = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorizationSuccess() {
        // Given
        mockHealthStore.shouldSucceedAuthorization = true
        mockTypeFactory.shouldReturnNil = false
        let expectation = XCTestExpectation(description: "Authorization completion called")
        
        // When
        healthKitManager.requestAuthorization { success, error in
            // Then
            XCTAssertTrue(success)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRequestAuthorizationFailure() {
        // Given
        mockHealthStore.shouldSucceedAuthorization = false
        mockHealthStore.authorizationError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockTypeFactory.shouldReturnNil = false
        let expectation = XCTestExpectation(description: "Authorization completion called")
        
        // When
        healthKitManager.requestAuthorization { success, error in
            // Then
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRequestAuthorizationTypeUnavailable() {
        // Given
        mockTypeFactory.shouldReturnNil = true
        let expectation = XCTestExpectation(description: "Authorization completion called")
        
        // When
        healthKitManager.requestAuthorization { success, error in
            // Then
            XCTAssertFalse(success)
            XCTAssertTrue(error is HealthKitError)
            if case HealthKitError.typeUnavailable = error! {
                // Expected error type
            } else {
                XCTFail("Expected HealthKitError.typeUnavailable")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Body Mass Tests
    
    func testFetchLatestBodyMassInPoundsSuccess() {
        // Given
        let testWeightKg = 70.0
        let expectedWeightLbs = testWeightKg * 2.2046226218
        let mockSample = createMockBodyMassSample(weightInKg: testWeightKg)
        mockQueryExecutor.mockSamples = [mockSample]
        mockTypeFactory.shouldReturnNil = false
        
        let expectation = XCTestExpectation(description: "Body mass fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyMassInPounds { weight, error in
            // Then
            XCTAssertNil(error)
            XCTAssertNotNil(weight)
            XCTAssertEqual(weight!, expectedWeightLbs, accuracy: 0.001)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchLatestBodyMassInPoundsTypeUnavailable() {
        // Given
        mockTypeFactory.shouldReturnNil = true
        let expectation = XCTestExpectation(description: "Body mass fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyMassInPounds { weight, error in
            // Then
            XCTAssertNil(weight)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is HealthKitError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchBodyMassInPoundsOnSpecificDate() {
        // Given
        let testDate = Date()
        let testWeightKg = 68.5
        let expectedWeightLbs = testWeightKg * 2.2046226218
        let mockSample = createMockBodyMassSample(weightInKg: testWeightKg)
        mockQueryExecutor.mockSamples = [mockSample]
        mockTypeFactory.shouldReturnNil = false
        
        let expectation = XCTestExpectation(description: "Body mass fetch completion called")
        
        // When
        healthKitManager.fetchBodyMassInPounds(on: testDate) { weight, error in
            // Then
            XCTAssertNil(error)
            XCTAssertNotNil(weight)
            XCTAssertEqual(weight!, expectedWeightLbs, accuracy: 0.001)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Body Fat Tests
    
    func testFetchLatestBodyFatSuccess() {
        // Given
        let testBodyFatPercent = 15.5
        let mockSample = createMockBodyFatSample(percentage: testBodyFatPercent)
        mockQueryExecutor.mockSamples = [mockSample]
        mockTypeFactory.shouldReturnNil = false
        
        let expectation = XCTestExpectation(description: "Body fat fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyFat { bodyFat, error in
            // Then
            XCTAssertNil(error)
            XCTAssertNotNil(bodyFat)
            XCTAssertEqual(bodyFat!, testBodyFatPercent, accuracy: 0.001)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchBodyFatOnSpecificDate() {
        // Given
        let testDate = Date()
        let testBodyFatPercent = 12.8
        let mockSample = createMockBodyFatSample(percentage: testBodyFatPercent)
        mockQueryExecutor.mockSamples = [mockSample]
        mockTypeFactory.shouldReturnNil = false
        
        let expectation = XCTestExpectation(description: "Body fat fetch completion called")
        
        // When
        healthKitManager.fetchBodyFat(on: testDate) { bodyFat, error in
            // Then
            XCTAssertNil(error)
            XCTAssertNotNil(bodyFat)
            XCTAssertEqual(bodyFat!, testBodyFatPercent, accuracy: 0.001)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchBodyFatTypeUnavailable() {
        // Given
        mockTypeFactory.shouldReturnNil = true
        let expectation = XCTestExpectation(description: "Body fat fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyFat { bodyFat, error in
            // Then
            XCTAssertNil(bodyFat)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is HealthKitError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testFetchBodyMassWithHealthKitError() {
        // Given
        let healthKitError = NSError(domain: HKErrorDomain, code: HKError.errorHealthDataRestricted.rawValue, userInfo: nil)
        mockQueryExecutor.mockError = healthKitError
        mockTypeFactory.shouldReturnNil = false
        
        let expectation = XCTestExpectation(description: "Body mass fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyMassInPounds { weight, error in
            // Then
            XCTAssertNil(weight)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, HKErrorDomain)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchBodyFatWithHealthKitError() {
        // Given
        let healthKitError = NSError(domain: HKErrorDomain, code: HKError.errorHealthDataUnavailable.rawValue, userInfo: nil)
        mockQueryExecutor.mockError = healthKitError
        mockTypeFactory.shouldReturnNil = false
        
        let expectation = XCTestExpectation(description: "Body fat fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyFat { bodyFat, error in
            // Then
            XCTAssertNil(bodyFat)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, HKErrorDomain)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Query Verification Tests
    
    func testQueryExecutorCalled() {
        // Given
        mockTypeFactory.shouldReturnNil = false
        let expectation = XCTestExpectation(description: "Body mass fetch completion called")
        
        // When
        healthKitManager.fetchLatestBodyMassInPounds { _, _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockQueryExecutor.executedQueries.count, 1)
        let executedQuery = mockQueryExecutor.executedQueries.first!
        XCTAssertEqual(executedQuery.limit, 1)
        XCTAssertNil(executedQuery.predicate)
    }
    
    // MARK: - Helper Methods
    
    private func createMockBodyMassSample(weightInKg: Double) -> HKQuantitySample {
        let massType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        return HKQuantitySample(type: massType, quantity: quantity, start: Date(), end: Date())
    }
    
    private func createMockBodyFatSample(percentage: Double) -> HKQuantitySample {
        let fatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        let quantity = HKQuantity(unit: .percent(), doubleValue: percentage)
        return HKQuantitySample(type: fatType, quantity: quantity, start: Date(), end: Date())
    }
}

// MARK: - Mock Classes for Testing

class MockHealthStore: HealthStoreProtocol {
    var shouldSucceedAuthorization = true
    var authorizationError: Error?
    
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?,
                            read typesToRead: Set<HKObjectType>?,
                            completion: @escaping @Sendable (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(self.shouldSucceedAuthorization, self.authorizationError)
        }
    }
    
    func execute(_ query: HKQuery) {
        // Not used in our testing approach since we inject MockQueryExecutor
    }
}

class MockQueryExecutor: QueryExecutorProtocol {
    var mockSamples: [HKSample] = []
    var mockError: Error?
    var executedQueries: [MockQueryInfo] = []
    
    func executeSampleQuery(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor],
        completion: @escaping ([HKSample]?, Error?) -> Void
    ) {
        // Record the query info for verification
        let queryInfo = MockQueryInfo(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
        executedQueries.append(queryInfo)
        
        // Simulate async execution and call completion
        DispatchQueue.main.async {
            completion(self.mockError == nil ? self.mockSamples : nil, self.mockError)
        }
    }
    
    struct MockQueryInfo {
        let sampleType: HKSampleType
        let predicate: NSPredicate?
        let limit: Int
        let sortDescriptors: [NSSortDescriptor]
    }
}

class MockHealthKitTypeFactory: HealthKitTypeFactoryProtocol {
    var shouldReturnNil = false
    
    func quantityType(forIdentifier identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        if shouldReturnNil {
            return nil
        }
        return HKObjectType.quantityType(forIdentifier: identifier)
    }
}
