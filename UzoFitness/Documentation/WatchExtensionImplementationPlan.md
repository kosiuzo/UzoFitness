# UzoFitness Watch Extension Implementation Plan

This document outlines the key steps for extending UzoFitness to Apple Watch using a shared App Group container and the existing SwiftUI + MVVM architecture.

## 1. Create watchOS Targets
- Add a **Watch App for iOS App** target in Xcode, generating both a watch app and watch extension.
- Ensure the watch targets share the same team and bundle identifier prefix as the iOS app.

## 2. Configure a Shared App Group
- In the iOS app, watch app, and watch extension targets, enable the same App Group capability (for example `group.com.yourcompany.UzoFitnessShared`).
- Update the SwiftData store to read and write data using a URL inside this shared container so both platforms use the same database.

## 3. Share Models and View Models
- Place data models and common view models in a shared group or framework so they compile for both iOS and watchOS.
- Reuse business logic like `markSetComplete()` across platforms while keeping watch‑specific views separate.

## 4. Watch UI and User Interaction
- Provide a minimal interface that shows the current exercise, set progress, and a **Complete Set** button.
- If the exercise is part of a superset, automatically switch to the paired exercise after completing a set.
- Include a per‑exercise **Rest Timer** that users can start or adjust quickly from the watch.

## 5. Data Syncing and Connectivity
- The shared App Group ensures the latest workout state is available on both devices.
- Use **WCSession** messages for real‑time updates when one device is active and the other is locked or unreachable.

## 6. HealthKit and Background Tasks
- Extend the existing `HealthKitManager` if the watch should record metrics like heart rate or active energy.
- Use `WKExtendedRuntimeSession` or `WorkoutConfiguration` to keep the app active during a workout when necessary.

## 7. Testing
- Add watchOS unit tests for the watch view models, especially superset switching and timer logic.
- Run UI tests in the watch simulator to verify that completing sets updates the exercise correctly and that rest timers trigger haptic feedback.

## 8. Deployment Considerations
- Keep watch interactions lightweight to conserve battery.
- Package the watch app with the iOS app for App Store submission and include watch screenshots and metadata.

By following these steps, UzoFitness can provide a streamlined workout companion on Apple Watch while maintaining data consistency with the iOS app.
