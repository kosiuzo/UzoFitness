import Foundation

public protocol DataPersistenceServiceProtocol {
    func insert(_ object: Any) throws
    func save() throws
} 