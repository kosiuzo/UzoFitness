import SwiftUI

struct DayDetailView: View {
    let dayTemplate: DayTemplate
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingExercisePicker = false
    
    var body: some View {
        List {
            if dayTemplate.isRest {
                Section {
                    HStack {
                        Image(systemName: "bed.double")
                            .foregroundStyle(.blue)
                        Text("This is a rest day")
                            .font(.body)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else {
                if dayTemplate.exerciseTemplates.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            
                            Text("No exercises added")
                                .font(.headline)
                            
                            Text("Tap 'Add Exercise' to get started")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    Section("Exercises") {
                        ForEach(dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })) { exerciseTemplate in
                            NavigationLink(destination: ExerciseTemplateEditorView(exerciseTemplate: exerciseTemplate, viewModel: viewModel)) {
                                ExerciseTemplateRowView(exerciseTemplate: exerciseTemplate)
                            }
                        }
                        .onMove(perform: moveExercises)
                        .onDelete(perform: deleteExercises)
                    }
                }
            }
            
            // Notes section
            if !dayTemplate.notes.isEmpty {
                Section("Notes") {
                    Text(dayTemplate.notes)
                        .font(.body)
                }
            }
        }
        .navigationTitle(dayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !dayTemplate.isRest {
                    HStack {
                        EditButton()
                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(viewModel: viewModel) { selectedExercises in
                viewModel.addExercises(selectedExercises, to: dayTemplate)
            }
        }
    }
    
    private var dayName: String {
        dayTemplate.weekday.fullName
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        viewModel.reorderExerciseTemplates(in: dayTemplate, from: source, to: destination)
    }
    
    private func deleteExercises(offsets: IndexSet) {
        AppLogger.info("[DayDetailView.deleteExercises] Deleting exercises at offsets: \(offsets)", category: "LibraryView")
        
        let sortedExercises = dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })
        for index in offsets {
            let exerciseTemplate = sortedExercises[index]
            viewModel.deleteExerciseTemplate(exerciseTemplate)
        }
    }
} 