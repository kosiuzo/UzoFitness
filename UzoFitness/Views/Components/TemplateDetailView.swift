import SwiftUI
import UzoFitnessCore

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var summary: String
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    
    init(template: WorkoutTemplate, viewModel: LibraryViewModel) {
        self.template = template
        self.viewModel = viewModel
        self._name = State(initialValue: template.name)
        self._summary = State(initialValue: template.summary)
    }
    
    private var orderedWeekdays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
    
    var body: some View {
        List {
            // Template Info Section
            Section("Workout Info") {
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        TextField("Workout Name", text: $name)
                            .font(.headline)
                            .autocapitalization(.words)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Summary", text: $summary, axis: .vertical)
                            .font(.body)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(template.name)
                            .font(.headline)
                        
                        if !template.summary.isEmpty {
                            Text(template.summary)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Created: \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            
            // Days Section
            Section("Weekly Schedule") {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    DayRowView(
                        weekday: weekday,
                        dayTemplate: template.dayTemplateFor(weekday),
                        viewModel: viewModel
                    )
                }
            }
            
            // Delete Template Section
            Section {
                Button("Delete Workout", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isEditing ? "Edit Workout" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            // Reset values
                            name = template.name
                            summary = template.summary
                            isEditing = false
                        }
                        
                        Button("Save") {
                            saveTemplate()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteTemplate(template)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
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
    
    private func saveTemplate() {
        AppLogger.info("[TemplateDetailView.saveTemplate] Saving template changes", category: "LibraryView")
        
        do {
            try viewModel.updateTemplate(
                template,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            AppLogger.info("[TemplateDetailView.saveTemplate] Successfully saved template", category: "LibraryView")
            isEditing = false
        } catch {
            AppLogger.error("[TemplateDetailView.saveTemplate] Error saving template", category: "LibraryView", error: error)
            viewModel.error = error
        }
    }
} 