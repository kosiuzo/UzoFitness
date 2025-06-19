# UzoFitness Models Architecture Summary

## Overview
UzoFitness is a comprehensive fitness tracking app built with SwiftData that manages workout templates, exercise execution, progress tracking, and fitness history. The app follows a template-based approach where users create reusable workout templates and execute them as workout sessions.

## Core Architecture Patterns

### Protocols
- **Identified**: Provides UUID-based identification and Identifiable/Hashable conformance
- **Timestamped**: Adds creation timestamp tracking to models

### Domain Layers
1. **Template Layer**: Reusable workout and exercise templates
2. **Execution Layer**: Runtime workout sessions and exercise tracking
3. **Progress Layer**: Historical data and progress photos
4. **Core Layer**: Basic exercise definitions and metadata

## Model Relationships Diagram

```
WorkoutTemplate (1) ←→ (M) DayTemplate (1) ←→ (M) ExerciseTemplate (M) → (1) Exercise
          │
          └── (1) ←→ (M) WorkoutPlan (1) ←→ (M) WorkoutSession (1) ←→ (M) SessionExercise (1) ←→ (M) CompletedSet
                                       │                          │
                                       └────────── PerformedExercise ────────┘

ProgressPhoto (standalone)
```

## Detailed Models

### 1. Core Exercise Model

#### Exercise
**Purpose**: Master catalog of all available exercises
**Properties**:
- `id: UUID` (unique identifier)
- `name: String` (unique exercise name)
- `category: ExerciseCategory` (strength, cardio, mobility, balance)
- `instructions: String` (exercise instructions)
- `mediaAssetID: String?` (optional media reference)

**Relationships**:
- `completedSets: [CompletedSet]` (all completed sets for this exercise)
- `performedRecords: [PerformedExercise]` (all performance records)

**Key Methods**: Validation and helper methods for exercise management

### 2. Template Layer (Planning & Reusability)

#### WorkoutTemplate
**Purpose**: Reusable workout blueprint that can be used multiple times
**Properties**:
- `id: UUID` (unique identifier)
- `name: String` (unique template name)
- `summary: String` (template description)
- `createdAt: Date` (creation timestamp)

**Relationships**:
- `dayTemplates: [DayTemplate]` (days within the workout template)  
- `plans: [WorkoutPlan]` (all plans instantiated from this template)

**Key Features**:
- Name uniqueness validation
- Template creation and management
- Suggested naming for duplicates

