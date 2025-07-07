import SwiftUI
import SwiftData



struct LoggingView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: LoggingViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                LoggingContentView(viewModel: viewModel)
            } else {
                SwiftUI.ProgressView("Loading...")
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
            } else if !viewModel.exercises.isEmpty {
                // Current Exercise Header
                if viewModel.isWorkoutInProgress {
                    CurrentExerciseHeaderView(
                        currentExercise: viewModel.currentExercise,
                        totalExercises: viewModel.exercises.count,
                        currentIndex: viewModel.currentExerciseIndex,
                        isWorkoutInProgress: viewModel.isWorkoutInProgress,
                        getSupersetNumber: viewModel.getSupersetNumber
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isWorkoutInProgress)
                }
                
                // Exercise List
                exerciseListSection
                
                // Complete Workout Button
                completeWorkoutButton
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
        .refreshable {
            AppLogger.info("[LoggingContentView] Refreshing workout plans", category: "LoggingView")
            viewModel.loadAvailablePlans()
            viewModel.loadLastPerformedData()
        }
        // Remove error alerts for missing workout plans - handle gracefully in UI
    }
    
    // MARK: - Pickers Section
    private var pickersSection: some View {
        VStack(spacing: 20) {
            // Template Picker - Modern Design
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.blue)
                        .font(.headline)
                    Text("Workout Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
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
            
            // Day Picker - Modern Rectangular Design
            if !viewModel.availableDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.availableDays, id: \.id) { day in
                                Button(action: {
                                    AppLogger.info("[LoggingView] Day tapped: \(day.weekday)", category: "LoggingView")
                                    viewModel.handleIntent(.selectDay(day.weekday))
                                }) {
                                    VStack(spacing: 4) {
                                        Text(day.weekday.abbreviation)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(isSelected(day) ? .white : .primary)
                                        
                                        if day.isRest || day.exerciseTemplates.isEmpty {
                                            Image(systemName: "bed.double.fill")
                                                .font(.caption2)
                                                .foregroundColor(isSelected(day) ? .white.opacity(0.8) : .secondary)
                                        } else {
                                            Text("\(day.exerciseTemplates.count)")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(isSelected(day) ? .white : .blue)
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
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
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.groupedExercises, id: \.1.first?.id) { group in
                    if let supersetNumber = group.0 {
                        // Superset group with minimal visual separation
                        VStack(spacing: 12) {
                            ForEach(group.1) { exercise in
                                LoggingExerciseRowView(
                                    exercise: exercise,
                                    onEditSet: { setIndex, reps, weight in
                                        viewModel.handleIntent(.editSet(
                                            exerciseID: exercise.id,
                                            setIndex: setIndex,
                                            reps: reps,
                                            weight: weight
                                        ))
                                    },
                                    onAddSet: {
                                        viewModel.handleIntent(.addSet(exerciseID: exercise.id))
                                    },
                                    onToggleSetCompletion: { setIndex in
                                        viewModel.handleIntent(.toggleSetCompletion(
                                            exerciseID: exercise.id,
                                            setIndex: setIndex
                                        ))
                                    },
                                    onMarkComplete: {
                                        viewModel.handleIntent(.markExerciseComplete(exerciseID: exercise.id))
                                    },
                                    getSupersetNumber: viewModel.getSupersetNumber,
                                    isCurrentExercise: viewModel.currentExercise?.id == exercise.id
                                )
                                .background(Color(.systemGray6).opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        // Individual exercises
                        ForEach(group.1) { exercise in
                            LoggingExerciseRowView(
                                exercise: exercise,
                                onEditSet: { setIndex, reps, weight in
                                    viewModel.handleIntent(.editSet(
                                        exerciseID: exercise.id,
                                        setIndex: setIndex,
                                        reps: reps,
                                        weight: weight
                                    ))
                                },
                                onAddSet: {
                                    viewModel.handleIntent(.addSet(exerciseID: exercise.id))
                                },
                                onToggleSetCompletion: { setIndex in
                                    viewModel.handleIntent(.toggleSetCompletion(
                                        exerciseID: exercise.id,
                                        setIndex: setIndex
                                    ))
                                },
                                onMarkComplete: {
                                    viewModel.handleIntent(.markExerciseComplete(exerciseID: exercise.id))
                                },
                                getSupersetNumber: viewModel.getSupersetNumber,
                                isCurrentExercise: viewModel.currentExercise?.id == exercise.id
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Complete Workout Button
    private var completeWorkoutButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                AppLogger.info("[LoggingView] Complete Workout button tapped", category: "LoggingView")
                viewModel.handleIntent(.finishSession)
            } label: {
                Text("Complete Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.canFinishSession ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canFinishSession)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.background)
        }
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

// MARK: - Logging Exercise Row View
struct LoggingExerciseRowView: View {
    let exercise: SessionExerciseUI
    let onEditSet: (Int, Int, Double) -> Void
    let onAddSet: () -> Void
    let onToggleSetCompletion: (Int) -> Void
    let onMarkComplete: () -> Void
    let getSupersetNumber: ((UUID) -> Int?)?
    let isCurrentExercise: Bool
    
    @State private var editingSetIndex: Int? = nil
    @State private var tempReps: String = ""
    @State private var tempWeight: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let supersetID = exercise.supersetID,
                           let getSupersetNumber = getSupersetNumber,
                           let supersetNumber = getSupersetNumber(supersetID) {
                            SupersetBadgeView(
                                supersetNumber: supersetNumber,
                                isHead: exercise.isSupersetHead
                            )
                        }
                    }
                    
                    Text("\(exercise.plannedSets) sets × \(exercise.plannedReps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if exercise.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        let completedSets = exercise.sets.filter { $0.isCompleted }.count
                        let totalSets = exercise.sets.count
                        
                        Text("\(completedSets)/\(totalSets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Complete All Sets") {
                            onMarkComplete()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Sets List
            VStack(spacing: 8) {
                ForEach(0..<exercise.sets.count, id: \.self) { setIndex in
                    SetRowView(
                        setIndex: setIndex,
                        set: exercise.sets[setIndex],
                        plannedReps: exercise.plannedReps,
                        plannedWeight: exercise.plannedWeight ?? 0,
                        isEditing: editingSetIndex == setIndex,
                        tempReps: $tempReps,
                        tempWeight: $tempWeight,
                        onEdit: {
                            editingSetIndex = setIndex
                            tempReps = "\(exercise.sets[setIndex].reps)"
                            tempWeight = "\(Int(exercise.sets[setIndex].weight))"
                        },
                        onSave: {
                            guard let reps = Int(tempReps),
                                  let weight = Double(tempWeight) else { return }
                            onEditSet(setIndex, reps, weight)
                            editingSetIndex = nil
                        },
                        onCancel: {
                            editingSetIndex = nil
                        },
                        onToggleCompletion: {
                            onToggleSetCompletion(setIndex)
                        }
                    )
                }
                
                // Add Set Button
                if !exercise.isCompleted {
                    Button {
                        onAddSet()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Set")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Rest timer feature temporarily removed for cleaner UI
        }
        .padding(16)
        .background(isCurrentExercise ? Color.blue.opacity(0.05) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentExercise ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .scaleEffect(isCurrentExercise ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCurrentExercise)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    let setIndex: Int
    let set: CompletedSet?
    let plannedReps: Int
    let plannedWeight: Double
    let isEditing: Bool
    @Binding var tempReps: String
    @Binding var tempWeight: String
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(setIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            if isEditing {
                // Editing Mode with Auto-save
                HStack(spacing: 8) {
                    TextField("Reps", text: $tempReps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .onSubmit {
                            onSave()
                        }
                        .onChange(of: tempReps) { oldValue, newValue in
                            // Auto-save after a brief delay when user stops typing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if tempReps == newValue && !tempReps.isEmpty && !tempWeight.isEmpty {
                                    onSave()
                                }
                            }
                        }
                    
                    Text("×")
                        .foregroundColor(.secondary)
                    
                    TextField("Weight", text: $tempWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .onSubmit {
                            onSave()
                        }
                        .onChange(of: tempWeight) { oldValue, newValue in
                            // Auto-save after a brief delay when user stops typing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if tempWeight == newValue && !tempReps.isEmpty && !tempWeight.isEmpty {
                                    onSave()
                                }
                            }
                        }
                    
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else {
                // Direct Editing Mode - No Edit Button Required
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: 4) {
                            if let set = set {
                                Text("\(set.reps)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 30)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            } else {
                                Text("\(plannedReps)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 30)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            }
                            
                            Text("×")
                                .foregroundColor(.secondary)
                            
                            if let set = set {
                                Text("\(Int(set.weight))")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 40)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            } else {
                                Text("\(Int(plannedWeight))")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 40)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            }
                            
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Completion toggle button
                    Button {
                        onToggleCompletion()
                    } label: {
                        Image(systemName: set?.isCompleted == true ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set?.isCompleted == true ? .green : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct LoggingView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingView()
            .modelContainer(PersistenceController.preview.container)
    }
}
