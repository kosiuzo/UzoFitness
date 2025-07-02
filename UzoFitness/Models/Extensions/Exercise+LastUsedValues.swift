//
//  Exercise+LastUsedValues.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/24/25.
//


// MARK: - Last Used Values Management
extension Exercise {
    /// Updates the cached last used values based on the most recent completed session
    func updateLastUsedValues() {
        AppLogger.debug("[Exercise.updateLastUsedValues] Updating cached values for: \(name)", category: "Exercise")
        
        // Find the most recent session exercise with completed sets
        let recentSessionExercise = findMostRecentCompletedSessionExercise()
        
        guard let sessionExercise = recentSessionExercise,
              !sessionExercise.completedSets.isEmpty else {
            AppLogger.debug("[Exercise.updateLastUsedValues] No recent completed sets found", category: "Exercise")
            return
        }
        
        // Calculate values from the most recent session
        let completedSets = sessionExercise.completedSets
        let totalVolume = completedSets.reduce(0) { $0 + (Double($1.reps) * $1.weight) }
        
        // Use the last completed set for weight and reps
        if let lastSet = completedSets.last {
            lastUsedWeight = lastSet.weight
            lastUsedReps = lastSet.reps
        }
        
        lastTotalVolume = totalVolume
        lastUsedDate = sessionExercise.session?.date ?? sessionExercise.createdAt
        
        AppLogger.info("[Exercise.updateLastUsedValues] Updated - Weight: \(lastUsedWeight ?? 0), Reps: \(lastUsedReps ?? 0), Volume: \(lastTotalVolume ?? 0)", category: "Exercise")
    }
    
    /// Finds the most recent session exercise with completed sets for this exercise
    private func findMostRecentCompletedSessionExercise() -> SessionExercise? {
        // This will be called from the context where we have access to all session exercises
        // For now, we'll rely on the relationship structure
        return nil // This will be implemented in the helper methods
    }
    
    /// Returns suggested starting values for a new session exercise
    var suggestedStartingValues: (weight: Double?, reps: Int?, totalVolume: Double?) {
        return (lastUsedWeight, lastUsedReps, lastTotalVolume)
    }
}