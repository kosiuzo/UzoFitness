# Logging View Implementation Tasks

## 1. Screen & Layout  
- [ ] Create `LoggingView` (SwiftUI or UIKit)  
  - [ ] Add **Template Picker** at top (dropdown or menu)  
  - [ ] Add **Day Picker** (segmented control or picker)  
  - [ ] Render **Exercise List** container beneath  
  - [ ] Pin **Complete Workout** button at bottom  

## 2. ViewModel Binding  
- [ ] Inject `LoggingViewModel` into `LoggingView`  
- [ ] Bind:  
  - [ ] `currentTemplate` ↔ Template Picker  
  - [ ] `currentDay` ↔ Day Picker  
  - [ ] `exercises` array ↔ Exercise List  

## 3. Data Binding & Selection  
- [ ] Implement template selection flow:  
  - [ ] Fetch available workout templates  
  - [ ] Update `currentTemplate` when user selects  
- [ ] Implement day selection flow:  
  - [ ] Calculate today’s index by default  
  - [ ] Allow manual override to any day in template  

## 4. Exercise List & Supersets  
- [ ] For each exercise in `viewModel.exercises`:  
  - [ ] Display name, sets × reps × weight fields  
  - [ ] Visually group supersets (e.g. colored background or header)  
  - [ ] Add inline editable controls for:  
    - [ ] Reps (stepper or text entry)  
    - [ ] Sets  
    - [ ] Weight  
    - [ ] Rest duration  

## 5. Auto-Population of Last Performance  
- [ ] On view appear, call `viewModel.loadLastPerformedData()`  
- [ ] Populate each exercise row’s reps/weight with last-performed values  
- [ ] Fall back to template defaults if no history exists  

## 6. Completion Actions  
- [ ] **Complete All Sets** per exercise:  
  - [ ] Add button/link within each exercise row  
  - [ ] Call `viewModel.completeAllSets(for: exercise)`  
- [ ] **Complete Workout** button:  
  - [ ] Call `viewModel.finishWorkout()`  
  - [ ] Dismiss or navigate away on success  

## 7. Rest Timer  
- [ ] In each exercise grouping, add **Start Rest** button  
  - [ ] Inline control to adjust rest duration before start  
  - [ ] Call `viewModel.startRestTimer(for: exercise)`  
  - [ ] Trigger haptic feedback at timer start  
  - [ ] Schedule local notification at timer end  
- [ ] Implement `RestTimerManager` to encapsulate timer, notifications, and haptics  

## 8. Persistence & State Management  
- [ ] On each inline edit, immediately update `viewModel` properties  
- [ ] On `finishWorkout()`, persist all logged sets to SwiftData/Core Data  
- [ ] Ensure logging progress survives view re-loads until saved  

## 9. Error Handling & Edge Cases  
- [ ] Handle missing template/day gracefully (show placeholder)  
- [ ] Validate inline inputs (e.g. non-negative reps/weight)  
- [ ] Fall back if `loadLastPerformedData()` fails (show defaults)  

## 10. Testing  
- [ ] Unit tests for `LoggingViewModel`:  
  - [ ] Template/day selection logic  
  - [ ] Inline edit handlers  
  - [ ] Auto-population fetch and fallback  
  - [ ] `completeAllSets` and `finishWorkout` behavior  
- [ ] Unit tests for `RestTimerManager`:  
  - [ ] Timer start/stop logic  
  - [ ] Notification scheduling  
  - [ ] Haptic trigger  
- [ ] UI tests (optional):  
  - [ ] Verify pickers update view model  
  - [ ] Simulate inline edits and complete actions  
  - [ ] Start rest timer and assert notification scheduled  

## 11. QA & Manual Validation  
- [ ] Manual test on device:  
  - [ ] Default to today’s workout and day  
  - [ ] Switch templates and days  
  - [ ] Edit reps/sets/weight/rest and ensure UI/state updates  
  - [ ] Complete All Sets and Complete Workout scenarios  
  - [ ] Start rest timer: feel haptic, receive notification  
- [ ] Solicit feedback on minimalist layout and interaction clarity  