#### DayTemplate
**Purpose**: Represents a single day's workout within a template
**Properties**:
- `id: UUID` (unique identifier)
- `weekday: Weekday` (Sunday-Saturday)
- `isRest: Bool` (whether it's a rest day)
- `notes: String` (day-specific notes)

**Relationships**:
- `workoutTemplate: WorkoutTemplate?` (parent template)
- `exerciseTemplates: [ExerciseTemplate]` (exercises for this day)

#### ExerciseTemplate
**Purpose**: Exercise configuration within a day template
**Properties**:
- `id: UUID` (unique identifier)
- `setCount: Int` (planned number of sets)
- `reps: Int` (planned repetitions per set)
- `weight: Double?` (planned weight, optional)
- `position: Double` (order within the day)
- `supersetID: UUID?` (grouping for supersets)
- `createdAt: Date` (creation timestamp)

**Relationships**:
- `exercise: Exercise` (reference to the actual exercise)
- `dayTemplate: DayTemplate?` (parent day template)

**Key Features**:
- Comprehensive validation (reps, sets, weight, position)
- Safe update methods with rollback on validation failure
- Parameter validation without instance creation

### 3. Execution Layer (Active Workouts)

#### WorkoutPlan  
**Purpose**: Active workout plan based on a template
**Properties**:
- `id: UUID` (unique identifier)
- `customName: String` (plan name)
- `isActive: Bool` (whether currently active)
- `startedAt: Date` (when plan was started)
- `durationWeeks: Int` (planned length of the block in weeks)
- `createdAt: Date` (creation timestamp)

**Relationships**:
- `template: WorkoutTemplate?` (source template)

#### WorkoutSession
**Purpose**: Individual workout session execution
**Properties**:
- `id: UUID` (unique identifier)  
- `date: Date` (session date)
- `title: String` (session title)
- `duration: TimeInterval?` (workout duration)
- `createdAt: Date` (creation timestamp)

**Relationships**:
- `plan: WorkoutPlan?` (associated plan)
- `sessionExercises: [SessionExercise]` (exercises in this session)

**Computed Properties**:
- `totalVolume: Double` (sum of all exercise volumes)

#### SessionExercise
**Purpose**: Exercise execution within a workout session
**Properties**:
- `id: UUID` (unique identifier)
- `plannedSets: Int` (intended sets)
- `plannedReps: Int` (intended reps)
- `plannedWeight: Double?` (intended weight)
- `position: Double` (exercise order)
- `supersetID: UUID?` (superset grouping)
- `currentSet: Int` (current set being performed)
- `isCompleted: Bool` (completion status)
- `restTimer: TimeInterval?` (rest timer state)
- `createdAt: Date` (creation timestamp)

**Relationships**:
- `exercise: Exercise` (reference to exercise)
- `session: WorkoutSession?` (parent session)
- `completedSets: [CompletedSet]` (completed sets)

**Computed Properties**:
- `totalVolume: Double` (volume for this exercise)

#### CompletedSet
**Purpose**: Individual set completion record
**Properties**:
- `id: UUID` (unique identifier)
- `reps: Int` (actual repetitions performed)
- `weight: Double` (actual weight used)
- `externalSampleUUID: UUID?` (external tracking reference)

**Relationships**:
- `sessionExercise: SessionExercise?` (parent exercise)

### 4. Progress Layer (Historical Data)

#### PerformedExercise
**Purpose**: Historical exercise performance record
**Properties**:
- `id: UUID` (unique identifier)
- `performedAt: Date` (performance timestamp)
- `reps: Int` (repetitions performed)
- `weight: Double` (weight used)

**Relationships**:
- `exercise: Exercise` (reference to exercise)
- `workoutSession: WorkoutSession?` (associated session)

#### ProgressPhoto
**Purpose**: Progress photo management
**Properties**:
- `id: UUID` (unique identifier)
- `date: Date` (photo date)
- `angle: PhotoAngle` (front, side, back)
- `assetIdentifier: String` (photo asset ID)
- `weightSampleUUID: UUID?` (associated weight measurement)
- `notes: String` (photo notes)
- `createdAt: Date` (creation timestamp)

## Enumerations

### ExerciseCategory
- `strength`: Resistance training exercises
- `cardio`: Cardiovascular exercises  
- `mobility`: Flexibility and mobility work
- `balance`: Balance and stability exercises

### Weekday
- `sunday` through `saturday` (Int-based, 1-7)

### PhotoAngle
- `front`: Front-facing progress photo
- `side`: Side profile progress photo
- `back`: Back-facing progress photo

### ValidationError
Comprehensive error handling for:
- Duplicate names
- Empty/invalid inputs
- Negative values
- Invalid positions
- Custom validation messages

## Key User Workflows

### 1. Template Creation Workflow
1. Create `WorkoutTemplate` with unique name
2. Add `DayTemplate` for each workout day
3. Add `ExerciseTemplate` to each day with exercises from the master catalog
4. Set rep/set/weight targets and exercise order

### 2. Workout Execution Workflow  
1. Create `WorkoutPlan` from `WorkoutTemplate`
2. Start `WorkoutSession` 
3. Convert template exercises to `SessionExercise` with runtime state
4. Track `CompletedSet` for each performed set
5. Record `PerformedExercise` for historical tracking

### 3. Progress Tracking Workflow
1. View historical `PerformedExercise` data
2. Track progress with `ProgressPhoto` 
3. Analyze volume and performance trends
4. Compare against planned vs actual performance

## UI Implications for Wireframes

### Key Screens Needed:
1. **Template Management**: Create/edit workout templates
2. **Day Planning**: Configure exercises for each day
3. **Exercise Library**: Browse and select exercises
4. **Active Workout**: Real-time workout execution
5. **Exercise Logging**: Set/rep/weight input
6. **Progress Dashboard**: Charts and historical data
7. **Photo Progress**: Progress photo management
8. **Settings**: App configuration

### Core UI Components:
- Exercise picker with category filtering
- Set/rep/weight input controls
- Timer components for rest periods
- Progress charts and graphs
- Photo capture and comparison views
- Template copying and modification interfaces

### Data Relationships for UI:
- Master-detail views for templates → days → exercises
- Real-time updates during workout sessions
- Historical data visualization
- Template reusability and customization options

This architecture supports a full-featured fitness app with planning, execution, and progress tracking capabilities. 

***VIEWS***
struct MainTabView: View {
    var body: some View {
        TabView {
            LoggingView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book")
                }
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "photo")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }

            
        }