# Workout Session Improvements - Claude Implementation Guide

## Overview
This guide provides step-by-step implementation instructions for Claude to generate the code needed to fix the four workout session issues in UzoFitness. Each section includes specific file changes, code examples, and implementation order.

## Implementation Order
1. **Workout Stopwatch** (High Priority)
2. **Rest Timer with Notifications** (High Priority)  
3. **Fix Bulk Edit Sets Default Values** (Medium Priority)
4. **Fix Workout Session Default Reps** (Medium Priority)

---

## 1. Workout Stopwatch Implementation

### Step 1: Update LoggingViewModel
**File**: `UzoFitness/ViewModels/LoggingViewModel.swift`

**Add these properties after the existing @Published variables:**
```swift
@Published var workoutElapsedTime: TimeInterval = 0
private var workoutTimer: Timer?
```

**Add this method after the existing timer methods:**
```swift
private func startWorkoutTimer() {
    AppLogger.info("[LoggingViewModel.startWorkoutTimer] Starting workout timer", category: "LoggingViewModel")
    
    guard sessionStartTime != nil else {
        AppLogger.error("[LoggingViewModel.startWorkoutTimer] No session start time", category: "LoggingViewModel")
        return
    }
    
    workoutTimer = timerFactory.createTimer(interval: 1.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
            self?.updateWorkoutElapsedTime()
        }
    }
    
    AppLogger.debug("[LoggingViewModel.startWorkoutTimer] Workout timer started", category: "LoggingViewModel")
}

private func updateWorkoutElapsedTime() {
    guard let startTime = sessionStartTime else { return }
    workoutElapsedTime = Date().timeIntervalSince(startTime)
}

private func stopWorkoutTimer() {
    AppLogger.info("[LoggingViewModel.stopWorkoutTimer] Stopping workout timer", category: "LoggingViewModel")
    workoutTimer?.invalidate()
    workoutTimer = nil
}
```

**Update the `startWorkoutSession()` method to start the timer:**
```swift
// Add this line after sessionStartTime = Date()
startWorkoutTimer()
```

**Update the `finishSession()` method to stop the timer:**
```swift
// Add this line at the beginning of finishSession()
stopWorkoutTimer()
```

**Update the `cancelSession()` method to stop the timer:**
```swift
// Add this line after resetting session state
stopWorkoutTimer()
```

### Step 2: Create WorkoutStopwatchView Component
**File**: `UzoFitness/Views/Components/WorkoutStopwatchView.swift`

**Create this new file:**
```swift
import SwiftUI

struct WorkoutStopwatchView: View {
    let elapsedTime: TimeInterval
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Workout Time")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatTime(elapsedTime))
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    WorkoutStopwatchView(elapsedTime: 125) // 2:05
        .padding()
}
```

### Step 3: Update WorkoutSessionView
**File**: `UzoFitness/Views/Screens/WorkoutSessionView.swift`

**Add the stopwatch at the top of the contentView:**
```swift
@ViewBuilder
private var contentView: some View {
    VStack(spacing: 0) {
        // Add this section at the top
        if viewModel.isWorkoutInProgress {
            WorkoutStopwatchView(elapsedTime: viewModel.workoutElapsedTime)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
        
        if !viewModel.exercises.isEmpty {
            // Exercise List
            ScrollView {
                exerciseListSection
            }
            
            // Complete Workout Button (only show when all sets are completed)
            if viewModel.canFinishSession {
                completeWorkoutButton
            }
        } else {
            // Loading or no exercises
            VStack(spacing: 24) {
                SwiftUI.ProgressView("Loading workout...")
                    .font(.headline)
                
                Text("Preparing your exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
    .background(Color(.systemGroupedBackground))
}
```

### Step 4: Build Verification and Testing
**After completing all steps for Issue #1 (Workout Stopwatch):**

1. **Build the project** to ensure no compilation errors:
   ```bash
   xcodebuild -scheme UzoFitness -destination "generic/platform=iOS" -configuration Debug build
   ```

