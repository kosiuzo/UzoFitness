# UzoFitness Test Implementation Task List

This task list is based on the TestCodeMapping.md file and provides a structured approach to rebuilding the test suite. Each task can be checked off as it's completed.

## Milestone 1: Foundation & Model Tests (Week 1)

### 1.1 Test Infrastructure Setup

#### Task 1.1.1: Set up in-memory SwiftData containers for testing
- [x] **Reference File**: `UzoFitness/Persistence/PersistenceController.swift`
- [x] Create `InMemoryPersistenceController.swift` for testing
- [x] Implement schema setup with all model types
- [x] Add test cleanup methods (`deleteAllData()`)
- [x] Test container creation and cleanup
- [x] Verify all model types can be inserted and fetched
- [x] **Success Criteria**: In-memory containers work without file system dependencies
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for infrastructure tests
- [x] **Verify**: All infrastructure tests compile and pass in simulator

#### Task 1.1.2: Create base test utilities and helper methods
- [x] **Reference Files**: 
  - `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/Logger.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/DateFormatters.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/FormattingUtilities.swift`
- [x] Create `TestHelpers.swift` with common test utilities
- [x] Implement async/await support for testing
- [x] Add helper methods for creating test data
- [x] Create mock factory methods
- [x] **Success Criteria**: Helper methods exist and work correctly
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for utility tests
- [x] **Verify**: All utility tests compile and pass in simulator

#### Task 1.1.3: Set up test data factories for all model types
- [x] **Reference Files**: All files in `UzoFitnessCore/Sources/UzoFitnessCore/Models/`
- [x] Create `TestDataFactories.swift`
- [x] Implement factory for `Exercise` model
- [x] Implement factory for `WorkoutTemplate` model
- [x] Implement factory for `WorkoutSession` model
- [x] Implement factory for `SessionExercise` model
- [x] Implement factory for `CompletedSet` model
- [x] Implement factory for `ProgressPhoto` model
- [x] Implement factory for `ExerciseTemplate` model
- [x] Implement factory for `DayTemplate` model
- [x] Implement factory for `WorkoutPlan` model
- [x] Implement factory for `PerformedExercise` model
- [x] **Success Criteria**: All factories create valid, realistic test data
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for factory tests
- [x] **Verify**: All factory tests compile and pass in simulator

### 1.2 Core Model Validation Tests

#### Task 1.2.1: Recreate RelationshipIntegrityTests
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`
- [x] Create `RelationshipIntegrityTests.swift`
- [x] Test `WorkoutSession.totalVolume` computed property
- [x] Test cascade delete behavior for `WorkoutSession`
- [x] Test cascade delete behavior for `SessionExercise`
- [x] Test cascade delete behavior for `CompletedSet`
- [x] Verify no orphaned objects remain after deletion
- [x] **Success Criteria**: `testCascadeDeleteSessionRemovesChildren()` passes
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'` for relationship integrity tests
- [x] **Verify**: All relationship integrity tests compile and pass in simulator

#### Task 1.2.2: Recreate ValidationTests - WorkoutTemplate validation
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/WorkoutTemplate+Validation.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift`
- [x] Create `ValidationTests.swift`
- [x] Test `testUniqueWorkoutTemplateName()`
- [x] Test `testWorkoutTemplateNameValidation()`
- [x] Test `testWorkoutTemplateNameSuggestion()`
- [x] Test `ValidationError` enum cases and error descriptions
- [x] Test name uniqueness validation
- [x] **Success Criteria**: All template validation tests pass
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'` for template validation tests
- [x] **Verify**: All template validation tests compile and pass in simulator

#### Task 1.2.3: Recreate ValidationTests - ExerciseTemplate validation
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/Exercise+Validation.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/ExerciseTemplate.swift`
- [x] Test parameter validation (reps, sets, weight, position)
- [x] Test `testExerciseTemplateSafeUpdates()` with rollback
- [x] Test negative value validation
- [x] Test zero value validation
- [x] Test invalid position validation
- [x] **Success Criteria**: All exercise template validation tests pass
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'` for exercise validation tests
- [x] **Verify**: All exercise validation tests compile and pass in simulator

