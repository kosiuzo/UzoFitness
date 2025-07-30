import SwiftUI
import SwiftData
import WatchKit
import UzoFitnessCore

struct WorkoutView: View {
    @ObservedObject var viewModel: WatchWorkoutViewModel
    @State private var showingSetCompletion = false
    @State private var repsInput: String = ""
    @State private var weightInput: String = ""
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    IdleWorkoutView(viewModel: viewModel)
                    
                case .loading:
                    LoadingWorkoutView()
                    
                case .noWorkoutToday:
                    NoWorkoutView()
                    
                case .workoutAvailable(let plan):
                    AvailableWorkoutView(plan: plan, viewModel: viewModel)
                    
                case .workoutInProgress(let session):
                    ActiveWorkoutView(
                        session: session,
                        viewModel: viewModel,
                        showingSetCompletion: $showingSetCompletion,
                        repsInput: $repsInput,
                        weightInput: $weightInput
                    )
                    
                case .workoutCompleted:
                    CompletedWorkoutView(viewModel: viewModel)
                    
                case .error(let message):
                    ErrorWorkoutView(message: message, viewModel: viewModel)
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSetCompletion) {
            SetCompletionSheet(
                viewModel: viewModel,
                repsInput: $repsInput,
                weightInput: $weightInput,
                isPresented: $showingSetCompletion
            )
        }
    }
}