2. **If build is successful**, pause here for user testing:
   - Start a workout session
   - Verify the stopwatch appears at the top
   - Verify the timer starts automatically
   - Verify the timer continues running during the workout
   - Test app backgrounding/foregrounding

3. **After user testing**, commit the changes:
   ```bash
   git add .
   git commit -m "feat: Add workout stopwatch to session view

   - Add workoutElapsedTime and workoutTimer to LoggingViewModel
   - Create WorkoutStopwatchView component with MM:SS format
   - Integrate stopwatch into WorkoutSessionView header
   - Add startWorkoutTimer() and stopWorkoutTimer() methods
   - Timer starts automatically when session begins
   - Timer stops when session completes or cancels
   - Timer persists across app lifecycle events
   
   Resolves: Missing workout duration tracking in active sessions"
   ```

---

## 2. Rest Timer with Notifications

### Step 1: Update LoggingViewModel
**File**: `UzoFitness/ViewModels/LoggingViewModel.swift`

**Add these properties after the existing @Published variables:**
```swift
@Published var globalRestTimer: TimeInterval?
@Published var globalRestTimerActive: Bool = false
```

**Add these methods after the existing timer methods:**
```swift
private func startGlobalRestTimer(seconds: TimeInterval) {
    AppLogger.info("[LoggingViewModel.startGlobalRestTimer] Starting global rest timer: \(seconds)s", category: "LoggingViewModel")
    
    globalRestTimer = seconds
    globalRestTimerActive = true
    
    // Trigger haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    
    // Schedule local notification
    scheduleRestTimerNotification(seconds: seconds)
    
    // Start timer
    restTimer = timerFactory.createTimer(interval: 1.0, repeats: true) { [weak self] timer in
        Task { @MainActor in
            self?.tickGlobalRestTimer()
        }
    }
    
    AppLogger.debug("[LoggingViewModel.startGlobalRestTimer] Global rest timer started", category: "LoggingViewModel")
}

private func tickGlobalRestTimer() {
    guard let currentTimer = globalRestTimer, currentTimer > 0 else {
        return
    }
    
    globalRestTimer = currentTimer - 1
    
    if globalRestTimer! <= 0 {
        AppLogger.info("[LoggingViewModel.tickGlobalRestTimer] Global rest timer completed", category: "LoggingViewModel")
        cancelGlobalRestTimer()
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

private func cancelGlobalRestTimer() {
    AppLogger.info("[LoggingViewModel.cancelGlobalRestTimer] Cancelling global rest timer", category: "LoggingViewModel")
    
    restTimer?.invalidate()
    restTimer = nil
    globalRestTimer = nil
    globalRestTimerActive = false
    
    // Cancel any pending notifications
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    
    AppLogger.debug("[LoggingViewModel.cancelGlobalRestTimer] Global rest timer cancelled", category: "LoggingViewModel")
}

private func scheduleRestTimerNotification(seconds: TimeInterval) {
    let content = UNMutableNotificationContent()
    content.title = "Rest Timer Complete"
    content.body = "Time to start your next set!"
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            AppLogger.error("[LoggingViewModel.scheduleRestTimerNotification] Failed to schedule notification", category: "LoggingViewModel", error: error)
        } else {
            AppLogger.debug("[LoggingViewModel.scheduleRestTimerNotification] Rest timer notification scheduled", category: "LoggingViewModel")
        }
    }
}
```

**Add this method to handle rest timer intents:**
```swift
func startGlobalRest(seconds: TimeInterval) {
    AppLogger.info("[LoggingViewModel.startGlobalRest] Starting global rest timer", category: "LoggingViewModel")
    startGlobalRestTimer(seconds: seconds)
}

func cancelGlobalRest() {
    AppLogger.info("[LoggingViewModel.cancelGlobalRest] Cancelling global rest timer", category: "LoggingViewModel")
    cancelGlobalRestTimer()
}
```

