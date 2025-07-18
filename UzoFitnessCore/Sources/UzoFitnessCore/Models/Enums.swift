import Foundation

public enum ExerciseCategory: String, Codable, CaseIterable {
  case strength = "strength"
  case cardio = "cardio"
  case mobility = "mobility"
  case balance = "balance"
}

public enum Weekday: Int, Codable, CaseIterable {
  case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

public extension Weekday {
    var abbreviation: String {
        switch self {
        case .sunday: return "SUN"
        case .monday: return "MON"
        case .tuesday: return "TUE"
        case .wednesday: return "WED"
        case .thursday: return "THU"
        case .friday: return "FRI"
        case .saturday: return "SAT"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    /// Creates a Weekday from a string representation (case-insensitive)
    public static func from(string: String) -> Weekday? {
        let lowercased = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch lowercased {
        case "sunday", "sun":
            return .sunday
        case "monday", "mon":
            return .monday
        case "tuesday", "tue", "tues":
            return .tuesday
        case "wednesday", "wed":
            return .wednesday
        case "thursday", "thu", "thur", "thurs":
            return .thursday
        case "friday", "fri":
            return .friday
        case "saturday", "sat":
            return .saturday
        default:
            return nil
        }
    }
}

public enum PhotoAngle: String, Codable, CaseIterable {
  case front = "front"
  case side = "side"
  case back = "back"
}

public extension PhotoAngle {
    var displayName: String {
        switch self {
        case .front: return "Front"
        case .side: return "Side"
        case .back: return "Back"
        }
    }
}

// MARK: - Validation Error Types
public enum ValidationError: Error, LocalizedError {
    case duplicateWorkoutTemplateName(String)
    case emptyWorkoutTemplateName
    case workoutTemplateNameTooLong(Int)
    case negativeReps(Int)
    case negativeSetCount(Int)
    case negativeWeight(Double)
    case invalidPosition(Double)
    case zeroReps
    case zeroSets
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .duplicateWorkoutTemplateName(let name):
            return "A workout template with name '\(name)' already exists"
        case .emptyWorkoutTemplateName:
            return "Workout template name cannot be empty"
        case .workoutTemplateNameTooLong(let length):
            return "Workout template name is too long (\(length) characters). Maximum is 100 characters."
        case .negativeReps(let reps):
                    return "Reps cannot be negative: \(reps)"
                case .negativeSetCount(let setCount):
                    return "Set count cannot be negative: \(setCount)"
                case .negativeWeight(let weight):
                    return "Weight cannot be negative: \(weight)"
                case .invalidPosition(let position):
                    return "Position must be positive: \(position)"
                case .zeroReps:
                    return "Reps must be at least 1"
                case .zeroSets:
                    return "Set count must be at least 1"
                case .custom(let message):
                    return message
        }
    }
}
