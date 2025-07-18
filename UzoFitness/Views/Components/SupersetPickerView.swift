import SwiftUI

struct SupersetPickerView: View {
    let exerciseTemplate: ExerciseTemplate
    let onSelection: (UUID?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(exerciseTemplate: ExerciseTemplate, onSelection: @escaping (UUID?) -> Void) {
        self.exerciseTemplate = exerciseTemplate
        self.onSelection = onSelection
    }
    
    private var existingSupersets: [UUID] {
        guard let dayTemplate = exerciseTemplate.dayTemplate else { return [] }
        let supersetIDs = dayTemplate.exerciseTemplates.compactMap { $0.supersetID }
        return Array(Set(supersetIDs)) // Remove duplicates
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Actions") {
                    Button("Create New Superset") {
                        onSelection(UUID())
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                    
                    Button("Remove from Superset") {
                        onSelection(nil)
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
                
                if !existingSupersets.isEmpty {
                    Section("Existing Supersets") {
                        ForEach(existingSupersets, id: \.self) { supersetID in
                            SupersetRowView(
                                supersetID: supersetID,
                                exerciseTemplate: exerciseTemplate
                            ) {
                                onSelection(supersetID)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Superset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SupersetRowView: View {
    let supersetID: UUID
    let exerciseTemplate: ExerciseTemplate
    let onTap: () -> Void
    
    private var exercisesInSuperset: [ExerciseTemplate] {
        guard let dayTemplate = exerciseTemplate.dayTemplate else { return [] }
        return dayTemplate.exerciseTemplates.filter { $0.supersetID == supersetID }
    }
    
    private var supersetNumber: Int? {
        guard let dayTemplate = exerciseTemplate.dayTemplate else { return nil }
        return dayTemplate.getSupersetNumber(for: supersetID)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let number = supersetNumber {
                        Text("Superset \(number)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Superset")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Text("\(exercisesInSuperset.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(exercisesInSuperset.prefix(3), id: \.id) { template in
                        HStack {
                            Text("• \(template.exercise.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    
                    if exercisesInSuperset.count > 3 {
                        Text("... and \(exercisesInSuperset.count - 3) more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
} 