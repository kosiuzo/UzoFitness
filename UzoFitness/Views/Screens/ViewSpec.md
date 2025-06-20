## Conventions (apply to all View specs)

- **SwiftUI + MVVM**: inject your ViewModel via `@StateObject` or `@ObservedObject`.  
- **Declarative layout** only—no imperative logic in `body`.  
- **Use system components** (`NavigationStack`, `TabView`, `List`, `LazyVStack`, `Picker`, etc.).  
- **Modifiers**: apply spacing, fonts, colors, and accessibility labels per HIG.  
- **Error handling**: bind `viewModel.error` to `.alert`.  
- **Styling**: stick to neutral backgrounds (e.g. `.systemGray6`), accent color, SF Symbols.  
- **Intent-driven**: user actions map to `viewModel.send(.intent)` calls.  

---

## 1. MainTabView

| Section        | Details                                                                                                                                                                                                                          |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Purpose**    | Entry point hosting the five feature tabs                                                                                                                                                                                        |
| **Dependencies** | None directly; each child view manages its own ViewModel                                                                                                                                                                        |
| **@State**     | `private var selectedTab: Tab = .log` (`enum Tab { case log, library, history, progress, settings }`)                                                                                                                             |
| **Body**       | `TabView(selection: $selectedTab) { … }` with five tabs:  <br>• `LoggingView()` → `Label("Log", systemImage: "plus.circle")`  <br>• `LibraryView()` → `Label("Library", systemImage: "book")`  <br>• `HistoryView()` → `Label("History", systemImage: "clock")`  <br>• `ProgressView()` → `Label("Progress", systemImage: "photo")`  <br>• `SettingsView()` → `Label("Settings", systemImage: "gear")` |
| **Styling**    | `.accentColor(.blue)` on TabView                                                                                                                                                                                                 |
| **Evaluation** | • Builds without errors  <br>• All tabs selectable and icons/labels match SF Symbols  <br>• iPhone HIG spacing and accent applied                                                                                                |

---

## 2. LoggingView

| Section               | Details                                                                                                                                                                                                                 |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Purpose**           | Real-time workout execution: select plan/day, track sets & reps, rest timer, finish session                                                                                                                             |
| **ViewModel**         | `@StateObject var viewModel: LoggingViewModel`                                                                                                                                                                          |
| **@Published State**  | Uses `viewModel.activePlan`, `viewModel.selectedDay`, `viewModel.exercises`, `viewModel.isRestDay`, `viewModel.showTimerSheet`, `viewModel.error`                                                                       |
| **UI Elements**       | • `Picker` for `activePlan`  <br>• `Picker` or `SegmentedControl` for `selectedDay`  <br>• `List` or `LazyVStack` of `SessionExerciseUI` rows (name, sets, weight, status)  <br>• “Rest” overlay when `isRestDay` with “Log Anyway” button  <br>• Timer sheet (`.sheet` bound to `showTimerSheet`)  <br>• “Finish” button disabled until `viewModel.canFinishSession` |
| **Actions/Intents**   | On select plan/day → `viewModel.send(.selectPlan(id))` / `.selectDay(day)`  <br>On tap reps/weight → `.editSet(...)`  <br>On add set → `.addSet(...)`  <br>On finish → `.finishSession`                                 |
| **Layout**            | Vertical stack with header pickers, scrollable exercise list, fixed footer for “Finish” button                                                                                                                         |
| **Styling**           | Use standard paddings (16pt), card backgrounds (`.systemGray6`), bold headers, SF Symbols for each exercise                                                                                                            |
| **Evaluation**        | • Compiles & runs  <br>• Can select plan/day  <br>• Exercises update in real time  <br>• Timer functionality works  <br>• Finish saves session and navigates away if needed                                       |

---

## 3. LibraryView – Updated

