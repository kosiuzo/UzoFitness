import SwiftUI
import SwiftData

struct LoggingView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: LoggingViewModel?
    @State private var showingWorkoutSession = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    LoggingContentView(viewModel: viewModel, showingWorkoutSession: $showingWorkoutSession)
                } else {
                    SwiftUI.ProgressView("Loading...")
                }
            }
            .fullScreenCover(isPresented: $showingWorkoutSession) {
                if let viewModel = viewModel {
                    WorkoutSessionView(viewModel: viewModel, isPresented: $showingWorkoutSession)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                AppLogger.info("[LoggingView] Initializing viewModel with context", category: "LoggingView")
                viewModel = LoggingViewModel(modelContext: context)
            }
        }
    }
}

// MARK: - Logging Content View
struct LoggingContentView: View {
    @ObservedObject var viewModel: LoggingViewModel
    @Binding var showingWorkoutSession: Bool
    
    var body: some View {
        contentView
            .onAppear {
                AppLogger.info("[LoggingContentView] View appeared - loading data", category: "LoggingView")
                viewModel.loadAvailablePlans()
                viewModel.loadLastPerformedData()
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            // Template and Day Pickers
            pickersSection
            
            if viewModel.availablePlans.isEmpty {
                // No workout plans available - show create workout guidance
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isRestDay {
                // Rest day selected
                restDayView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.activePlan != nil && viewModel.selectedDay != nil && !viewModel.isRestDay {
                // Show day summary and start session button
                daySummarySection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.activePlan != nil && viewModel.selectedDay != nil {
                // Workout plan selected but no exercises for this day - treat as rest day
                restDayView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Plan selected but no day selected - show day selection prompt
                daySelectionPromptView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.background.secondary)
        // .refreshable { ... } removed to disable pull-to-refresh
        // Remove error alerts for missing workout plans - handle gracefully in UI
    }
    
    // MARK: - Pickers Section
    private var pickersSection: some View {
        VStack(spacing: 20) {
            // Template Picker - Modern Design
            VStack(alignment: .leading, spacing: 12) {
                
                if viewModel.availablePlans.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No workout plans available")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    Menu {
                        ForEach(viewModel.availablePlans) { plan in
                            Button(action: {
                                viewModel.handleIntent(.selectPlan(plan.id))
                            }) {
                                HStack {
                                    Text(plan.customName)
                                    if plan.isActive {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.activePlan?.customName ?? "Select a plan")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.activePlan != nil ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.quaternary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Day Picker - Compact Design
            if !viewModel.availableDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    
                    HStack(spacing: 6) {
                        ForEach(viewModel.availableDays, id: \.id) { day in
                            Button(action: {
                                AppLogger.info("[LoggingView] Day tapped: \(day.weekday)", category: "LoggingView")
                                viewModel.handleIntent(.selectDay(day.weekday))
                            }) {
                                VStack(spacing: 2) {
                                    Text(day.weekday.abbreviation)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(isSelected(day) ? .white : .primary)
                                    
                                    if day.isRest || day.exerciseTemplates.isEmpty {
                                        Image(systemName: "bed.double.fill")
                                            .font(.caption2)
                                            .foregroundColor(isSelected(day) ? .white.opacity(0.8) : .secondary)
                                    } else {
                                        Text("\(day.exerciseTemplates.count)")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(isSelected(day) ? .white : .blue)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected(day) ? .blue : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(isSelected(day) ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected(day))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(.regularMaterial)
    }
    
    private func isSelected(_ day: DayTemplate) -> Bool {
        viewModel.selectedDay?.weekday == day.weekday
    }
    
    // MARK: - Rest Day View
    private var restDayView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bed.double.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text("Rest Day")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Take time to recover and prepare for your next workout.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    // MARK: - Day Summary Section
    private var daySummarySection: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise Summary List
                    if let selectedDay = viewModel.selectedDay {
                        LazyVStack(spacing: 12) {
                            ForEach(selectedDay.exerciseTemplates.sorted(by: { $0.position < $1.position })) { exerciseTemplate in
                                exerciseSummaryRow(exerciseTemplate)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Extra padding at bottom for fixed button
                    Color.clear
                        .frame(height: 80)
                }
            }
            
            // Fixed Start Session Button
            VStack(spacing: 0) {
                Divider()
                
                Button {
                    startWorkoutSession()
                } label: {
                    Text(viewModel.sessionButtonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func exerciseSummaryRow(_ exerciseTemplate: ExerciseTemplate) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseTemplate.exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(exerciseTemplate.setCount) sets × \(exerciseTemplate.reps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let weight = exerciseTemplate.weight, weight > 0 {
                        Text("\(Int(weight)) lbs")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if let supersetID = exerciseTemplate.supersetID,
                   let selectedDay = viewModel.selectedDay,
                   let supersetNumber = selectedDay.getSupersetNumber(for: supersetID) {
                    SupersetBadgeView(
                        supersetNumber: supersetNumber,
                        isHead: selectedDay.exerciseTemplates.filter { $0.supersetID == supersetID }.min(by: { $0.position < $1.position })?.id == exerciseTemplate.id
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func startWorkoutSession() {
        AppLogger.info("[LoggingView] Starting workout session", category: "LoggingView")
        viewModel.handleIntent(.startSession)
        showingWorkoutSession = true
    }
    
    
    // MARK: - Empty State View (No Workout Plans)
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Ready to Start?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Create a workout plan and schedule it in the Library tab first.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
    
    // MARK: - Day Selection Prompt View
    private var daySelectionPromptView: some View {
        VStack(spacing: 32) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Select a Day")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Choose which day of your workout plan you'd like to log.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
}


// MARK: - Preview
struct LoggingView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingView()
            .modelContainer(PersistenceController.preview.container)
    }
}
