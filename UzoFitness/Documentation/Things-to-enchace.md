Here is the complete, detailed markdown-formatted task list from your PRD:

## Relevant Files

* `Views/Screens/WorkoutCreationView.swift`
* `Views/Screens/HistoryView.swift`
* `Views/Screens/ProgressView.swift`
* `Views/Components/CalendarComponent.swift`
* `Views/Components/WorkoutDetailsComponent.swift`
* `Views/Components/ImageComparisonComponent.swift`
* `ViewModels/WorkoutCreationViewModel.swift`
* `ViewModels/HistoryViewModel.swift`
* `ViewModels/ProgressViewModel.swift`
* `Models/ProgressPhoto.swift`
* `Utilities/HealthKitIntegration.swift`
* `Tests/WorkoutCreationTests.swift`
* `Tests/HistoryViewTests.swift`
* `Tests/ProgressViewTests.swift`

## Detailed Task List

### 1.0 Streamline Workout Creation Flow

* [x] **1.1** Modify navigation to immediately open weekly schedule and workout details screen after tapping "Create Workout".
* [x] **1.2** Remove the "Library" title from the workout creation screen.
* [x] **1.3** Update form validation to require only "Workout Name" as mandatory.
* [x] **1.4** Write/update unit tests for streamlined workout creation.

### 2.0 Enhance Workout History Interface

* [x] **2.1** Replace bottom sheet with a fixed lower-half detail view upon selecting a calendar date.
* [x] **2.2** Remove the "History" title from the top.
* [x] **2.3** Shift calendar UI component upward to allocate sufficient space for workout details below.
* [x] **2.4** Adjust calendar sizing and spacing to ensure clear visibility of workout details and calendar simultaneously.

### 3.0 Optimize Data Consistency and Filtering

* [x] **3.1** Review existing data filtering logic for unnecessary or unintended filtering of exercises.
* [x] **3.2** Simplify the filtering logic to ensure all logged exercises, including incomplete sets, are accurately displayed.
* [x] **3.3** Verify comprehensive display of logged workout details without data omissions.

### 4.0 Improve Progress View

* [x] **4.1** Remove the "Progress" title from the top of the Progress View.
* [x] **4.2** Display date, weight, and body fat percentage beneath each progress thumbnail, fetching data directly from HealthKit.
* [x] **4.3** Handle cases where HealthKit data is unavailable without placeholder text (leave fields empty).
* [x] **4.4** Remove overlays showing weight from progress images.

### 5.0 Implement Seamless Image Comparison

* [x] **5.1** Enable full-screen viewing when tapping on progress images.
* [x] **5.2** Implement horizontal swipe gestures for comparing progress images.
* [x] **5.3** Ensure image swiping transitions are smooth and minimalistic in line with existing design standards.

### 6.0 Enable Angle Group Swiping

* [x] **6.1** Group progress images by photo angle (front, side, back).
* [x] **6.2** Implement horizontal swiping to seamlessly navigate through images within each angle group.
* [x] **6.3** Validate swiping transitions to ensure they are smooth and intuitive.

## Notes

* Follow minimalist design guidelines strictly, ensuring every UI change reduces complexity and visual noise.
* Consistently run unit tests using:

  ```
  xcodebuild -scheme MyFitnessApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
  ```
* Thoroughly test functionality via the Xcode simulator and TestFlight releases.