#### Task 1.2.4: Recreate WorkoutDomainTests
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`
- [x] Create `WorkoutDomainTests.swift`
- [x] Test `testTotalVolumePerExerciseAndSession()`
- [x] Test `testAddWeightedVolume()`
- [x] Test volume calculations for body-weight exercises
- [x] Test volume calculations for weighted exercises
- [x] **Success Criteria**: Volume calculations are mathematically correct
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'` for workout domain tests
- [x] **Verify**: All workout domain tests compile and pass in simulator

### 1.3 Data Import/Export Tests

#### Task 1.3.1: Recreate WorkoutTemplateImportTests ✅ COMPLETED
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplateImportDTO.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplate.swift`
- [x] Create `WorkoutTemplateImportTests.swift`
- [x] Test `testMinimalValidWorkoutTemplate()`
- [x] Test `testWorkoutTemplateWithDayNames()`
- [x] Test JSON validation and error handling (12 comprehensive test cases)
- [x] Test auto-ID generation for missing IDs
- [x] Test malformed JSON handling and missing required fields
- [x] Test invalid exercise parameters (zero sets/reps, negative weights)
- [x] **Success Criteria**: JSON import functionality works with various scenarios ✅
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'` for template import tests ✅ ALL TESTS PASS
- [x] **Verify**: All template import tests compile and pass in simulator ✅

#### Task 1.3.2: Recreate JSONImportTests ✅ COMPLETED
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/Exercise.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift`
- [x] Create `JSONImportTests.swift`
- [x] Test `testExerciseJSONImport_WithMissingID()`
- [x] Test `testExerciseJSONImport_WithExistingID()`
- [x] Test `testExerciseJSONImport_AllCategories()`
- [x] Test `testExerciseJSONImport_MinimalData()`
- [x] Test ID handling in JSON import (auto-generation and preservation)
- [x] Test error handling for malformed JSON and invalid categories
- [x] Test round-trip encoding/decoding and array import/export
- [x] Test unique ID generation for multiple exercises
- [x] **Success Criteria**: Exercise JSON import functionality works correctly ✅
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'` for JSON import tests ✅ ALL TESTS PASS
- [x] **Verify**: All JSON import tests compile and pass in simulator ✅

#### Task 1.3.3: Recreate ProgressPhotoTests ✅ COMPLETED
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift`
- [x] Create `ProgressPhotoTests.swift`
- [x] Test `testInitializerSetsAllProperties()`
- [x] Test `testInsertAndFetchProgressPhoto()`
- [x] Test SwiftData persistence operations (insert, fetch, update, delete)
- [x] Test `Codable` implementation with JSON encoding/decoding
- [x] Test all PhotoAngle enum values (.front, .side, .back)
- [x] Test protocol conformance (Identified, Timestamped)
- [x] Test error handling for invalid JSON and missing fields
- [x] Created 15 comprehensive test cases covering all functionality
- [x] **Success Criteria**: Progress photo model functionality works correctly ✅
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:UzoFitnessTests/ProgressPhotoTests` ✅ ALL TESTS PASS
- [x] **Verify**: All progress photo tests compile and pass in simulator ✅
- [x] **Note**: Fixed floating-point precision issue in date comparisons for JSON encoding/decoding test

### 1.4 Advanced Model Tests

#### Task 1.4.1: Recreate ExerciseCachingTests ✅ COMPLETED
- [x] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/Exercise+LastUsedValues.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/Exercise.swift`
- [x] Create `ExerciseCachingTests.swift`
- [x] Test caching behavior (initialization, manual updates, independence)
- [x] Test auto-population functionality (from cache, defaults, explicit values)
- [x] Test cache updates after workout completion (completed vs not completed, with/without sets)
- [x] Test manual overrides (explicit values override cache, disable auto-population)
- [x] Test volume calculations and most recent session data
- [x] Created 13 comprehensive test cases covering all caching functionality
- [x] **Success Criteria**: All caching behavior tests pass ✅
- [x] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:UzoFitnessTests/ExerciseCachingTests` ✅ ALL TESTS PASS
- [x] **Verify**: All exercise caching tests compile and pass in simulator ✅
- [x] **Note**: Fixed method visibility by making `updateExerciseCacheOnCompletion()` public for testing

