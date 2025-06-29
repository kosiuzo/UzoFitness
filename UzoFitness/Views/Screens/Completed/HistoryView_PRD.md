# PRD: History View

## 1. Introduction / Overview

The **History View** provides users a bird’s-eye on their workout consistency and performance over time. It displays a calendar with marked workout days, showcases the current streak, and lets users drill into any date to view completed workouts, exercise volumes, and weights. This screen is strictly for viewing history and does not allow editing—keeping the interface clean and focused. It adheres to our iOS Minimalist Design Philosophy for clarity and simplicity.

## 2. Goals

1. Surface a calendar with visual indicators (dots or marks) on days the user logged workouts.
2. Display the user’s current workout streak prominently.
3. Allow tapping a marked date to view:

   * Workouts completed on that date.
   * Total volume per workout (sum of sets × reps × weight).
   * Total volume per exercise within each workout.
   * Weights used for each exercise that day.
4. Show **workout plan progress**: for plans spanning multiple weeks, display how many weeks have been completed based on the plan’s start date and duration.
5. (Stretch) Display **template usage count**: number of times any template has been logged.
6. Inspire users by showing progression in consistency and volume.

## 3. User Stories

* **Calendar Overview**

  * *As a fitness enthusiast, I want to see which days I worked out this month so I can track my consistency.*
* **Streak Tracking**

  * *As a user, I want to see my current streak of consecutive workout days to stay motivated.*
* **Drill-Down Details**

  * *As a user, I want to tap a date and see all workouts and exercise volumes so I can review my performance.*
* **Volume Insight**

  * *As a user, I want to see total volume per workout and per exercise so I know if I’m improving.*
* **Plan Progress Tracking**

  * *As a user following an 8‑week workout plan, I want to know how many weeks I’ve completed so I can gauge my progress toward plan completion.*
* **Template Usage Count (Stretch)**

  * *As a user, I want to see how many times I’ve logged a given template so I understand my frequency with each routine.*

## 4. Functional Requirements

### 4.1 Calendar Display

* Show a standard monthly calendar grid.
* Mark days with logged workouts using a subtle dot or underline.
* Disable navigation beyond available history range.

### 4.2 Streak Indicator

* Display “🔥 Streak: X days” above the calendar.
* Update dynamically as workouts are logged.

### 4.3 Plan Progress Tracking

* If the selected date’s workout is part of a multi‑week plan with a configured duration:

  * Calculate completed weeks: `floor((selectedDate – planStartDate) / 7) + 1`, capped at total plan weeks.
  * Display “Week Y of Z” on the drill-down detail for that plan entry.
* If a workout is logged outside of a plan template, omit this display.

### 4.4 Date Drill-Down

* On tapping a marked day:

  * Present a list of workouts done that day.
  * For each workout, show:

    * Workout name.
    * Total volume (Σ sets × reps × weight).
    * **If part of a plan:** display “Week Y of Z”.
  * Under each workout, list exercises with:

    * Exercise name.
    * Total volume.
    * Weight(s) used.

### 4.5 Volume Calculations

* Compute total volume per workout by summing all exercise volumes.
* Compute total volume per exercise by summing sets × reps × weight logged that day.

### 4.6 Template Usage Count (Stretch)

* On drill-down or hover, show badge “Logged N times” for each template.
* Calculate by counting persisted `PerformedWorkout` entries per template ID.

### 4.7 Persistence & Data Flow

* Read history data from persisted `PerformedWorkout` and `PerformedExercise` entities.
* Cache recent months in memory to ensure smooth scrolling.

### 4.8 Error Handling

* If no history exists for the current month, show “No workouts logged yet” message.
* If data fetch fails, display an inline error with “Retry” action.

## 5. Non-Goals

* Editing or logging workouts (handled in Logging View).
* Advanced analytics or charts (a dedicated Progress View will cover that).
* Social sharing or export features.

## 6. Design Considerations

* **Minimalist Layout:** generous whitespace, muted calendar grid, single accent color for dots.
* **Clear Hierarchy:**

  * Streak at top in bold.
  * Calendar occupies the majority of screen real estate.
  * Drill-down list in a simple modal or bottom sheet.
* **Consistent Typography:** system fonts, size hierarchy for headers vs. detail text.

## 7. Technical Considerations

* Use SwiftUI’s `CalendarView` or a lightweight custom component for calendar rendering.
* Bind to `HistoryViewModel` exposing:

  * `currentMonthData: [Date: WorkoutSummary]`
  * `streakCount: Int`
  * `selectedDateDetails: [PerformedWorkout]`
  * `planWeekStatus: (currentWeek: Int, totalWeeks: Int)?`
  * `templateUsageCounts: [TemplateID: Int]` (stretch)
* Prefetch adjacent months to avoid loading delays.

## 8. Success Metrics

* **Engagement:** ≥80% of active users open History View at least once per week.
* **Performance:** Calendar renders in <100 ms, drill-down loads in <200 ms.
* **Reliability:** 0 errors in fetching persisted history data in QA.
* **Usability:** Users can interpret streak, plan progress, and volume data correctly in usability testing.

## 9. Open Questions

* Should the streak reset visualization animate when broken?
* Do we want to support week-view or year-view zoom levels?
* How far back should history be displayed (e.g., 6 months, 1 year)?
* For the stretch template usage count, should it display on calendar hover or only in drill-down?

---

*End of Document*
