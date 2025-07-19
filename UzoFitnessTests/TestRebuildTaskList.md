# UzoFitness Test Suite Rebuild Task List

This document provides a detailed breakdown of tasks needed to recreate the test suite after the refactor, organized by milestones with clear success criteria.

## Overview

**Total Tasks**: 47 tasks across 4 milestones  
**Estimated Timeline**: 3-4 weeks  
**Priority Order**: Model Tests → Service Tests → ViewModel Tests → Integration Tests

---

## Milestone 1: Foundation & Model Tests (Week 1)
**Goal**: Establish testing infrastructure and validate core data models

### 1.1 Test Infrastructure Setup
- [ ] **Task 1.1.1**: Set up in-memory SwiftData containers for testing
  - **Success Criteria**: 
    - In-memory containers work without file system dependencies
    - All model types can be inserted and fetched
    - Containers are properly cleaned up after each test
  - **Test**: `testInMemoryContainerSetup()` - Verify container creation and cleanup

- [ ] **Task 1.1.2**: Create base test utilities and helper methods
  - **Success Criteria**:
    - Helper methods for creating test data exist
    - Async/await support is properly configured
    - Mock factory methods are available
  - **Test**: `testTestUtilities()` - Verify helper methods work correctly

- [ ] **Task 1.1.3**: Set up test data factories for all model types
  - **Success Criteria**:
    - Factory methods for Exercise, WorkoutTemplate, SessionExercise, etc.
    - Factories create valid, realistic test data
    - Factories support customization for specific test scenarios
  - **Test**: `testDataFactories()` - Verify all factories create valid objects

### 1.2 Core Model Validation Tests
- [ ] **Task 1.2.1**: Recreate RelationshipIntegrityTests
  - **Success Criteria**:
    - `testCascadeDeleteSessionRemovesChildren()` passes
    - Deleting WorkoutSession removes all child objects
    - No orphaned SessionExercise or CompletedSet objects remain
  - **Test**: Verify cascade delete behavior works correctly

- [ ] **Task 1.2.2**: Recreate ValidationTests - WorkoutTemplate validation
  - **Success Criteria**:
    - `testUniqueWorkoutTemplateName()` passes
    - `testWorkoutTemplateNameValidation()` passes
    - `testWorkoutTemplateNameSuggestion()` passes
    - Duplicate names are rejected with appropriate errors
  - **Test**: Verify template name validation and uniqueness constraints

- [ ] **Task 1.2.3**: Recreate ValidationTests - ExerciseTemplate validation
  - **Success Criteria**:
    - All parameter validation tests pass (reps, sets, weight, position)
    - `testExerciseTemplateSafeUpdates()` passes with rollback on failure
    - Invalid parameters are rejected with ValidationError
  - **Test**: Verify exercise template parameter validation

- [ ] **Task 1.2.4**: Recreate WorkoutDomainTests
  - **Success Criteria**:
    - `testTotalVolumePerExerciseAndSession()` passes
    - `testAddWeightedVolume()` passes
    - Volume calculations are mathematically correct
    - Both body-weight and weighted exercises calculate correctly
  - **Test**: Verify workout volume calculations

### 1.3 Data Import/Export Tests
- [ ] **Task 1.3.1**: Recreate WorkoutTemplateImportTests
  - **Success Criteria**:
    - `testValidWorkoutTemplateImport()` passes
    - `testMinimalValidWorkoutTemplate()` passes
    - JSON validation rejects invalid templates
    - Auto-ID generation works correctly
  - **Test**: Verify JSON import functionality with various scenarios

- [ ] **Task 1.3.2**: Recreate JSONImportTests
  - **Success Criteria**:
    - `testExerciseJSONImport_WithMissingID()` passes
    - `testExerciseJSONImport_WithExistingID()` passes
    - Import handles both scenarios correctly
    - Error handling works for malformed JSON
  - **Test**: Verify exercise JSON import functionality

- [ ] **Task 1.3.3**: Recreate ProgressPhotoTests
  - **Success Criteria**:
    - `testInitializerSetsAllProperties()` passes
    - `testInsertAndFetchProgressPhoto()` passes
    - SwiftData persistence works correctly
    - Unique IDs are generated properly
  - **Test**: Verify progress photo model functionality

### 1.4 Advanced Model Tests
- [ ] **Task 1.4.1**: Recreate ExerciseCachingTests
  - **Success Criteria**:
    - All caching behavior tests pass
    - Auto-population works correctly
    - Cache updates after workout completion
    - Manual overrides work as expected
  - **Test**: Verify exercise caching and auto-population functionality

**Milestone 1 Success Criteria**: All model tests pass, data integrity is maintained, and business logic works correctly.

---

## Milestone 2: Service Layer Tests (Week 2)
**Goal**: Validate external service integrations and data persistence

