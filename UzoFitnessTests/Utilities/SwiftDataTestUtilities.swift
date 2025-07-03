import Foundation
import SwiftData
import XCTest

/// Utility class for handling SwiftData operations in tests with proper async support
class SwiftDataTestUtilities {
    
    private let modelContext: ModelContext
    private let maxWaitTime: TimeInterval = 5.0 // 5 seconds max wait time
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("🔄 [SwiftDataTestUtilities.init] Initialized with model context")
    }
    
    /// Waits for SwiftData operations to complete with proper error handling
    func waitForSwiftDataOperations() async throws {
        print("🔄 [SwiftDataTestUtilities.waitForSwiftDataOperations] Starting wait for SwiftData operations")
        
        let startTime = Date()
        var attempts = 0
        let maxAttempts = 50 // 50 attempts with 0.1 second intervals = 5 seconds max
        
        while attempts < maxAttempts {
            do {
                try await MainActor.run {
                    try self.modelContext.save()
                }
                // Check if there are any pending changes
                let hasChanges = await MainActor.run { self.modelContext.hasChanges }
                if !hasChanges {
                    let waitTime = Date().timeIntervalSince(startTime)
                    print("✅ [SwiftDataTestUtilities.waitForSwiftDataOperations] Operations completed in \(waitTime)s")
                    return
                }
                // Wait a bit before next attempt
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                attempts += 1
            } catch {
                print("❌ [SwiftDataTestUtilities.waitForSwiftDataOperations] Error during save attempt \(attempts): \(error.localizedDescription)")
                throw error
            }
        }
        let totalWaitTime = Date().timeIntervalSince(startTime)
        print("❌ [SwiftDataTestUtilities.waitForSwiftDataOperations] Timeout after \(totalWaitTime)s")
        throw SwiftDataTestError.timeout(maxWaitTime)
    }
    
    /// Performs a SwiftData operation and waits for completion
    func performOperation<T>(_ operation: () throws -> T) async throws -> T {
        print("🔄 [SwiftDataTestUtilities.performOperation] Starting operation")
        let result = try operation()
        try await waitForSwiftDataOperations()
        print("✅ [SwiftDataTestUtilities.performOperation] Operation completed successfully")
        return result
    }
    
    /// Inserts an object and waits for the operation to complete
    func insertAndWait<T: PersistentModel>(_ object: T) async throws {
        print("🔄 [SwiftDataTestUtilities.insertAndWait] Inserting object: \(type(of: object))")
        await MainActor.run { self.modelContext.insert(object) }
        try await waitForSwiftDataOperations()
        print("✅ [SwiftDataTestUtilities.insertAndWait] Object inserted successfully")
    }
    
    /// Deletes an object and waits for the operation to complete
    func deleteAndWait<T: PersistentModel>(_ object: T) async throws {
        print("🔄 [SwiftDataTestUtilities.deleteAndWait] Deleting object: \(type(of: object))")
        await MainActor.run { self.modelContext.delete(object) }
        try await waitForSwiftDataOperations()
        print("✅ [SwiftDataTestUtilities.deleteAndWait] Object deleted successfully")
    }
    
    /// Fetches objects and waits for the operation to complete
    func fetchAndWait<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) async throws -> [T] {
        print("🔄 [SwiftDataTestUtilities.fetchAndWait] Fetching objects with descriptor")
        let results = try await MainActor.run { try self.modelContext.fetch(descriptor) }
        try await waitForSwiftDataOperations()
        print("✅ [SwiftDataTestUtilities.fetchAndWait] Fetched \(results.count) objects")
        return results
    }
    
    /// Saves the context and waits for completion
    func saveAndWait() async throws {
        print("🔄 [SwiftDataTestUtilities.saveAndWait] Saving context")
        try await MainActor.run { try self.modelContext.save() }
        try await waitForSwiftDataOperations()
        print("✅ [SwiftDataTestUtilities.saveAndWait] Context saved successfully")
    }
    
    /// Waits for a specific condition to be true (async closure)
    func waitForCondition(_ condition: @escaping () async -> Bool, timeout: TimeInterval = 5.0) async throws {
        print("🔄 [SwiftDataTestUtilities.waitForCondition] Waiting for condition")
        let startTime = Date()
        var attempts = 0
        let maxAttempts = Int(timeout * 10) // 10 attempts per second
        while attempts < maxAttempts {
            if await condition() {
                let waitTime = Date().timeIntervalSince(startTime)
                print("✅ [SwiftDataTestUtilities.waitForCondition] Condition met in \(waitTime)s")
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            attempts += 1
        }
        let totalWaitTime = Date().timeIntervalSince(startTime)
        print("❌ [SwiftDataTestUtilities.waitForCondition] Timeout after \(totalWaitTime)s")
        throw SwiftDataTestError.timeout(timeout)
    }
    
    /// Waits for a specific count of objects in a fetch descriptor
    func waitForCount<T: PersistentModel>(_ expectedCount: Int, descriptor: FetchDescriptor<T>) async throws {
        print("🔄 [SwiftDataTestUtilities.waitForCount] Waiting for \(expectedCount) objects")
        try await waitForCondition {
            do {
                let count = try? await MainActor.run { try self.modelContext.fetchCount(descriptor) }
                return count == expectedCount
            } catch {
                return false
            }
        }
        print("✅ [SwiftDataTestUtilities.waitForCount] Found \(expectedCount) objects")
    }
}

// MARK: - Error Types

enum SwiftDataTestError: LocalizedError {
    case timeout(TimeInterval)
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .timeout(let duration):
            return "SwiftData operation timed out after \(duration) seconds"
        case .operationFailed(let message):
            return "SwiftData operation failed: \(message)"
        }
    }
}

// MARK: - XCTestCase Extension

extension XCTestCase {
    /// Creates a SwiftData test utility for the given model context
    func createSwiftDataTestUtilities(modelContext: ModelContext) -> SwiftDataTestUtilities {
        return SwiftDataTestUtilities(modelContext: modelContext)
    }
    
    /// Waits for SwiftData operations to complete
    func waitForSwiftDataOperations(modelContext: ModelContext) async throws {
        let utilities = SwiftDataTestUtilities(modelContext: modelContext)
        try await utilities.waitForSwiftDataOperations()
    }
    
    /// Performs an operation and waits for SwiftData to complete
    func performSwiftDataOperation<T>(modelContext: ModelContext, operation: () throws -> T) async throws -> T {
        let utilities = SwiftDataTestUtilities(modelContext: modelContext)
        return try await utilities.performOperation(operation)
    }
} 