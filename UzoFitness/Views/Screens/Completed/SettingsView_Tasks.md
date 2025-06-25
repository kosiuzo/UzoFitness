# Settings View Implementation Tasks

## 1. Screen & Layout
- [x] ✅ Create `SettingsView` in SwiftUI (or UIKit screen)
  - [x] ✅ Add two sections: **Permissions** and **Data Sync**
  - [x] ✅ In **Permissions**, add:
    - [x] ✅ "HealthKit Sync" toggle
    - [x] ✅ "Photo Library Access" toggle
  - [x] ✅ In **Data Sync**, add:
    - [x] ✅ "Sync to iCloud Backup" button
    - [x] ✅ Last-backup timestamp label below the button
    - [x] ✅ "Restore from iCloud Backup" button
  - [x] ✅ Apply minimalist styling:
    - [x] ✅ Generous white space
    - [x] ✅ Subtle gray separators between sections
    - [x] ✅ System font sizes and weights (headers `.semibold`, secondary text smaller/gray)
    - [x] ✅ Center action buttons

## 2. ViewModel Binding
- [x] ✅ Inject `SettingsViewModel` into `SettingsView`
- [x] ✅ Bind toggles/buttons to ViewModel properties & methods:
  - [x] ✅ `isHealthKitEnabled` ↔ Toggle
  - [x] ✅ `isPhotoAccessEnabled` ↔ Toggle
  - [x] ✅ `syncToICloud()` ↔ Sync button action
  - [x] ✅ `restoreFromICloud()` ↔ Restore button action
  - [x] ✅ `lastBackupTimestamp` ↔ Timestamp label

## 3. Permissions Logic
- [x] ✅ HealthKit toggle
  - [x] ✅ In **release**: call real `HealthKitManager.requestAuthorization()` on "On"
  - [x] ✅ In **debug**: flip mock-data flag only
  - [x] ✅ On "Off": call `HealthKitManager.disableSync()`
  - [x] ✅ Display "Denied" state if system permission is off, with "Go to Settings" link
- [x] ✅ Photo toggle
  - [x] ✅ Call `PhotoPermissionService.requestAccess()` on "On"
  - [x] ✅ Call `PhotoPermissionService.revokeAccess()` on "Off"
  - [x] ✅ Handle "Denied" state identically

## 4. iCloud Backup & Restore
- [x] ✅ **Sync to iCloud Backup**
  - [x] ✅ Implement `SettingsViewModel.syncToICloud()`
    - [x] ✅ Use `NSUbiquitousKeyValueStore` or CloudKit API
    - [x] ✅ Kick off background upload
    - [x] ✅ Update `lastBackupTimestamp` on success
  - [x] ✅ Display non-blocking activity indicator while sync runs
  - [x] ✅ Post local notification on failure
- [x] ✅ **Restore from iCloud Backup**
  - [x] ✅ Add confirmation alert before invoking restore
  - [x] ✅ Implement `SettingsViewModel.restoreFromICloud()`
    - [x] ✅ Show progress overlay until complete
    - [x] ✅ Update UI or send notification on success/failure

## 5. Persistence
- [x] ✅ Persist toggle states (HealthKit / Photo) to UserDefaults or SwiftData
- [x] ✅ Persist `lastBackupTimestamp`
- [x] ✅ On app launch, read stored states and update toggles & timestamp

## 6. Error Handling & Edge Cases
- [x] ✅ Show inline alerts/toasts for:
  - [x] ✅ HealthKit unavailable or request failure
  - [x] ✅ Photo-access request failure
- [x] ✅ Handle backup/restore errors with local notifications
- [x] ✅ Ensure UI recovers gracefully if services are unavailable

## 7. Testing
- [x] ✅ Unit tests for toggle logic:
  - [x] ✅ HealthKit toggle in release vs. debug
  - [x] ✅ Photo toggle success & denied paths
- [x] ✅ Unit tests for backup & restore methods:
  - [x] ✅ Success path updates timestamp
  - [x] ✅ Failure path posts notification
- [x] ✅ UI tests (if applicable):
  - [x] ✅ Verify toggles reflect persisted states  
  - [x] ✅ Simulate tap on Sync/Restore and assert UI feedback
  - *Note: UI tests require physical device/simulator for actual interaction testing*

## 8. QA & Manual Validation
- [ ] Manual test on device:
  - [ ] Toggle HealthKit on/off (debug & release)
  - [ ] Toggle Photo access on/off
  - [ ] Trigger backup and confirm timestamp updates
  - [ ] Trigger restore and confirm data recovery flow
- [ ] Validate "Go to Settings" link opens system Settings
- [x] ✅ Check haptic feedback on toggles

## ✅ Implementation Status Summary:
- **Complete**: Full SettingsView UI with proper sections, icons, and styling
- **Complete**: SettingsViewModel with comprehensive state management and intent handling  
- **Complete**: Permission handling for HealthKit and Photo Library with proper states
- **Complete**: iCloud backup/restore functionality with progress tracking and error handling
- **Complete**: Persistence using AppSettingsStore and UserDefaults
- **Complete**: Comprehensive error handling with user-friendly messages
- **Complete**: Unit test coverage for ViewModel functionality
- **Complete**: All core functionality implemented with haptic feedback
- **Remaining**: Manual device testing only (requires physical device for full validation)
- **Note**: The implementation follows MVVM architecture with proper dependency injection, logging, and accessibility support