---

## Milestone 2: Service Layer Tests (Week 2)

### 2.1 Mock Infrastructure Setup

#### Task 2.1.1: Recreate MockPhotoLibraryService
- [ ] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/PhotoServiceProtocol.swift`
  - `UzoFitness/Services/PhotoService.swift`
- [ ] Create `MockPhotoLibraryService.swift`
- [ ] Mock `requestPhotoLibraryAuthorization()`
- [ ] Mock `saveToPhotoLibrary(image:)`
- [ ] Mock `pickImage()`
- [ ] Support different authorization states
- [ ] Track method calls for verification
- [ ] **Success Criteria**: Mock behavior is verified correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for photo library mock tests
- [ ] **Verify**: All photo library mock tests compile and pass in simulator

#### Task 2.1.2: Recreate MockFileSystemService
- [ ] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/FileSystemServiceProtocol.swift`
  - `UzoFitness/Services/PhotoService.swift`
- [ ] Create `MockFileSystemService.swift`
- [ ] Mock `cacheDirectory()`
- [ ] Mock `writeData(_:to:)`
- [ ] Simulate cache directory access
- [ ] Track write operations
- [ ] Support error simulation
- [ ] **Success Criteria**: Mock behavior is verified correctly

#### Task 2.1.3: Recreate MockHealthStore and related mocks
- [ ] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthStoreProtocol.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthKitTypeFactoryProtocol.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/CalendarProtocol.swift`
- [ ] Create `MockHealthStore.swift`
- [ ] Create `MockQueryExecutor.swift`
- [ ] Create `MockHealthKitTypeFactory.swift`
- [ ] Create `MockCalendar.swift`
- [ ] Mock HealthKit authorization methods
- [ ] Mock query execution methods
- [ ] Mock type factory methods
- [ ] Mock calendar operations
- [ ] **Success Criteria**: All HealthKit mocks work correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for HealthKit mock tests
- [ ] **Verify**: All HealthKit mock tests compile and pass in simulator

### 2.2 PhotoService Tests

#### Task 2.2.1: Recreate PhotoService authorization tests
- [ ] **Reference Files**:
  - `UzoFitness/Services/PhotoService.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/PhotoServiceProtocol.swift`
- [ ] Create `PhotoServiceTests.swift`
- [ ] Test `testRequestPhotoLibraryAuthorization_WhenAlreadyAuthorized_ReturnsAuthorized()`
- [ ] Test `testRequestPhotoLibraryAuthorization_WhenNotDetermined_RequestsAuthorization()`
- [ ] Test `testRequestPhotoLibraryAuthorization_WhenDenied_ReturnsDenied()`
- [ ] Test all authorization states
- [ ] **Success Criteria**: All authorization states are handled correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for photo service authorization tests
- [ ] **Verify**: All photo service authorization tests compile and pass in simulator

#### Task 2.2.2: Recreate PhotoService save functionality tests
- [ ] **Reference Files**:
  - `UzoFitness/Services/PhotoService.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/DataPersistenceServiceProtocol.swift`
- [ ] Test `testSaveToPhotoLibrary_WhenAuthorized_SavesImage()`
- [ ] Test `testSaveToCache_ValidImage_SavesSuccessfully()`
- [ ] Test error handling for denied access
- [ ] Test file system error handling
- [ ] **Success Criteria**: Image saving functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for photo service save tests
- [ ] **Verify**: All photo service save tests compile and pass in simulator

#### Task 2.2.3: Recreate PhotoService image picker tests
- [ ] **Reference Files**:
  - `UzoFitness/Services/PhotoService.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/ImagePickerServiceProtocol.swift`
- [ ] Test `testPickImage_UserSelectsImage_ReturnsImage()`
- [ ] Test `testPickImage_UserCancels_ReturnsNil()`
- [ ] Test progress photo saving
- [ ] Test invalid image data handling
- [ ] **Success Criteria**: Image picker integration works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for photo service picker tests
- [ ] **Verify**: All photo service picker tests compile and pass in simulator

### 2.3 HealthKitManager Tests

#### Task 2.3.1: Recreate HealthKit authorization tests
- [ ] **Reference Files**:
  - `UzoFitness/Services/HealthKitManager.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthStoreProtocol.swift`
- [ ] Create `HealthKitManagerTests.swift`
- [ ] Test `testRequestAuthorizationSuccess()`
- [ ] Test `testRequestAuthorizationFailure()`
- [ ] Test `testRequestAuthorizationTypeUnavailable()`
- [ ] Test all authorization scenarios
- [ ] **Success Criteria**: All authorization scenarios are handled
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for HealthKit authorization tests
- [ ] **Verify**: All HealthKit authorization tests compile and pass in simulator

#### Task 2.3.2: Recreate HealthKit body mass tests
- [ ] **Reference Files**:
  - `UzoFitness/Services/HealthKitManager.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`
- [ ] Test `testFetchLatestBodyMassInPoundsSuccess()`
- [ ] Test `testFetchBodyMassInPoundsOnSpecificDate()`
- [ ] Test weight conversion (kg to lbs)
- [ ] Test error handling for unavailable types
- [ ] **Success Criteria**: Body mass data retrieval works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for HealthKit body mass tests
- [ ] **Verify**: All HealthKit body mass tests compile and pass in simulator

#### Task 2.3.3: Recreate HealthKit body fat tests
- [ ] **Reference Files**:
  - `UzoFitness/Services/HealthKitManager.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`
- [ ] Test `testFetchLatestBodyFatSuccess()`
- [ ] Test `testFetchBodyFatOnSpecificDate()`
- [ ] Test percentage value handling
- [ ] Test no data scenarios
- [ ] **Success Criteria**: Body fat data retrieval works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for HealthKit body fat tests
- [ ] **Verify**: All HealthKit body fat tests compile and pass in simulator

### 2.4 Data Persistence Tests

#### Task 2.4.1: Recreate MockDataPersistenceService
- [ ] **Reference Files**:
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/DataPersistenceServiceProtocol.swift`
  - `UzoFitness/Persistence/PersistenceController.swift`