### 2.1 Mock Infrastructure Setup
- [ ] **Task 2.1.1**: Recreate MockPhotoLibraryService
  - **Success Criteria**:
    - Mocks Photos framework authorization
    - Mocks image saving functionality
    - Supports different authorization states
    - Tracks method calls for verification
  - **Test**: `testMockPhotoLibraryService()` - Verify mock behavior

- [ ] **Task 2.1.2**: Recreate MockFileSystemService
  - **Success Criteria**:
    - Mocks file system operations
    - Simulates cache directory access
    - Tracks write operations
    - Supports error simulation
  - **Test**: `testMockFileSystemService()` - Verify mock behavior

- [ ] **Task 2.1.3**: Recreate MockHealthStore and related mocks
  - **Success Criteria**:
    - Mocks HealthKit authorization
    - Mocks query execution
    - Supports different HealthKit states
    - Tracks method calls for verification
  - **Test**: `testMockHealthKitServices()` - Verify mock behavior

### 2.2 PhotoService Tests
- [ ] **Task 2.2.1**: Recreate PhotoService authorization tests
  - **Success Criteria**:
    - `testRequestPhotoLibraryAuthorization_WhenAlreadyAuthorized_ReturnsAuthorized()` passes
    - `testRequestPhotoLibraryAuthorization_WhenNotDetermined_RequestsAuthorization()` passes
    - `testRequestPhotoLibraryAuthorization_WhenDenied_ReturnsDenied()` passes
    - All authorization states are handled correctly
  - **Test**: Verify photo library authorization handling

- [ ] **Task 2.2.2**: Recreate PhotoService save functionality tests
  - **Success Criteria**:
    - `testSaveToPhotoLibrary_WhenAuthorized_SavesImage()` passes
    - `testSaveToCache_ValidImage_SavesSuccessfully()` passes
    - Error handling works for denied access
    - File system errors are handled gracefully
  - **Test**: Verify image saving functionality

- [ ] **Task 2.2.3**: Recreate PhotoService image picker tests
  - **Success Criteria**:
    - `testPickImage_UserSelectsImage_ReturnsImage()` passes
    - `testPickImage_UserCancels_ReturnsNil()` passes
    - Progress photo saving works correctly
    - Invalid image data is handled properly
  - **Test**: Verify image picker integration

### 2.3 HealthKitManager Tests
- [ ] **Task 2.3.1**: Recreate HealthKit authorization tests
  - **Success Criteria**:
    - `testRequestAuthorizationSuccess()` passes
    - `testRequestAuthorizationFailure()` passes
    - `testRequestAuthorizationTypeUnavailable()` passes
    - All authorization scenarios are handled
  - **Test**: Verify HealthKit authorization handling

- [ ] **Task 2.3.2**: Recreate HealthKit body mass tests
  - **Success Criteria**:
    - `testFetchLatestBodyMassInPoundsSuccess()` passes
    - `testFetchBodyMassInPoundsOnSpecificDate()` passes
    - Weight conversion (kg to lbs) is accurate
    - Error handling works for unavailable types
  - **Test**: Verify body mass data retrieval

- [ ] **Task 2.3.3**: Recreate HealthKit body fat tests
  - **Success Criteria**:
    - `testFetchLatestBodyFatSuccess()` passes
    - `testFetchBodyFatOnSpecificDate()` passes
    - Percentage values are handled correctly
    - No data scenarios are handled gracefully
  - **Test**: Verify body fat data retrieval

### 2.4 Data Persistence Tests
- [ ] **Task 2.4.1**: Recreate MockDataPersistenceService
  - **Success Criteria**:
    - Mocks SwiftData operations
    - Tracks insert and save operations
    - Supports error simulation
    - Verifies data persistence behavior
  - **Test**: `testMockDataPersistenceService()` - Verify mock behavior

- [ ] **Task 2.4.2**: Test data persistence integration
  - **Success Criteria**:
    - All model types can be persisted
    - Relationships are maintained
    - Cascade operations work correctly
    - Error handling works for persistence failures
  - **Test**: Verify end-to-end data persistence

**Milestone 2 Success Criteria**: All service tests pass, external integrations work correctly, and error handling is robust.

---

## Milestone 3: ViewModel Tests (Week 3)
**Goal**: Validate UI logic and state management

### 3.1 LibraryViewModel Tests
- [ ] **Task 3.1.1**: Recreate LibraryViewModel initialization tests
  - **Success Criteria**:
    - `testInitialization_SetsDefaultState()` passes
    - ViewModel initializes with correct default values
    - Dependencies are properly injected
    - State is consistent after initialization
  - **Test**: Verify ViewModel initialization

