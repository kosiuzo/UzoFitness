# UzoFitness: watchOS Companion App Integration Plan

## Overview
This document outlines a best-practices approach for implementing a watchOS companion app for UzoFitness that shares state with the iOS app. The watch app will:
- Display the current exercise
- Show exercises in the current superset
- Allow marking a set as completed
- Start a rest timer
- Mark the workout as complete when all exercises are done

The plan covers architecture, product requirements (PRDs), and necessary restructuring for seamless state sharing and user experience.

**✅ MIGRATION STATUS: UzoFitnessCore migration completed successfully**
- All models, protocols, services, and utilities have been moved to UzoFitnessCore
- iOS app has been refactored to use shared code
- Project builds successfully with no compilation errors

---

## 1. Architecture

### 1.1. MVVM-C (Model-View-ViewModel-Coordinator)
- **MVVM** for both iOS and watchOS targets, ensuring testability and separation of concerns.
- **Coordinator** pattern for navigation and workflow management, especially for the watch app's linear workout flow.

### 1.2. Shared Code & Data ✅ COMPLETED
- **UzoFitnessCore Swift Package**: ✅ All shared models, business logic, and services have been moved to `UzoFitnessCore`.
- **SwiftData**: ✅ Shared data model for workout/exercise/session state is in UzoFitnessCore.
- **Protocols**: ✅ All service protocols defined and moved to UzoFitnessCore for dependency injection and mocking.

**Completed Migration Components:**
- **Models**: Exercise, WorkoutSession, SessionExercise, CompletedSet, ProgressPhoto, etc.
- **Protocols**: HealthStoreProtocol, PhotoServiceProtocol, FileSystemServiceProtocol, etc.
- **Services**: WorkoutSessionLogic, ProgressAnalysisLogic, TimerLogic
- **Utilities**: Logger, DateFormatters, FormattingUtilities

### 1.3. State Synchronization
- **App Groups**: Use App Groups to share data between iOS and watchOS apps securely.
- **WatchConnectivity**: Use `WatchConnectivity` framework for real-time state sync (e.g., current exercise, set completion, rest timer events).
- **Background Sync**: Implement background transfer for reliability if the watch is out of range.

### 1.4. UI/UX
- **Minimalist, glanceable UI**: Focus on quick interactions (mark set, start timer, view superset).
- **Haptics**: Use haptic feedback for set completion and rest timer events.
- **Accessibility**: Support VoiceOver and large text.

---

## 2. Product Requirements (PRDs)

### 2.1. User Stories
- **As a user, I want to see my current exercise and superset on my watch, so I can follow my workout without my phone.**
- **As a user, I want to mark a set as completed from my watch, so my progress is tracked.**
- **As a user, I want to start a rest timer from my watch, so I know when to resume.**
- **As a user, I want the workout to be marked complete when all exercises are done, both on my phone and watch.**
- **As a user, I want to start the workout session for the current day from my watch, if today is not a rest day, so I can begin my workout without needing my phone.**

### 2.2. Functional Requirements
- Display current exercise and superset details
- Mark set as completed (syncs to iOS)
- Start/stop rest timer (syncs to iOS)
- Mark workout as complete (syncs to iOS)
- Handle offline mode and sync when reconnected
- Show error states (e.g., sync failure)
- Start the workout session for the current day from the watch (if today is not a rest day, syncs to iOS)

### 2.3. Non-Functional Requirements
- Real-time or near-real-time sync (<2s latency)
- Data consistency between devices
- Battery-efficient background sync
- Secure data sharing (App Groups, no sensitive data leakage)
- Test coverage for all sync and state logic

---

## 3. Implementation Steps

### 3.1. Project Restructuring ✅ COMPLETED
- **✅ UzoFitnessCore Swift Package**: Created and configured with all shared components
- **✅ Models Refactored**: All workout/session/exercise models conform to protocols and are serializable (Codable)
- **✅ Services Abstracted**: All service protocols defined in UzoFitnessCore
- **✅ iOS App Refactored**: All references updated to use UzoFitnessCore
- **App Group Setup**: Configure App Groups in both targets for shared storage

### 3.2. Watch App Target
- **Add watchOS target**: Use Xcode's template for a new watchOS app with SwiftUI.
- **Implement MVVM structure**: Mirror iOS ViewModels, but scoped to watch-specific flows.
- **UI Components**: Build glanceable views for current exercise, superset, set completion, and rest timer.
- **Workout Start Flow**: Implement logic and UI to allow the user to start the workout session for the current day from the watch, only if today is not a rest day. Provide feedback if today is a rest day.

### 3.3. State Sync
- **Implement WatchConnectivity**: 
    - Session activation and message transfer for real-time events
    - Background transfer for reliability
    - Handle conflicts and merge state
    - Ensure starting a workout session from the watch updates the iOS app and vice versa
