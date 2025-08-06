# Workout Session Improvements - Requirements Document

## Overview
This document outlines the requirements for fixing critical issues identified in the UzoFitness workout session functionality. These improvements will enhance the user experience by adding essential timing features and fixing data persistence issues.

## Issues Identified

### 1. Missing Workout Stopwatch
**Problem**: No visual indication of workout duration when session starts
**Impact**: Users cannot track how long their workout is taking
**Priority**: High

### 2. Missing Rest Timer with Notifications
**Problem**: No dedicated rest timer button with haptic feedback and notifications
**Impact**: Users cannot easily time rest periods between sets
**Priority**: High

### 3. Bulk Edit Sets Default Values Issue
**Problem**: "Edit all sets" always defaults to 10 reps and 0 weight, ignoring the values from the first completed set
**Impact**: Users must manually re-enter values in the bulk edit dialog even after completing sets with different values
**Priority**: Medium

### 4. Workout Session Default Reps Issue
**Problem**: Starting workout session defaults reps to 10 even when different values were planned in the exercise template
**Impact**: Users lose their planned workout parameters and the app doesn't respect the exercise template values
**Priority**: Medium

## Detailed Requirements

### 1. Workout Stopwatch Implementation

#### 1.1 UI Requirements
- **Location**: Top of WorkoutSessionView, below navigation bar
- **Display**: 
  - Show elapsed time in MM:SS format
  - Use large, prominent font (title2 or larger)
  - Center-aligned in a dedicated header section
  - Background: subtle container with rounded corners
- **State Management**:
  - Start automatically when workout session begins
  - Continue running until session is completed or cancelled
  - Persist across app backgrounding/foregrounding

#### 1.2 Technical Requirements
- **Timer Implementation**:
  - Use `Timer.scheduledTimer` with 1-second intervals
  - Store start time in `LoggingViewModel.sessionStartTime`
  - Calculate elapsed time: `Date().timeIntervalSince(sessionStartTime)`
- **State Persistence**:
  - Save start time to `WorkoutSession` model
  - Handle app lifecycle events (background/foreground)
  - Resume timer correctly when app returns to foreground

#### 1.3 Code Changes Required
```swift
// In LoggingViewModel
@Published var workoutElapsedTime: TimeInterval = 0
private var workoutTimer: Timer?

// In WorkoutSessionView
struct WorkoutStopwatchView: View {
    let elapsedTime: TimeInterval
    
    var body: some View {
        VStack {
            Text("Workout Time")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatTime(elapsedTime))
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

### 2. Rest Timer with Notifications

#### 2.1 UI Requirements
- **Location**: Bottom of WorkoutSessionView, above "Complete Workout" button
- **Design**: 
  - Large, prominent button with timer icon
  - Show current rest timer if active
  - Display time remaining in MM:SS format
  - Use different colors for active/inactive states
- **Interaction**:
  - Tap to start rest timer
  - Long press for custom duration selection
  - Swipe to cancel active timer

#### 2.2 Notification Requirements
- **Local Notifications**:
  - Send notification when rest timer completes
  - Include haptic feedback (medium impact)
  - Play sound (system default)
  - Show notification even if app is backgrounded
- **Haptic Feedback**:
  - Light impact when timer starts
  - Medium impact when timer completes
  - Heavy impact for custom duration selection

#### 2.3 Technical Requirements
- **Timer Management**:
  - Use existing `restTimer` in `LoggingViewModel`
  - Add global rest timer state to track active timer
  - Handle multiple concurrent timers properly
- **Notification Integration**:
  - Request notification permissions on first use
  - Schedule local notifications for rest completion
  - Handle notification taps to return to app

#### 2.4 Code Changes Required
```swift
// In LoggingViewModel
@Published var globalRestTimer: TimeInterval?
@Published var globalRestTimerActive: Bool = false

