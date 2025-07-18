import Foundation
import Combine

/// Protocol for watch connectivity service
public protocol WatchConnectivityServiceProtocol: AnyObject {
    /// Publisher for incoming messages from watch/phone
    var messageReceived: AnyPublisher<WatchMessage, Never> { get }
    
    /// Publisher for connectivity state changes
    var connectivityStateChanged: AnyPublisher<Bool, Never> { get }
    
    /// Whether the counterpart app is reachable
    var isReachable: Bool { get }
    
    /// Whether the watch app is installed
    var isWatchAppInstalled: Bool { get }
    
    /// Send a message to the counterpart app
    func sendMessage(_ message: WatchMessage) async throws
    
    /// Send user info to the counterpart app (for background sync)
    func sendUserInfo(_ userInfo: [String: Any]) async throws
    
    /// Transfer file to the counterpart app
    func transferFile(at url: URL, metadata: [String: Any]?) async throws
    
    /// Start the connectivity session
    func startSession()
    
    /// Stop the connectivity session
    func stopSession()
}

/// Watch connectivity error types
public enum WatchConnectivityError: Error, LocalizedError {
    case sessionNotActivated
    case counterpartNotReachable
    case watchAppNotInstalled
    case messageSendFailed(String)
    case userInfoSendFailed(String)
    case fileTransferFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotActivated:
            return "Watch connectivity session is not activated"
        case .counterpartNotReachable:
            return "Counterpart device is not reachable"
        case .watchAppNotInstalled:
            return "Watch app is not installed"
        case .messageSendFailed(let message):
            return "Failed to send message: \(message)"
        case .userInfoSendFailed(let message):
            return "Failed to send user info: \(message)"
        case .fileTransferFailed(let message):
            return "Failed to transfer file: \(message)"
        }
    }
}