| Section             | Details                                                                                                                                                                                                                                                                                                                                                                                                                   |
|---------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Purpose**         | Browse & CRUD workout templates, exercises, exercise Templates, and workout plans                                                                                                                                                                                                                                                                                                                                                       |
| **ViewModel**       | `@StateObject var viewModel: LibraryViewModel`                                                                                                                                                                                                                                                                                                                                                                             |
| **@Published State**| `viewModel.templates`, `viewModel.exerciseCatalog`, `viewModel.activePlanID`, `viewModel.showTemplateSheet`, `viewModel.error`                                                                                                                                                                                                                                                                                              |
| **UI Elements**     | • `SegmentedControl` or `Picker` for two modes: **Workouts** / **Exercises**  <br>• **Workouts** tab:  <br>&nbsp;&nbsp;– `List` of `WorkoutTemplate` rows with context menu (duplicate, delete)  <br>&nbsp;&nbsp;– “+ Template” toolbar button → sheet  <br>&nbsp;&nbsp;– Tap a template → **Detail**: default 7-day tabs, day picker, exercise list per day, “Duplicate from another day” button  <br>&nbsp;&nbsp;– In detail: “+ Exercise” → adds `ExerciseTemplate` (default 3× sets/reps), tap row to edit reps/sets/weight  <br>&nbsp;&nbsp;– “Create Plan” button → sheet to pick templates for new `WorkoutPlan`  <br>• **Exercises** tab:  <br>&nbsp;&nbsp;– `List` of `Exercise` rows with context menu (edit, delete)  <br>&nbsp;&nbsp;– “+ Exercise” toolbar button → sheet |
| **User Actions**    | • Switch between **Workouts** and **Exercises** to manage each.  <br>• Create, rename, duplicate, and delete workout templates.  <br>• New workout templates assume a 7-day week—only edit days you care about.  <br>• Add exercises into a template (auto-3× sets/reps) then edit those details.  <br>• Copy exercises from one day to another.  <br>• Create a workout plan by selecting templates.  <br>• Standard CRUD on exercise catalog (add/edit/delete).  <br>• Upload a JSON file to batch-generate workout templates (including their day and exercise templates).  <br>• Upload a JSON file to import a list of exercises directly into the exercise catalog. |
| **Actions/Intents** | • `.switchMode(.workouts/.exercises)`  <br>• `.createTemplate(name)` / `.duplicateTemplate(id)` / `.deleteTemplate(id)`  <br>• `.selectTemplate(id)` → loads 7-day detail  <br>• `.selectDay(weekday)`  <br>• `.addExercise(toTemplateID, exerciseID)` → creates `ExerciseTemplate`  <br>• `.editExerciseTemplate(templateID, reps, sets, weight)`  <br>• `.duplicateExercise(fromDay, toDay, exerciseTemplateID)`  <br>• `.createWorkoutPlan(name, templateIDs)`  <br>• `.createExercise(...)` / `.editExercise(id, ...)` / `.deleteExercise(id)` |
| **Layout**          | `NavigationStack` → `VStack`: segmented picker at top, then content block swapping between `WorkoutsListView` and `ExercisesListView`.  <br>In **WorkoutsListView**, tap row pushes into `WorkoutTemplateDetailView` (tabs for days).                                                                                                                                                                |
| **Styling**         | Standard paddings (16pt), neutral backgrounds (`.systemGray6`), SF Symbols for add/duplicate icons.  <br>Sheets use `.presentationDetents([.medium, .large])`.  <br>Detail view uses `TabView` (page style) or horizontal `Picker` for days.                                                                                                                                                                  |
| **Evaluation**      | • Builds without errors  <br>• Segmented control switches modes correctly  <br>• Workouts tab: template CRUD, detail view with 7 days, add/edit/duplicate exercises, plan-creation sheet  <br>• Exercises tab: exercise CRUD works  <br>• Alerts/sheets present/dismiss correctly; error handling via `viewModel.error` alerts                                                                                          |

---

## 4. HistoryView

| Section              | Details                                                                                                                                                         |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Purpose**          | Show past workouts in a calendar, drill into daily details of `PerformedExercise`                                                                               |
| **ViewModel**        | `@StateObject var viewModel: HistoryViewModel`                                                                                                                  |
| **@Published State** | `viewModel.calendarData`, `viewModel.selectedDate`, `viewModel.dailyDetails`, `viewModel.error`                                                                 |
| **UI Elements**      | • `CalendarView` or grid of dates with dots for sessions  <br>• Detail list below showing session summaries (volume, time)                                      |
| **Actions/Intents**  | On date tap → `viewModel.send(.selectDate(date))`                                                                                                              |
| **Layout**           | Vertical scroll: calendar at top, list of `dailyDetails` below                                                                                                  |
| **Styling**          | Use `.accentColor(.green)` for completed dates, lightweight fonts, clear headers                                                                                |
| **Evaluation**       | • Builds  <br>• Calendar renders  <br>• Selecting a date updates detail list                                                                                     |

---

## 5. ProgressView

| Section                     | Details                                                                                                                                                                                                                |
|-----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Purpose**                 | Display performance trends (charts) and progress photos                                                                                                                                                                |
| **ViewModel**               | `@StateObject var viewModel: ProgressViewModel`                                                                                                                                                                        |
| **@Published State**        | `viewModel.exerciseTrends`, `viewModel.photosByAngle`, `viewModel.compareSelection`, `viewModel.photoMetrics`, `viewModel.error`                                                                                      |
| **UI Elements – Stats Tab** | • `Picker` for exercise selection  <br>• Toggle buttons for metrics (weight, volume)  <br>• `Chart` view showing `viewModel.trendChartData`                                                                              |
| **UI Elements – Photos Tab**| • Grid of `ProgressPhoto` thumbnails grouped by angle  <br>• Tap to add/delete  <br>• Compare sheet showing two photos side-by-side with weight/body-fat metrics                                                       |
| **Actions/Intents**         | `.selectExercise`, `.toggleMetric`, `.addPhoto`, `.deletePhoto`, `.selectForCompare`                                                                                                                                    |
| **Layout**                  | `TabView` with “Stats” and “Photos” tabs; each uses `ScrollView`                                                                                                                                                        |
| **Styling**                 | Minimalist cards around charts, use `.chartStyle(DefaultChartStyle())`, photo thumbnails with rounded corners                                                                                                           |
| **Evaluation**              | • Builds  <br>• Charts render correct data  <br>• Photo grid loads  <br>• Compare sheet calculates metrics                                                                                                              |

---

## 6. SettingsView

| Section             | Details                                                                                                                                                  |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Purpose**         | App configuration: HealthKit access, photo permissions, iCloud backup/restore                                                                             |
| **ViewModel**       | `@StateObject var viewModel: SettingsViewModel`                                                                                                           |
| **@Published State**| `viewModel.isHealthKitEnabled`, `viewModel.isPhotoAccessGranted`, `viewModel.lastBackupDate`, `viewModel.error`                                           |
| **UI Elements**     | • Toggles for HealthKit & Photos  <br>• “Backup Now” / “Restore” buttons  <br>• Last backup date display                                                    |
| **Actions/Intents** | `.requestHealthKitAccess`, `.togglePhotoAccess`, `.performBackup`, `.performRestore`                                                                     |
| **Layout**          | Form inside `NavigationStack`, grouped sections                                                                                                           |
| **Styling**         | Use `Form` rows, footers for notes, disable backup button on low battery (show disabled state)                                                            |
| **Evaluation**      | • Builds  <br>• Toggles reflect state  <br>• Buttons call correct intents  <br>• Alerts appear on error                                                     |