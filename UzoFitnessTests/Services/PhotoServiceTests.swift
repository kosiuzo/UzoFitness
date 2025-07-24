import Foundation
import UIKit
import Photos
import Testing
import UzoFitnessCore
@testable import UzoFitness

// MARK: - PhotoService Tests

/// Tests for PhotoService with simulator-compatible mock dependencies
@MainActor
final class PhotoServiceTests {
    
    // MARK: - Test Properties
    private var mockFileSystemService: MockFileSystemService!
    private var mockImagePickerService: MockImagePickerService!
    private var mockDataPersistenceService: MockDataPersistenceService!
    private var photoService: PhotoService!
    
    // MARK: - Setup and Teardown
    
    private func setUp() {
        mockFileSystemService = MockFileSystemService()
        mockImagePickerService = MockImagePickerService()
        mockDataPersistenceService = MockDataPersistenceService()
        
        photoService = PhotoService(
            fileSystemService: mockFileSystemService,
            imagePickerService: mockImagePickerService,
            dataPersistenceService: mockDataPersistenceService
        )
    }
    
    private func tearDown() {
        mockFileSystemService = nil
        mockImagePickerService = nil
        mockDataPersistenceService = nil
        photoService = nil
    }
    
    // MARK: - Basic Mock Verification Tests
    
    @Test("Mock services initialize correctly")
    func testMockServicesInitialize() {
        setUp()
        defer { tearDown() }
        
        // Verify mock services are properly initialized
        #expect(mockFileSystemService.cacheDirectoryCallCount == 0)
        #expect(mockImagePickerService.pickImageCallCount == 0)
        #expect(mockDataPersistenceService.insertCallCount == 0)
        #expect(mockDataPersistenceService.saveCallCount == 0)
    }
    
    @Test("MockFileSystemService returns configured cache directory")
    func testMockFileSystemServiceCacheDirectory() throws {
        setUp()
        defer { tearDown() }
        
        let testURL = URL(fileURLWithPath: "/test/cache/directory")
        mockFileSystemService.mockCacheDirectory = testURL
        
        // Call method
        let result = try mockFileSystemService.cacheDirectory()
        
        // Verify behavior
        #expect(result == testURL)
        #expect(mockFileSystemService.cacheDirectoryCallCount == 1)
    }
    
    @Test("MockImagePickerService tracks pick image calls")
    func testMockImagePickerServiceTracking() async {
        setUp()
        defer { tearDown() }
        
        // Configure mock to return nil
        mockImagePickerService.mockPickImageResult = nil
        
        // Call method
        let result = await mockImagePickerService.pickImage()
        
        // Verify behavior
        #expect(result == nil)
        #expect(mockImagePickerService.pickImageCallCount == 1)
    }
    
    @Test("MockDataPersistenceService tracks insert and save calls")
    func testMockDataPersistenceServiceTracking() throws {
        setUp()
        defer { tearDown() }
        
        let testObject = "test object"
        
        // Call methods
        try mockDataPersistenceService.insert(testObject)
        try mockDataPersistenceService.save()
        
        // Verify behavior
        #expect(mockDataPersistenceService.insertCallCount == 1)
        #expect(mockDataPersistenceService.saveCallCount == 1)
        #expect(mockDataPersistenceService.insertedObjects.count == 1)
        #expect(mockDataPersistenceService.insertedObjects[0] as? String == testObject)
    }
    
    // MARK: - PhotoService Integration Tests (with mocked dependencies)
    
