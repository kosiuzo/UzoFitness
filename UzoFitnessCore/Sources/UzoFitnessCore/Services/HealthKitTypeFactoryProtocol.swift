import Foundation
import HealthKit

public protocol HealthKitTypeFactoryProtocol {
    func quantityType(forIdentifier identifier: HKQuantityTypeIdentifier) -> HKQuantityType?
} 