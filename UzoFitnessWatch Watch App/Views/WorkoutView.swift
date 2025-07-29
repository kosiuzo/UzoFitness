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
            VStack(spacing: 12) {
                // Workout Progress
                WorkoutProgressView(session: session, viewModel: viewModel)
                
                // Current Exercise
                if let currentExercise = viewModel.currentExercise {
                    CurrentExerciseView(
                        exercise: currentExercise,
                        showingSetCompletion: $showingSetCompletion
                    )
                } else {
                    Text("Loading exercise...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Navigation Controls
                WorkoutNavigationControls(viewModel: viewModel)
                
                // Quick Actions
                WorkoutQuickActions(viewModel: viewModel)
            }
            .padding(.horizontal, 8)
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
        VStack(spacing: 8) {
            Text(session.title)
                .font(.headline)
                .lineLimit(1)
            
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(session.currentExerciseIndex)/\(session.totalExercises) exercises")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Current Exercise View
struct CurrentExerciseView: View {
    let exercise: SessionExercise
    @Binding var showingSetCompletion: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text(exercise.exercise.name)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if !exercise.exercise.instructions.isEmpty {
                Text(exercise.exercise.instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Set Information
            VStack(spacing: 4) {
                Text("Target: \(exercise.plannedSets) sets × \(exercise.plannedReps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let weight = exercise.plannedWeight, weight > 0 {
                    Text("Weight: \(Int(weight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Complete Set") {
                showingSetCompletion = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
.background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Workout Navigation Controls
struct WorkoutNavigationControls: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.handle(.previousExercise)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.currentExerciseIndex == 0)
            
            Spacer()
            
            Text("Exercise \(viewModel.currentExerciseIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                viewModel.handle(.nextExercise)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
}

// MARK: - Workout Quick Actions
struct WorkoutQuickActions: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button("Rest Timer") {
                    viewModel.handle(.startRestTimer(duration: 90, exerciseName: viewModel.currentExercise?.exercise.name))
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("Complete") {
                    viewModel.handle(.completeWorkout)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
            }
            
            Button("Cancel Workout") {
                viewModel.handle(.cancelWorkout)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(.top, 8)
    }
}

// MARK: - Completed Workout View
struct CompletedWorkoutView: View {
    let viewModel: WatchWorkoutViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Workout Complete!")
                .font(.headline)
            
            Text("Great job! Your workout has been saved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("New Workout") {
                // Reset to check for another workout
                viewModel.handle(.startTodaysWorkout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
        NavigationStack {
            VStack(spacing: 16) {
                Text("Complete Set")
                    .font(.headline)
                
                if let exercise = viewModel.currentExercise {
                    Text(exercise.exercise.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Reps:")
                                .font(.caption)
                            TextField("12", text: $repsInput)
                                .focused($isRepsFieldFocused)
                        }
                        
                        HStack {
                            Text("Weight:")
                                .font(.caption)
                            TextField("0", text: $weightInput)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPresented = false
                            resetInputs()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            completeSet()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(repsInput.isEmpty)
                    }
                }
            }
            .padding()
            .onAppear {
                setupDefaultValues()
                isRepsFieldFocused = true
            }
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
            exerciseID: exercise.exercise.id,
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

#Preview {
    WorkoutView(viewModel: WatchWorkoutViewModel(
        modelContext: ModelContext.preview,
        syncCoordinator: SyncCoordinator.shared,
        sharedData: SharedDataManager.shared,
        calendar: CalendarService()
    ))
}