- [ ] Create `MockDataPersistenceService.swift`
- [ ] Mock `insert(_:)` method
- [ ] Mock `save()` method
- [ ] Track insert and save operations
- [ ] Support error simulation
- [ ] **Success Criteria**: Mock behavior is verified correctly

#### Task 2.4.2: Test data persistence integration
- [ ] **Reference Files**:
  - `UzoFitness/Persistence/PersistenceController.swift`
  - All model files in `UzoFitnessCore/Sources/UzoFitnessCore/Models/`
- [ ] Test SwiftData operations with all model types
- [ ] Test relationship persistence
- [ ] Test cascade operations
- [ ] Test error handling for persistence failures
- [ ] **Success Criteria**: End-to-end data persistence works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for data persistence integration tests
- [ ] **Verify**: All data persistence integration tests compile and pass in simulator

**Milestone 2 Success Criteria**: All service tests pass, external integrations work correctly, and error handling is robust.

---

## Milestone 3: ViewModel Tests (Week 3)

### 3.1 LibraryViewModel Tests

#### Task 3.1.1: Recreate LibraryViewModel initialization tests
- [ ] **Reference File**: `UzoFitness/ViewModels/LibraryViewModel.swift`
- [ ] Create `LibraryViewModelTests.swift`
- [ ] Test `testInitialization_SetsDefaultState()`
- [ ] Test ViewModel initialization with correct default values
- [ ] Test dependency injection
- [ ] Test state consistency after initialization
- [ ] **Success Criteria**: ViewModel initialization works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LibraryViewModel initialization tests
- [ ] **Verify**: All LibraryViewModel initialization tests compile and pass in simulator

