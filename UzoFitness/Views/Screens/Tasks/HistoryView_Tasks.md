# History View Implementation Tasks

## 1. Screen & Layout  
- [ ] Create `HistoryView` (SwiftUI or UIKit)  
  - [ ] Add a monthly calendar grid beneath the streak label  
  - [ ] Implement a persistent bottom sheet view directly under the calendar  

## 2. Calendar Display  
- [ ] Preload calendar data at app launch and cache in memory
- [ ] Render calendar for the current month  
  - [ ] Highlight days with logged workouts using a subtle dot or underline  
  - [ ] Disable navigation past available history range  
- [ ] Add controls to navigate to previous/next month  

## 4. Plan Progress Tracking  
- [ ] In `HistoryViewModel`, detect when a `PerformedWorkout` belongs to a multi-week plan  
- [ ] Compute `currentWeek = floor((date – planStartDate)/7) + 1`, capped at total plan weeks  
- [ ] Expose `planWeekStatus` (currentWeek, totalWeeks) for the selected date  
- [ ] In the drill-down panel, display “Week Y of Z” for plan entries  

## 5. Workout Summary Cards Under Calendar
- [ ] Render a list of workout summary cards under the calendar for the selected day
- [ ] Each card shows:
  - [ ] Workout name
  - [ ] Total volume (Σ sets × reps × weight)
- [ ] Expandable section per workout card to reveal:
  - [ ] Each performed exercise:
    - [ ] Exercise name
    - [ ] Reps, sets, and weight (displayed compactly)

## 6. Volume Calculations  
- [ ] In `HistoryViewModel`, check if you have the necessary columns for Total Volume to decide if you need to implement  
- [ ] Ensure calculations are efficient and cached where appropriate  

## 7. Template Usage Count (Stretch)  
- [ ] In `HistoryViewModel`, count persisted `PerformedWorkout` entries per template ID  
- [ ] Expose `templateUsageCounts: [TemplateID: Int]`  
- [ ] In drill-down panel (or hover), display “Logged N times” badge for each template  

## 8. Persistence & Data Flow  
- [ ] Load calendar-relevant history data during app launch and persist in memory for fast access
- [ ] Fetch history from SwiftData/Core Data `PerformedWorkout` and `PerformedExercise` entities  
- [ ] Cache adjacent months’ data in memory for smooth scrolling  
- [ ] Invalidate cache when new workouts are logged  

## 9. Error Handling & Empty States  
- [ ] If no workouts exist for the displayed month, show “No workouts logged yet” placeholder  
- [ ] On data-fetch failure, show inline error message with a **Retry** button  
- [ ] Handle edge cases: corrupted entries, missing relationships  

## 10. Testing  
- [ ] **Unit tests** for `HistoryViewModel`:  
  - [ ] `streakCount` calculation for various date sequences  
  - [ ] Volume computations (exercise and workout)  
  - [ ] `planWeekStatus` logic for plan and non-plan workouts  
  - [ ] Template usage count aggregation  
- [ ] **UI tests** (optional but recommended):  
  - [ ] Verify calendar dots appear on correct dates  
  - [ ] Tap a date and assert drill-down contents match persisted data  
  - [ ] Assert streak label updates after a new workout is added  
  - [ ] Simulate fetch failures and empty-state display  

## 11. QA & Manual Validation  
- [ ] On device, verify calendar navigation and marking accuracy  
- [ ] Confirm streak count matches consecutive workout days  
- [ ] Tap several dates to validate drill-down details, including plan progress labels  
- [ ] Test error and empty states by clearing history or mocking failures  
- [ ] Gather feedback on layout clarity and minimalist styling  