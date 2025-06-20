//
//  WorkoutTemplate+HelperMethods.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/17/25.
//

import Foundation
import SwiftData

extension WorkoutTemplate {
    /// Check if a name would be unique without creating an instance
    static func isNameAvailable(_ name: String, in context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        let existing = try context.fetch(descriptor)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !existing.contains { $0.name.lowercased() == trimmedName.lowercased() }
    }
    
    /// Get suggested name if the proposed name is taken
    static func suggestAvailableName(_ baseName: String, in context: ModelContext) throws -> String {
        let trimmedBaseName = baseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if try isNameAvailable(trimmedBaseName, in: context) {
            return trimmedBaseName
        }
        
        // Try appending numbers
        for i in 2...999 {
            let suggestedName = "\(trimmedBaseName) \(i)"
            if try isNameAvailable(suggestedName, in: context) {
                return suggestedName
            }
        }
        
        // Fallback with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd-HHmm"
        return "\(trimmedBaseName) \(formatter.string(from: Date()))"
    }
    
    /// Returns the DayTemplate for a specific weekday, creating one if it doesn't exist
    func dayTemplateFor(_ weekday: Weekday) -> DayTemplate {
        if let existingTemplate = dayTemplates.first(where: { $0.weekday == weekday }) {
            return existingTemplate
        }
        
        // Create a new DayTemplate if one doesn't exist
        let newTemplate = DayTemplate(weekday: weekday, workoutTemplate: self)
        dayTemplates.append(newTemplate)
        return newTemplate
    }
    
    /// Ensures all 7 days have DayTemplates
    func ensureAllDaysExist() {
        for weekday in Weekday.allCases {
            _ = dayTemplateFor(weekday)
        }
    }
}
