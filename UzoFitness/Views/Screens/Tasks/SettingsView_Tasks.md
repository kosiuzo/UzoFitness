# Settings View Implementation Tasks

## 1. Screen & Layout
- [ ] Create `SettingsView` in SwiftUI (or UIKit screen)
  - [ ] Add two sections: **Permissions** and **Data Sync**
  - [ ] In **Permissions**, add:
    - [ ] “HealthKit Sync” toggle
    - [ ] “Photo Library Access” toggle
  - [ ] In **Data Sync**, add:
    - [ ] “Sync to iCloud Backup” button
    - [ ] Last-backup timestamp label below the button
    - [ ] “Restore from iCloud Backup” button
  - [ ] Apply minimalist styling:
    - [ ] Generous white space
    - [ ] Subtle gray separators between sections
    - [ ] System font sizes and weights (headers `.semibold`, secondary text smaller/gray)
    - [ ] Center action buttons

## 2. ViewModel Binding
- [ ] Inject `SettingsViewModel` into `SettingsView`
- [ ] Bind toggles/buttons to ViewModel properties & methods:
  - [ ] `isHealthKitEnabled` ↔ Toggle
  - [ ] `isPhotoAccessEnabled` ↔ Toggle
  - [ ] `syncToICloud()` ↔ Sync button action
  - [ ] `restoreFromICloud()` ↔ Restore button action
  - [ ] `lastBackupTimestamp` ↔ Timestamp label

## 3. Permissions Logic
- [ ] HealthKit toggle
  - [ ] In **release**: call real `HealthKitManager.requestAuthorization()` on “On”
  - [ ] In **debug**: flip mock-data flag only
  - [ ] On “Off”: call `HealthKitManager.disableSync()`
  - [ ] Display “Denied” state if system permission is off, with “Go to Settings” link
- [ ] Photo toggle
  - [ ] Call `PhotoPermissionService.requestAccess()` on “On”
  - [ ] Call `PhotoPermissionService.revokeAccess()` on “Off”
  - [ ] Handle “Denied” state identically

## 4. iCloud Backup & Restore
- [ ] **Sync to iCloud Backup**
  - [ ] Implement `SettingsViewModel.syncToICloud()`
    - [ ] Use `NSUbiquitousKeyValueStore` or CloudKit API
    - [ ] Kick off background upload
    - [ ] Update `lastBackupTimestamp` on success
  - [ ] Display non-blocking activity indicator while sync runs
  - [ ] Post local notification on failure
- [ ] **Restore from iCloud Backup**
  - [ ] Add confirmation alert before invoking restore
  - [ ] Implement `SettingsViewModel.restoreFromICloud()`
    - [ ] Show progress overlay until complete
    - [ ] Update UI or send notification on success/failure

## 5. Persistence
- [ ] Persist toggle states (HealthKit / Photo) to UserDefaults or SwiftData
- [ ] Persist `lastBackupTimestamp`
- [ ] On app launch, read stored states and update toggles & timestamp

## 6. Error Handling & Edge Cases
- [ ] Show inline alerts/toasts for:
  - [ ] HealthKit unavailable or request failure
  - [ ] Photo-access request failure
- [ ] Handle backup/restore errors with local notifications
- [ ] Ensure UI recovers gracefully if services are unavailable

## 7. Testing
- [ ] Unit tests for toggle logic:
  - [ ] HealthKit toggle in release vs. debug
  - [ ] Photo toggle success & denied paths
- [ ] Unit tests for backup & restore methods:
  - [ ] Success path updates timestamp
  - [ ] Failure path posts notification
- [ ] UI tests (if applicable):
  - [ ] Verify toggles reflect persisted states
  - [ ] Simulate tap on Sync/Restore and assert UI feedback

## 8. QA & Manual Validation
- [ ] Manual test on device:
  - [ ] Toggle HealthKit on/off (debug & release)
  - [ ] Toggle Photo access on/off
  - [ ] Trigger backup and confirm timestamp updates
  - [ ] Trigger restore and confirm data recovery flow
- [ ] Validate “Go to Settings” link opens system Settings
- [ ] Check haptic feedback on toggles