#### Task 3.1.2: Recreate LibraryViewModel template management tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LibraryViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/WorkoutTemplate+HelperMethods.swift`
- [ ] Test `testCreateTemplate_ValidData_CreatesTemplate()`
- [ ] Test `testCreateTemplate_DuplicateName_SetsError()`
- [ ] Test `testDuplicateTemplate_ValidTemplate_CreatesCopy()`
- [ ] Test `testDeleteTemplate_ValidTemplate_RemovesTemplate()`
- [ ] Test template validation and error handling
- [ ] **Success Criteria**: Template CRUD operations work correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LibraryViewModel template management tests
- [ ] **Verify**: All LibraryViewModel template management tests compile and pass in simulator

#### Task 3.1.3: Recreate LibraryViewModel exercise management tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LibraryViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/Exercise+HelperMethods.swift`
- [ ] Test `testCreateExercise_ValidData_CreatesExercise()`
- [ ] Test `testDeleteExercise_ExerciseInUse_SetsError()`
- [ ] Test exercise catalog management
- [ ] Test error handling for invalid operations
- [ ] **Success Criteria**: Exercise management functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LibraryViewModel exercise management tests
- [ ] **Verify**: All LibraryViewModel exercise management tests compile and pass in simulator

#### Task 3.1.4: Recreate LibraryViewModel import/export tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LibraryViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplateImportDTO.swift`
- [ ] Test `testImportExercises_ValidJSON_ImportsSuccessfully()`
- [ ] Test `testImportExercises_InvalidJSON_SetsError()`
- [ ] Test JSON import/export functionality
- [ ] Test error handling for malformed data
- [ ] **Success Criteria**: Import/export functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LibraryViewModel import/export tests
- [ ] **Verify**: All LibraryViewModel import/export tests compile and pass in simulator

### 3.2 HistoryViewModel Tests

#### Task 3.2.1: Recreate HistoryViewModel initialization tests
- [ ] **Reference File**: `UzoFitness/ViewModels/HistoryViewModel.swift`
- [ ] Create `HistoryViewModelTests.swift`
- [ ] Test `testInitialization_SetsDefaultState()`
- [ ] Test calendar data initialization
- [ ] Test default state setup
- [ ] **Success Criteria**: HistoryViewModel initialization works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for HistoryViewModel initialization tests
- [ ] **Verify**: All HistoryViewModel initialization tests compile and pass in simulator

#### Task 3.2.2: Recreate HistoryViewModel workout summary tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/HistoryViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`
- [ ] Test `testWorkoutSessionSummary_CreatesCorrectSummary()`
- [ ] Test `testWorkoutSessionSummary_EmptyTitle_UsesDefaultTitle()`
- [ ] Test summary calculations
- [ ] Test default values application
- [ ] **Success Criteria**: Workout summary functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for HistoryViewModel workout summary tests
- [ ] **Verify**: All HistoryViewModel workout summary tests compile and pass in simulator

#### Task 3.2.3: Recreate HistoryViewModel date selection tests
- [ ] **Reference File**: `UzoFitness/ViewModels/HistoryViewModel.swift`
- [ ] Test `testSelectDate_WithNoWorkoutData_SetsSelectedDateWithEmptyDetails()`
- [ ] Test `testClearSelection_ClearsSelectedDateAndDetails()`
- [ ] Test date selection functionality
- [ ] Test empty states handling
- [ ] **Success Criteria**: Date selection functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test \
  -scheme UzoFitness \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:UzoFitnessTests/HistoryViewModelTests`
- [ ] **Verify**: All HistoryViewModel date selection tests compile and pass in simulator

### 3.3 LoggingViewModel Tests

#### Task 3.3.1: Recreate LoggingViewModel plan selection tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LoggingViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutPlan.swift`
- [ ] Create `LoggingViewModelTests.swift`
- [ ] Test `testSelectPlan_ValidPlan_SetsActivePlan()`
- [ ] Test `testSelectPlan_InvalidPlanID_SetsError()`
- [ ] Test plan selection functionality
- [ ] Test error handling for invalid plans
- [ ] **Success Criteria**: Plan selection functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LoggingViewModel plan selection tests
- [ ] **Verify**: All LoggingViewModel plan selection tests compile and pass in simulator

