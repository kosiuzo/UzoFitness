# PRD: Progress View

## 1. Introduction / Overview

The **Progress View** provides users with insights into their performance and visual progress over time. It features a segmented control with two sections: **Stats** for charting exercise metrics (weight, sets, reps, total volume) and **Pictures** for tracking progress photos by angle. A global date filter lets users choose standard ranges (e.g. 6 months, 1 year) or custom spans. It adheres to the iOS Minimalist Design Philosophy for a clean, intuitive experience.

## 2. Goals

1. Display trending charts for exercise performance metrics (weight, reps, sets, total volume) over a selectable time range.
2. Show progress photos (front, side, back) grouped by date, with compare functionality.
3. Auto-fetch weight and body‑fat from HealthKit for each photo date, falling back to manual entry if unavailable.
4. Surface a global date picker to filter both stats and pictures across the same time span.
5. Ensure the view gracefully degrades if required permissions aren’t granted.

## 3. User Stories

* **Performance Charts**

  * *As a user, I want to see how my weight, reps, sets, and total volume trend over time so I can measure progress.*
* **Date Filtering**

  * *As a user, I want to view data from the past year, past six months, or a custom range so I can analyze different periods.*
* **Progress Photos**

  * *As a user, I want to see my front/side/back photos grouped by date so I can visually track changes.*
* **Photo Comparison**

  * *As a user, I want to compare two photos from different dates side by side so I can see my transformation.*
* **HealthKit Data**

  * *As a user, I want the app to automatically show my weight and body‑fat for each photo date from HealthKit, and enter it manually if missing.*
* **Permissions**

  * *As a user, I expect clear behavior if HealthKit or photo permissions are not granted—data sections may be disabled.*

## 4. Functional Requirements

### 4.1 Segmented Control & Date Filter

* Add top **Segmented Picker** with two segments: **Stats** and **Pictures**.
* Below it, place a **Date Range Picker** with presets: Last 6 months, Last 12 months, Custom…
* Changing the date range updates both charts and photo grouping.

### 4.2 Stats Section

* For each metric (Weight, Reps, Sets, Total Volume), render a line chart using performed exercise data.
* X‑axis: date; Y‑axis: metric value.
* Allow toggling individual metrics on/off in a legend or checklist.
* Support pinch‑to‑zoom and pan for detailed exploration (optional).

### 4.3 Pictures Section

* Display a scrollable list of dates within the filter, each with up to three thumbnails (front, side, back).
* Tapping a thumbnail opens a **compare mode** where users select a second date/angle and see images side by side.
* Below each date’s group, show two labels:

  * **Weight:** auto-filled from HealthKit or blank for manual entry.
  * **Body‑fat:** auto-filled from HealthKit or blank for manual entry.

### 4.4 Permissions Handling

* If HealthKit permission is denied, disable auto‑fetch and show a warning icon with “Grant HealthKit in Settings.”
* If Photo permission is denied, show “Grant Photos access in Settings” and hide thumbnails.

## 5. Non‑Goals

* In‑chart editing of data points—charts are read‑only.
* Advanced statistical analysis beyond trending lines.
* Editing or deleting progress photos (handled elsewhere).

## 6. Design Considerations

* **Minimalist Layout:** generous whitespace, monochrome charts with a single accent per metric.
* **Typography:** system fonts; segment labels bold.
* **Interactions:** smooth chart animations; clear haptic on segment change.

## 7. Technical Considerations

* **ViewModel:** bind `ProgressViewModel` exposing:

  * `selectedDateRange: DateInterval`
  * `exerciseMetrics: [MetricType: [Date: Double]]`
  * `availableRanges: [PresetRange]`
  * `progressPhotos: [Date: [Angle: UIImage]]`
  * `healthData: [Date: (weight: Double?, bodyFat: Double?)]`
* **Charting:** use Swift Charts or a lightweight library; lazy load data.
* **Photo Storage:** fetch from SwiftData/Core Data; cache thumbnails.

## 8. Success Metrics

* **Engagement:** ≥50% of active users view Progress View weekly.
* **Performance:** Charts render <200 ms; photo grid loads <300 ms.
* **Reliability:** 0 crashes due to missing permissions.
* **Usability:** 90% of users can switch segments and ranges without confusion in testing.

## 9. Open Questions

* Should we allow users to annotate charts with personal notes?
* Do we need presets beyond 6/12 months (e.g. 3 months)?
* How many photo angles should we support beyond front/side/back?

---

*End of Document*