// In WorkoutSessionView
struct RestTimerButton: View {
    @ObservedObject var viewModel: LoggingViewModel
    @State private var showingCustomDuration = false
    
    var body: some View {
        Button {
            if viewModel.globalRestTimerActive {
                viewModel.cancelGlobalRest()
            } else {
                showingCustomDuration = true
            }
        } label: {
            HStack {
                Image(systemName: viewModel.globalRestTimerActive ? "timer" : "timer.circle")
                Text(viewModel.globalRestTimerActive ? 
                     formatTime(viewModel.globalRestTimer ?? 0) : 
                     "Rest Timer")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.globalRestTimerActive ? Color.orange : Color.blue)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingCustomDuration) {
            RestTimerDurationPicker(viewModel: viewModel)
        }
    }
}
```

### 3. Fix Bulk Edit Sets Default Values

#### 3.1 Problem Analysis
Current implementation in `LoggingExerciseRowView.swift`:
```swift
Button("Edit All Sets") {
    bulkReps = "\(exercise.plannedReps)"  // Always uses planned reps
    bulkWeight = "\(Int(exercise.plannedWeight ?? 0))"  // Always uses planned weight
    showingBulkEdit = true
}
```

#### 3.2 Solution Requirements
- **Default Values**: Use first completed set's values for the bulk edit dialog
- **Fallback Logic**: 
  1. Use first completed set's reps/weight if available
  2. Use last completed set's values as fallback
  3. Use planned values only if no completed sets exist
- **Data Validation**: Ensure values are reasonable (reps > 0, weight >= 0)
- **Dialog Context**: The bulk edit dialog should reflect the actual values from completed sets, not the planned template values

#### 3.3 Code Changes Required
```swift
// In LoggingExerciseRowView
private func getDefaultBulkEditValues() -> (reps: String, weight: String) {
    let completedSets = exercise.sets.filter { $0.isCompleted }
    
    if let firstCompletedSet = completedSets.first {
        return ("\(firstCompletedSet.reps)", "\(Int(firstCompletedSet.weight))")
    } else if let lastCompletedSet = completedSets.last {
        return ("\(lastCompletedSet.reps)", "\(Int(lastCompletedSet.weight))")
    } else {
        return ("\(exercise.plannedReps)", "\(Int(exercise.plannedWeight ?? 0))")
    }
}

