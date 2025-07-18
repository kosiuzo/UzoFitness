import SwiftUI
import UzoFitnessCore

struct WorkoutPlanEditorView: View {
    let plan: WorkoutPlan
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var customName: String
    @State private var durationWeeks: Int
    @State private var isActive: Bool
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    
    init(plan: WorkoutPlan, viewModel: LibraryViewModel) {
        self.plan = plan
        self.viewModel = viewModel
        self._customName = State(initialValue: plan.customName)
        self._durationWeeks = State(initialValue: plan.durationWeeks)
        self._isActive = State(initialValue: plan.isActive)
    }
    
    var body: some View {
        List {
            // Plan Info Section
            Section("Plan Details") {
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        TextField("Plan Name", text: $customName)
                            .font(.headline)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Text("Duration (weeks)")
                                .font(.body)
                            Spacer()
                            Stepper(value: $durationWeeks, in: 1...52) {
                                Text("\(durationWeeks)")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Toggle("Active Plan", isOn: $isActive)
                            .font(.body)
                    } else {
                        Text(plan.customName)
                            .font(.headline)
                        
                        HStack {
                            Text("Duration:")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("\(plan.durationWeeks) weeks")
                                .font(.body)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Status:")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(plan.isActive ? "Active" : "Inactive")
                                .font(.body)
                                .fontWeight(plan.isActive ? .semibold : .regular)
                                .foregroundStyle(plan.isActive ? .blue : .primary)
                            Spacer()
                        }
                    }
                    
                    Text("Created: \(plan.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            
            // Template Info Section
            if let template = plan.template {
                Section("Based on Workout") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.headline)
                        
                        if !template.summary.isEmpty {
                            Text(template.summary)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Workout created: \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Delete Plan Section
            Section {
                Button("Delete Plan", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isEditing ? "Edit Plan" : plan.customName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            // Reset values
                            customName = plan.customName
                            durationWeeks = plan.durationWeeks
                            isActive = plan.isActive
                            isEditing = false
                        }
                        
                        Button("Save") {
                            savePlan()
                        }
                        .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
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
    
    private func savePlan() {
        AppLogger.info("[WorkoutPlanEditorView.savePlan] Saving plan changes", category: "LibraryView")
        
        do {
            try viewModel.updateWorkoutPlan(
                plan,
                customName: customName.trimmingCharacters(in: .whitespacesAndNewlines),
                durationWeeks: durationWeeks,
                isActive: isActive
            )
            AppLogger.info("[WorkoutPlanEditorView.savePlan] Successfully saved plan", category: "LibraryView")
            isEditing = false
        } catch {
            AppLogger.error("[WorkoutPlanEditorView.savePlan] Error", category: "LibraryView", error: error)
            viewModel.error = error
        }
    }
    
    private func deletePlan() {
        AppLogger.info("[WorkoutPlanEditorView.deletePlan] Deleting plan", category: "LibraryView")
        
        do {
            try viewModel.deleteWorkoutPlan(plan)
            AppLogger.info("[WorkoutPlanEditorView.deletePlan] Successfully deleted plan", category: "LibraryView")
            dismiss()
        } catch {
            AppLogger.error("[WorkoutPlanEditorView.deletePlan] Error", category: "LibraryView", error: error)
            viewModel.error = error
        }
    }
} 