#### Task 3.3.2: Recreate LoggingViewModel day selection tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LoggingViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/DayTemplate.swift`
- [ ] Test `testSelectDay_ValidDay_SetsSelectedDay()`
- [ ] Test day selection within plans
- [ ] Test rest day detection
- [ ] **Success Criteria**: Day selection functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LoggingViewModel day selection tests
- [ ] **Verify**: All LoggingViewModel day selection tests compile and pass in simulator

#### Task 3.3.3: Recreate LoggingViewModel exercise logging tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LoggingViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`
- [ ] Test `testAddSet_InvalidExerciseID_SetsError()`
- [ ] Test set logging functionality
- [ ] Test error handling for invalid exercises
- [ ] **Success Criteria**: Exercise logging functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for LoggingViewModel exercise logging tests
- [ ] **Verify**: All LoggingViewModel exercise logging tests compile and pass in simulator

### 3.4 ProgressViewModel Tests

#### Task 3.4.1: Recreate ProgressViewModel state tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/ProgressViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`
- [ ] Create `ProgressViewModelTests.swift`
- [ ] Test `testGetPhotosForAngle_WithEmptyState_ReturnsEmptyArray()`
- [ ] Test `testGetExerciseOptions_WithEmptyState_ReturnsEmptyArray()`
- [ ] Test empty state handling
- [ ] **Success Criteria**: Empty state handling works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for ProgressViewModel state tests
- [ ] **Verify**: All ProgressViewModel state tests compile and pass in simulator

#### Task 3.4.2: Recreate ProgressViewModel metrics tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/ProgressViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Services/ProgressAnalysisLogic.swift`
- [ ] Test `testExerciseTrend_CalculatesMetricsCorrectly()`
- [ ] Test `testBodyMetrics_FormatsValuesCorrectly()`
- [ ] Test `testBodyMetrics_HandlesNilValues()`
- [ ] Test metrics calculations
- [ ] **Success Criteria**: Metrics calculation and formatting works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for ProgressViewModel metrics tests
- [ ] **Verify**: All ProgressViewModel metrics tests compile and pass in simulator

#### Task 3.4.3: Recreate ProgressViewModel photo management tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/ProgressViewModel.swift`
  - `UzoFitness/Services/PhotoService.swift`
- [ ] Test `testAddPhoto_SavesToCacheAndUpdatesViewModel()`
- [ ] Test photo addition functionality
- [ ] Test ViewModel state updates
- [ ] **Success Criteria**: Photo management functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for ProgressViewModel photo management tests
- [ ] **Verify**: All ProgressViewModel photo management tests compile and pass in simulator

### 3.5 SettingsViewModel Tests

#### Task 3.5.1: Recreate SettingsViewModel initialization tests
- [ ] **Reference File**: `UzoFitness/ViewModels/SettingsViewModel.swift`
- [ ] Create `SettingsViewModelTests.swift`
- [ ] Test `testViewModel_InitializationWithDependencies()`
- [ ] Test dependency injection
- [ ] Test initial state setup
- [ ] **Success Criteria**: SettingsViewModel initialization works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for SettingsViewModel initialization tests
- [ ] **Verify**: All SettingsViewModel initialization tests compile and pass in simulator

