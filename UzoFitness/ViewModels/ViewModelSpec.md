Below is a **concise, Cursor-friendly spec** for each View Model.
Copy any section directly into Cursor to scaffold code, or tweak bullet points first if you want to change behaviour.

---

## Conventions used here (keep for all VM files)

* **`ObservableObject` + `@Published`** for reactive state.
* **Dependency-injected services** (e.g. `@Environment(\.modelContext)`, `HealthKitManager`, etc.) to keep VMs platform-agnostic and testable.
* **Intents enum** for user actions → keeps `View` → `ViewModel` communication explicit.
* **Combine‐driven side-effects** (timers, async saves) run on `@MainActor`.
* **ErrorHandlingStrategy** protocol allows uniform toast / alert surfacing.

---

# 1. `LoggingViewModel` - Completed

| Section               | Details                                                                                                                                                                                                                                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Purpose**           | Drive the “Log” tab – choosing a workout, selecting the day, real-time set/rep tracking, rest timer, superset logic, session completion.                                                                                                                                                                                              |
| **Primary Models**    | `WorkoutPlan`, `WorkoutSession`, `SessionExercise`, `CompletedSet`, `ExerciseTemplate`                                                                                                                                                                                                                                                |
| **@Published State**  | `activePlan: WorkoutPlan?` <br> `selectedDay: DayTemplate?` <br> `session: WorkoutSession?` (auto-created on first interaction) <br> `exercises: [SessionExerciseUI]` *(struct for easy binding: id, name, sets, currentSet, timerRemaining, isSupersetHead)* <br> `isRestDay: Bool` <br> `showTimerSheet: Bool` <br> `error: Error?` |
| **Computed Helpers**  | `canFinishSession: Bool` (all exercises completed) <br> `totalVolume: Double`                                                                                                                                                                                                                                                         |
| **Intents / Actions** | `.selectPlan(UUID)` <br> `.selectDay(Weekday)` – auto-defaults to today but user-changeable <br> `.editSet(exerciseID, setIndex, reps, weight)` <br> `.addSet(exerciseID)` <br> `.startRest(exerciseID, seconds)` <br> `.tickTimer` (Combine) <br> `.markExerciseComplete(exerciseID)` <br> `.finishSession`                          |
| **Business Rules**    | - If day = rest, `isRestDay` true but still allow **“Log Anyway”** path. <br> - Superset = same `supersetID`, UI orders by `position`. <br> - `tickTimer` decrements; when 0, triggers haptic + auto-advance focus to next set.                                                                                                       |
| **Services / DI**     | `ModelContext`,`TimerFactory` (testable).                                                                                                                                                                                                                       |
| **Persistence Steps** | 1. On `.finishSession`, update `session.duration`, save context. <br> 2. For each `SessionExercise`, convert to `PerformedExercise` records for history.                                                                                                                                                                              |
| **Why this matters**  | Keeps log logic out of `LoggingView` so UI remains declarative; unit tests can cover volume math & timer edge-cases.                                                                                                                                                                                                                  |

---

# 2. `LibraryViewModel` - Completed

| Section              | Details                                                                                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Purpose**          | CRUD hub for templates, exercises & active plans.                                                                                                                                                                        |
| **Models**           | `WorkoutTemplate`, `DayTemplate`, `ExerciseTemplate`, `WorkoutPlan`, `Exercise`                                                                                                                                          |
| **@Published State** | `templates: [WorkoutTemplate]` <br> `exerciseCatalog: [Exercise]` <br> `activePlanID: UUID?` <br> `showTemplateSheet`, `showExerciseSheet`, `error`                                                                      |
| **Intents**          | `.createTemplate(name)` <br> `.duplicateTemplate(id)` (handles unique-name helper) <br> `.deleteTemplate(id)` <br> `.createExercise(...)` <br> `.activatePlan(templateID, customName, startDate)` <br> `.deactivatePlan` |
| **Business Rules**   | - Enforce unique template names (`ValidationError.duplicateName`). <br> - Cannot delete template if referenced by active plan.                                                                                           |
| **Services**         | `ModelContext`, `FileImporter` (for exercise media if needed).                                                                                                                                                           |
| **Why**              | Separates *planning* layer from runtime; reduces complexity in Logging.                                                                                                                                                  |

---

# 3. `HistoryViewModel`

| Section              | Details                                                                                                                                                                       |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Purpose**          | Calendar + daily summary of past workouts.                                                                                                                                    |
| **Models**           | `WorkoutSession`, `PerformedExercise`                                                                                                                                         |
| **@Published State** | `calendarData: [Date: [WorkoutSessionSummary]]` *(pre-computed for fast calendar rendering)* <br> `selectedDate: Date?` <br> `dailyDetails: [PerformedExercise]` <br> `error` |
| **Intents**          | `.selectDate(Date)`                                                                                                                                                           |
| **Computed**         | `totalVolumeForDay`, `longestSession`, `streakCount`                                                                                                                          |
| **Why**              | Users quickly gauge adherence; performant calendar loading avoids CoreData hits on every scroll.                                                                              |

---

# 4. `ProgressViewModel`

| Section              | Stats Tab                                                                    | Photos Tab                                                                                   |
| -------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Purpose**          | Show performance trends & current weight for selected exercise.                             |   Show progress of body over time                                                                                           |
| **Models**           | `PerformedExercise`                                                          | `ProgressPhoto`                                                                              |
| **@Published State** | `exerciseTrends: [ExerciseTrend]` (max weight, volume over weeks) (latest weight sample via HealthKit)           | `photosByAngle: [PhotoAngle: [ProgressPhoto]]` <br> `compareSelection: (PhotoID?, PhotoID?)` <br> `photoMetrics: [PhotoID: Body Metrics]` (weight & bodyFat captured) |
| **Intents**          | `.selectExercise(id)` <br> `.toggleMetric(metricType)`                       | `.addPhoto(angle, UIImage)` <br> `.deletePhoto(id)` <br> `.selectForCompare(id)`             |
| **Computed**         | `trendChartData` (array of `(Date, Double)` ready for Charts)                | `canCompare: Bool`                                                                           |
| **Services**         | `ModelContext`, `PhotoService`, `HealthKitManager` (optional weight samples) |                                                                                              |
| **Why**              | Separation lets you swap Charts/Photos UI without touching underlying logic. |                                                                                              |

---

# 5. `SettingsViewModel`

| Section               | Details                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------ |
| **Purpose**           | Permission toggles, iCloud backup / restore, app metadata.                                       |
| **Models / Services** | `AppSettingsStore`, `HealthKitManager`, `PhotoService`, `iCloudBackupService`                    |
| **@Published State**  | `isHealthKitEnabled`, `isPhotoAccessGranted`, `lastBackupDate`, `error`                          |
| **Intents**           | `.requestHealthKitAccess` <br> `.togglePhotoAccess` <br> `.performBackup` <br> `.performRestore` |
| **Business Rules**    | - Backup disabled if <10 % battery (example guard).                                              |
| **Why**               | Centralises potentially sensitive operations for easier auditing & testing.                      |

---

## Next Steps (if you want Cursor to generate code)

1. **Paste one VM section at a time** into Cursor with a prompt like
   “Generate Swift implementation for the following ViewModel spec.”
2. Review generated code:

   * Confirm dependencies are injected (not singletons).
   * Ensure Combine publishers use `@MainActor` where mutating UI state.
   * Check error handling aligns with your `ErrorHandlingStrategy`.
3. Refine spec bullets first whenever behaviour changes—simpler feedback loop than editing generated code later.

Feel free to ask for deeper examples (unit-test templates, Mock services, etc.) if that will speed up your build-out!
