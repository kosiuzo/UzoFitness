import SwiftUI

struct WorkoutPlanEditorView: View {
    let plan: WorkoutPlan
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var customName: String
    @State private var durationWeeks: Int
    @State private var isActive: Bool
    @State private var notes: String
    @State private var showingDeleteAlert = false
    
    init(plan: WorkoutPlan, viewModel: LibraryViewModel) {
        self.plan = plan
        self.viewModel = viewModel
        self._customName = State(initialValue: plan.customName)
        self._durationWeeks = State(initialValue: plan.durationWeeks)
        self._isActive = State(initialValue: plan.isActive)
        self._notes = State(initialValue: plan.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section {
                    HStack {
                        Text("Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Plan name", text: $customName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper("\(durationWeeks) weeks", value: $durationWeeks, in: 1...52)
                    }
                    
                    if let template = plan.template {
                        HStack {
                            Text("Based on")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(template.name)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    HStack {
                        Text("Started")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(plan.startedAt, style: .date)
                            .foregroundStyle(.primary)
                    }
                    
                    if let endedAt = plan.endedAt {
                        HStack {
                            Text("Ended")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(endedAt, style: .date)
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Plan Details")
                }
                
                // Status Section
                Section {
                    Toggle("Active Plan", isOn: $isActive)
                        .tint(.blue)
                    
                    HStack {
                        Text("Progress")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(plan.completionPercentage))%")
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("End Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(plan.calculatedEndDate, style: .date)
                            .foregroundStyle(.primary)
                    }
                    
                    if plan.isCompleted {
                        HStack {
                            Text("Status")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Completed")
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                // Actions Section
                Section {
                    Button("Delete Plan", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } header: {
                    Text("Actions")
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
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Plan", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deletePlan()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this workout plan? This action cannot be undone.")
            }
        }
    }
    
    private func savePlan() {
        plan.customName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.durationWeeks = durationWeeks
        plan.isActive = isActive
        plan.notes = notes
        
        if !isActive && plan.endedAt == nil {
            plan.endedAt = Date()
        } else if isActive {
            plan.endedAt = nil
        }
        
        viewModel.savePlan(plan)
        dismiss()
    }
    
    private func deletePlan() {
        viewModel.deletePlan(plan)
        dismiss()
    }
}

#Preview {
    let plan = WorkoutPlan(
        customName: "Summer Strength Program",
        durationWeeks: 12,
        notes: "Focus on compound movements and progressive overload"
    )
    let viewModel = LibraryViewModel(modelContext: PersistenceController.preview.container.mainContext)
    
    return WorkoutPlanEditorView(plan: plan, viewModel: viewModel)
}