import SwiftUI

struct WorkoutPlanRowView: View {
    let plan: WorkoutPlan
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: WorkoutPlanEditorView(plan: plan, viewModel: viewModel)) {
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
    }
} 