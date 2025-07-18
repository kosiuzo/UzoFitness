import SwiftUI

struct ExerciseEditorView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise? // nil for create mode
    
    @State private var name: String = ""
    @State private var category: ExerciseCategory = .strength
    @State private var instructions: String = ""
    
    init(exercise: Exercise? = nil, viewModel: LibraryViewModel) {
        self.exercise = exercise
        self.viewModel = viewModel
        self._name = State(initialValue: exercise?.name ?? "")
        self._category = State(initialValue: exercise?.category ?? .strength)
        self._instructions = State(initialValue: exercise?.instructions ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                        .autocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
                
                // Last Used Values Section
                if let exercise = exercise {
                    Section("Last Used Values") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Last Used Weight:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let lastWeight = exercise.lastUsedWeight {
                                    Text("\(lastWeight, specifier: "%.1f") lbs")
                                        .fontWeight(.medium)
                                } else {
                                    Text("Not recorded")
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                }
                            }
                            
                            HStack {
                                Text("Last Used Reps:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let lastReps = exercise.lastUsedReps {
                                    Text("\(lastReps)")
                                        .fontWeight(.medium)
                                } else {
                                    Text("Not recorded")
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                }
                            }
                            
                            HStack {
                                Text("Last Total Volume:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let lastVolume = exercise.lastTotalVolume {
                                    Text("\(lastVolume, specifier: "%.1f") lbs")
                                        .fontWeight(.medium)
                                } else {
                                    Text("Not recorded")
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                }
                            }
                            
                            HStack {
                                Text("Last Used Date:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let lastDate = exercise.lastUsedDate {
                                    Text(lastDate.formatted(date: .abbreviated, time: .omitted))
                                        .fontWeight(.medium)
                                } else {
                                    Text("Never used")
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if exercise != nil {
                    Section {
                        Button("Delete Exercise", role: .destructive) {
                            if let exercise = exercise {
                                viewModel.deleteExercise(exercise)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            if let existingExercise = exercise {
                // Edit mode
                try viewModel.updateExercise(existingExercise, name: trimmedName, category: category, instructions: instructions)
            } else {
                // Create mode
                try viewModel.createExercise(name: trimmedName, category: category, instructions: instructions)
            }
        } catch {
            AppLogger.error("[ExerciseEditorView] Error", category: "LibraryView", error: error)
            viewModel.error = error
        }
    }
} 