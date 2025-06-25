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
                ProgressView("Loading...")
            }
        }
        .onAppear {
            if viewModel == nil {
                print("🔄 [LoggingView] Initializing viewModel with context")
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
                print("🔄 [LoggingContentView] View appeared - loading data")
                viewModel.loadAvailablePlans()
                viewModel.loadLastPerformedData()
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            // Template and Day Pickers
            pickersSection
            
            if viewModel.isRestDay {
                restDayView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.exercises.isEmpty {
                // Exercise List
                exerciseListSection
                
                // Complete Workout Button
                completeWorkoutButton
            } else {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.background.secondary)
        .refreshable {
            print("🔄 [LoggingContentView] Refreshing workout plans")
            viewModel.loadAvailablePlans()
            viewModel.loadLastPerformedData()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Pickers Section
    private var pickersSection: some View {
        VStack(spacing: 16) {
            // Template Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Workout Plan")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if viewModel.availablePlans.isEmpty {
                    Text("No workout plans available")
                        .foregroundColor(.secondary)
                        .padding()
                        .background(.tertiary)
                        .cornerRadius(8)
                } else {
                    Picker("Workout Plan", selection: Binding(
                        get: { viewModel.activePlan?.id ?? UUID() },
                        set: { planID in
                            if planID != UUID() {
                                viewModel.handleIntent(.selectPlan(planID))
                            }
                        }
                    )) {
                        ForEach(viewModel.availablePlans) { plan in
                            HStack {
                                Text(plan.customName)
                                if plan.isActive {
                                    Spacer()
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .tag(plan.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Day Picker - Clean Design
            if !viewModel.availableDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Select Day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableDays, id: \.id) { day in
                                Button(action: {
                                    print("🔄 [LoggingView] Day tapped: \(day.weekday)")
                                    viewModel.handleIntent(.selectDay(day.weekday))
                                }) {
                                    VStack(spacing: 4) {
                                        Text(day.weekday.abbreviation)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        if day.isRest {
                                            Circle()
                                                .fill(.secondary)
                                                .frame(width: 4, height: 4)
                                        } else {
                                            Text("\(day.exerciseTemplates.count)")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .foregroundColor(viewModel.selectedDay?.weekday == day.weekday ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(viewModel.selectedDay?.weekday == day.weekday ? .blue : Color(.systemGray5))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(.background)
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
            LazyVStack(spacing: 12) {
                ForEach(viewModel.exercises) { exercise in
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
                        onStartRest: { seconds in
                            viewModel.handleIntent(.startRest(
                                exerciseID: exercise.id,
                                seconds: seconds
                            ))
                        },
                        onMarkComplete: {
                            viewModel.handleIntent(.markExerciseComplete(exerciseID: exercise.id))
                        }
                    )
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
                print("🔄 [LoggingView] Complete Workout button tapped")
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
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("No Exercises Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Text("Select a workout plan and day to get started.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if viewModel.availablePlans.isEmpty {
                    Text("Create a workout plan in the Library tab first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    Text("Found \(viewModel.availablePlans.count) workout plan(s)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let activePlan = viewModel.activePlan {
                    Text("Active Plan: \(activePlan.customName)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("No active plan selected")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Text("Available Days: \(viewModel.availableDays.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            
            // Debug refresh button
            Button("Refresh Plans") {
                print("🔄 [EmptyStateView] Manual refresh triggered")
                viewModel.loadAvailablePlans()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Logging Exercise Row View
struct LoggingExerciseRowView: View {
    let exercise: SessionExerciseUI
    let onEditSet: (Int, Int, Double) -> Void
    let onAddSet: () -> Void
    let onStartRest: (TimeInterval) -> Void
    let onMarkComplete: () -> Void
    
    @State private var editingSetIndex: Int? = nil
    @State private var tempReps: String = ""
    @State private var tempWeight: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(exercise.plannedSets) sets × \(exercise.plannedReps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if exercise.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Button("Complete All Sets") {
                        onMarkComplete()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Sets List
            VStack(spacing: 8) {
                ForEach(0..<max(exercise.sets.count, 1), id: \.self) { setIndex in
                    SetRowView(
                        setIndex: setIndex,
                        set: setIndex < exercise.sets.count ? exercise.sets[setIndex] : nil,
                        plannedReps: exercise.plannedReps,
                        plannedWeight: exercise.plannedWeight ?? 0,
                        isEditing: editingSetIndex == setIndex,
                        tempReps: $tempReps,
                        tempWeight: $tempWeight,
                        onEdit: {
                            editingSetIndex = setIndex
                            if setIndex < exercise.sets.count {
                                tempReps = "\(exercise.sets[setIndex].reps)"
                                tempWeight = "\(Int(exercise.sets[setIndex].weight))"
                            } else {
                                tempReps = "\(exercise.plannedReps)"
                                tempWeight = "\(Int(exercise.plannedWeight ?? 0))"
                            }
                        },
                        onSave: {
                            guard let reps = Int(tempReps),
                                  let weight = Double(tempWeight) else { return }
                            onEditSet(setIndex, reps, weight)
                            editingSetIndex = nil
                        },
                        onCancel: {
                            editingSetIndex = nil
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
            
            // Rest Timer Section
            if let timerRemaining = exercise.timerRemaining, timerRemaining > 0 {
                VStack(spacing: 8) {
                    Text("Rest Timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(timerRemaining))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 8)
            } else if !exercise.isCompleted {
                HStack(spacing: 12) {
                    ForEach([60, 90, 120], id: \.self) { seconds in
                        Button("\(seconds)s") {
                            onStartRest(TimeInterval(seconds))
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tertiary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(setIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            if isEditing {
                // Editing Mode
                HStack(spacing: 8) {
                    TextField("Reps", text: $tempReps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    
                    Text("×")
                        .foregroundColor(.secondary)
                    
                    TextField("Weight", text: $tempWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Save") {
                        onSave()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
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
                    
                    if set == nil {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
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
