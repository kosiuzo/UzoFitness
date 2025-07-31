import SwiftUI

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingTemplateEditor = false
    
    private var orderedWeekdays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
    
    var body: some View {
        List {
            // Template Info Section
            Section("Workout Info") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(template.name)
                        .font(.headline)
                    
                    if !template.summary.isEmpty {
                        Text(template.summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
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
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingTemplateEditor = true
                }
            }
        }
        .sheet(isPresented: $showingTemplateEditor) {
            WorkoutTemplateEditorView(template: template, viewModel: viewModel)
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
} 