- [ ] **Task 3.1.2**: Recreate LibraryViewModel template management tests
  - **Success Criteria**:
    - `testCreateTemplate_ValidData_CreatesTemplate()` passes
    - `testCreateTemplate_DuplicateName_SetsError()` passes
    - `testDuplicateTemplate_ValidTemplate_CreatesCopy()` passes
    - `testDeleteTemplate_ValidTemplate_RemovesTemplate()` passes
  - **Test**: Verify template CRUD operations

- [ ] **Task 3.1.3**: Recreate LibraryViewModel exercise management tests
  - **Success Criteria**:
    - `testCreateExercise_ValidData_CreatesExercise()` passes
    - `testDeleteExercise_ExerciseInUse_SetsError()` passes
    - Exercise catalog is properly managed
    - Error handling works for invalid operations
  - **Test**: Verify exercise management functionality

- [ ] **Task 3.1.4**: Recreate LibraryViewModel import/export tests
  - **Success Criteria**:
    - `testImportExercises_ValidJSON_ImportsSuccessfully()` passes
    - `testImportExercises_InvalidJSON_SetsError()` passes
    - JSON import/export works correctly
    - Error handling for malformed data
  - **Test**: Verify import/export functionality

### 3.2 HistoryViewModel Tests
- [ ] **Task 3.2.1**: Recreate HistoryViewModel initialization tests
  - **Success Criteria**:
    - `testInitialization_SetsDefaultState()` passes
    - Calendar data is properly initialized
    - Default state is consistent
  - **Test**: Verify HistoryViewModel initialization

- [ ] **Task 3.2.2**: Recreate HistoryViewModel workout summary tests
  - **Success Criteria**:
    - `testWorkoutSessionSummary_CreatesCorrectSummary()` passes
    - `testWorkoutSessionSummary_EmptyTitle_UsesDefaultTitle()` passes
    - Summary calculations are accurate
    - Default values are applied correctly
  - **Test**: Verify workout summary functionality

- [ ] **Task 3.2.3**: Recreate HistoryViewModel date selection tests
  - **Success Criteria**:
    - `testSelectDate_WithNoWorkoutData_SetsSelectedDateWithEmptyDetails()` passes
    - `testClearSelection_ClearsSelectedDateAndDetails()` passes
    - Date selection works correctly
    - Empty states are handled properly
  - **Test**: Verify date selection functionality

### 3.3 LoggingViewModel Tests
- [ ] **Task 3.3.1**: Recreate LoggingViewModel plan selection tests
  - **Success Criteria**:
    - `testSelectPlan_ValidPlan_SetsActivePlan()` passes
    - `testSelectPlan_InvalidPlanID_SetsError()` passes
    - Plan selection works correctly
    - Error handling for invalid plans
  - **Test**: Verify plan selection functionality

- [ ] **Task 3.3.2**: Recreate LoggingViewModel day selection tests
  - **Success Criteria**:
    - `testSelectDay_ValidDay_SetsSelectedDay()` passes
    - Day selection within plans works
    - Rest day detection works correctly
  - **Test**: Verify day selection functionality

- [ ] **Task 3.3.3**: Recreate LoggingViewModel exercise logging tests
  - **Success Criteria**:
    - `testAddSet_InvalidExerciseID_SetsError()` passes
    - Set logging works correctly
    - Error handling for invalid exercises
  - **Test**: Verify exercise logging functionality

### 3.4 ProgressViewModel Tests
- [ ] **Task 3.4.1**: Recreate ProgressViewModel state tests
  - **Success Criteria**:
    - `testGetPhotosForAngle_WithEmptyState_ReturnsEmptyArray()` passes
    - `testGetExerciseOptions_WithEmptyState_ReturnsEmptyArray()` passes
    - Empty states are handled correctly
  - **Test**: Verify empty state handling

- [ ] **Task 3.4.2**: Recreate ProgressViewModel metrics tests
  - **Success Criteria**:
    - `testExerciseTrend_CalculatesMetricsCorrectly()` passes
    - `testBodyMetrics_FormatsValuesCorrectly()` passes
    - `testBodyMetrics_HandlesNilValues()` passes
    - Metrics calculations are accurate
  - **Test**: Verify metrics calculation and formatting

- [ ] **Task 3.4.3**: Recreate ProgressViewModel photo management tests
  - **Success Criteria**:
    - `testAddPhoto_SavesToCacheAndUpdatesViewModel()` passes
    - Photo addition works correctly
    - ViewModel state updates properly
  - **Test**: Verify photo management functionality

### 3.5 SettingsViewModel Tests
- [ ] **Task 3.5.1**: Recreate SettingsViewModel initialization tests
  - **Success Criteria**:
    - `testViewModel_InitializationWithDependencies()` passes
    - Dependencies are properly injected
    - Initial state is correct
  - **Test**: Verify SettingsViewModel initialization

