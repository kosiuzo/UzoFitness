import Foundation
import HealthKit

public protocol HealthStoreProtocol {
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping @Sendable (Bool, Error?) -> Void)
    func execute(_ query: HKQuery)
} 