// Update the button action
Button("Edit All Sets") {
    let defaults = getDefaultBulkEditValues()
    bulkReps = defaults.reps
    bulkWeight = defaults.weight
    showingBulkEdit = true
}
```

### 4. Fix Workout Session Default Reps

#### 4.1 Problem Analysis
Current implementation in `SessionExercise.swift`:
```swift
init(..., autoPopulateFromLastSession: Bool = true) {
    // Auto-populate from exercise's cached values if requested
    if autoPopulateFromLastSession {
        let suggestedValues = exercise.suggestedStartingValues
        self.plannedReps = plannedReps ?? suggestedValues.reps ?? 10 // Default to 10
        self.plannedWeight = plannedWeight ?? suggestedValues.weight
    } else {
        self.plannedReps = plannedReps ?? 10  // Always defaults to 10
        self.plannedWeight = plannedWeight
    }
}
```

#### 4.2 Solution Requirements
- **Respect Planned Values**: Use exercise template values as primary source for session creation
- **Auto-population Logic**: Only use cached values when template values are not specified
- **Priority Order**:
  1. Use exercise template reps/weight if specified (this should be the primary source)
  2. Use cached values from previous sessions as fallback
  3. Use system defaults (10 reps, 0 weight) only as last resort
- **Maintain Caching Logic**: Keep the existing logic that provides last completed set values for individual exercises, but ensure template values are respected during session creation

#### 4.3 Code Changes Required
```swift
// In SessionExercise.swift
init(..., autoPopulateFromLastSession: Bool = true) {
    // ... existing initialization ...
    
    if autoPopulateFromLastSession {
        let suggestedValues = exercise.suggestedStartingValues
        
        // Prioritize template values over cached values for session creation
        self.plannedReps = plannedReps ?? exerciseTemplate?.reps ?? suggestedValues.reps ?? 10
        self.plannedWeight = plannedWeight ?? exerciseTemplate?.weight ?? suggestedValues.weight
        
        // Keep the caching logic intact for individual exercise suggestions
        self.previousTotalVolume = suggestedValues.totalVolume
        self.previousSessionDate = exercise.lastUsedDate
    } else {
        // Use template values or defaults
        self.plannedReps = plannedReps ?? exerciseTemplate?.reps ?? 10
        self.plannedWeight = plannedWeight ?? exerciseTemplate?.weight
        self.previousTotalVolume = nil
        self.previousSessionDate = nil
    }
}
```

## Implementation Priority

### Phase 1 (High Priority)
1. **Workout Stopwatch** - Essential for user experience
2. **Rest Timer with Notifications** - Critical for workout flow

### Phase 2 (Medium Priority)
3. **Fix Bulk Edit Sets** - Improve data entry efficiency
4. **Fix Session Default Reps** - Ensure planned workouts are respected

## Testing Requirements

### Unit Tests
- Timer functionality and state management
- Notification scheduling and delivery
- Default value calculation logic
- Data persistence across app lifecycle

### Integration Tests
- Workout session flow with timer integration
- Rest timer with notification delivery
- Bulk edit functionality with correct defaults
- Session creation with proper value inheritance

### UI Tests
- Timer display and interaction
- Rest timer button functionality
- Bulk edit dialog with correct defaults
- Session creation workflow

## Success Criteria

### Workout Stopwatch
- [ ] Timer displays immediately when session starts
- [ ] Timer continues running during app backgrounding
- [ ] Timer persists across app restarts
- [ ] Timer stops when session is completed

### Rest Timer
- [ ] Rest timer button is prominently displayed
- [ ] Timer starts with haptic feedback
- [ ] Notification is delivered when timer completes
- [ ] Timer can be cancelled with swipe gesture
- [ ] Custom duration selection works correctly

### Bulk Edit Fix
- [ ] "Edit all sets" dialog uses first completed set's values as defaults
- [ ] Fallback to last completed set if no first set
- [ ] Fallback to planned values only if no completed sets
- [ ] Values are properly validated before saving
- [ ] Bulk edit dialog reflects actual completed set values, not template values

### Session Defaults Fix
- [ ] Session exercises use template values when available during session creation
- [ ] Auto-population only occurs when template values are missing
- [ ] Cached values are used as secondary fallback
- [ ] System defaults are only used as last resort
- [ ] Individual exercise suggestions still use last completed set logic

## Technical Notes

### Dependencies
- `UserNotifications` framework for local notifications
- `UIKit` for haptic feedback
- `Combine` for timer management
- `SwiftData` for persistence

### Performance Considerations
- Timer updates should be efficient (1-second intervals)
- Notification scheduling should be lightweight
- State persistence should not block UI updates

### Accessibility
- Timer displays should support VoiceOver
- Rest timer button should have appropriate accessibility labels
- Haptic feedback should respect system accessibility settings

## Future Enhancements

### Potential Additions
- **Workout Pacing**: Show target vs actual time
- **Rest Timer Presets**: Quick-select common rest durations
- **Workout Splits**: Track time per exercise
- **Progress Tracking**: Compare session times over time

### Advanced Features
- **Smart Rest Timer**: Auto-suggest rest duration based on exercise intensity
- **Workout Templates**: Save and reuse timer configurations
- **Social Features**: Share workout times with friends
- **Analytics**: Detailed workout timing analytics

---

*This document serves as the primary reference for implementing workout session improvements. All changes should follow the established MVVM architecture and coding standards outlined in the project guidelines.* 