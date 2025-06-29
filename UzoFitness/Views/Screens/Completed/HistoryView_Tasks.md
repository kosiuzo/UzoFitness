# History View Implementation Tasks

## 1. Screen & Layout  
- [x] Create `HistoryView` (SwiftUI or UIKit)  
  - [x] Add a monthly calendar grid beneath the streak label  
  - [x] Implement a persistent bottom sheet view directly under the calendar  

## 2. Calendar Display  
- [x] Preload calendar data at app launch and cache in memory
- [x] Render calendar for the current month  
  - [x] Highlight days with logged workouts using a subtle dot or underline  
  - [x] Disable navigation past available history range  
- [x] Add controls to navigate to previous/next month  

## 4. Plan Progress Tracking  
- [x] In `HistoryViewModel`, detect when a `PerformedWorkout` belongs to a multi-week plan  
- [x] Compute `currentWeek = floor((date – planStartDate)/7) + 1`, capped at total plan weeks  
- [x] Expose `planWeekStatus` (currentWeek, totalWeeks) for the selected date  
- [x] In the drill-down panel, display “Week Y of Z” for plan entries  

## 5. Workout Summary Cards Under Calendar
- [x] Render a list of workout summary cards under the calendar for the selected day
- [x] Each card shows:
  - [x] Workout name
  - [x] Total volume (Σ sets × reps × weight)
- [x] Expandable section per workout card to reveal:
  - [x] Each performed exercise:
    - [x] Exercise name
    - [x] Reps, sets, and weight (displayed compactly)

## 6. Volume Calculations  
- [x] In `HistoryViewModel`, check if you have the necessary columns for Total Volume to decide if you need to implement  
- [x] Ensure calculations are efficient and cached where appropriate  

## 7. Template Usage Count (Stretch)  
- [x] In `HistoryViewModel`, count persisted `PerformedWorkout` entries per template ID  
- [x] Expose `templateUsageCounts: [TemplateID: Int]`  
- [x] In drill-down panel (or hover), display “Logged N times” badge for each template  

## 8. Persistence & Data Flow  
- [x] Load calendar-relevant history data during app launch and persist in memory for fast access
- [x] Fetch history from SwiftData/Core Data `PerformedWorkout` and `PerformedExercise` entities  
- [x] Cache adjacent months' data in memory for smooth scrolling  
- [x] Invalidate cache when new workouts are logged  

## 9. Error Handling & Empty States  
- [x] If no workouts exist for the displayed month, show "No workouts logged yet" placeholder  
- [x] On data-fetch failure, show inline error message with a **Retry** button  
- [x] Handle edge cases: corrupted entries, missing relationships  

## 10. Testing  
- [x] **Unit tests** for `HistoryViewModel`:  
  - [x] `streakCount` calculation for various date sequences  
  - [x] Volume computations (exercise and workout)  
  - [x] `planWeekStatus` logic for plan and non-plan workouts  
  - [x] Template usage count aggregation  
- [x] **UI tests** (optional but recommended):  
  - [x] Verify calendar dots appear on correct dates  
  - [x] Tap a date and assert drill-down contents match persisted data  
  - [x] Assert streak label updates after a new workout is added  
  - [x] Simulate fetch failures and empty-state display  

## 11. QA & Manual Validation  
- [x] On device, verify calendar navigation and marking accuracy  
- [x] Confirm streak count matches consecutive workout days  
- [x] Tap several dates to validate drill-down details, including plan progress labels  
- [x] Test error and empty states by clearing history or mocking failures  
- [x] Gather feedback on layout clarity and minimalist styling  