### Step 2: Create RestTimerButton Component
**File**: `UzoFitness/Views/Components/RestTimerButton.swift`

**Create this new file:**
```swift
import SwiftUI

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
            HStack(spacing: 12) {
                Image(systemName: viewModel.globalRestTimerActive ? "timer" : "timer.circle")
                    .font(.title2)
                
                Text(viewModel.globalRestTimerActive ? 
                     formatTime(viewModel.globalRestTimer ?? 0) : 
                     "Rest Timer")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.globalRestTimerActive ? Color.orange : Color.blue)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingCustomDuration) {
            RestTimerDurationPicker(viewModel: viewModel)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    RestTimerButton(viewModel: LoggingViewModel(modelContext: ModelContext(try! ModelContainer(for: WorkoutPlan.self))))
        .padding()
}
```

### Step 3: Create RestTimerDurationPicker
**File**: `UzoFitness/Views/Components/RestTimerDurationPicker.swift`

**Create this new file:**
```swift
import SwiftUI

struct RestTimerDurationPicker: View {
    @ObservedObject var viewModel: LoggingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDuration: TimeInterval = 60
    private let durationOptions: [TimeInterval] = [30, 45, 60, 90, 120, 180]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select Rest Duration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(durationOptions, id: \.self) { duration in
                        Button {
                            selectedDuration = duration
                        } label: {
                            VStack(spacing: 8) {
                                Text(formatTime(duration))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(selectedDuration == duration ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedDuration == duration ? .white : .primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button {
                    viewModel.startGlobalRest(seconds: selectedDuration)
                    dismiss()
                } label: {
                    Text("Start Rest Timer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(Int(timeInterval))s"
        }
    }
}

#Preview {
    RestTimerDurationPicker(viewModel: LoggingViewModel(modelContext: ModelContext(try! ModelContainer(for: WorkoutPlan.self))))
}
```

### Step 4: Update WorkoutSessionView
**File**: `UzoFitness/Views/Screens/WorkoutSessionView.swift`

**Add the rest timer button above the complete workout button:**
```swift
// MARK: - Complete Workout Button
private var completeWorkoutButton: some View {
    VStack(spacing: 0) {
        Divider()
        
        // Add rest timer button
        RestTimerButton(viewModel: viewModel)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        
        Button {
            AppLogger.info("[WorkoutSessionView] Complete Workout button tapped", category: "WorkoutSessionView")
            viewModel.handleIntent(.finishSession)
            isPresented = false
        } label: {
            Text("Complete Workout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canFinishSession ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!viewModel.canFinishSession)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
    }
}
```

### Step 5: Build Verification and Testing
**After completing all steps for Issue #2 (Rest Timer with Notifications):**

1. **Build the project** to ensure no compilation errors:
   ```bash
   xcodebuild -scheme UzoFitness -destination "generic/platform=iOS" -configuration Debug build
   ```

2. **If build is successful**, pause here for user testing:
   - Start a workout session
   - Tap the "Rest Timer" button at the bottom
   - Verify the duration picker appears
   - Select a duration and start the timer
   - Verify haptic feedback when timer starts
   - Verify the timer button shows countdown
   - Test notification delivery when timer completes
   - Test app backgrounding during timer
   - Verify haptic feedback when timer completes

3. **After user testing**, commit the changes:
   ```bash
   git add .
   git commit -m "feat: Add global rest timer with notifications and haptics

   - Add globalRestTimer and globalRestTimerActive to LoggingViewModel
   - Create RestTimerButton component with active/inactive states
   - Create RestTimerDurationPicker with preset duration options
   - Integrate rest timer into WorkoutSessionView bottom section
   - Add haptic feedback for timer start and completion
   - Implement local notifications for timer completion
   - Add notification permissions handling
   - Timer persists across app backgrounding/foregrounding
   
   Resolves: Missing rest timer functionality with notifications"
   ```