// MARK: - Idle Workout View
struct IdleWorkoutView: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("UzoFitness")
                .font(.headline)
            
            Text("Ready to workout")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Check Today's Workout") {
                viewModel.handle(.startTodaysWorkout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Loading Workout View
struct LoadingWorkoutView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading workout...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - No Workout View
struct NoWorkoutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Rest Day")
                .font(.headline)
            
            Text("No workout scheduled for today")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Available Workout View
struct AvailableWorkoutView: View {
    let plan: WorkoutPlan
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text(plan.customName)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Ready to start")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Start Workout") {
                viewModel.handle(.startTodaysWorkout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    let session: SharedWorkoutSession
    let viewModel: WatchWorkoutViewModel
    @Binding var showingSetCompletion: Bool
    @Binding var repsInput: String
    @Binding var weightInput: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Workout Progress
                WorkoutProgressView(session: session, viewModel: viewModel)
                
                // Current Exercise
                if let currentExercise = viewModel.currentExercise {
                    CurrentExerciseView(
                        exercise: currentExercise,
                        showingSetCompletion: $showingSetCompletion
                    )
                } else {
                    Text("Loading...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Quick Actions Only
                MinimalWorkoutActions(viewModel: viewModel)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Workout Progress View
struct WorkoutProgressView: View {
    let session: SharedWorkoutSession
    let viewModel: WatchWorkoutViewModel
    
    private var progressPercentage: Double {
        guard session.totalExercises > 0 else { return 0 }
        return Double(session.currentExerciseIndex) / Double(session.totalExercises)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(session.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 4)
            
            Text("\(session.currentExerciseIndex + 1)/\(session.totalExercises)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Current Exercise View
struct CurrentExerciseView: View {
    let exercise: SharedSessionExercise
    @Binding var showingSetCompletion: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(exercise.name)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            // Compact Set Information
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("\(exercise.plannedSets)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text("×")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 2) {
                    Text("\(exercise.plannedReps)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("reps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let weight = exercise.plannedWeight, weight > 0 {
                    Text("@")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(weight))")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("lbs")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button("Complete Set") {
                showingSetCompletion = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .font(.caption)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Workout Navigation Controls
struct WorkoutNavigationControls: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.handle(.previousExercise)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(viewModel.currentExerciseIndex == 0)
            
            Spacer()
            
            Text("\(viewModel.currentExerciseIndex + 1) of \(viewModel.allExercises.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                viewModel.handle(.nextExercise)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(viewModel.currentExerciseIndex >= viewModel.allExercises.count - 1)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Minimal Workout Actions
struct MinimalWorkoutActions: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button("Rest 90s") {
                viewModel.handle(.startRestTimer(duration: 90, exerciseName: viewModel.currentExercise?.name))
            }
            .buttonStyle(.bordered)
            .font(.caption)
            
            Button("Next") {
                viewModel.handle(.nextExercise)
            }
            .buttonStyle(.borderedProminent)
            .font(.caption)
            .disabled(viewModel.currentExerciseIndex >= viewModel.allExercises.count - 1)
        }
        .padding(.top, 8)
    }
}

// MARK: - Completed Workout View
struct CompletedWorkoutView: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Complete!")
                .font(.system(size: 16, weight: .semibold))
            
            Text("Great job! Workout saved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Done") {
                // This will be handled by the auto-reset in viewModel
                // But user can manually trigger it too
                viewModel.handle(.cancelWorkout)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .font(.caption)
        }
        .padding(12)
        .onAppear {
            // Additional safety: auto-reset after 5 seconds if user doesn't interact
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if case .workoutCompleted = viewModel.state {
                    viewModel.handle(.cancelWorkout)
                }
            }
        }
    }
}

// MARK: - Error Workout View
struct ErrorWorkoutView: View {
    let message: String
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                viewModel.handle(.startTodaysWorkout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Set Completion Sheet
struct SetCompletionSheet: View {
    let viewModel: WatchWorkoutViewModel
    @Binding var repsInput: String
    @Binding var weightInput: String
    @Binding var isPresented: Bool
    @FocusState private var isRepsFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Complete Set")
                    .font(.system(size: 16, weight: .medium))
                
                if let exercise = viewModel.currentExercise {
                    Text(exercise.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                    
                    VStack(spacing: 8) {
                        VStack(spacing: 4) {
                            Text("Reps")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("12", text: $repsInput)
                                .focused($isRepsFieldFocused)
                                .frame(width: 80)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Weight (lbs)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0", text: $weightInput)
                                .frame(width: 80)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            isPresented = false
                            resetInputs()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .font(.caption)
                        
                        Button("Save") {
                            completeSet()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .font(.caption)
                        .disabled(repsInput.isEmpty)
                    }
                }
            }
            .padding(8)
        }
        .onAppear {
            setupDefaultValues()
            isRepsFieldFocused = true
        }
    }
    
    private func setupDefaultValues() {
        if let exercise = viewModel.currentExercise {
            repsInput = "\(exercise.plannedReps)"
            weightInput = exercise.plannedWeight.map { "\(Int($0))" } ?? "0"
        }
    }
    
    private func completeSet() {
        guard let exercise = viewModel.currentExercise,
              let reps = Int(repsInput),
              let weight = Double(weightInput) else { return }
        
        viewModel.handle(.completeSet(
            exerciseID: exercise.exerciseId,
            setIndex: 0, // TODO: Track actual set index
            reps: reps,
            weight: weight
        ))
        
        isPresented = false
        resetInputs()
    }
    
    private func resetInputs() {
        repsInput = ""
        weightInput = ""
    }
}

// MARK: - All Exercises Overview
struct AllExercisesView: View {
    let exercises: [SharedSessionExercise]
    let currentIndex: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Today's Workout")
                .font(.caption)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseChipView(
                            exercise: exercise,
                            isCurrent: index == currentIndex,
                            isCompleted: exercise.isCompleted
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Chip View
struct ExerciseChipView: View {
    let exercise: SharedSessionExercise
    let isCurrent: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text(exercise.name)
                .font(.caption2)
                .fontWeight(isCurrent ? .semibold : .regular)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("\(exercise.completedSets.count)/\(exercise.plannedSets)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else if isCurrent {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isCurrent ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isCompleted ? Color.green : (isCurrent ? Color.blue : Color.clear),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    WorkoutView(viewModel: WatchWorkoutViewModel(
        modelContext: ModelContext.preview,
        syncCoordinator: SyncCoordinator.shared,
        sharedData: SharedDataManager.shared,
        calendar: CalendarService()
    ))
}