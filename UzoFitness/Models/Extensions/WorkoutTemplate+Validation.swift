//
//  WorkoutTemplate+Validation.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/17/25.
//

import SwiftData

extension WorkoutTemplate {
    /// Validates that this template's name is unique in the context
    func validateUniqueness(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        let existing = try context.fetch(descriptor)
        
        // Filter out self when checking for duplicates (for updates)
        let matching = existing.filter {
            $0.name.lowercased() == self.name.lowercased() &&
            $0.persistentModelID != self.persistentModelID
        }
        
        if !matching.isEmpty {
            throw ValidationError.duplicateWorkoutTemplateName(self.name)
        }
    }
    
    /// Validates the name format and content
    private func validateName() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyWorkoutTemplateName
        }
        
        guard trimmedName.count <= 100 else {
            throw ValidationError.workoutTemplateNameTooLong(trimmedName.count)
        }
        
        // Update the actual name to the trimmed version
        self.name = trimmedName
    }
    
    /// Validates all business rules for this template
    func validate(in context: ModelContext) throws {
        // Validate name format first
        try validateName()
        
        // Check uniqueness (this also handles the @Attribute(.unique) constraint)
        try validateUniqueness(in: context)
        
        // Add other validation rules here as needed
        // For example, you might want to validate dayTemplates
    }
    
    /// Convenience method to validate and save
    func validateAndSave(in context: ModelContext) throws {
        try validate(in: context)
        try context.save()
    }
    
    /// Convenience method to validate before insert and save
    static func createAndSave(
        name: String,
        summary: String = "",
        in context: ModelContext
    ) throws -> WorkoutTemplate {
        let template = WorkoutTemplate(name: name, summary: summary)
        context.insert(template)
        try template.validateAndSave(in: context)
        return template
    }
}
