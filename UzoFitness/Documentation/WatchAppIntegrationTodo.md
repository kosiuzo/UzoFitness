# UzoFitness Watch App Integration: Detailed TODO Checklist

This document tracks the remaining work for the watchOS companion app integration, combining the original plan and current progress. Check off each item as you complete it.

---

## 1. Move Shared Services to UzoFitnessCore
- [ ] Identify all business logic/services in `UzoFitness/Services/` needed by both iOS and watchOS
- [ ] Refactor services to use protocols and ensure they are platform-agnostic
- [ ] Move service implementations and protocols to `UzoFitnessCore/Services/`
- [ ] Update iOS and watchOS targets to use services from `UzoFitnessCore`
- [ ] Add/Update unit tests for shared services in `UzoFitnessCore/Tests/`
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 2. Set Up WatchConnectivity Framework Integration
- [ ] Add WatchConnectivity integration to both iOS and watchOS targets
- [ ] Implement `WatchConnectivityService` conforming to `WatchConnectivityServiceProtocol` in `UzoFitnessCore`
- [ ] Handle session activation, message transfer, and background transfer
- [ ] Implement sync logic for workout state, set completion, and rest timer events
- [ ] Handle offline mode and queue actions for later sync
- [ ] Add error handling and user feedback for sync failures
- [ ] Add/Update unit tests for connectivity logic
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 3. Implement Watch App ViewModels
- [ ] Mirror iOS ViewModels in `UzoFitnessWatch/ViewModels/` (adapt for watch-specific flows)
- [ ] Inject shared services via dependency injection
- [ ] Implement state management for workout session, exercise, set completion, and rest timer
- [ ] Add/Update unit tests for ViewModels
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 4. Create Watch App UI Components
- [ ] Build glanceable views for:
    - [ ] Current exercise
    - [ ] Superset details
    - [ ] Set completion
    - [ ] Rest timer
    - [ ] Workout start/completion
- [ ] Add haptic feedback for set completion and timer events
- [ ] Support accessibility (VoiceOver, large text)
- [ ] Add/Update UI tests for watchOS flows
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 5. Implement State Synchronization Logic
- [ ] Ensure marking a set complete or starting a timer updates both devices
- [ ] Implement conflict resolution and merge logic (use timestamps)
- [ ] Use App Groups for shared storage (UserDefaults or file-based)
- [ ] Ensure starting a workout session from the watch updates the iOS app and vice versa
- [ ] Optimize sync for battery efficiency and minimal data transfer
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 6. Build Project After Shared Code Restructuring
- [ ] Update Xcode project/workspace to use new shared code locations
- [ ] Build iOS and watchOS targets to ensure no breaking changes
- [ ] Fix any build errors or warnings
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 7. Build and Test Watch App Integration
- [ ] Run unit and UI tests for both iOS and watchOS
- [ ] Perform manual QA for:
    - [ ] Offline/online transitions
    - [ ] Error handling
    - [ ] Edge cases (e.g., workout already completed, rest day)
- [ ] Validate real-time sync and data consistency
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

## 8. Final Build and Validation
- [ ] Finalize documentation and update App Store assets/release notes
- [ ] Perform final build for release
- [ ] Validate on physical devices (iPhone and Apple Watch)
- [ ] **Build iPhone and watchOS targets; only proceed if there are no errors or warnings**

---

*Check off each sub-task as you complete it. This checklist is designed for step-by-step tracking of the remaining work for UzoFitness watchOS integration.* 