    @Test("PhotoService save method integrates with mock dependencies")
    func testPhotoServiceSaveIntegration() throws {
        setUp()
        defer { tearDown() }
        
        // Create a test image
        guard let testImage = UIImage(systemName: "photo") else {
            throw TestError.testImageCreationFailed
        }
        
        // Configure mocks for success
        let cacheURL = URL(fileURLWithPath: "/tmp/test_cache")
        mockFileSystemService.mockCacheDirectory = cacheURL
        mockFileSystemService.shouldThrowOnCacheDirectory = false
        mockFileSystemService.shouldThrowOnWriteData = false
        mockDataPersistenceService.shouldThrowOnInsert = false
        mockDataPersistenceService.shouldThrowOnSave = false
        
        // Call PhotoService save method
        try photoService.save(image: testImage, angle: PhotoAngle.front, date: Date())
        
        // Verify all dependencies were called
        #expect(mockFileSystemService.cacheDirectoryCallCount == 1)
        #expect(mockFileSystemService.writeDataCallCount == 1)
        #expect(mockDataPersistenceService.insertCallCount == 1)
        #expect(mockDataPersistenceService.saveCallCount == 1)
        
        // Verify correct data was written
        #expect(mockFileSystemService.writtenData.count == 1)
        let (writtenData, writtenURL) = mockFileSystemService.writtenData[0]
        #expect(writtenData.count > 0) // JPEG data should have some size
        #expect(writtenURL.path.contains(cacheURL.path)) // URL should be in cache directory
        #expect(writtenURL.pathExtension == "jpg") // Should be JPEG file
        
        // Verify ProgressPhoto was inserted
        #expect(mockDataPersistenceService.insertedObjects.count == 1)
        let insertedObject = mockDataPersistenceService.insertedObjects[0]
        #expect(insertedObject is ProgressPhoto)
        
        if let progressPhoto = insertedObject as? ProgressPhoto {
            #expect(progressPhoto.angle == PhotoAngle.front)
            #expect(progressPhoto.assetIdentifier.hasSuffix(".jpg"))
        }
    }
    
    @Test("PhotoService save handles file system error")
    func testPhotoServiceSaveHandlesFileSystemError() throws {
        setUp()
        defer { tearDown() }
        
        guard let testImage = UIImage(systemName: "photo") else {
            throw TestError.testImageCreationFailed
        }
        
        // Configure mock to throw error on cache directory
        mockFileSystemService.shouldThrowOnCacheDirectory = true
        mockFileSystemService.cacheDirectoryError = PhotoServiceError.cacheDirectoryNotFound
        
        // Expect PhotoService save to throw the error
        #expect(throws: PhotoServiceError.self) {
            try self.photoService.save(image: testImage, angle: PhotoAngle.front, date: Date())
        }
        
        // Verify cache directory was called but write data was not
        #expect(mockFileSystemService.cacheDirectoryCallCount == 1)
        #expect(mockFileSystemService.writeDataCallCount == 0)
        #expect(mockDataPersistenceService.insertCallCount == 0)
        #expect(mockDataPersistenceService.saveCallCount == 0)
    }
    
    @Test("PhotoService save handles persistence error")
    func testPhotoServiceSaveHandlesPersistenceError() throws {
        setUp()
        defer { tearDown() }
        
        guard let testImage = UIImage(systemName: "photo") else {
            throw TestError.testImageCreationFailed
        }
        
        // Configure mocks - file system succeeds, persistence fails
        mockFileSystemService.shouldThrowOnCacheDirectory = false
        mockFileSystemService.shouldThrowOnWriteData = false
        mockDataPersistenceService.shouldThrowOnInsert = true
        mockDataPersistenceService.insertError = PhotoServiceError.invalidObjectType
        
        // Expect PhotoService save to throw the persistence error
        #expect(throws: PhotoServiceError.self) {
            try self.photoService.save(image: testImage, angle: PhotoAngle.front, date: Date())
        }
        
        // Verify file system operations succeeded but persistence failed
        #expect(mockFileSystemService.cacheDirectoryCallCount == 1)
        #expect(mockFileSystemService.writeDataCallCount == 1)
        #expect(mockDataPersistenceService.insertCallCount == 1)
        #expect(mockDataPersistenceService.saveCallCount == 0) // Save not called due to insert failure
    }
    
    @Test("PhotoService pickImage delegates to image picker service")
    func testPhotoServicePickImageDelegation() async throws {
        setUp()
        defer { tearDown() }
        
        // Configure mock to return a test image
        let testImage = UIImage(systemName: "photo")
        mockImagePickerService.mockPickImageResult = testImage
        
        // Call PhotoService pickImage
        let result = await photoService.pickImage()
        
        // Verify delegation worked
        #expect(mockImagePickerService.pickImageCallCount == 1)
        #expect(result == testImage)
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case testImageCreationFailed
}