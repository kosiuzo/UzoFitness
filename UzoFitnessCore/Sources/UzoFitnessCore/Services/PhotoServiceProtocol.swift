import Foundation
#if canImport(Photos)
import Photos
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(PhotosUI)
import PhotosUI
#endif

// Protocol for photo library operations
public protocol PhotoLibraryServiceProtocol {
    #if canImport(Photos)
    func authorizationStatus() async -> PHAuthorizationStatus
    func requestAuthorization() async -> PHAuthorizationStatus
    #endif
    #if canImport(UIKit)
    func saveImage(_ image: UIImage) async throws
    #endif
} 