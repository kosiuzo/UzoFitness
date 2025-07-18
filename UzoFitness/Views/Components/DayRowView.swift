import SwiftUI

struct DayRowView: View {
    let weekday: Weekday
    let dayTemplate: DayTemplate?
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayName)
                        .font(.headline)
                    
                    if let dayTemplate = dayTemplate {
                        if dayTemplate.isRest {
                            Text("Rest Day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(dayTemplate.exerciseTemplates.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                // Rest/Workout capsule button
                RestWorkoutCapsuleButton(
                    isRest: dayTemplate?.isRest ?? false,
                    onToggle: toggleRestDay
                )
            }
        }
    }
    
    private var dayName: String {
        weekday.fullName
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let dayTemplate = dayTemplate {
            DayDetailView(dayTemplate: dayTemplate, viewModel: viewModel)
        } else {
            Text("Day not configured")
                .foregroundStyle(.secondary)
        }
    }
    
    private func toggleRestDay() {
        if let dayTemplate = dayTemplate {
            viewModel.toggleRestDay(for: dayTemplate)
        }
    }
} 