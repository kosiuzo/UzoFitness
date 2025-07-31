import SwiftUI

struct WorkoutsTabView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingTemplateEditor = false
    @State private var showingPlanCreator = false
    @State private var showingJSONImport = false
    @State private var navigationPath = NavigationPath()
    @State private var templateToEdit: WorkoutTemplate?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header with title and create button
                HStack {
                    Spacer()
                    // Toolbar/menu button will be conditionally added below
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // List of workouts
                if viewModel.workoutTemplates.isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No Workouts",
                            systemImage: "figure.strengthtraining.traditional",
                            description: Text("Create your first workout to get started")
                        )
                        
                        Button("Create Workout") {
                            createNewWorkout() // New streamlined workout creation
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Import from JSON") {
                            showingJSONImport = true
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button {
                                showingJSONImport = true
                            } label: {
                                Label("Import from JSON", systemImage: "doc.text")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        
                        List {
                            // Workout Templates Section
                            Section("My Workouts") {
                                ForEach(viewModel.workoutTemplates) { template in
                                    NavigationLink(value: template) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(.headline)
                                            if (!template.summary.isEmpty) {
                                                Text(template.summary)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                
                                Button("Add Workout") {
                                    createNewWorkout() // New streamlined workout creation
                                }
                                .foregroundStyle(.blue)
                            }
                            
                            // Workout Plans Section
                            Section("My Schedule") {
                                if viewModel.workoutPlans.isEmpty {
                                    Text("No schedules")
                                        .foregroundStyle(.secondary)
                                        .italic()
                                } else {
                                    ForEach(viewModel.workoutPlans) { plan in
                                        WorkoutPlanRowView(plan: plan, viewModel: viewModel)
                                    }
                                }
                                
                                Button("Schedule Workout") {
                                    showingPlanCreator = true
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: WorkoutTemplate.self) { template in
                WorkoutTemplateEditorView(template: template, viewModel: viewModel)
            }
            .navigationDestination(for: String.self) { identifier in
                if identifier == "new_workout" {
                    // Navigate directly to the newly created workout's editor view
                    if let latestTemplate = viewModel.workoutTemplates.first {
                        WorkoutTemplateEditorView(template: latestTemplate, viewModel: viewModel)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplateEditor) {
            WorkoutTemplateEditorView(template: templateToEdit, viewModel: viewModel)
        }
        .actionSheet(isPresented: $showingPlanCreator) {
            ActionSheet(
                title: Text("Create Plan From Workout"),
                buttons: viewModel.workoutTemplates.map { template in
                    .default(Text(template.name)) {
                        viewModel.createPlan(from: template)
                    }
                } + [.cancel()]
            )
        }
        .sheet(isPresented: $showingJSONImport) {
            WorkoutTemplateJSONImportView(viewModel: viewModel)
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
    
    // MARK: - Helper Methods
    private func createNewWorkout() {
        templateToEdit = nil // Create new template
        showingTemplateEditor = true
    }
} 