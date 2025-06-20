import SwiftUI

struct WorkoutPlanEditorView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    let plan: WorkoutPlan
    
    @State private var customName: String
    @State private var durationWeeks: Int
    @State private var isActive: Bool
    @State private var showingDeleteConfirmation = false
    
    init(plan: WorkoutPlan, viewModel: LibraryViewModel) {
        self.plan = plan
        self.viewModel = viewModel
        self._customName = State(initialValue: plan.customName)
        self._durationWeeks = State(initialValue: plan.durationWeeks)
        self._isActive = State(initialValue: plan.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Plan Details") {
                    TextField("Plan Name", text: $customName)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Stepper("\(durationWeeks) weeks", value: $durationWeeks, in: 1...52)
                            .labelsHidden()
                        Text("\(durationWeeks) weeks")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Status") {
                    Toggle("Active Plan", isOn: $isActive)
                    
                    if isActive {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Only one plan can be active at a time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let template = plan.template {
                    Section("Template Info") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Based on: \(template.name)")
                                .font(.headline)
                            
                            if !template.summary.isEmpty {
                                Text(template.summary)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Started: \(plan.startedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button("Delete Plan", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlan()
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Plan", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deletePlan()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this workout plan? This action cannot be undone.")
            }
        }
    }
    
    private func savePlan() {
        print("🔄 [WorkoutPlanEditorView.savePlan] Saving plan changes")
        
        do {
            try viewModel.updateWorkoutPlan(
                plan,
                customName: customName,
                durationWeeks: durationWeeks,
                isActive: isActive
            )
            print("✅ [WorkoutPlanEditorView.savePlan] Successfully saved plan")
            dismiss()
        } catch {
            print("❌ [WorkoutPlanEditorView.savePlan] Error: \(error.localizedDescription)")
            viewModel.error = error
        }
    }
    
    private func deletePlan() {
        print("🔄 [WorkoutPlanEditorView.deletePlan] Deleting plan")
        
        do {
            try viewModel.deleteWorkoutPlan(plan)
            print("✅ [WorkoutPlanEditorView.deletePlan] Successfully deleted plan")
            dismiss()
        } catch {
            print("❌ [WorkoutPlanEditorView.deletePlan] Error: \(error.localizedDescription)")
            viewModel.error = error
        }
    }
}

// MARK: - Preview
#Preview {
    WorkoutPlanEditorView(
        plan: WorkoutPlan(customName: "Sample Plan", isActive: true, durationWeeks: 8),
        viewModel: LibraryViewModel(modelContext: PersistenceController.preview.container.mainContext)
    )
} 