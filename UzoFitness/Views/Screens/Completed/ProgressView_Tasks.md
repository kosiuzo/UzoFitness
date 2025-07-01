## Relevant Files

- `Views/Screens/Progress/ProgressView.swift` – Main screen with segmented control and conditional views for stats or pictures
- `ViewModels/ProgressViewModel.swift` – Holds business logic and bindings for selected range, metrics, photos, and health data
- `Components/Charts/MetricLineChart.swift` – Reusable chart component for plotting metrics
- `Components/Photos/ProgressPhotoGrid.swift` – Displays photo thumbnails by date and angle
- `Components/Photos/PhotoCompareView.swift` – Full-screen photo comparison UI
- `Models/Progress/PerformedExercise.swift` – Source of exercise data for stats
- `Models/Progress/ProgressPhoto.swift` – Progress photo model with angle/date/asset info
- `Services/HealthKitService.swift` – Fetches HealthKit weight/body-fat samples
- `Services/PhotoPermissionService.swift` – Manages photo access permissions
- `Tests/ProgressViewModel.test.swift` – Unit tests for data bindings and permissions logic
- `Tests/ProgressView.test.swift` – UI tests for interaction flows and layout

## Tasks

- [x] 1.0 Implement Segmented Picker and Date Range Filter
  - [x] 1.1 Add a segmented picker for "Stats" and "Pictures"
  - [x] 1.2 Create a date range picker component with presets (6 months, 1 year, custom)
  - [x] 1.3 Wire both controls to `selectedDateRange` and `selectedSegment` in `ProgressViewModel`
  - [x] 1.4 Trigger view updates on date range or segment change

- [x] 2.0 Build Stats Section with Line Charts
  - [x] 2.1 Create `MetricLineChart` that accepts `[Date: Double]` for a single metric
  - [x] 2.2 Build metric toggle controls (checkbox or inline list) to show/hide each chart
  - [x] 2.3 Integrate pinch-to-zoom and pan (optional, only if charting lib supports it easily)
  - [x] 2.4 Fetch `PerformedExercise` data grouped by date and metric from SwiftData
  - [x] 2.5 Display line charts for selected metrics within date range

- [x] 3.0 Build Pictures Section with Compare Mode
  - [x] 3.1 Create `ProgressPhotoGrid` that shows grouped thumbnails (front, side, back)
  - [x] 3.2 Tap opens `PhotoCompareView` to select second date/angle for comparison
  - [x] 3.3 Fetch HealthKit weight/body-fat for each photo date if permission granted
  - [x] 3.4 Allow manual entry if no data is available
  - [x] 3.5 Bind `progressPhotos` and `healthData` to view model

- [x] 4.0 Handle HealthKit and Photo Permissions
  - [x] 4.1 In `HealthKitService`, detect and request authorization for weight/body-fat types
  - [x] 4.2 In `PhotoPermissionService`, check for photo library access and request if needed
  - [x] 4.3 If HealthKit access denied, show inline warning in UI and disable autofill
  - [x] 4.4 If Photo access denied, hide photo section and show Settings prompt

- [x] 5.0 Connect View to ProgressViewModel
  - [x] 5.1 Expose all required published properties: `selectedDateRange`, `exerciseMetrics`, `progressPhotos`, `healthData`
  - [x] 5.2 Add computed properties or async loaders for lazy data fetching
  - [x] 5.3 Ensure bindings between UI and ViewModel are testable and reactive
  - [x] 5.4 Cache images and data efficiently for smooth scrolling and interactions

### Notes

- Prioritize test coverage for ViewModel logic including date filtering and permission fallback.
- Charts and photos should be lazily loaded for performance.
- Follow the iOS Minimalist Design Guide for layout, spacing, and interaction fidelity.