- **Shared Storage**: Use UserDefaults (with App Groups) or file-based storage for persistent state
- **Sync Logic**: Ensure marking a set complete or starting a timer updates both devices

### 3.4. Testing & QA
- **Unit Tests**: For shared logic, sync, and state management
- **UI Tests**: For watchOS flows (set completion, timer, workout completion)
- **Manual QA**: Test offline/online transitions, error handling, and edge cases

---

## 4. Folder Structure (Current)

```
UzoFitness/
├── UzoFitness/           # iOS App
│   ├── Views/            # SwiftUI Views
│   ├── ViewModels/       # iOS-specific ViewModels
│   ├── Services/         # iOS-specific service implementations
│   ├── Persistence/      # PersistenceController
│   └── ...
├── UzoFitnessCore/       # ✅ Shared Swift Package
│   ├── Models/           # ✅ All data entities
│   ├── Services/         # ✅ Service protocols and shared logic
│   ├── Protocols/        # ✅ All protocols
│   ├── Extensions/       # ✅ Model extensions
│   └── Utilities/        # ✅ Shared utilities
├── UzoFitnessWatch/      # 🆕 watchOS target (to be created)
│   ├── Views/
│   ├── ViewModels/
│   └── ...
```

---

## 5. Best Practices & References
- Use dependency injection for all services (testability)
- Prefer async/await for sync operations
- Use protocols for all shared services
- Minimize data transfer (send only diffs, not full state)
- Provide user feedback for sync status
- Follow Apple's [watchOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/watchos/overview/themes/)
- Reference: [Sharing Data Between iOS and watchOS Apps](https://developer.apple.com/documentation/watchkit/communicating_with_your_companion_ios_app)

---

## 6. Milestones & PRs

### ✅ Milestone 1: Project Restructuring - COMPLETED
- **✅ Move shared code to UzoFitnessCore**
- **✅ Refactor models/services for protocol conformance**
- **✅ Update iOS app to use UzoFitnessCore**
- **✅ Build verification**: ✅ Project builds successfully with no compilation errors

### 🆕 Milestone 2: App Group & WatchConnectivity Setup
- Configure entitlements for App Groups in both targets
- Set up initial WatchConnectivity session management
- Implement basic message transfer between iOS and watchOS
- **Build verification**: Ensure both iOS and watchOS targets build successfully

### 🆕 Milestone 3: watchOS Target Creation
- Add watchOS target to Xcode project
- Configure UzoFitnessCore dependency for watchOS target
- Set up basic watchOS app structure with SwiftUI
- **Build verification**: Ensure watchOS target builds and runs on simulator

### 🆕 Milestone 4: watchOS UI Implementation
- Build main workout flow views
- Implement set completion UI
- Create rest timer interface
- Add workout start flow for current day
- **Build verification**: Ensure all watchOS views compile and render correctly

### 🆕 Milestone 5: State Sync & Error Handling
- Implement robust sync logic using WatchConnectivity
- Add conflict resolution and merge logic
- Handle offline mode and reconnection
- Implement error handling and user feedback
- **Build verification**: Test sync functionality and ensure no build errors

### 🆕 Milestone 6: Testing & QA
- Write unit tests for shared logic and sync
- Create UI tests for watchOS flows
- Perform manual QA testing
- Test edge cases and error scenarios
- **Build verification**: Ensure all tests pass and no warnings

### 🆕 Milestone 7: Documentation & Release
- Update README with watchOS integration details
- Create App Store assets for watchOS
- Write release notes
- Update internal documentation
- **Build verification**: Final build check before release

---

## 7. Risks & Mitigations
- **Sync Conflicts**: Use timestamps and merge logic
- **Offline Mode**: Queue actions and sync when reconnected
- **Battery Usage**: Optimize sync frequency and payload size
- **User Confusion**: Provide clear UI feedback for sync status

---

## 8. README Update Plan

### 8.1. Documentation Updates
- **Project Structure**: Update to reflect UzoFitnessCore and watchOS target
- **Installation**: Add instructions for building both iOS and watchOS targets
- **Architecture**: Document the shared code approach and MVVM-C pattern
- **Development**: Add guidelines for working with shared code

### 8.2. README Sections to Add/Update
- **Features**: Add watchOS companion app features
- **Requirements**: Update minimum iOS/watchOS versions
- **Building**: Add instructions for building both targets
- **Testing**: Add watchOS testing instructions
- **Contributing**: Update guidelines for shared code development

### 8.3. Technical Documentation
- **UzoFitnessCore**: Document the shared module structure and usage
- **State Sync**: Document WatchConnectivity implementation
- **App Groups**: Document shared data configuration
- **Testing**: Document testing strategy for shared code

---

*Prepared by: Cursor Agent Mode*
*Date: [2025-07-18]*
*Last Updated: [2025-07-18] - UzoFitnessCore migration completed* 