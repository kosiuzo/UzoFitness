import Foundation
import UIKit
import Photos
import UzoFitnessCore
@testable import UzoFitness

/// Mock implementation of PhotoLibraryServiceProtocol for testing
final class MockPhotoLibraryService: PhotoLibraryServiceProtocol {
    
    // MARK: - Mock Configuration
    var mockAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    var mockRequestAuthorizationResult: PHAuthorizationStatus = .authorized
    var shouldThrowOnSaveImage = false
    var saveImageError: Error = PhotoServiceError.authorizationDenied
    
    // MARK: - Call Tracking
    private(set) var authorizationStatusCallCount = 0
    private(set) var requestAuthorizationCallCount = 0
    private(set) var saveImageCallCount = 0
    private(set) var savedImages: [UIImage] = []
    
    // MARK: - PhotoLibraryServiceProtocol Implementation
    
    func authorizationStatus() async -> PHAuthorizationStatus {
        authorizationStatusCallCount += 1
        return mockAuthorizationStatus
    }
    
    func requestAuthorization() async -> PHAuthorizationStatus {
        requestAuthorizationCallCount += 1
        return mockRequestAuthorizationResult
    }
    
    func saveImage(_ image: UIImage) async throws {
        saveImageCallCount += 1
        savedImages.append(image)
        
        if shouldThrowOnSaveImage {
            throw saveImageError
        }
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        authorizationStatusCallCount = 0
        requestAuthorizationCallCount = 0
        saveImageCallCount = 0
        savedImages.removeAll()
        mockAuthorizationStatus = .notDetermined
        mockRequestAuthorizationResult = .authorized
        shouldThrowOnSaveImage = false
        saveImageError = PhotoServiceError.authorizationDenied
    }
    
    func configure(
        authorizationStatus: PHAuthorizationStatus = .notDetermined,
        requestAuthorizationResult: PHAuthorizationStatus = .authorized,
        shouldThrowOnSaveImage: Bool = false,
        saveImageError: Error = PhotoServiceError.authorizationDenied
    ) {
        self.mockAuthorizationStatus = authorizationStatus
        self.mockRequestAuthorizationResult = requestAuthorizationResult
        self.shouldThrowOnSaveImage = shouldThrowOnSaveImage
        self.saveImageError = saveImageError
    }
}

/// Mock implementation of ImagePickerServiceProtocol for testing
@MainActor
final class MockImagePickerService: ImagePickerServiceProtocol {
    
    // MARK: - Mock Configuration
    var mockPickImageResult: UIImage?
    var pickImageDelay: TimeInterval = 0.0
    
    // MARK: - Call Tracking
    private(set) var pickImageCallCount = 0
    
    // MARK: - ImagePickerServiceProtocol Implementation
    
    func pickImage() async -> UIImage? {
        pickImageCallCount += 1
        
        if pickImageDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(pickImageDelay * 1_000_000_000))
        }
        
        return mockPickImageResult
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        pickImageCallCount = 0
        mockPickImageResult = nil
        pickImageDelay = 0.0
    }
    
    func configure(result: UIImage?, delay: TimeInterval = 0.0) {
        self.mockPickImageResult = result
        self.pickImageDelay = delay
    }
}

/// Mock implementation of FileSystemServiceProtocol for testing
final class MockFileSystemService: FileSystemServiceProtocol {
    
    // MARK: - Mock Configuration
    var mockCacheDirectory: URL = URL(fileURLWithPath: "/tmp/test_cache")
    var shouldThrowOnCacheDirectory = false
    var cacheDirectoryError: Error = PhotoServiceError.cacheDirectoryNotFound
    var shouldThrowOnWriteData = false
    var writeDataError: Error = PhotoServiceError.dataConversionFailed
    
    // MARK: - Call Tracking
    private(set) var cacheDirectoryCallCount = 0
    private(set) var writeDataCallCount = 0
    private(set) var writtenData: [(Data, URL)] = []
    
    // MARK: - FileSystemServiceProtocol Implementation
    
    func cacheDirectory() throws -> URL {
        cacheDirectoryCallCount += 1
        
        if shouldThrowOnCacheDirectory {
            throw cacheDirectoryError
        }
        
        return mockCacheDirectory
    }
    
    func writeData(_ data: Data, to url: URL) throws {
        writeDataCallCount += 1
        writtenData.append((data, url))
        
        if shouldThrowOnWriteData {
            throw writeDataError
        }
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        cacheDirectoryCallCount = 0
        writeDataCallCount = 0
        writtenData.removeAll()
        mockCacheDirectory = URL(fileURLWithPath: "/tmp/test_cache")
        shouldThrowOnCacheDirectory = false
        cacheDirectoryError = PhotoServiceError.cacheDirectoryNotFound
        shouldThrowOnWriteData = false
        writeDataError = PhotoServiceError.dataConversionFailed
    }
    
    func configure(
        cacheDirectory: URL = URL(fileURLWithPath: "/tmp/test_cache"),
        shouldThrowOnCacheDirectory: Bool = false,
        cacheDirectoryError: Error = PhotoServiceError.cacheDirectoryNotFound,
        shouldThrowOnWriteData: Bool = false,
        writeDataError: Error = PhotoServiceError.dataConversionFailed
    ) {
        self.mockCacheDirectory = cacheDirectory
        self.shouldThrowOnCacheDirectory = shouldThrowOnCacheDirectory
        self.cacheDirectoryError = cacheDirectoryError
        self.shouldThrowOnWriteData = shouldThrowOnWriteData
        self.writeDataError = writeDataError
    }
}

/// Mock implementation of DataPersistenceServiceProtocol for testing
final class MockDataPersistenceService: DataPersistenceServiceProtocol {
    
    // MARK: - Mock Configuration
    var shouldThrowOnInsert = false
    var insertError: Error = PhotoServiceError.invalidObjectType
    var shouldThrowOnSave = false
    var saveError: Error = PhotoServiceError.dataConversionFailed
    
    // MARK: - Call Tracking
    private(set) var insertCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var insertedObjects: [Any] = []
    
    // MARK: - DataPersistenceServiceProtocol Implementation
    
    func insert(_ object: Any) throws {
        insertCallCount += 1
        insertedObjects.append(object)
        
        if shouldThrowOnInsert {
            throw insertError
        }
    }
    
    func save() throws {
        saveCallCount += 1
        
        if shouldThrowOnSave {
            throw saveError
        }
    }
    
    // MARK: - Mock Control Methods
    
    func reset() {
        insertCallCount = 0
        saveCallCount = 0
        insertedObjects.removeAll()
        shouldThrowOnInsert = false
        insertError = PhotoServiceError.invalidObjectType
        shouldThrowOnSave = false
        saveError = PhotoServiceError.dataConversionFailed
    }
    
    func configure(
        shouldThrowOnInsert: Bool = false,
        insertError: Error = PhotoServiceError.invalidObjectType,
        shouldThrowOnSave: Bool = false,
        saveError: Error = PhotoServiceError.dataConversionFailed
    ) {
        self.shouldThrowOnInsert = shouldThrowOnInsert
        self.insertError = insertError
        self.shouldThrowOnSave = shouldThrowOnSave
        self.saveError = saveError
    }
}