#### Task 3.5.2: Recreate SettingsViewModel permission tests
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/SettingsViewModel.swift`
  - `UzoFitness/Services/HealthKitManager.swift`
  - `UzoFitness/Services/PhotoService.swift`
- [ ] Test `testViewModel_HandleHealthKitAccessIntent()`
- [ ] Test `testViewModel_HandlePhotoAccessIntent()`
- [ ] Test permission requests
- [ ] **Success Criteria**: Permission handling works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for SettingsViewModel permission tests
- [ ] **Verify**: All SettingsViewModel permission tests compile and pass in simulator

#### Task 3.5.3: Recreate SettingsViewModel backup tests
- [ ] **Reference File**: `UzoFitness/ViewModels/SettingsViewModel.swift`
- [ ] Test `testViewModel_HandleBackupIntent_Success()`
- [ ] Test `testViewModel_HandleBackupIntent_LowBattery()`
- [ ] Test backup operations
- [ ] Test battery protection
- [ ] **Success Criteria**: Backup functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for SettingsViewModel backup tests
- [ ] **Verify**: All SettingsViewModel backup tests compile and pass in simulator


**Milestone 3 Success Criteria**: All ViewModel tests pass, UI logic works correctly, and state management is robust.

---

## Milestone 4: Integration & End-to-End Tests (Week 4)

### 4.1 Workflow Integration Tests

#### Task 4.1.1: Create workout creation workflow test
- [ ] **Reference Files**: All ViewModels and Models
- [ ] Create `WorkflowIntegrationTests.swift`
- [ ] Test complete workflow: Template creation → Plan activation → Workout logging → Session completion
- [ ] Test data flow through all ViewModels
- [ ] Test persistence integrity
- [ ] **Success Criteria**: End-to-end workout creation and logging works
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for workout creation workflow tests
- [ ] **Verify**: All workout creation workflow tests compile and pass in simulator

#### Task 4.1.2: Create progress tracking workflow test
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/ProgressViewModel.swift`
  - `UzoFitness/Services/PhotoService.swift`
  - `UzoFitness/Services/HealthKitManager.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`
- [ ] Test workflow: Photo capture → Storage → HealthKit integration → Metrics calculation
- [ ] Test end-to-end progress tracking
- [ ] **Success Criteria**: End-to-end progress tracking workflow works
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for progress tracking workflow tests
- [ ] **Verify**: All progress tracking workflow tests compile and pass in simulator

#### Task 4.1.3: Create data import/export workflow test
- [ ] **Reference Files**:
  - `UzoFitness/ViewModels/LibraryViewModel.swift`
  - `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplateImportDTO.swift`
- [ ] Test workflow: JSON import → Validation → Persistence → Export
- [ ] Test data integrity maintenance
- [ ] **Success Criteria**: End-to-end data import/export workflow works
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for data import/export workflow tests
- [ ] **Verify**: All data import/export workflow tests compile and pass in simulator

### 4.2 Performance Tests

#### Task 4.2.1: Create large dataset performance tests
- [ ] **Reference Files**: All ViewModels and Models
- [ ] Create `PerformanceTests.swift`
- [ ] Test app performance with 1000+ exercises
- [ ] Test app performance with 100+ workout sessions
- [ ] Test UI responsiveness
- [ ] Test memory usage
- [ ] **Success Criteria**: Performance with large datasets is acceptable
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for large dataset performance tests
- [ ] **Verify**: All large dataset performance tests compile and pass in simulator

#### Task 4.2.2: Create concurrent operation tests
- [ ] **Reference Files**: All ViewModels and Services
- [ ] Test multiple operations running concurrently
- [ ] Test race condition prevention
- [ ] Test data consistency under load
- [ ] Test error handling under load
- [ ] **Success Criteria**: Concurrent operation handling works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for concurrent operation tests
- [ ] **Verify**: All concurrent operation tests compile and pass in simulator

### 4.3 Error Recovery Tests

#### Task 4.3.1: Create error recovery workflow tests
- [ ] **Reference Files**: All ViewModels and Services
- [ ] Create `ErrorRecoveryTests.swift`
- [ ] Test graceful error recovery
- [ ] Test user data protection
- [ ] Test error messaging
- [ ] **Success Criteria**: Error recovery scenarios work correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for error recovery workflow tests
- [ ] **Verify**: All error recovery workflow tests compile and pass in simulator

