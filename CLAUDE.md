# UzoFitness - iOS Fitness Tracking App

## Project Overview

UzoFitness is a modern iOS application built with **Swift 5** and **SwiftUI** that helps users track their fitness journey end-to-end. The app focuses on three core pillars:

1. **Workout Planning & Execution** – Create reusable workout templates, run guided workout sessions, and log sets/reps/weights
2. **Progress Tracking** – Log body-weight, body-fat %, and upload progress photos organized in grid views
3. **Apple Health Integration** – Securely read body-mass and body-fat data directly from Apple Health

**Architecture**: SwiftUI + MVVM with SwiftData persistence  
**Target**: iOS 17.0+ (SwiftData requirement)  
**Status**: Active development (June 2025)  
**Design Philosophy**: Minimalist iOS design with clean typography, generous white space, and subtle visual hierarchy

## Directory Structure

```
UzoFitness/
├── UzoFitnessApp.swift              # Entry point
├── Models/                          # SwiftData entities & protocols
│   ├── Exercise.swift              # Exercise definitions
│   ├── WorkoutTemplate.swift       # Reusable workout plans
│   ├── WorkoutSession.swift        # Active workout instances
│   ├── ProgressPhoto.swift         # Progress tracking
│   ├── Protocols.swift             # Identified, Timestamped protocols
│   ├── Enums.swift                 # ExerciseCategory, Weekday, etc.
│   └── Extensions/                 # Model helper methods
├── ViewModels/                     # ObservableObject business logic
│   ├── LoggingViewModel.swift      # Workout session management
│   ├── LibraryViewModel.swift      # Template CRUD operations
│   ├── HistoryViewModel.swift      # Historical data & analytics
│   ├── ProgressViewModel.swift     # Progress tracking & charts
│   └── SettingsViewModel.swift     # App configuration
├── Views/
│   ├── Screens/                    # Main app screens
│   │   ├── MainTabView.swift       # Tab navigation
│   │   ├── LoggingView.swift       # Active workout interface
│   │   ├── LibraryView.swift       # Template management
│   │   ├── HistoryView.swift       # Workout history
│   │   ├── ProgressView.swift      # Progress tracking
│   │   └── SettingsView.swift      # App settings
│   └── Components/                 # Reusable UI components
│       ├── MetricLineChart.swift   # Performance charts
│       ├── ProgressPhotoGrid.swift # Photo gallery
│       └── CustomDateRangePickerView.swift
├── Services/                       # External integrations
│   ├── HealthKitManager.swift      # Apple Health integration
│   └── PhotoService.swift          # Photo library management
├── Persistence/                    # Data layer
│   └── PersistenceController.swift # SwiftData configuration
├── Utilities/                      # Extensions & helpers
│   └── Logger.swift               # Logging utilities
├── Resources/                      # App resources
│   ├── Assets.xcassets           # Images & colors
│   └── Info.plist                # App configuration
├── Documentation/                  # Project documentation
│   ├── AppComponentsOverview.md   # Architecture guide
│   ├── CloudKitBackImplementation.md
│   └── TestEvaluationReport.md
└── Tests/                         # Test suites
    ├── UzoFitnessTests/           # Unit tests
    └── UzoFitnessUITests/         # UI tests
```

## Essential Commands and Setup

### Development Requirements
- **Xcode 15.4** or later
- **iOS 17.0** or later (SwiftData requirement)
- iPhone 15+ simulator or device

### Build Commands
```bash
# Build for simulator (without launching)
xcodebuild -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build

# Build for device
xcodebuild -scheme UzoFitness -sdk iphoneos -configuration Debug build

# Build for simulator (launches simulator)
xcodebuild -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'

# Run tests
xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'
```

### Code Quality Tools
```bash
# Format code (install SwiftFormat first)
swiftformat .

# Lint code (install SwiftLint first)
swiftlint
```

## Coding Standards and Guidelines

