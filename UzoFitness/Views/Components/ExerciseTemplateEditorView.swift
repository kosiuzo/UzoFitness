import SwiftUI

struct ExerciseTemplateEditorView: View {
    let exerciseTemplate: ExerciseTemplate
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var setCount: Int
    @State private var reps: Int
    @State private var weight: String
    @State private var restDuration: Double = 60 // Default 60 seconds
    @State private var supersetID: UUID?
    @State private var showingSuperset = false
    
    init(exerciseTemplate: ExerciseTemplate, viewModel: LibraryViewModel) {
        self.exerciseTemplate = exerciseTemplate
        self.viewModel = viewModel
        self._setCount = State(initialValue: exerciseTemplate.setCount)
        self._reps = State(initialValue: exerciseTemplate.reps)
        self._weight = State(initialValue: exerciseTemplate.weight?.formatted() ?? "")
        self._supersetID = State(initialValue: exerciseTemplate.supersetID)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Exercise Info Section
                Section("Exercise") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exerciseTemplate.exercise.name)
                                .font(.headline)
                            
                            Text(exerciseTemplate.exercise.category.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // Parameters Section
                Section("Parameters") {
                    // Sets
                    HStack {
                        Text("Sets")
                        Spacer()
                        Stepper(value: $setCount, in: 1...20) {
                            Text("\(setCount)")
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Reps
                    HStack {
                        Text("Reps")
                        Spacer()
                        Stepper(value: $reps, in: 1...100) {
                            Text("\(reps)")
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Weight
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("Optional", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    // Rest Duration
                    HStack {
                        Text("Rest")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatRestDuration(restDuration))
                                .fontWeight(.medium)
                            Slider(value: $restDuration, in: 30...300, step: 15)
                                .frame(width: 120)
                        }
                    }
                }
                
                // Superset Section
                Section("Superset") {
                    HStack {
                        Text("Superset")
                        Spacer()
                        
                        if supersetID != nil {
                            Button("Remove") {
                                self.supersetID = nil
                            }
                            .foregroundStyle(.red)
                        } else {
                            Button("Add to Superset") {
                                showingSuperset = true
                            }
                        }
                    }
                    
                    if supersetID != nil {
                        Text("This exercise is part of a superset")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Instructions Section (if available)
                if !exerciseTemplate.exercise.instructions.isEmpty {
                    Section("Instructions") {
                        Text(exerciseTemplate.exercise.instructions)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingSuperset) {
                SupersetPickerView(exerciseTemplate: exerciseTemplate) { selectedSupersetID in
                    self.supersetID = selectedSupersetID
                }
            }
        }
    }
    
    private func formatRestDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(Int(seconds))s"
        }
    }
    
    private func saveChanges() {
        let weightValue = weight.isEmpty ? nil : Double(weight)
        
        viewModel.updateExerciseTemplate(
            exerciseTemplate,
            setCount: setCount,
            reps: reps,
            weight: weightValue,
            rest: restDuration,
            supersetID: supersetID
        )
        
        AppLogger.info("[ExerciseTemplateEditorView] Saved changes for \(exerciseTemplate.exercise.name)", category: "LibraryView")
    }
} 