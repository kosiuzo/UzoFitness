import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol ImagePickerServiceProtocol {
    func pickImage() async -> UIImage?
} 