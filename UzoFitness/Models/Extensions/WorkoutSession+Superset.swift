import Foundation
import SwiftData

// MARK: - WorkoutSession Superset Extensions
extension WorkoutSession {
    /// Determines if the session has any active supersets based on the session exercises
    var hasActiveSupersets: Bool {
        // Check if any exercises have a supersetID
        let exercisesWithSuperset = sessionExercises.filter { $0.supersetID != nil }
        
        // Group exercises by supersetID to find supersets with multiple exercises
        let supersetGroups = Dictionary(grouping: exercisesWithSuperset) { $0.supersetID! }
        
        // A superset is active if there are multiple exercises with the same supersetID
        return supersetGroups.values.contains { $0.count > 1 }
    }
    
    /// Returns all superset groups in the session
    var supersetGroups: [[SessionExercise]] {
        let exercisesWithSuperset = sessionExercises.filter { $0.supersetID != nil }
        let grouped = Dictionary(grouping: exercisesWithSuperset) { $0.supersetID! }
        
        // Return only groups with multiple exercises (actual supersets)
        return grouped.values.filter { $0.count > 1 }
            .map { $0.sorted(by: { $0.position < $1.position }) }
    }
    
    /// Returns the current superset group if the session is in a superset
    var currentSupersetGroup: [SessionExercise]? {
        guard isSupersetActive,
              let currentExerciseID = currentExerciseID,
              let currentExercise = sessionExercises.first(where: { $0.id == currentExerciseID }),
              let supersetID = currentExercise.supersetID else {
            return nil
        }
        
        let supersetExercises = sessionExercises.filter { $0.supersetID == supersetID }
        return supersetExercises.count > 1 ? supersetExercises.sorted(by: { $0.position < $1.position }) : nil
    }
    
    /// Returns the next exercise in the current superset
    var nextExerciseInSuperset: SessionExercise? {
        guard let currentGroup = currentSupersetGroup,
              let currentExerciseID = currentExerciseID,
              let currentIndex = currentGroup.firstIndex(where: { $0.id == currentExerciseID }) else {
            return nil
        }
        
        let nextIndex = currentIndex + 1
        return nextIndex < currentGroup.count ? currentGroup[nextIndex] : nil
    }
    
    /// Updates the isSupersetActive property based on the current session state
    func updateSupersetState() {
        let newState = hasActiveSupersets && currentExerciseID != nil
        
        if isSupersetActive != newState {
            isSupersetActive = newState
            AppLogger.debug("[WorkoutSession.updateSupersetState] Superset state updated to: \(newState)", category: "WorkoutSession")
        }
    }
    
    /// Advances to the next exercise in the current superset
    func advanceToNextExerciseInSuperset() -> Bool {
        guard let nextExercise = nextExerciseInSuperset else {
            // No next exercise - superset is complete
            isSupersetActive = false
            currentExerciseID = nil
            currentSetNumber = 0
            AppLogger.info("[WorkoutSession.advanceToNextExerciseInSuperset] Superset completed", category: "WorkoutSession")
            return false
        }
        
        currentExerciseID = nextExercise.id
        currentSetNumber = 0
        AppLogger.info("[WorkoutSession.advanceToNextExerciseInSuperset] Advanced to: \(nextExercise.exercise.name)", category: "WorkoutSession")
        return true
    }
    
    /// Gets the current exercise if one is selected
    var currentExercise: SessionExercise? {
        guard let currentExerciseID = currentExerciseID else { return nil }
        return sessionExercises.first { $0.id == currentExerciseID }
    }
    
    /// Gets the current set if a current exercise and set number are set
    var currentSet: CompletedSet? {
        guard let currentExercise = currentExercise,
              currentSetNumber > 0,
              currentSetNumber <= currentExercise.completedSets.count else {
            return nil
        }
        
        let orderedSets = currentExercise.completedSets.sorted(by: { $0.position < $1.position })
        let setIndex = currentSetNumber - 1
        return setIndex < orderedSets.count ? orderedSets[setIndex] : nil
    }
} 