import Foundation

public protocol FileSystemServiceProtocol {
    func cacheDirectory() throws -> URL
    func writeData(_ data: Data, to url: URL) throws
} 