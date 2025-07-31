import SwiftUI

struct WorkoutPlanRowView: View {
    let plan: WorkoutPlan
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingPlanEditor = false
    
    var body: some View {
        Button {
            showingPlanEditor = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.customName)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        if let template = plan.template {
                            Text("Based on: \(template.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(plan.durationWeeks) weeks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if plan.completionPercentage > 0 {
                            Text("\(Int(plan.completionPercentage))% complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if plan.isActive {
                        Text("ACTIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPlanEditor) {
            WorkoutPlanEditorView(plan: plan, viewModel: viewModel)
        }
    }
} 