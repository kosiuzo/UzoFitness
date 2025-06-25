# Logging View Implementation Tasks

## 1. Screen & Layout  
- [x] Create `LoggingView` (SwiftUI or UIKit)   
  - [x] Add **Template Picker** at top (dropdown or menu) highlight the ones that are apart of an active workout plans those should be sorted at the top. 
  - [x] Add **Day Picker** (segmented control or picker) based on the Template selected  
  - [x] Render **Exercise List** container beneath  
  - [x] Pin **Complete Workout** button at bottom after the Workout has been selected 

## 2. ViewModel Binding  
- [x] Inject `LoggingViewModel` into `LoggingView`  
- [x] Bind:  
  - [x] `currentTemplate` ↔ Template Picker  
  - [x] `currentDay` ↔ Day Picker  
  - [x] `exercises` array ↔ Exercise List  

## 3. Data Binding & Selection  
- [x] Implement template selection flow:  
  - [x] Fetch available workout templates  
  - [x] Update `currentTemplate` when user selects  
- [x] Implement day selection flow:  
  - [x] Calculate today's index by default  
  - [x] Allow manual override to any day in template  

## 4. Exercise List & Supersets  
- [x] For each exercise in `viewModel.exercises`:  
  - [x] Display name, sets × reps × weight fields  
  - [x] Visually group supersets (e.g. header)  
  - [x] Add inline editable controls for:  
    - [x] Reps (stepper or text entry)  
    - [x] Sets  
    - [x] Weight  
    - [x] Rest duration  

## 5. Auto-Population of Last Performance  
- [x] On view appear, call `viewModel.loadLastPerformedData()`  
- [x] Populate each exercise row's reps/weight with last-performed values based on existing logic only add something if it's not already implemented 
- [x] Fall back to template defaults if no history exists  

## 6. Completion Actions  
- [x] **Complete All Sets** per exercise:  
  - [x] Add button/link within each exercise row  
  - [x] Call `viewModel.completeAllSets(for: exercise)`  
- [x] **Complete Workout** button:  
  - [x] Call `viewModel.finishWorkout()`  
  - [x] Dismiss or navigate away on success  
 

## 7. Persistence & State Management  
- [x] On each inline edit, immediately update `viewModel` properties  
- [x] On `finishWorkout()`, persist all logged sets to SwiftData/Core Data  
- [x] Ensure logging progress survives view re-loads until saved  

## 8. Error Handling & Edge Cases  
- [x] Handle missing template/day gracefully (show placeholder)  
- [x] Validate inline inputs (e.g. non-negative reps/weight)  
- [x] Fall back if `loadLastPerformedData()` fails (show defaults)  

## 9. Testing  
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

## 10. QA & Manual Validation  
- [ ] Manual test on device:  
  - [ ] Default to today's workout and day  
  - [ ] Switch templates and days  
  - [ ] Edit reps/sets/weight/rest and ensure UI/state updates  
  - [ ] Complete All Sets and Complete Workout scenarios  
  - [ ] Start rest timer: feel haptic, receive notification  
- [ ] Solicit feedback on minimalist layout and interaction clarity  

## ✅ BUILD SUCCESS
The LoggingView implementation is complete and the app builds successfully! All core functionality has been implemented following MVVM architecture and minimalist design principles.