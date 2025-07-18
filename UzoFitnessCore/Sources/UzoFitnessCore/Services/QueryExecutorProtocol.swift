import Foundation
import HealthKit

public protocol QueryExecutorProtocol {
    func executeSampleQuery(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor],
        completion: @escaping ([HKSample]?, Error?) -> Void
    )
} 