### Swift Style Guide
- Follow **Swift API Design Guidelines**
- Use **4-space indentation**
- Maximum line length: **100 characters**
- Prefer `guard` over deep nesting
- Mark immutable values with `let`
- Use trailing closures for single-parameter closures

### Naming Conventions
- **Types**: UpperCamelCase (`WorkoutTemplate`, `ExerciseCategory`)
- **Properties & Methods**: lowerCamelCase (`workoutName`, `fetchExercises()`)
- **Constants**: UPPER_SNAKE_CASE for static values
- **Protocols**: End with "Protocol" (e.g., `HealthStoreProtocol`)
- **Views**: End with "View" (e.g., `WorkoutListView`)
- **ViewModels**: End with "ViewModel" (e.g., `WorkoutListViewModel`)

### SwiftUI Best Practices
- Use `@State` for local view state
- Use `@StateObject` for owned ViewModels
- Use `@ObservedObject` for injected ViewModels
- Use `@Environment` for shared app-wide dependencies
- Extract complex views into separate components when body exceeds 10-15 lines
- Use `.task{}` over `.onAppear{}` for async operations

### UI Design Principles
- **Follow Minimalist iOS Design**: All UI changes must adhere to the [Minimalist iOS Design Guide](.cursor/rules/minimalist-ios-guide.mdc)
- Use generous white space (16px, 24px, 32px increments) as primary design element
- Employ subtle gray backgrounds (`Color(.systemGray6)`) for gentle visual separation
- Prioritize clear, readable text over decorative elements
- Use system fonts (San Francisco) for consistency and legibility
- Default to neutral color scheme with whites, light grays, and subtle accents
- Use color sparingly and purposefully (blue for interactive elements, green for completion states)
- Avoid gradients, shadows, or complex visual effects unless absolutely necessary
- Design with clean, simple shapes and minimal ornamentation
- Implement subtle interactive states with light gray fills on tap
- Group related content with consistent card-based layouts and gentle borders
- Follow iOS Human Interface Guidelines for familiar interaction patterns
- Implement smooth, subtle animations that feel natural to iOS users

### Async/Await Patterns
- Prefer `async/await` over Combine for new code
- Use `@MainActor` for UI updates from background tasks
- Handle cancellation with `Task.isCancelled` checks
- Use `TaskGroup` for concurrent operations

### Error Handling
- Create custom error types conforming to `LocalizedError`
- Use `Result<Success, Failure>` for operations that can fail
- Provide user-friendly error messages
- Log errors appropriately (avoid logging sensitive data)

## Workflow and Repository Etiquette

### Branching Strategy
- Create feature branches: `feature/workout-templates`
- Create bug fix branches: `fix/healthkit-sync-issue`
- Keep pull requests focused and self-contained

### Commit Guidelines
- Use conventional commit messages
- Run `swiftformat` and `swiftlint` before committing
- Ensure all tests pass before pushing

### Testing Requirements
- Write unit tests for ViewModels and Services
- Use dependency injection for testable code
- Mock external dependencies (HealthKit, network calls)
- Test both success and failure scenarios

## Technical Specifications

### Core Technologies
- **Swift 5** - Primary language
- **SwiftUI** - UI framework
- **SwiftData** - Local persistence (CoreData-like)
- **HealthKit** - Apple Health integration
- **PhotosUI** - Photo library access

### Key Protocols and Patterns

#### Model Protocols
```swift
// Every model gets UUID + Identifiable/Hashable
protocol Identified: Identifiable, Hashable {
    var id: UUID { get set }
}

// Models with creation timestamps
protocol Timestamped {
    var createdAt: Date { get set }
}
```

#### ViewModel Pattern
```swift
@MainActor
class ExampleViewModel: ObservableObject {
    @Published var state: ViewState<Data> = .idle
    private let service: ExampleServiceProtocol
    
    init(service: ExampleServiceProtocol) {
        self.service = service
    }
    
    func loadData() async {
        // Async data loading with state management
    }
}
```

