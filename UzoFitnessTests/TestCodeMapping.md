# UzoFitness Test Code Mapping

This document maps each test task from the rebuild task list to the actual code files and methods they're testing. This ensures we're testing against the correct, compilable code.

## Milestone 1: Foundation & Model Tests

### 1.1 Test Infrastructure Setup

#### Task 1.1.1: Set up in-memory SwiftData containers for testing
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/*.swift` (All model files)
- `UzoFitness/Persistence/PersistenceController.swift`

**Key Methods to Test:**
- Model initialization and SwiftData `@Model` annotation
- `Identified` and `Timestamped` protocol conformance
- In-memory container creation and cleanup

#### Task 1.1.2: Create base test utilities and helper methods
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/Logger.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/DateFormatters.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/FormattingUtilities.swift`

**Key Methods to Test:**
- `AppLogger` static methods
- Date formatting utilities
- Test data factory methods

#### Task 1.1.3: Set up test data factories for all model types
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/Exercise.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplate.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/ExerciseTemplate.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/DayTemplate.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutPlan.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/PerformedExercise.swift`

**Key Methods to Test:**
- All model initializers
- `Codable` implementations where applicable
- Relationship setup

### 1.2 Core Model Validation Tests

#### Task 1.2.1: Recreate RelationshipIntegrityTests
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`

**Key Methods to Test:**
- `WorkoutSession.totalVolume` computed property
- Cascade delete behavior in SwiftData relationships
- Relationship integrity during deletion

#### Task 1.2.2: Recreate ValidationTests - WorkoutTemplate validation
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/WorkoutTemplate+Validation.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift` (ValidationError)

**Key Methods to Test:**
- `WorkoutTemplate` validation methods
- `ValidationError` enum cases and error descriptions
- Name uniqueness validation

#### Task 1.2.3: Recreate ValidationTests - ExerciseTemplate validation
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/Exercise+Validation.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/ExerciseTemplate.swift`

**Key Methods to Test:**
- Exercise parameter validation methods
- Safe update operations with rollback
- Validation error handling

#### Task 1.2.4: Recreate WorkoutDomainTests
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`

**Key Methods to Test:**
- Volume calculation methods
- `totalVolume` computed properties
- Weighted vs body-weight exercise calculations

### 1.3 Data Import/Export Tests

#### Task 1.3.1: Recreate WorkoutTemplateImportTests
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplateImportDTO.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplate.swift`

**Key Methods to Test:**
- `WorkoutTemplateImportDTO` decoding
- JSON validation and error handling
- Auto-ID generation for missing IDs

#### Task 1.3.2: Recreate JSONImportTests
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/Exercise.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift`

**Key Methods to Test:**
- `Exercise` `Codable` implementation
- ID handling in JSON import (missing vs existing)
- Error handling for malformed JSON

#### Task 1.3.3: Recreate ProgressPhotoTests
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift` (PhotoAngle)

**Key Methods to Test:**
- `ProgressPhoto` initializer and properties
- SwiftData persistence operations
- `Codable` implementation

### 1.4 Advanced Model Tests

#### Task 1.4.1: Recreate ExerciseCachingTests
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/Exercise+LastUsedValues.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/Exercise.swift`

**Key Methods to Test:**
- Last used values caching
- Auto-population of exercise parameters
- Cache update mechanisms

## Milestone 2: Service Layer Tests

### 2.1 Mock Infrastructure Setup

#### Task 2.1.1: Recreate MockPhotoLibraryService
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/PhotoServiceProtocol.swift`
- `UzoFitness/Services/PhotoService.swift`

**Key Methods to Mock:**
- `requestPhotoLibraryAuthorization()`
- `saveToPhotoLibrary(image:)`
- `pickImage()`

#### Task 2.1.2: Recreate MockFileSystemService
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/FileSystemServiceProtocol.swift`
- `UzoFitness/Services/PhotoService.swift` (DefaultFileSystemService)

**Key Methods to Mock:**
- `cacheDirectory()`
- `writeData(_:to:)`

#### Task 2.1.3: Recreate MockHealthStore and related mocks
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthStoreProtocol.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthKitTypeFactoryProtocol.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/CalendarProtocol.swift`

**Key Methods to Mock:**
- HealthKit authorization methods
- Query execution methods
- Type factory methods
- Calendar operations

### 2.2 PhotoService Tests

#### Task 2.2.1: Recreate PhotoService authorization tests
**Target Files:**
- `UzoFitness/Services/PhotoService.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/PhotoServiceProtocol.swift`

**Key Methods to Test:**
- `requestPhotoLibraryAuthorization()`
- Authorization state handling

#### Task 2.2.2: Recreate PhotoService save functionality tests
**Target Files:**
- `UzoFitness/Services/PhotoService.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/DataPersistenceServiceProtocol.swift`

**Key Methods to Test:**
- `saveToPhotoLibrary(image:)`
- `save(image:angle:date:)`
- Error handling for denied access

#### Task 2.2.3: Recreate PhotoService image picker tests
**Target Files:**
- `UzoFitness/Services/PhotoService.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/ImagePickerServiceProtocol.swift`

**Key Methods to Test:**
- `pickImage()`
- Image selection and cancellation handling

### 2.3 HealthKitManager Tests

#### Task 2.3.1: Recreate HealthKit authorization tests
**Target Files:**
- `UzoFitness/Services/HealthKitManager.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthStoreProtocol.swift`

**Key Methods to Test:**
- `requestAuthorization(completion:)`
- Authorization success/failure scenarios

#### Task 2.3.2: Recreate HealthKit body mass tests
**Target Files:**
- `UzoFitness/Services/HealthKitManager.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`

**Key Methods to Test:**
- `fetchLatestBodyMassInPounds(completion:)`
- `fetchBodyMassInPounds(on:completion:)`
- Weight conversion (kg to lbs)

#### Task 2.3.3: Recreate HealthKit body fat tests
**Target Files:**
- `UzoFitness/Services/HealthKitManager.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`

**Key Methods to Test:**
- `fetchLatestBodyFat(completion:)`
- `fetchBodyFat(on:completion:)`
- Percentage value handling

### 2.4 Data Persistence Tests

#### Task 2.4.1: Recreate MockDataPersistenceService
**Target Files:**
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/DataPersistenceServiceProtocol.swift`
- `UzoFitness/Persistence/PersistenceController.swift`

**Key Methods to Mock:**
- `insert(_:)`
- `save()`

#### Task 2.4.2: Test data persistence integration
**Target Files:**
- `UzoFitness/Persistence/PersistenceController.swift`
- All model files in `UzoFitnessCore/Sources/UzoFitnessCore/Models/`

**Key Methods to Test:**
- SwiftData operations with all model types
- Relationship persistence
- Cascade operations

## Milestone 3: ViewModel Tests

### 3.1 LibraryViewModel Tests

#### Task 3.1.1: Recreate LibraryViewModel initialization tests
**Target Files:**
- `UzoFitness/ViewModels/LibraryViewModel.swift`

**Key Methods to Test:**
- `init(modelContext:)`
- Default state initialization
- Published property initial values

#### Task 3.1.2: Recreate LibraryViewModel template management tests
**Target Files:**
- `UzoFitness/ViewModels/LibraryViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/WorkoutTemplate+HelperMethods.swift`

**Key Methods to Test:**
- `createTemplate(name:summary:)`
- `duplicateTemplate(id:)`
- `deleteTemplate(id:)`
- Template validation and error handling

#### Task 3.1.3: Recreate LibraryViewModel exercise management tests
**Target Files:**
- `UzoFitness/ViewModels/LibraryViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/Exercise+HelperMethods.swift`

**Key Methods to Test:**
- `createExercise(name:category:instructions:mediaAssetID:)`
- `deleteExercise(id:)`
- Exercise catalog management

#### Task 3.1.4: Recreate LibraryViewModel import/export tests
**Target Files:**
- `UzoFitness/ViewModels/LibraryViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplateImportDTO.swift`

**Key Methods to Test:**
- JSON import/export functionality
- Error handling for malformed data
- Data validation during import

### 3.2 HistoryViewModel Tests

#### Task 3.2.1: Recreate HistoryViewModel initialization tests
**Target Files:**
- `UzoFitness/ViewModels/HistoryViewModel.swift`

**Key Methods to Test:**
- `init(modelContext:)`
- Calendar data initialization
- Default state setup

#### Task 3.2.2: Recreate HistoryViewModel workout summary tests
**Target Files:**
- `UzoFitness/ViewModels/HistoryViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutSession.swift`

**Key Methods to Test:**
- Workout summary creation
- Default title handling
- Summary calculations

#### Task 3.2.3: Recreate HistoryViewModel date selection tests
**Target Files:**
- `UzoFitness/ViewModels/HistoryViewModel.swift`

**Key Methods to Test:**
- Date selection functionality
- Empty state handling
- Selection clearing

### 3.3 LoggingViewModel Tests

#### Task 3.3.1: Recreate LoggingViewModel plan selection tests
**Target Files:**
- `UzoFitness/ViewModels/LoggingViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutPlan.swift`

**Key Methods to Test:**
- Plan selection functionality
- Invalid plan ID handling
- Active plan management

#### Task 3.3.2: Recreate LoggingViewModel day selection tests
**Target Files:**
- `UzoFitness/ViewModels/LoggingViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/DayTemplate.swift`

**Key Methods to Test:**
- Day selection within plans
- Rest day detection
- Day template handling

#### Task 3.3.3: Recreate LoggingViewModel exercise logging tests
**Target Files:**
- `UzoFitness/ViewModels/LoggingViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/SessionExercise.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/CompletedSet.swift`

**Key Methods to Test:**
- Set logging functionality
- Invalid exercise ID handling
- Exercise session management

### 3.4 ProgressViewModel Tests

#### Task 3.4.1: Recreate ProgressViewModel state tests
**Target Files:**
- `UzoFitness/ViewModels/ProgressViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`

**Key Methods to Test:**
- Empty state handling
- Photo retrieval by angle
- Exercise options generation

#### Task 3.4.2: Recreate ProgressViewModel metrics tests
**Target Files:**
- `UzoFitness/ViewModels/ProgressViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Services/ProgressAnalysisLogic.swift`

**Key Methods to Test:**
- Exercise trend calculations
- Body metrics formatting
- Nil value handling

#### Task 3.4.3: Recreate ProgressViewModel photo management tests
**Target Files:**
- `UzoFitness/ViewModels/ProgressViewModel.swift`
- `UzoFitness/Services/PhotoService.swift`

**Key Methods to Test:**
- Photo addition functionality
- Cache and persistence integration
- ViewModel state updates

### 3.5 SettingsViewModel Tests

#### Task 3.5.1: Recreate SettingsViewModel initialization tests
**Target Files:**
- `UzoFitness/ViewModels/SettingsViewModel.swift`

**Key Methods to Test:**
- `init(healthKitManager:photoService:)`
- Dependency injection
- Initial state setup

#### Task 3.5.2: Recreate SettingsViewModel permission tests
**Target Files:**
- `UzoFitness/ViewModels/SettingsViewModel.swift`
- `UzoFitness/Services/HealthKitManager.swift`
- `UzoFitness/Services/PhotoService.swift`

**Key Methods to Test:**
- HealthKit permission requests
- Photo library permission requests
- Permission state handling

#### Task 3.5.3: Recreate SettingsViewModel backup tests
**Target Files:**
- `UzoFitness/ViewModels/SettingsViewModel.swift`

**Key Methods to Test:**
- Backup operation handling
- Battery protection logic
- Success/failure scenarios

## Milestone 4: Integration & End-to-End Tests

### 4.1 Workflow Integration Tests

#### Task 4.1.1: Create workout creation workflow test
**Target Files:**
- All ViewModels in `UzoFitness/ViewModels/`
- All Models in `UzoFitnessCore/Sources/UzoFitnessCore/Models/`
- `UzoFitness/Persistence/PersistenceController.swift`

**Key Workflows to Test:**
- Template creation → Plan activation → Workout logging → Session completion
- Data flow through all ViewModels
- Persistence integrity

#### Task 4.1.2: Create progress tracking workflow test
**Target Files:**
- `UzoFitness/ViewModels/ProgressViewModel.swift`
- `UzoFitness/Services/PhotoService.swift`
- `UzoFitness/Services/HealthKitManager.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/ProgressPhoto.swift`

**Key Workflows to Test:**
- Photo capture → Storage → HealthKit integration → Metrics calculation
- End-to-end progress tracking

#### Task 4.1.3: Create data import/export workflow test
**Target Files:**
- `UzoFitness/ViewModels/LibraryViewModel.swift`
- `UzoFitnessCore/Sources/UzoFitnessCore/Models/WorkoutTemplateImportDTO.swift`
- All model files with `Codable` conformance

**Key Workflows to Test:**
- JSON import → Validation → Persistence → Export
- Data integrity maintenance

### 4.2 Performance Tests

#### Task 4.2.1: Create large dataset performance tests
**Target Files:**
- All ViewModels and Models
- `UzoFitness/Persistence/PersistenceController.swift`

**Key Areas to Test:**
- Large dataset handling
- UI responsiveness
- Memory usage

#### Task 4.2.2: Create concurrent operation tests
**Target Files:**
- All ViewModels
- Service classes
- Persistence layer

**Key Areas to Test:**
- Concurrent operations
- Race condition prevention
- Data consistency

### 4.3 Error Recovery Tests

#### Task 4.3.1: Create error recovery workflow tests
**Target Files:**
- All ViewModels and Services
- Error handling throughout the app

**Key Areas to Test:**
- Graceful error recovery
- User data protection
- Error messaging

#### Task 4.3.2: Create data corruption recovery tests
**Target Files:**
- `UzoFitness/Persistence/PersistenceController.swift`
- All model files
- Backup/restore functionality

**Key Areas to Test:**
- Data corruption detection
- Recovery mechanisms
- Backup restoration

### 4.4 Accessibility Tests

#### Task 4.4.1: Create accessibility compliance tests
**Target Files:**
- All Views in `UzoFitness/Views/`
- SwiftUI accessibility features

**Key Areas to Test:**
- VoiceOver compatibility
- Dynamic Type support
- High contrast mode
- Accessibility labels

### 4.5 Final Integration Tests

#### Task 4.5.1: Create complete app lifecycle test
**Target Files:**
- `UzoFitness/UzoFitnessApp.swift`
- All major app components

**Key Areas to Test:**
- App startup
- Screen navigation
- Background/foreground transitions

#### Task 4.5.2: Create data migration test
**Target Files:**
- `UzoFitness/Persistence/PersistenceController.swift`
- All model files
- Migration logic

**Key Areas to Test:**
- Data migration scenarios
- Version compatibility
- Migration rollback

## Key Dependencies and Imports

### Core Dependencies:
- `SwiftData` - For all model persistence
- `UzoFitnessCore` - For all core models and protocols
- `HealthKit` - For health data integration
- `PhotosUI` - For photo library access
- `Combine` - For reactive programming in ViewModels

### Testing Dependencies:
- `XCTest` - For unit testing framework
- `@testable import UzoFitness` - For testing app components
- `@testable import UzoFitnessCore` - For testing core components

### Mock Dependencies:
- All protocol-based services can be mocked
- SwiftData in-memory containers for testing
- Mock implementations of external services

## Compilation Requirements

### For Model Tests:
- All models must conform to `Identified` and `Timestamped` protocols
- SwiftData `@Model` annotations must be present
- `Codable` implementations where needed

### For Service Tests:
- All services must use protocol-based dependency injection
- Mock implementations must conform to the same protocols
- Error handling must be consistent

### For ViewModel Tests:
- All ViewModels must be `@MainActor` classes
- Published properties must be properly declared
- Async/await patterns must be used correctly

### For Integration Tests:
- All components must work together without conflicts
- Data flow must be consistent across the app
- Error propagation must work correctly

This mapping ensures that all tests are written against the actual, compilable code and that the test suite accurately reflects the current state of the application.

## Test Setup Reference Files

The following files should be examined to understand how to set up the test infrastructure:

### Core Test Infrastructure Files

#### 1. Persistence Setup
**File**: `UzoFitness/Persistence/PersistenceController.swift`
**Purpose**: Shows how to create in-memory SwiftData containers for testing
**Key Methods to Reference**:
- `init(inMemory: Bool = false)` - Shows schema setup and container creation
- `deleteAllData()` - Useful for test cleanup
- `addSampleData()` - Shows how to create test data
- Generic CRUD operations for testing data persistence

#### 2. Logging Infrastructure
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/Logger.swift`
**Purpose**: Shows the logging system used throughout the app
**Key Methods to Reference**:
- `AppLogger.debug()`, `AppLogger.info()`, `AppLogger.error()` - For test logging
- Category-based logging for different test areas

#### 3. Date and Formatting Utilities
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/DateFormatters.swift`
**Purpose**: Shows date formatting utilities used in tests
**Key Methods to Reference**:
- `DateFormatter.monthYear`, `DateFormatter.dayMonth`, etc. - For date testing
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/FormattingUtilities.swift`
**Purpose**: Shows value formatting utilities
**Key Methods to Reference**:
- `FormattingUtilities.formatWeight()`, `FormattingUtilities.formatVolume()` - For value testing

#### 4. Protocol Definitions
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Protocols/Protocols.swift`
**Purpose**: Shows the base protocols all models conform to
**Key Protocols to Reference**:
- `Identified` - For UUID and Identifiable conformance
- `Timestamped` - For creation timestamp tracking
- `entityName` extension - For SwiftData entity names

#### 5. Error Types
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Models/Enums.swift`
**Purpose**: Shows validation errors and other enums used in testing
**Key Types to Reference**:
- `ValidationError` enum - For validation testing
- `ExerciseCategory`, `PhotoAngle`, `Weekday` enums - For model testing

### Service Protocol Files

#### 6. HealthKit Protocols
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthStoreProtocol.swift`
**Purpose**: Shows HealthKit abstraction for mocking
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/QueryExecutorProtocol.swift`
**Purpose**: Shows query execution abstraction
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/HealthKitTypeFactoryProtocol.swift`
**Purpose**: Shows HealthKit type factory abstraction
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/CalendarProtocol.swift`
**Purpose**: Shows calendar abstraction

#### 7. Photo Service Protocols
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/PhotoServiceProtocol.swift`
**Purpose**: Shows photo service abstraction
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/FileSystemServiceProtocol.swift`
**Purpose**: Shows file system abstraction
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/ImagePickerServiceProtocol.swift`
**Purpose**: Shows image picker abstraction
**File**: `UzoFitnessCore/Sources/UzoFitnessCore/Services/DataPersistenceServiceProtocol.swift`
**Purpose**: Shows data persistence abstraction

### Model Files for Test Data Creation

#### 8. Core Models
**Files**: All files in `UzoFitnessCore/Sources/UzoFitnessCore/Models/`
**Purpose**: Show model structure and relationships for test data creation
**Key Files**:
- `Exercise.swift` - Exercise model with caching properties
- `WorkoutTemplate.swift` - Template model with relationships
- `WorkoutSession.swift` - Session model with volume calculations
- `SessionExercise.swift` - Session exercise model with sets
- `CompletedSet.swift` - Completed set model
- `ProgressPhoto.swift` - Progress photo model
- `ExerciseTemplate.swift` - Exercise template model
- `DayTemplate.swift` - Day template model
- `WorkoutPlan.swift` - Workout plan model
- `PerformedExercise.swift` - Performed exercise model

### Extension Files for Business Logic

#### 9. Model Extensions
**Files**: All files in `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/`
**Purpose**: Show business logic and validation methods
**Key Files**:
- `Exercise+HelperMethods.swift` - Exercise helper methods
- `Exercise+Validation.swift` - Exercise validation logic
- `Exercise+LastUsedValues.swift` - Caching logic
- `WorkoutTemplate+HelperMethods.swift` - Template helper methods
- `WorkoutTemplate+Validation.swift` - Template validation logic
- `DayTemplate+Superset.swift` - Superset logic
- `ProgressPhoto+DuplicateDetection.swift` - Duplicate detection

### Service Implementation Files

#### 10. Service Implementations
**File**: `UzoFitness/Services/PhotoService.swift`
**Purpose**: Shows photo service implementation and error handling
**File**: `UzoFitness/Services/HealthKitManager.swift`
**Purpose**: Shows HealthKit manager implementation and error handling

### ViewModel Files for UI Logic Testing

#### 11. ViewModel Implementations
**Files**: All files in `UzoFitness/ViewModels/`
**Purpose**: Show ViewModel structure and state management
**Key Files**:
- `LibraryViewModel.swift` - Template and exercise management
- `HistoryViewModel.swift` - Workout history and date selection
- `LoggingViewModel.swift` - Workout logging and plan management
- `ProgressViewModel.swift` - Progress tracking and metrics
- `SettingsViewModel.swift` - Settings and permissions

### Test Infrastructure Examples

#### 12. Existing Test Files
**File**: `UzoFitnessTests/TestSummary.md`
**Purpose**: Shows the structure and intent of all original tests
**File**: `UzoFitnessUITests/UzoFitnessUITests.swift`
**Purpose**: Shows basic UI test setup
**File**: `UzoFitnessCore/Tests/UzoFitnessCoreTests/UzoFitnessCoreTests.swift`
**Purpose**: Shows basic unit test setup for core module

### Test Setup Checklist

When setting up tests, reference these files to ensure proper setup:

1. **SwiftData Setup**: Use `PersistenceController.swift` as reference for in-memory containers
2. **Mock Creation**: Use service protocol files to create proper mocks
3. **Test Data**: Use model files to understand required properties and relationships
4. **Business Logic**: Use extension files to understand validation and helper methods
5. **Error Handling**: Use `Enums.swift` for validation errors and service error types
6. **Logging**: Use `Logger.swift` for consistent test logging
7. **Formatting**: Use utility files for value formatting in tests

### Test File Organization

Based on the existing structure, organize test files as follows:

```
UzoFitnessTests/
├── Models/
│   ├── RelationshipIntegrityTests.swift
│   ├── ValidationTests.swift
│   ├── WorkoutDomainTests.swift
│   ├── WorkoutTemplateImportTests.swift
│   ├── ProgressPhotoTests.swift
│   ├── JSONImportTests.swift
│   └── ExerciseCachingTests.swift
├── Services/
│   ├── PhotoServiceTests.swift
│   ├── HealthKitManagerTests.swift
│   └── MockImplementations/
│       ├── MockPhotoLibraryService.swift
│       ├── MockFileSystemService.swift
│       ├── MockHealthStore.swift
│       └── MockDataPersistenceService.swift
├── ViewModels/
│   ├── LibraryViewModelTests.swift
│   ├── HistoryViewModelTests.swift
│   ├── LoggingViewModelTests.swift
│   ├── ProgressViewModelTests.swift
│   └── SettingsViewModelTests.swift
└── Utilities/
    ├── TestDataFactories.swift
    ├── TestHelpers.swift
    └── InMemoryPersistenceController.swift
```

This file organization matches the existing test structure and provides clear separation of concerns for different types of tests. 