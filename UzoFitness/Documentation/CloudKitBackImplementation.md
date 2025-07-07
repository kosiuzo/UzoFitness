

# 1. **CloudKit Setup**

> **Status**: The iCloud capability is already enabled in the project, but the actual sync implementation is still in progress.

### a. Enable CloudKit in Xcode
- Go to your project target → **Signing & Capabilities**.
- Add **iCloud** capability, check **CloudKit**.
- Ensure your app uses the correct iCloud container.

### b. CloudKit Dashboard
- Visit [CloudKit Dashboard](https://icloud.developer.apple.com/).
- Create record types for each SwiftData entity you want to back up (e.g., `WorkoutSession`, `ProgressPhoto`).
- For photos, add a `CKAsset` field.

---

# 2. **Model Serialization for CloudKit**

SwiftData models must be converted to/from a format CloudKit understands (typically dictionaries).

### a. Add Codable Conformance (if not present)
For each model you want to back up, add `Codable` conformance.  
Example for `WorkoutSession`:

```swift
import Foundation
import SwiftData

@Model
class WorkoutSession: Identified, Timestamped, Codable {
    // ... your properties ...
}
```
If you have relationships, you may need to use custom `CodingKeys` or flatten relationships for backup.

### b. Add Conversion Helpers

Add methods to convert between your model and a `CKRecord`:

```swift
import CloudKit

extension WorkoutSession {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "WorkoutSession", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["date"] = self.date as CKRecordValue
        // ... add other fields ...
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> WorkoutSession {
        let session = WorkoutSession()
        session.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        session.date = record["date"] as? Date ?? Date()
        // ... set other fields ...
        return session
    }
}
```

Do the same for other models (e.g., `ProgressPhoto`). For photos, see below.

---

# 3. **Handling Photos with CKAsset**

For models with images (e.g., `ProgressPhoto`):

- When backing up, write the image to a temporary file and attach as a `CKAsset`.
- When restoring, download the asset and save it locally, updating your model’s file path.

Example:

```swift
extension ProgressPhoto {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ProgressPhoto", recordID: CKRecord.ID(recordName: self.id.uuidString))
        // ... other fields ...
        if let imagePath = self.imagePath {
            let fileURL = URL(fileURLWithPath: imagePath)
            record["imageAsset"] = CKAsset(fileURL: fileURL)
        }
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> ProgressPhoto {
        let photo = ProgressPhoto()
        // ... other fields ...
        if let asset = record["imageAsset"] as? CKAsset, let fileURL = asset.fileURL {
            // Copy asset to app's directory and set imagePath
            let destinationURL = ... // your app's documents directory + unique filename
            try? FileManager.default.copyItem(at: fileURL, to: destinationURL)
            photo.imagePath = destinationURL.path
        }
        return photo
    }
}
```

---

# 4. **CloudKit Sync Service Implementation**

Create a new service, e.g., `CloudKitSyncService.swift` in `Services/`.

```swift
import Foundation
import CloudKit
import SwiftData

protocol CloudKitSyncServiceProtocol {
    func backupAllData(context: ModelContext) async throws
    func restoreAllData(context: ModelContext) async throws
    func lastBackupDate() async -> Date?
}

class CloudKitSyncService: CloudKitSyncServiceProtocol {
    private let database = CKContainer.default().privateCloudDatabase

    func backupAllData(context: ModelContext) async throws {
        // 1. Fetch all entities
        let sessions: [WorkoutSession] = try context.fetch(FetchDescriptor<WorkoutSession>())
        let photos: [ProgressPhoto] = try context.fetch(FetchDescriptor<ProgressPhoto>())
        // ... fetch other models as needed

        // 2. Convert to CKRecords
        let sessionRecords = sessions.map { $0.toCKRecord() }
        let photoRecords = photos.map { $0.toCKRecord() }
        // ... other records

        // 3. Save to CloudKit (in batches)
        let allRecords = sessionRecords + photoRecords // + ...
        try await saveRecordsInBatches(records: allRecords)
    }

    func restoreAllData(context: ModelContext) async throws {
        // 1. Query all records for each type
        let sessionRecords = try await fetchAllRecords(ofType: "WorkoutSession")
        let photoRecords = try await fetchAllRecords(ofType: "ProgressPhoto")
        // ... other types

        // 2. Convert to models and insert into SwiftData
        for record in sessionRecords {
            let session = WorkoutSession.fromCKRecord(record)
            context.insert(session)
        }
        for record in photoRecords {
            let photo = ProgressPhoto.fromCKRecord(record)
            context.insert(photo)
        }
        // ... other types

        try context.save()
    }

    func lastBackupDate() async -> Date? {
        // Optionally, store a backup date record in CloudKit and fetch it here
        return nil
    }

    // MARK: - Helpers

    private func saveRecordsInBatches(records: [CKRecord], batchSize: Int = 100) async throws {
        for batch in records.chunked(into: batchSize) {
            let operation = CKModifyRecordsOperation(recordsToSave: batch, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            try await withCheckedThrowingContinuation { continuation in
                operation.modifyRecordsCompletionBlock = { _, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
                database.add(operation)
            }
        }
    }

    private func fetchAllRecords(ofType type: String) async throws -> [CKRecord] {
        var results: [CKRecord] = []
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.recordFetchedBlock = { record in results.append(record) }
        try await withCheckedThrowingContinuation { continuation in
            operation.queryCompletionBlock = { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            database.add(operation)
        }
        return results
    }
}

// Helper for batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
```

---

# 5. **Integrate with ViewModel**

- Inject your new `CloudKitSyncService` into `SettingsViewModel`.
- Replace the mock backup/restore calls with real ones.

Example:

```swift
class SettingsViewModel: ObservableObject {
    // ...
    private let cloudKitSyncService: CloudKitSyncServiceProtocol
    private let modelContext: ModelContext

    init(..., cloudKitSyncService: CloudKitSyncServiceProtocol, modelContext: ModelContext) {
        self.cloudKitSyncService = cloudKitSyncService
        self.modelContext = modelContext
        // ...
    }

    func performBackup() async {
        do {
            try await cloudKitSyncService.backupAllData(context: modelContext)
            // Update last backup date, show success, etc.
        } catch {
            // Handle error
        }
    }

    func performRestore() async {
        do {
            try await cloudKitSyncService.restoreAllData(context: modelContext)
            // Show success, refresh UI, etc.
        } catch {
            // Handle error
        }
    }
}
```

---

# 6. **UI/UX and Permissions**

- Ensure you handle iCloud account availability and permissions gracefully.
- Show progress and error messages in your UI.
- Consider warning the user before overwriting local data on restore.

---

# 7. **Testing**

- Test on real devices (CloudKit is limited in the simulator).
- Try with different iCloud accounts and network conditions.
- Test with large data sets and many photos.

---

# 8. **Advanced: Relationships and Migrations**

- If your models have relationships, you may need to serialize relationships (e.g., store related IDs).
- On restore, re-link relationships after all records are restored.

---

# 9. **Security and Privacy**

- Use the private CloudKit database for all user data.
- Do not store sensitive data in public CloudKit records.

---

# 10. **References**

- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Sample: Using CloudKit with Codable](https://developer.apple.com/documentation/cloudkit/ckrecord/record_with_codable_support)

---

## **Summary Table**

| Step                | What to Do                                                                 |
|---------------------|----------------------------------------------------------------------------|
| CloudKit Setup      | Enable CloudKit, create record types                                        |
| Model Serialization | Add Codable, toCKRecord/fromCKRecord methods                               |
| Photo Handling      | Use CKAsset for images                                                     |
| Sync Service        | Implement backup/restore with CloudKit                                     |
| ViewModel           | Inject service, call backup/restore on user action                         |
| UI/UX               | Show progress, handle errors, warn on restore                              |
| Testing             | Test on device, with real iCloud accounts                                  |

---

**If you want a concrete code example for a specific model, or want to see how to handle relationships, let me know!**