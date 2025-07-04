//
//  PhotoService.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/18/25.
//

import Foundation
import UIKit
import SwiftData
import PhotosUI
import Photos

// MARK: - Protocols for Dependency Injection

/// Protocol for photo library operations
protocol PhotoLibraryServiceProtocol {
    func authorizationStatus() async -> PHAuthorizationStatus
    func requestAuthorization() async -> PHAuthorizationStatus
    func saveImage(_ image: UIImage) async throws
}

/// Protocol for file system operations
protocol FileSystemServiceProtocol {
    func cacheDirectory() throws -> URL
    func writeData(_ data: Data, to url: URL) throws
}

/// Protocol for image picking operations
protocol ImagePickerServiceProtocol {
    @MainActor func pickImage() async -> UIImage?
}

/// Protocol for SwiftData operations
protocol DataPersistenceServiceProtocol {
    func insert(_ object: Any) throws
    func save() throws
}

// MARK: - Default Implementations

final class DefaultPhotoLibraryService: PhotoLibraryServiceProtocol {
    func authorizationStatus() async -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
    
    func saveImage(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

final class DefaultFileSystemService: FileSystemServiceProtocol {
    /// Returns a persistent directory for storing progress photos.
    /// The directory is located in Application Support to avoid being purged by the system (unlike the caches directory).
    /// A sub-folder "ProgressPhotos" is created the first time this method is called.
    func cacheDirectory() throws -> URL {
        let fileManager = FileManager.default

        guard var baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw PhotoServiceError.cacheDirectoryNotFound
        }

        // Ensure our app-specific folder exists (App Support may be shared with other data).
        // Some apps run in the simulator do not have the Application Support directory created upfront.
        if !fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        }

        // Use subfolder to keep things tidy.
        baseURL.appendPathComponent("ProgressPhotos", isDirectory: true)
        if !fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        }

        return baseURL
    }
    
    func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}

final class DefaultImagePickerService: NSObject, ImagePickerServiceProtocol {
    private var pickerContinuation: CheckedContinuation<UIImage?, Never>?
    
    @MainActor
    func pickImage() async -> UIImage? {
        await withCheckedContinuation { continuation in
            pickerContinuation = continuation
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = 1
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            
            // Present on topmost VC
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
               let root = windowScene.windows.first?.rootViewController {
                root.present(picker, animated: true)
            }
        }
    }
}

extension DefaultImagePickerService: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            pickerContinuation?.resume(returning: nil)
            return
        }
        provider.loadObject(ofClass: UIImage.self) { image, _ in
            DispatchQueue.main.async {
                self.pickerContinuation?.resume(returning: image as? UIImage)
            }
        }
    }
}

final class DefaultDataPersistenceService: DataPersistenceServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func insert(_ object: Any) throws {
        if let persistentModel = object as? any PersistentModel {
            modelContext.insert(persistentModel)
        } else {
            throw PhotoServiceError.invalidObjectType
        }
    }
    
    func save() throws {
        try modelContext.save()
    }
}

// MARK: - Refactored PhotoService

/// Service for picking, caching, persisting, and exporting progress photos.
final class PhotoService {
    private let photoLibraryService: PhotoLibraryServiceProtocol
    private let fileSystemService: FileSystemServiceProtocol
    private let imagePickerService: ImagePickerServiceProtocol
    private let dataPersistenceService: DataPersistenceServiceProtocol

    init(
        photoLibraryService: PhotoLibraryServiceProtocol = DefaultPhotoLibraryService(),
        fileSystemService: FileSystemServiceProtocol = DefaultFileSystemService(),
        imagePickerService: ImagePickerServiceProtocol? = nil,
        dataPersistenceService: DataPersistenceServiceProtocol
    ) {
        self.photoLibraryService = photoLibraryService
        self.fileSystemService = fileSystemService
        if let imagePickerService = imagePickerService {
            self.imagePickerService = imagePickerService
        } else {
            self.imagePickerService = DefaultImagePickerService()
        }
        self.dataPersistenceService = dataPersistenceService
    }

    // MARK: - Photo Library Authorization

    /// Ensure the app has permission to add assets to user's photo library.
    func requestPhotoLibraryAuthorization() async -> PHAuthorizationStatus {
        let status = await photoLibraryService.authorizationStatus()
        switch status {
        case .notDetermined:
            return await photoLibraryService.requestAuthorization()
        default:
            return status
        }
    }

    // MARK: - Save To Photo Library

    /// Save a UIImage back into the user's photo library.
    func saveToPhotoLibrary(image: UIImage) async throws {
        let status = await requestPhotoLibraryAuthorization()
        guard status == .authorized || status == .limited else {
            throw PhotoServiceError.authorizationDenied
        }
        try await photoLibraryService.saveImage(image)
    }

    // MARK: - Image Picking (Upload from library)

    /// Present PHPicker UI and return the selected image (async/await).
    @MainActor
    func pickImage() async -> UIImage? {
        await imagePickerService.pickImage()
    }

    // MARK: - Cache & Persist

    /// Save an image to disk cache and SwiftData as a `ProgressPhoto` entity.
    func save(image: UIImage, angle: PhotoAngle, date: Date = .now) throws {
        // 1. Convert to JPEG data
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoServiceError.dataConversionFailed
        }

        // 2. Write to cache directory
        let filename = UUID().uuidString + ".jpg"
        let cacheDir = try fileSystemService.cacheDirectory()
        let url = cacheDir.appendingPathComponent(filename)
        try fileSystemService.writeData(data, to: url)

        // 3. Insert into SwiftData
        let photo = ProgressPhoto(
            id: UUID(),
            date: date,
            angle: angle,
            assetIdentifier: filename
        )
        try dataPersistenceService.insert(photo)
        try dataPersistenceService.save()
    }
}

// MARK: - Errors

enum PhotoServiceError: Error, Equatable {
    case authorizationDenied
    case dataConversionFailed
    case cacheDirectoryNotFound
    case invalidObjectType
}
