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
7. [Documentation](#documentation)
8. [Dependencies](#dependencies)
9. [Contributing](#contributing)
10. [Roadmap](#roadmap)
11. [License](#license)

---

## Features
- **Workout Templates** – Design multi-day workout plans consisting of exercises, sets, and rest timers.
- **Workout Sessions** – Run interactive sessions that automatically progress through planned sets while persisting results with SwiftData.
- **Progress Photos** – Import photos from the library or camera and view them in an adaptive `ProgressPhotoGrid` component.
- **Apple Health Sync** – One-tap authorisation to read body-mass (kg/lb) and body-fat %.  Data is cached for offline viewing.
- **SwiftData Persistence** – Cloud-sync-ready local storage for workouts, sessions, and user metrics.
- **iCloud Support** – Capability is enabled; cross-device sync will arrive in a future update.
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

### Adding a Workout Template via JSON
You can import a custom workout template using JSON. To do this:

1. Go to the *Workouts* tab.
2. Tap the **Import** button (usually labeled as "Import JSON" or similar).
3. Paste or select your JSON file in the import dialog.
4. Confirm to add the template to your library.

**Sample Workout Template JSON (with day names):**
```json
{
  "name": "Push Pull Legs Template",
  "summary": "A 3-day template using day names instead of indices",
  "days": [
    {
      "dayName": "Monday",
      "name": "Push Day",
      "exercises": [
        {
          "name": "Bench Press",
          "sets": 4,
          "reps": 8,
          "weight": 185.0
        },
        {
          "name": "Overhead Press",
          "sets": 3,
          "reps": 10,
          "weight": 95.0
        },
        {
          "name": "Dips",
          "sets": 3,
          "reps": 12,
          "supersetGroup": 1
        },
        {
          "name": "Close Grip Push-ups",
          "sets": 3,
          "reps": 15,
          "supersetGroup": 1
        }
      ]
    },
    {
      "dayName": "Wednesday",
      "name": "Pull Day",
      "exercises": [
        {
          "name": "Pull-ups",
          "sets": 4,
          "reps": 6
        },
        {
          "name": "Barbell Rows",
          "sets": 4,
          "reps": 8,
          "weight": 135.0
        },
        {
          "name": "Face Pulls",
          "sets": 3,
          "reps": 15,
          "weight": 30.0,
          "supersetGroup": 2
        },
        {
          "name": "Hammer Curls",
          "sets": 3,
          "reps": 12,
          "weight": 25.0,
          "supersetGroup": 2
        }
      ]
    },
    {
      "dayName": "Friday",
      "name": "Legs Day",
      "exercises": [
        {
          "name": "Squats",
          "sets": 4,
          "reps": 10,
          "weight": 225.0
        },
        {
          "name": "Romanian Deadlifts",
          "sets": 3,
          "reps": 8,
          "weight": 185.0
        },
        {
          "name": "Walking Lunges",
          "sets": 3,
          "reps": 20
        },
        {
          "name": "Calf Raises",
          "sets": 4,
          "reps": 15,
          "weight": 45.0
        }
      ]
    }
  ]
}
```

**Alternative: Sample Workout Template JSON (with day indices - legacy format):**
```json
{
  "name": "Legacy Format Template",
  "summary": "Using dayIndex (1-7) for backward compatibility",
  "days": [
    {
      "dayIndex": 1,
      "name": "Sunday Workout",
      "exercises": [
        {
          "name": "Push-ups",
          "sets": 3,
          "reps": 15
        }
      ]
    }
  ]
}
```

### Importing Exercises Only via JSON
You can also import a list of exercises directly using JSON. This is useful for quickly adding multiple exercises to your exercise catalog.

1. Go to the *Workouts* tab and switch to the **Exercises** segment.
2. Tap the **Import from JSON** button (or use the plus menu and select "Import from JSON").
3. Paste or select your JSON file containing an array of exercises.
4. Confirm to add the exercises to your library.

**Sample Exercises JSON:**
```json
[
  {
    "name": "Push-ups",
    "category": "strength",
    "instructions": "Start in a plank position with hands shoulder-width apart. Lower your body until your chest nearly touches the floor, then push back up.",
    "mediaAssetID": null
  },
  {
    "name": "Squats",
    "category": "strength",
    "instructions": "Stand with feet shoulder-width apart. Lower your body as if sitting back into a chair, keeping your chest up and weight on your heels.",
    "mediaAssetID": null
  },
  {
    "name": "Mountain Climbers",
    "category": "cardio",
    "instructions": "Start in plank position. Alternate bringing knees to chest rapidly.",
    "mediaAssetID": null
  }
]
```

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

## Documentation
Additional guides live in the [`UzoFitness/Documentation`](UzoFitness/Documentation) directory. Start with
[`AppComponentsOverview.md`](UzoFitness/Documentation/AppComponentsOverview.md) for a tour of the codebase and
[`CloudKitBackImplementation.md`](UzoFitness/Documentation/CloudKitBackImplementation.md) for CloudKit sync details.

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
- CloudKit-based sync with App Group containers *(capability enabled, implementation in progress)*
- Workout scheduling & reminders
- Social sharing & challenges

## License
This project is licensed under the [MIT License](LICENSE).