---

## 3. Fix Bulk Edit Sets Default Values

### Step 1: Update LoggingExerciseRowView
**File**: `UzoFitness/Views/Components/LoggingExerciseRowView.swift`

**Find the "Edit All Sets" button and replace it with:**
```swift
if !exercise.isCompleted && exercise.sets.count > 1 {
    Button("Edit All Sets") {
        let defaults = getDefaultBulkEditValues()
        bulkReps = defaults.reps
        bulkWeight = defaults.weight
        showingBulkEdit = true
    }
    .font(.caption)
    .foregroundColor(.blue)
}
```

**Add this method before the body property:**
```swift
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
```

### Step 2: Build Verification and Testing
**After completing all steps for Issue #3 (Bulk Edit Sets Default Values):**

1. **Build the project** to ensure no compilation errors:
   ```bash
   xcodebuild -scheme UzoFitness -destination "generic/platform=iOS" -configuration Debug build
   ```

2. **If build is successful**, pause here for user testing:
   - Start a workout session
   - Complete at least one set with different reps/weight than planned
   - Tap "Edit All Sets" for that exercise
   - Verify the dialog shows the first completed set's values
   - Test with multiple completed sets to verify fallback logic
   - Test with no completed sets to verify planned values fallback

3. **After user testing**, commit the changes:
   ```bash
   git add .
   git commit -m "fix: Update bulk edit dialog to use completed set values

   - Add getDefaultBulkEditValues() method to LoggingExerciseRowView
   - Update 'Edit All Sets' button to use first completed set values
   - Implement fallback logic: first completed set → last completed set → planned values
   - Ensure bulk edit dialog reflects actual completed set values, not template values
   - Maintain data validation for reasonable values (reps > 0, weight >= 0)
   
   Resolves: Bulk edit dialog always defaults to 10 reps and 0 weight"
   ```

---

## 4. Fix Workout Session Default Reps

### Step 1: Update SessionExercise Initializer
**File**: `UzoFitness/Models/SessionExercise.swift`

**Find the init method and update the auto-population logic:**
```swift
init(
    id: UUID = UUID(),
    exercise: Exercise,
    plannedSets: Int,
    plannedReps: Int? = nil,
    plannedWeight: Double? = nil,
    position: Double,
    supersetID: UUID? = nil,
    currentSet: Int = 0,
    isCompleted: Bool = false,
    restTimer: TimeInterval? = nil,
    session: WorkoutSession? = nil,
    createdAt: Date = .now,
    autoPopulateFromLastSession: Bool = true
) {
    self.id = id
    self.exercise = exercise
    self.plannedSets = plannedSets
    self.position = position
    self.supersetID = supersetID
    self.currentSet = currentSet
    self.isCompleted = isCompleted
    self.restTimer = restTimer
    self.session = session
    self.createdAt = createdAt
    self.completedSets = []
    
    // Auto-populate from exercise's cached values if requested
    if autoPopulateFromLastSession {
        let suggestedValues = exercise.suggestedStartingValues
        
        // Prioritize template values over cached values for session creation
        self.plannedReps = plannedReps ?? suggestedValues.reps ?? 10
        self.plannedWeight = plannedWeight ?? suggestedValues.weight
        
        // Keep the caching logic intact for individual exercise suggestions
        self.previousTotalVolume = suggestedValues.totalVolume
        self.previousSessionDate = exercise.lastUsedDate
        
        AppLogger.debug("[SessionExercise.init] Auto-populated from exercise: \(exercise.name)", category: "SessionExercise")
        AppLogger.debug("[SessionExercise.init] Suggested weight: \(suggestedValues.weight ?? 0), reps: \(suggestedValues.reps ?? 0)", category: "SessionExercise")
    } else {
        self.plannedReps = plannedReps ?? 10
        self.plannedWeight = plannedWeight
        self.previousTotalVolume = nil
        self.previousSessionDate = nil
        
        AppLogger.debug("[SessionExercise.init] Created without auto-population for: \(exercise.name)", category: "SessionExercise")
    }
}
```

