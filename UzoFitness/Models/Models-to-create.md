# SwiftData Models with Protocols

## Models/Protocols.swift

```swift
import Foundation

/// Gives every model a UUID `id` + native Identifiable/Hashable conformance.
protocol Identified: Identifiable, Hashable {
  var id: UUID { get set }
}

/// Gives any model a creation timestamp.
protocol Timestamped {
  var createdAt: Date { get set }
}

/// Convenience to avoid hard-coding your entity names.
extension Identified {
  static var entityName: String {
    String(describing: Self.self)
  }
}
```

## Models/Enums.swift

```swift
import Foundation

enum ExerciseCategory: String, Codable, CaseIterable {
  case strength = "strength"
  case cardio = "cardio"
  case flexibility = "flexibility"
  case balance = "balance"
}

enum Weekday: Int, Codable, CaseIterable {
  case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

enum PhotoAngle: String, Codable, CaseIterable {
  case front = "front"
  case side = "side"
  case back = "back"
}
```

## Models/Exercise.swift

```swift
import Foundation
import SwiftData

@Model
struct Exercise: Identified {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute(.unique) var name: String
  @Attribute var category: ExerciseCategory
  @Attribute var instructions: String = ""
  @Attribute var mediaAssetID: String?
  
  init(name: String, category: ExerciseCategory, instructions: String = "", mediaAssetID: String? = nil) {
    self.name = name
    self.category = category
    self.instructions = instructions
    self.mediaAssetID = mediaAssetID
  }
}
```

## Models/WorkoutTemplate.swift

```swift
import Foundation
import SwiftData

@Model
struct WorkoutTemplate: Identified, Timestamped {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute(.unique) var name: String
  @Attribute var summary: String = ""
  @Attribute var createdAt: Date = Date.now

  @Relationship var dayTemplates: [DayTemplate] = []
  
  init(name: String, summary: String = "") {
    self.name = name
    self.summary = summary
  }
}
```

## Models/DayTemplate.swift

```swift
import Foundation
import SwiftData

@Model
struct DayTemplate: Identified {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var weekday: Weekday
  @Attribute var isRest: Bool = false
  @Attribute var notes: String = ""

  @Relationship var workoutTemplate: WorkoutTemplate?
  @Relationship var exerciseTemplates: [ExerciseTemplate] = []
  
  init(weekday: Weekday, isRest: Bool = false, notes: String = "") {
    self.weekday = weekday
    self.isRest = isRest
    self.notes = notes
  }
}
```

## Models/ExerciseTemplate.swift

```swift
import Foundation
import SwiftData

@Model
struct ExerciseTemplate: Identified {
  @Attribute(.unique) var id: UUID = UUID()
  @Relationship var exercise: Exercise
  @Attribute var setCount: Int
  @Attribute var reps: Int
  @Attribute var weight: Double?
  @Attribute var position: Double
  @Attribute var supersetID: UUID?
  
  @Relationship var dayTemplate: DayTemplate?
  
  init(exercise: Exercise, setCount: Int, reps: Int, weight: Double? = nil, position: Double, supersetID: UUID? = nil) {
    self.exercise = exercise
    self.setCount = setCount
    self.reps = reps
    self.weight = weight
    self.position = position
    self.supersetID = supersetID
  }
}
```

## Models/WorkoutPlan.swift

```swift
import Foundation
import SwiftData

@Model
struct WorkoutPlan: Identified, Timestamped {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var customName: String
  @Attribute var isActive: Bool = true
  @Attribute var startedAt: Date = Date.now
  @Attribute var createdAt: Date = Date.now

  @Relationship var template: WorkoutTemplate?
  
  init(customName: String, template: WorkoutTemplate? = nil) {
    self.customName = customName
    self.template = template
  }
}
```

## Models/WorkoutSession.swift

```swift
import Foundation
import SwiftData

@Model
struct WorkoutSession: Identified, Timestamped {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var date: Date
  @Attribute var title: String = ""
  @Attribute var duration: TimeInterval?
  @Attribute var createdAt: Date = Date.now

  @Relationship var plan: WorkoutPlan?
  @Relationship var sessionExercises: [SessionExercise] = []

  /// Aggregate across all exercises
  var totalVolume: Double {
    sessionExercises.reduce(0) { $0 + $1.totalVolume }
  }
  
  init(date: Date = Date.now, title: String = "", plan: WorkoutPlan? = nil) {
    self.date = date
    self.title = title
    self.plan = plan
  }
}
```

## Models/SessionExercise.swift

```swift
import Foundation
import SwiftData

@Model
struct SessionExercise: Identified, Timestamped {
  @Attribute(.unique) var id: UUID = UUID()
  @Relationship var exercise: Exercise
  @Attribute var plannedSets: Int
  @Attribute var plannedReps: Int
  @Attribute var plannedWeight: Double?
  @Attribute var position: Double
  @Attribute var supersetID: UUID?
  @Attribute var currentSet: Int = 0
  @Attribute var isCompleted: Bool = false
  @Attribute var restTimer: TimeInterval?
  @Attribute var createdAt: Date = Date.now

  @Relationship var session: WorkoutSession?
  @Relationship var completedSets: [CompletedSet] = []

  /// Sum of (reps × weight) for each completed set
  var totalVolume: Double {
    completedSets.reduce(0) {
      $0 + (Double($1.reps) * $1.weight)
    }
  }
  
  init(exercise: Exercise, plannedSets: Int, plannedReps: Int, plannedWeight: Double? = nil, position: Double, supersetID: UUID? = nil) {
    self.exercise = exercise
    self.plannedSets = plannedSets
    self.plannedReps = plannedReps
    self.plannedWeight = plannedWeight
    self.position = position
    self.supersetID = supersetID
  }
}
```

## Models/CompletedSet.swift

```swift
import Foundation
import SwiftData

@Model
struct CompletedSet: Identified {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var reps: Int
  @Attribute var weight: Double
  @Attribute var externalSampleUUID: UUID?

  @Relationship var sessionExercise: SessionExercise?
  
  init(reps: Int, weight: Double, externalSampleUUID: UUID? = nil) {
    self.reps = reps
    self.weight = weight
    self.externalSampleUUID = externalSampleUUID
  }
}
```

## Models/ProgressPhoto.swift

```swift
import Foundation
import SwiftData

@Model
struct ProgressPhoto: Identified, Timestamped {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var date: Date
  @Attribute var angle: PhotoAngle
  @Attribute var assetIdentifier: String
  @Attribute var weightSampleUUID: UUID?
  @Attribute var notes: String = ""
  @Attribute var createdAt: Date = Date.now

  init(date: Date, angle: PhotoAngle, assetIdentifier: String, weightSampleUUID: UUID? = nil, notes: String = "") {
    self.date = date
    self.angle = angle
    self.assetIdentifier = assetIdentifier
    self.weightSampleUUID = weightSampleUUID
    self.notes = notes
  }
}
```

---

## Usage Examples

### Generic Functions
```swift
// Generic function works with any Identified model
func delete<T: Identified>(_ item: T, from context: ModelContext) {
    context.delete(item)
}

// Get entity name without hardcoding
let entityName = Exercise.entityName // "Exercise"
```

### Protocol Benefits
- **Consistent IDs**: Every entity has a UUID `id` with `@Attribute(.unique)`
- **Generic Operations**: Can write functions that work with any `Identified` type
- **Entity Names**: Get the entity name via `MyModel.entityName` instead of hardcoding strings
- **Hashable/Identifiable**: Automatic conformance for SwiftUI Lists, Sets, etc.