#### Service Pattern
```swift
protocol ExampleServiceProtocol {
    func fetchData() async throws -> Data
}

class ExampleService: ExampleServiceProtocol {
    // Implementation with dependency injection
}
```

### Data Models
- **Exercise**: Individual exercise definitions with categories
- **WorkoutTemplate**: Reusable workout plans with exercises and sets
- **WorkoutSession**: Active workout instances with progress tracking
- **ProgressPhoto**: Photo-based progress tracking with angles
- **CompletedSet**: Individual set results with weights/reps

### State Management
- **SwiftData**: Primary persistence layer with `@Model` entities
- **@Observable**: ViewModels for UI state management
- **@Environment**: Shared app-wide dependencies

## Problem Resolutions and Warnings

### Known Issues
- HealthKit requires device authorization on first launch
- SwiftData requires iOS 17.0+ minimum
- Photo library access requires user permission

### Common Gotchas
- Always use `@MainActor` for UI updates from background tasks
- SwiftData operations should be performed on background contexts for heavy operations
- HealthKit queries are asynchronous and require proper error handling
- Photo library access requires Info.plist permissions

### Performance Considerations
- Use `@State` and `@StateObject` judiciously to avoid unnecessary re-renders
- Implement lazy loading for large datasets (progress photos, workout history)
- Cache expensive computations when appropriate
- Profile memory usage with Instruments

## References to Additional Documentation

### Architecture & Design
- [App Components Overview](UzoFitness/Documentation/AppComponentsOverview.md) - High-level architecture guide
- [CloudKit Implementation](UzoFitness/Documentation/CloudKitBackImplementation.md) - Cloud sync details
- [Test Evaluation Report](UzoFitness/Documentation/TestEvaluationReport.md) - Testing strategy

### Development Guides
- [Contributing Guidelines](CONTRIBUTING.md) - Development setup and PR process
- [README](README.md) - Project overview and installation

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui/)
- [SwiftData](https://developer.apple.com/documentation/swiftdata/)
- [HealthKit](https://developer.apple.com/documentation/healthkit/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/)

### Design Documentation
- [Minimalist iOS Design Guide](.cursor/rules/minimalist-ios-guide.mdc) - **Required reading for all UI changes**

## Development Workflow

### New Feature Development
1. Create feature branch from main
2. **Review [Minimalist iOS Design Guide](.cursor/rules/minimalist-ios-guide.mdc) for UI design requirements**
3. Implement feature following MVVM pattern
4. **Design UI with minimalist principles: generous white space, clean typography, subtle visual cues**
5. Add unit tests for ViewModels and Services
6. Update documentation if needed
7. Run code quality tools (`swiftformat`, `swiftlint`)
8. Ensure all tests pass
9. Create pull request with clear description

### Bug Fix Process
1. Reproduce the issue
2. Create fix branch
3. **Ensure UI fixes follow minimalist design principles** (see [Minimalist iOS Design Guide](.cursor/rules/minimalist-ios-guide.mdc))
4. Implement fix with minimal changes
5. Add regression test if applicable
6. Test on both simulator and device
7. Submit pull request

### Code Review Checklist
- [ ] Follows Swift style guidelines
- [ ] Includes appropriate error handling
- [ ] Has unit tests for new functionality
- [ ] No memory leaks or performance issues
- [ ] Documentation updated if needed
- [ ] Accessibility considerations addressed
- [ ] **UI follows minimalist iOS design principles** (see [Minimalist iOS Design Guide](.cursor/rules/minimalist-ios-guide.mdc))
- [ ] Uses generous white space and clean typography
- [ ] Avoids visual clutter and unnecessary decorative elements
- [ ] Implements subtle, natural iOS animations

---

**Last Updated**: June 2025
**Maintainer**: UzoFitness Development Team 