### Step 2: Update LoggingViewModel Session Creation
**File**: `UzoFitness/ViewModels/LoggingViewModel.swift`

**Find the `createSessionExercises` method and update it to pass template values:**
```swift
private func createSessionExercises(for session: WorkoutSession, from dayTemplate: DayTemplate) {
    AppLogger.info("[LoggingViewModel.createSessionExercises] Creating exercises for session", category: "LoggingViewModel")
    
    for exerciseTemplate in dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position }) {
        let sessionExercise = SessionExercise(
            exercise: exerciseTemplate.exercise,
            plannedSets: exerciseTemplate.setCount,
            plannedReps: exerciseTemplate.reps, // Pass template reps
            plannedWeight: exerciseTemplate.weight, // Pass template weight
            position: exerciseTemplate.position,
            supersetID: exerciseTemplate.supersetID,
            currentSet: 0,
            isCompleted: false,
            session: session,
            autoPopulateFromLastSession: true
        )
        
        modelContext.insert(sessionExercise)
        session.sessionExercises.append(sessionExercise)
        
        // Create planned sets using template values
        for setIndex in 0..<exerciseTemplate.setCount {
            let plannedSet = CompletedSet(
                reps: exerciseTemplate.reps, // Use template reps
                weight: exerciseTemplate.weight ?? 0, // Use template weight
                isCompleted: false,
                position: setIndex,
                sessionExercise: sessionExercise
            )
            modelContext.insert(plannedSet)
            sessionExercise.completedSets.append(plannedSet)
            AppLogger.debug("[LoggingViewModel.createSessionExercises] Created planned set \(setIndex + 1) for \(exerciseTemplate.exercise.name)", category: "LoggingViewModel")
        }
        
        AppLogger.debug("[LoggingViewModel.createSessionExercises] Added exercise: \(exerciseTemplate.exercise.name) with \(exerciseTemplate.setCount) planned sets", category: "LoggingViewModel")
    }
    
    AppLogger.info("[LoggingViewModel.createSessionExercises] Created \(dayTemplate.exerciseTemplates.count) session exercises", category: "LoggingViewModel")
}
```

### Step 3: Build Verification and Testing
**After completing all steps for Issue #4 (Workout Session Default Reps):**

1. **Build the project** to ensure no compilation errors:
   ```bash
   xcodebuild -scheme UzoFitness -destination "generic/platform=iOS" -configuration Debug build
   ```

2. **If build is successful**, pause here for user testing:
   - Create or edit an exercise template with specific reps/weight
   - Start a workout session with that template
   - Verify the session exercises use the template values, not defaults
   - Test with exercises that have no template values (should use cached values)
   - Verify individual exercise suggestions still work correctly
   - Test with exercises that have both template and cached values

3. **After user testing**, commit the changes:
   ```bash
   git add .
   git commit -m "fix: Respect exercise template values during session creation

   - Update SessionExercise initializer to prioritize template values
   - Modify createSessionExercises to pass template reps/weight explicitly
   - Ensure session creation uses template values as primary source
   - Maintain existing caching logic for individual exercise suggestions
   - Implement fallback: template values → cached values → system defaults
   - Update CompletedSet creation to use template values
   
   Resolves: Session creation defaults to 10 reps regardless of template values"
   ```

---

## Testing Instructions

### Unit Tests to Add
**File**: `UzoFitnessTests/ViewModels/LoggingViewModelTests.swift`

**Add these test methods:**
```swift
func testWorkoutTimerStartsWhenSessionBegins() {
    // Test that workout timer starts when session begins
}

func testWorkoutTimerStopsWhenSessionCompletes() {
    // Test that workout timer stops when session completes
}

func testGlobalRestTimerWithNotifications() {
    // Test global rest timer functionality
}

func testBulkEditUsesFirstCompletedSetValues() {
    // Test that bulk edit uses first completed set values
}

func testSessionCreationRespectsTemplateValues() {
    // Test that session creation uses template values
}
```

