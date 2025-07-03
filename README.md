# UzoFitness

UzoFitness is a modern iOS application built with Swift 5 and SwiftUI that helps users track their fitness journey end-to-end.  The app focuses on three core pillars:

1. **Workout Planning & Execution** – Create reusable workout templates, run guided workout sessions, and log sets/reps/weights.
2. **Progress Tracking** – Log body-weight, body-fat %, and upload progress photos that are organised in grid views.
3. **Apple Health Integration** – Securely read body-mass and body-fat data directly from Apple Health to keep metrics in sync.

> **Status**: Active development (June 2025)

---

## Table of Contents
1. [Features](#features)
2. [Architecture](#architecture)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Project Structure](#project-structure)
7. [Dependencies](#dependencies)
8. [Contributing](#contributing)
9. [Roadmap](#roadmap)
10. [License](#license)

---

## Features
- **Workout Templates** – Design multi-day workout plans consisting of exercises, sets, and rest timers.
- **Workout Sessions** – Run interactive sessions that automatically progress through planned sets while persisting results with SwiftData.
- **Progress Photos** – Import photos from the library or camera and view them in an adaptive `ProgressPhotoGrid` component.
- **Apple Health Sync** – One-tap authorisation to read body-mass (kg/lb) and body-fat %.  Data is cached for offline viewing.
- **SwiftData Persistence** – Cloud-sync-ready local storage for workouts, sessions, and user metrics.
- **Accessibility** – Dynamic Type, VoiceOver, and high-contrast colour support.

## Architecture
UzoFitness follows Apple-recommended best practices for a **SwiftUI + MVVM** stack and takes advantage of **SwiftData** for persistence.

```
UzoFitnessApp (SwiftUI @main)
 ├─ MainTabView (3-tab navigation)
 │   ├─ WorkoutsView
 │   ├─ ProgressView
 │   └─ SettingsView
 ├─ ViewModels                // Business logic, @Observable & async/await
 ├─ Models                    // Value & reference types used by SwiftData
 ├─ Services                  // Isolated side-effect managers (HealthKit, Photos)
 └─ Utilities                 // Extensions & helpers
```

Key principles:
* **Single Source of Truth** – App state lives in `@ModelContext` or `@Observable` ViewModels.
* **Testability** – Heavy use of protocols and dependency injection (see `HealthKitManager`) enables unit testing.
* **Swift Concurrency** – Asynchronous work (HealthKit queries, file IO) uses `Task` & `async/await`.

## Requirements
- **Xcode 15.4** or later
- **iOS 17.0** or later (SwiftData requires iOS 17)
- A device with **Apple Health** (or simulator with HealthKit enabled) for Health features

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/uzo-fitness.git
   ```
2. Open the workspace:
   ```bash
   open UzoFitness.xcodeproj
   ```
3. Select a simulator or device and hit **Run (⌘R)**.

> **Note**: The first launch will request HealthKit authorisation.  Denying permission will disable body metrics features but the rest of the app will continue to work.

## Usage
1. **Create a Plan** – Navigate to the *Workouts* tab → press **＋** to build a workout template.
2. **Start a Session** – Tap any template and hit **Start Session**.  Log each set; progress auto-saves.
3. **Track Progress** – Go to the *Progress* tab to record or import progress photos and review body metrics.
4. **Sync Health** – In *Settings* toggle **Sync with Apple Health**.  The app will read the latest body-mass & body-fat samples automatically.

## Project Structure
```
UzoFitness/
 ├─ UzoFitnessApp.swift        // Entry point
 ├─ Models/                    // Data models & enums
 ├─ ViewModels/                // Observable objects
 ├─ Views/                     // Screens & sub-views
 ├─ Components/                // Re-usable SwiftUI views
 ├─ Services/                  // HealthKit & Photo managers
 └─ Utilities/                 // Extensions & helpers
```

## Dependencies
| Framework | Usage |
|-----------|-------|
| **SwiftData** | Local persistence layer (CoreData-like) |
| **HealthKit** | Reading body-mass & body-fat samples |
| **PhotosUI**  | Selecting images for progress photos |

All dependencies are **first-party Apple frameworks**—no external package managers are required.

## Contributing
We welcome pull requests!  Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

## Roadmap
- iCloud sync with App Group containers
- Workout scheduling & reminders
- Social sharing & challenges

## License
This project is licensed under the [MIT License](LICENSE).
