# UzoFitness App Components Overview

This document provides a high-level tour of the main components in the project. It is intended for new contributors who want to understand how the pieces fit together.

## 1. App Entry

* **`UzoFitnessApp.swift`** – Main application entry point. It creates the shared `PersistenceController` and injects its `ModelContainer` into the root view `MainTabView`.
* **`MainTabView`** – Hosts the five primary screens (`LoggingView`, `LibraryView`, `HistoryView`, `ProgressView`, `SettingsView`) inside a `TabView`.

## 2. Persistence Layer

* **Directory:** `UzoFitness/Persistence`
* **Key file:** `PersistenceController.swift`
  * Configures the SwiftData `ModelContainer` and exposes a `ModelContext` for database operations.
  * Provides generic CRUD helpers (`create`, `fetch`, `delete`) and sample data generation for previews.
  * The singleton `PersistenceController.shared` is used throughout the app for data access.

## 3. Domain Models

* **Directory:** `UzoFitness/Models`
* Contains all persistent models and related protocols/extensions. Important files include:
  * `Exercise`, `WorkoutTemplate`, `DayTemplate`, `ExerciseTemplate` – Planning layer models.
  * `WorkoutPlan`, `WorkoutSession`, `SessionExercise`, `CompletedSet` – Execution layer models.
  * `PerformedExercise`, `ProgressPhoto` – Historical data and progress tracking.
  * `Enums.swift` – Enumerations such as `ExerciseCategory`, `Weekday`, `PhotoAngle`, and validation errors.
  * `Protocols.swift` – Shared model protocols like `Identified` (provides a UUID) and `Timestamped` (creation date).
  * Extension files under `Models/Extensions` add validation and helper methods for the core models.

See `Models-Architecture-Summary.md` in this folder for a more detailed description of relationships between these models.

## 4. Services

* **Directory:** `UzoFitness/Services`
* **`HealthKitManager.swift`** – Handles all HealthKit read/write logic. Protocol-based abstractions allow the manager to be unit‑tested or mocked.
* **`PhotoService.swift`** – Manages progress‑photo capture and caching. It interacts with the photo library, file system and SwiftData via protocol‑driven dependencies.

## 5. View Models

* **Directory:** `UzoFitness/ViewModels`
* Each screen has a corresponding `ObservableObject` view model responsible for business logic and data flow:
  * `LoggingViewModel` – Drives workout logging, set tracking and rest timers.
  * `LibraryViewModel` – CRUD hub for workout templates, exercises and active plans.
  * `HistoryViewModel` – Loads historical workout sessions and summaries for the calendar view.
  * `ProgressViewModel` – Provides charts of performance trends and progress photo management.
  * `SettingsViewModel` – Handles permissions, backups and other app configuration settings.
* `ViewModelSpec.md` gives detailed specs for these view models.

## 6. Views

* **Directory:** `UzoFitness/Views`
  * `Screens/` – SwiftUI screens for each tab (`LoggingView.swift`, `LibraryView.swift`, etc.). Many have accompanying `*_PRD.md` and `*_Tasks.md` docs that outline design details and to‑dos.
  * `Components/` – Reusable UI pieces like charts (`MetricLineChart`, `ConsolidatedMetricChart`), photo management views and JSON import helpers.
* Views are intentionally kept lightweight. They delegate logic to their view models and use dependency injection for services.

## 7. Other Resources

* **`Assets.xcassets`** – Image and color assets used by the app.
* **`UzoFitness.entitlements`** – Capability settings (HealthKit, Photos, iCloud). The iCloud container is configured but sync is not yet implemented.
* **Tests** – Unit tests live in `UzoFitnessTests` and UI tests in `UzoFitnessUITests`.

---

This overview should help you navigate the repository and understand where each major piece of the application lives. For deeper dives, consult the other markdown files in this `Documentation` folder.
