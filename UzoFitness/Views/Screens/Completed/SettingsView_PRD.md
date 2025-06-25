Here’s the updated PRD in Markdown—including your answers—and a suggested file name.

⸻

PRD: Settings View

1. Introduction / Overview

The Settings View provides a centralized screen where fitness enthusiasts can manage key app permissions and data sync options. It consolidates controls for HealthKit synchronization, photo library access, iCloud backup/restore, and shows the last backup timestamp. This eliminates the need to hunt through system settings and ensures users have confidence in their privacy and data safety. It follows the iOS Minimalist Design Philosophy.

2. Goals
	1.	Enable users to toggle HealthKit data sync on or off.
	2.	Enable users to toggle photo library access on or off.
	3.	Provide one-tap Sync to iCloud Backup functionality.
	4.	Provide one-tap Restore from iCloud Backup functionality (with confirmation).
	5.	Display the last backup timestamp to inform users when their data was last saved.
	6.	Maintain a clean, intuitive layout that feels natural to iPhone users.

3. User Stories
	•	HealthKit Sync
	•	As a fitness enthusiast, I want to toggle HealthKit sync on/off so that I can control whether the app reads my workout metrics.
	•	Photo Library Access
	•	As a user, I want to toggle photo library access on/off so that I can manage whether progress photos are saved.
	•	iCloud Backup
	•	As a user, I want a “Sync to iCloud Backup” button so that my workout data is backed up without leaving the app.
	•	iCloud Restore
	•	As a user, I want a “Restore from iCloud Backup” button (with confirmation) so that I can recover my data if I reinstall or switch devices, without accidental overwrite.
	•	Last Backup Timestamp
	•	As a user, I want to see when the last backup occurred so I know my data is up-to-date.
	•	Debug Mode Mocking
	•	As a developer, I want the HealthKit toggle to use mock data in debug mode so I can test without real HealthKit calls.

4. Functional Requirements
	1.	HealthKit Sync Toggle
	•	Display a switch labeled HealthKit Sync.
	•	In release builds, toggling On requests HealthKit authorization; Off disables data reads.
	•	In debug builds, toggling flips a mock-data flag without invoking HealthKit APIs.
	•	If system permission is denied externally, display Denied state and prompt “Go to Settings” link.
	2.	Photo Library Access Toggle
	•	Display a switch labeled Photo Library Access.
	•	Toggling On requests photo-library permission; Off revokes access.
	•	If system permission is denied externally, display Denied state and prompt “Go to Settings” link.
	3.	Sync to iCloud Backup
	•	Display a button Sync to iCloud Backup.
	•	On tap, call SettingsViewModel.syncToICloud(), start background upload, and show a non-blocking activity indicator.
	4.	Last Backup Timestamp
	•	Show “Last backup: ” below the sync button in small, secondary text.
	5.	Restore from iCloud Backup
	•	Display a button Restore from iCloud Backup.
	•	On tap, present a confirmation alert (“This will overwrite local data. Continue?”).
	•	If confirmed, call SettingsViewModel.restoreFromICloud(), show progress overlay until complete.
	6.	Persistence
	•	All toggle states and “last backup” timestamp persist across launches.
	7.	Error Handling
	•	If HealthKit or Photo permission APIs fail, show inline toast or alert with the error.
	•	If backup/restore fails, send a local notification with failure details.

5. Non-Goals
	•	Managing settings beyond HealthKit, Photo Library, and iCloud.
	•	Viewing historical logs—this screen strictly initiates sync/restore and shows last timestamp.
	•	Handling conflict resolution beyond the confirmation prompt.

6. Design Considerations
	•	Minimalist Layout: Generous white space; subtle gray separators.
	•	Standard Components: System Toggle/Switch and plain Button.
	•	Visual Hierarchy:
	•	Section headers Permissions and Data Sync in .semibold.
	•	Toggles aligned left; labels on same line.
	•	Buttons centered; timestamp in secondary text underneath.
	•	Feedback:
	•	Smooth toggle animations; haptics on changes.
	•	Buttons show brief gray fill on tap.

7. Technical Considerations
	•	ViewModel Integration: Bind SettingsViewModel to SwiftUI or UIKit.
	•	HealthKitManager: Inject mock vs. real manager based on build.
	•	PhotoService: Wrap PHPhotoLibrary and manage denied states.
	•	iCloud API: Use NSUbiquitousKeyValueStore or CloudKit; support background transfers.

8. Success Metrics
	•	Functionality: Toggles and buttons correctly reflect and change permission/sync states.
	•	Reliability: Backup/restore runs without crashes; background sync works.
	•	Usability: New users immediately understand controls in usability testing.
	•	Test Coverage: Unit tests for toggle logic, mock vs. real flows, and error states.