### UI Tests to Add
**File**: `UzoFitnessUITests/UzoFitnessUITests.swift`

**Add these test methods:**
```swift
func testWorkoutStopwatchDisplay() {
    // Test that workout stopwatch displays correctly
}

func testRestTimerButtonFunctionality() {
    // Test rest timer button interaction
}

func testBulkEditDialogDefaults() {
    // Test bulk edit dialog shows correct defaults
}
```

---

## Implementation Checklist

### Phase 1 (High Priority)
- [ ] Add workout stopwatch to LoggingViewModel
- [ ] Create WorkoutStopwatchView component
- [ ] Integrate stopwatch into WorkoutSessionView
- [ ] Add global rest timer to LoggingViewModel
- [ ] Create RestTimerButton component
- [ ] Create RestTimerDurationPicker component
- [ ] Integrate rest timer into WorkoutSessionView
- [ ] Add notification permissions request

### Phase 2 (Medium Priority)
- [ ] Fix bulk edit default values in LoggingExerciseRowView
- [ ] Update SessionExercise initializer to respect template values
- [ ] Update LoggingViewModel session creation to pass template values
- [ ] Add unit tests for new functionality
- [ ] Add UI tests for new components

### Final Steps
- [ ] Test all functionality on device
- [ ] Verify notifications work correctly
- [ ] Test app lifecycle (background/foreground)
- [ ] Verify haptic feedback works
- [ ] Test accessibility features

### Final Build Verification and Testing
**After completing all four issues:**

1. **Build the project** to ensure no compilation errors:
   ```bash
   xcodebuild -scheme UzoFitness -destination "generic/platform=iOS" -configuration Debug build
   ```

2. **If build is successful**, perform comprehensive testing:
   - **Workout Stopwatch**: Verify timer displays and persists correctly
   - **Rest Timer**: Test all timer functionality with notifications
   - **Bulk Edit**: Verify dialog uses completed set values
   - **Session Defaults**: Confirm template values are respected
   - **Integration**: Test all features work together seamlessly

3. **After comprehensive testing**, commit all changes:
   ```bash
   git add .
   git commit -m "feat: Complete workout session improvements

   IMPROVEMENTS:
   - Add workout stopwatch with MM:SS format and persistence
   - Add global rest timer with notifications and haptic feedback
   - Fix bulk edit dialog to use completed set values
   - Fix session creation to respect exercise template values
   
   TECHNICAL DETAILS:
   - Add WorkoutStopwatchView and RestTimerButton components
   - Implement notification scheduling and haptic feedback
   - Update LoggingViewModel with timer management
   - Modify SessionExercise to prioritize template values
   - Add fallback logic for bulk edit defaults
   
   USER EXPERIENCE:
   - Users can now track workout duration in real-time
   - Rest timer provides haptic feedback and notifications
   - Bulk edit reflects actual completed set values
   - Session creation respects planned workout parameters
   
   Resolves: All four workout session issues identified by user"
   ```

---

## Notes for Claude

1. **Follow MVVM Architecture**: All business logic should be in ViewModels, UI logic in Views
2. **Use Existing Patterns**: Follow the same patterns used in the existing codebase
3. **Add Logging**: Include AppLogger calls for debugging
4. **Handle Errors**: Add proper error handling for all new functionality
5. **Test Thoroughly**: Each feature should be tested before moving to the next
6. **Respect Existing Code**: Don't break existing functionality while adding new features
7. **Build Verification**: After each issue is implemented, verify successful build with no errors
8. **User Testing**: Pause after each successful build for user testing
9. **Commit Changes**: After user testing, commit with thorough summary

The implementation should be done in the order specified, with Phase 1 features being the highest priority for user experience. 