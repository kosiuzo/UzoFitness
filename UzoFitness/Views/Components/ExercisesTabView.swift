import SwiftUI

struct ExercisesTabView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingExerciseCreator = false // for create
    @State private var showingJSONImport = false
    @State private var selectedExerciseForEdit: Exercise? // for edit
    
    var body: some View {
        VStack(spacing: 0) {
            // List of exercises
            if viewModel.exercises.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises to get started")
                    )
                    
                    Button("Add Exercise") {
                        showingExerciseCreator = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Import from JSON") {
                        showingJSONImport = true
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 0) {
                    // Add Exercise Button
                    HStack {
                        Spacer()
                        
                        Button {
                            showingExerciseCreator = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    List {
                        ForEach(viewModel.exercises) { exercise in
                            ExerciseRowView(exercise: exercise)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedExerciseForEdit = exercise
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteExercise(exercise)
                                    }
                                    
                                    Button("Edit") {
                                        selectedExerciseForEdit = exercise
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onDelete(perform: deleteExercises)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingExerciseCreator = true
                    } label: {
                        Label("Create Exercise", systemImage: "plus")
                    }
                    
                    Button {
                        showingJSONImport = true
                    } label: {
                        Label("Import from JSON", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingExerciseCreator) {
            ExerciseEditorView(exercise: nil, viewModel: viewModel)
        }
        .sheet(item: $selectedExerciseForEdit) { exercise in
            ExerciseEditorView(exercise: exercise, viewModel: viewModel)
        }
        .sheet(isPresented: $showingJSONImport) {
            JSONImportView(
                importAction: { jsonData in
                    try viewModel.importExercises(from: jsonData)
                },
                errorMessage: viewModel.importErrorMessage
            )
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func deleteExercises(offsets: IndexSet) {
        for index in offsets {
            let exercise = viewModel.exercises[index]
            viewModel.deleteExercise(exercise)
        }
    }
} 