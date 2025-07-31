import Foundation

// MARK: - WorkoutPlan Helper Methods
extension WorkoutPlan {
    
    /// Calculates completion percentage based on start date and duration
    var completionPercentage: Double {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: startedAt) ?? now
        
        // If plan is ended, use endedAt date instead of current date
        let referenceDate = endedAt ?? now
        
        // Calculate progress
        let totalDuration = endDate.timeIntervalSince(startedAt)
        let elapsedDuration = referenceDate.timeIntervalSince(startedAt)
        
        // Ensure we don't go beyond 100% or below 0%
        let percentage = (elapsedDuration / totalDuration) * 100.0
        return max(0.0, min(100.0, percentage))
    }
    
    /// Returns true if the plan has been completed (past end date or manually ended)
    var isCompleted: Bool {
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: startedAt) ?? Date()
        return endedAt != nil || Date() > endDate
    }
    
    /// Returns the calculated end date based on start date and duration
    var calculatedEndDate: Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: startedAt) ?? startedAt
    }
    
    /// Returns the number of weeks remaining in the plan
    var weeksRemaining: Int {
        let endDate = calculatedEndDate
        let now = Date()
        
        if now >= endDate {
            return 0
        }
        
        let remainingWeeks = Calendar.current.dateComponents([.weekOfYear], from: now, to: endDate).weekOfYear ?? 0
        return max(0, remainingWeeks)
    }
    
    /// Returns true if the plan is currently active and not completed
    var isCurrentlyActive: Bool {
        return isActive && !isCompleted
    }
    
    /// Returns a formatted string for the plan duration
    var durationDescription: String {
        if durationWeeks == 1 {
            return "1 week"
        } else {
            return "\(durationWeeks) weeks"
        }
    }
    
    /// Returns a formatted string for the progress status
    var progressDescription: String {
        if isCompleted {
            return "Completed"
        } else if completionPercentage > 0 {
            return "\(Int(completionPercentage))% complete"
        } else {
            return "Not started"
        }
    }
} 