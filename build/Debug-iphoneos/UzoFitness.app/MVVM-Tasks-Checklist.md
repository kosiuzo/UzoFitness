Here’s a production-oriented task list (parent tasks ➜ sub-tasks) you can drop straight into a `tasks-uzofitness.md` checklist in your repo. It follows the MVVM-first flow you outlined, folds in minimalist-UI guidance, and injects explicit test/CI gates so you stay debt-free as UzoFitness scales.

---

## Relevant Files (initial pass)

* `UzoFitnessApp.swift` – App entry point, global environment injection.
* `PersistenceController.swift` – SwiftData stack (in-memory toggle for tests).
* `Models/`

  * `Workout.swift`, `Exercise.swift`, `WorkoutExercise.swift`, etc. – Core data models.
  * `Models/__tests__/` – Unit tests for validations & computed props.
* `Services/HealthKitManager.swift` – All HealthKit read/write logic.

  * `Services/__tests__/HealthKitManagerTests.swift`
* `Services/PhotoService.swift` – Progress-photo capture & caching helper.

  * `Services/__tests__/PhotoServiceTests.swift`
* `ViewModels/LoggingViewModel.swift`, `ProgressPhotoViewModel.swift`, etc.

  * `ViewModels/__tests__/LoggingViewModelTests.swift`
* `Views/` – Feature screens & reusable components; no logic.
* `.github/workflows/ci.yml` – CI lane: `xcodebuild test && swiftlint`.
* `Docs/minimalist-ios-guide.md` – Design-system reference (link the uploaded file).

---

## Tasks

* [x] **0.0 Foundation Setup**

  * [x] 0.1 Create `UzoFitness` Xcode project (App template, SwiftUI, iOS 17+).
  * [x] 0.2 Add capabilities: HealthKit, Photos, iCloud KV (optional).
  * [x] 0.3 Implement `PersistenceController` w/ versioned `SwiftData` schema.
  * [x] 0.4 Scaffold folder structure (`Models/`, `ViewModels/`, …) and empty test targets.
  * [x] 0.5 Commit CI workflow (`xcodebuild build && test` on push).
  * [x] 0.6 **Gate:** Run `xcodebuild test` → green before moving on.

* [ ] **1.0 Models & Services**

  * [x] 1.1 Define core data models (`Workout`, `Exercise`, `WorkoutExercise`, `WorkoutSession`, `ProgressPhoto`).
  * [x] 1.2 Embed validation (e.g. `sets > 0`, `reps ≥ 1`, weight non-negative) via computed properties / `@Model` lifecycle hooks.
  * [x] 1.3 Build `HealthKitManager` (authorize, read body-mass, write workout samples).
  * [x] 1.4 Build `PhotoService` (image picker, file cache path, SwiftData link).
  * [x] 1.5 Seed `PreviewSampleData` helper for SwiftUI previews.
  * [x] 1.6 **Tests:**
    \- 1.6.1 `WorkoutExerciseTests` – invalid reps throws assertion.
    \- 1.6.2 `HealthKitManagerTests` – mock HK store read/write.
    \- 1.6.3 `PhotoServiceTests` – temp-directory save & load.
  * [x] 1.7 **Gate:** All model/service tests pass.

* [ ] **2.0 ViewModels (Business Logic)**

  * [ ] 2.1 `LoggingViewModel`
    \- 2.1.1 Inject `HealthKitManager`, `PersistenceController`.
    \- 2.1.2 Expose `@Published` `currentSet`, `timerState`, `isCompleted`.
  * [ ] 2.2 `ProgressPhotoViewModel`
    \- 2.2.1 Fetch photo entries, create/delete operations.
    \- 2.2.2 Thumbnail generation off-main thread.
  * [ ] 2.3 Dependency-inject mocks for previews & tests.
  * [ ] 2.4 **Tests:**
    \- 2.4.1 `LoggingViewModelTests` – `markSetCompleted` updates SwiftData.
    \- 2.4.2 `ProgressPhotoViewModelTests` – deletes cascade correctly.
  * [ ] 2.5 **Gate:** ViewModel test suite green.

* [ ] **3.0 Views & Navigation**

  * [ ] 3.1 Build tab-based shell (`TabView`: “Today”, “Workouts”, “Progress”, “Settings”).
  * [ ] 3.2 Screen: Today Dashboard – shows next workout, body-weight quick-log.
  * [ ] 3.3 Screen: Workout Logging – list exercises, “Complete Set” CTA, minimalist counters.
  * [ ] 3.4 Screen: Progress Photos – grid, add photo button, long-press context menu.
  * [ ] 3.5 Apply minimalist-IOS guide: neutral palette, SF fonts, generous spacing.
  * [ ] 3.6 Wire navigation links & sheet presentations (no business logic in Views).
  * [ ] 3.7 **Optional UI tests:** critical flows only (e.g. finish-workout button).

* [ ] **4.0 QA & Tech-Debt Checks**

  * [ ] 4.1 Static analysis: enable SwiftLint & SwiftFormat.
  * [ ] 4.2 Performance pass: run Instruments → Leaks on workout flow, address leaks < 5 KB/s sustained.
  * [ ] 4.3 Accessibility audit (VoiceOver labels, Dynamic Type).
  * [ ] 4.4 Update README with build/test commands & architecture diagram.

* [ ] **5.0 Release Readiness**

  * [ ] 5.1 Build archive for TestFlight, verify HealthKit entitlements in `.entitlements`.
  * [ ] 5.2 Fill App Store privacy manifest & NutritionLabel (Health data usage).
  * [ ] 5.3 Internal TestFlight distributed to pilot users w/ feedback form.
  * [ ] 5.4 Tag `v0.1.0` in Git; draft release notes.

---

**Next step:** work through 0.0 → 0.6, run CI, and you’re off to the races. Every parent task has an explicit green-test gate so you never advance with failing logic—future-you will thank present-you!