- [ ] **Task 3.5.2**: Recreate SettingsViewModel permission tests
  - **Success Criteria**:
    - `testViewModel_HandleHealthKitAccessIntent()` passes
    - `testViewModel_HandlePhotoAccessIntent()` passes
    - Permission requests work correctly
  - **Test**: Verify permission handling

- [ ] **Task 3.5.3**: Recreate SettingsViewModel backup tests
  - **Success Criteria**:
    - `testViewModel_HandleBackupIntent_Success()` passes
    - `testViewModel_HandleBackupIntent_LowBattery()` passes
    - Backup operations work correctly
    - Battery protection works
  - **Test**: Verify backup functionality

**Milestone 3 Success Criteria**: All ViewModel tests pass, UI logic works correctly, and state management is robust.

---

## Milestone 4: Integration & End-to-End Tests (Week 4)
**Goal**: Validate complete workflows and system integration

### 4.1 Workflow Integration Tests
- [ ] **Task 4.1.1**: Create workout creation workflow test
  - **Success Criteria**:
    - Complete workflow from template creation to workout completion
    - All ViewModels work together correctly
    - Data flows through the system properly
    - No data loss or corruption
  - **Test**: End-to-end workout creation and logging

- [ ] **Task 4.1.2**: Create progress tracking workflow test
  - **Success Criteria**:
    - Photo capture and storage works
    - HealthKit integration provides data
    - Progress metrics are calculated correctly
    - Data persistence is reliable
  - **Test**: End-to-end progress tracking workflow

- [ ] **Task 4.1.3**: Create data import/export workflow test
  - **Success Criteria**:
    - JSON import works for all data types
    - Export functionality works correctly
    - Data integrity is maintained
    - Error handling works for corrupted data
  - **Test**: End-to-end data import/export workflow

### 4.2 Performance Tests
- [ ] **Task 4.2.1**: Create large dataset performance tests
  - **Success Criteria**:
    - App performs well with 1000+ exercises
    - App performs well with 100+ workout sessions
    - UI remains responsive
    - Memory usage is reasonable
  - **Test**: Performance with large datasets

- [ ] **Task 4.2.2**: Create concurrent operation tests
  - **Success Criteria**:
    - Multiple operations can run concurrently
    - No race conditions occur
    - Data consistency is maintained
    - Error handling works under load
  - **Test**: Concurrent operation handling

### 4.3 Error Recovery Tests
- [ ] **Task 4.3.1**: Create error recovery workflow tests
  - **Success Criteria**:
    - App recovers gracefully from errors
    - User data is not lost
    - Error messages are helpful
    - App can continue functioning
  - **Test**: Error recovery scenarios

- [ ] **Task 4.3.2**: Create data corruption recovery tests
  - **Success Criteria**:
    - App detects corrupted data
    - Recovery mechanisms work
    - User is informed appropriately
    - Data can be restored from backup
  - **Test**: Data corruption handling

### 4.4 Accessibility Tests
- [ ] **Task 4.4.1**: Create accessibility compliance tests
  - **Success Criteria**:
    - VoiceOver works correctly
    - Dynamic Type is supported
    - High contrast mode works
    - Accessibility labels are present
  - **Test**: Accessibility compliance

### 4.5 Final Integration Tests
- [ ] **Task 4.5.1**: Create complete app lifecycle test
  - **Success Criteria**:
    - App starts correctly
    - All screens are accessible
    - Navigation works properly
    - App can be backgrounded and foregrounded
  - **Test**: Complete app lifecycle

- [ ] **Task 4.5.2**: Create data migration test
  - **Success Criteria**:
    - Old data can be migrated
    - No data loss during migration
    - App works with migrated data
    - Migration is reversible
  - **Test**: Data migration functionality

**Milestone 4 Success Criteria**: All integration tests pass, complete workflows work correctly, and the app is ready for production.

---

## Success Criteria Summary

### Overall Project Success Criteria:
1. **All 47 tasks are completed** and marked as done
2. **All unit tests pass** with 100% success rate
3. **Test coverage is maintained** at the same level as original
4. **Performance is acceptable** (no regression in test execution time)
5. **Documentation is updated** to reflect new test structure
6. **CI/CD pipeline works** with new test suite

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

## Risk Mitigation

### High-Risk Tasks:
- **Task 1.4.1** (ExerciseCachingTests): Complex caching logic
- **Task 2.3.2** (HealthKit body mass tests): External dependency
- **Task 3.1.2** (Template management): Complex business logic
- **Task 4.1.1** (Workflow integration): End-to-end complexity

### Mitigation Strategies:
1. **Start with simple tests** and build complexity gradually
2. **Use comprehensive mocking** for external dependencies
3. **Break complex tasks** into smaller subtasks
4. **Regular testing** throughout development
5. **Pair programming** for complex logic
6. **Code review** for all test implementations

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