#### Task 4.3.2: Create data corruption recovery tests
- [ ] **Reference Files**:
  - `UzoFitness/Persistence/PersistenceController.swift`
  - All model files
- [ ] Test data corruption detection
- [ ] Test recovery mechanisms
- [ ] Test backup restoration
- [ ] **Success Criteria**: Data corruption handling works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for data corruption recovery tests
- [ ] **Verify**: All data corruption recovery tests compile and pass in simulator

### 4.4 Accessibility Tests

#### Task 4.4.1: Create accessibility compliance tests
- [ ] **Reference Files**: All Views in `UzoFitness/Views/`
- [ ] Create `AccessibilityTests.swift`
- [ ] Test VoiceOver compatibility
- [ ] Test Dynamic Type support
- [ ] Test high contrast mode
- [ ] Test accessibility labels
- [ ] **Success Criteria**: Accessibility compliance is verified
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for accessibility compliance tests
- [ ] **Verify**: All accessibility compliance tests compile and pass in simulator

### 4.5 Final Integration Tests

#### Task 4.5.1: Create complete app lifecycle test
- [ ] **Reference Files**: All major app components
- [ ] Create `AppLifecycleTests.swift`
- [ ] Test app startup
- [ ] Test screen navigation
- [ ] Test background/foreground transitions
- [ ] **Success Criteria**: Complete app lifecycle works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for app lifecycle tests
- [ ] **Verify**: All app lifecycle tests compile and pass in simulator

#### Task 4.5.2: Create data migration test
- [ ] **Reference Files**:
  - `UzoFitness/Persistence/PersistenceController.swift`
  - All model files
- [ ] Test data migration scenarios
- [ ] Test version compatibility
- [ ] Test migration rollback
- [ ] **Success Criteria**: Data migration functionality works correctly
- [ ] **Run Simulator Test**: Execute `xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` for data migration tests
- [ ] **Verify**: All data migration tests compile and pass in simulator


**Milestone 4 Success Criteria**: All integration tests pass, complete workflows work correctly, and the app is ready for production.

---

## Overall Project Success Criteria

#### Task 5: Final Comprehensive Test Suite Run
- [ ] **Reference Files**: All test files created across all milestones
- [ ] Run complete test suite: `xcodebuild test \
  -scheme UzoFitness \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'`
- [ ] Verify all tests compile successfully
- [ ] Verify all tests pass (100% success rate) except for the helper methods
- [ ] Check for any compilation errors or warnings
- [ ] Verify complete test suite execution time is under 5 minutes
- [ ] Generate and verify code coverage report (target: 80%+)
- [ ] **Success Criteria**: Complete test suite compiles and passes successfully

### Quality Gates:
- [ ] **Code Coverage**: Maintain at least 80% code coverage
- [ ] **Test Execution Time**: Complete test suite runs in under 5 minutes
- [ ] **Zero Flaky Tests**: All tests are deterministic and reliable
- [ ] **Documentation**: All new tests are properly documented
- [ ] **Code Review**: All test code has been reviewed and approved

### Definition of Done for Each Task:
1. **Task is implemented** with all success criteria met
2. **Tests pass consistently** (no flaky behavior)
3. **Code is reviewed** and follows project standards
4. **Documentation is updated** if needed
5. **Task is marked complete** in this document

---

## Timeline Summary

| Milestone | Duration | Key Deliverables |
|-----------|----------|------------------|
| 1 | Week 1 | Model tests, data validation, import/export |
| 2 | Week 2 | Service tests, external integrations |
| 3 | Week 3 | ViewModel tests, UI logic |
| 4 | Week 4 | Integration tests, end-to-end workflows |

**Total Estimated Time**: 4 weeks  
**Buffer Time**: 1 week for unexpected issues  
**Total Project Time**: 5 weeks

This task list provides a comprehensive roadmap for rebuilding the test suite while maintaining the same level of quality and coverage as the original implementation. 