import Foundation
import SwiftData
import Combine
import UIKit

// MARK: - SessionExerciseUI Helper Struct
struct SessionExerciseUI: Identifiable, Hashable {
    let id: UUID
    let name: String
    let sets: [CompletedSet]
    let plannedSets: Int
    let plannedReps: Int
    let plannedWeight: Double?
    let currentSet: Int
    let timerRemaining: TimeInterval?
    let isSupersetHead: Bool
    let isCompleted: Bool
    let position: Double
    let supersetID: UUID?
    
    init(from sessionExercise: SessionExercise) {
        self.id = sessionExercise.id
        self.name = sessionExercise.exercise.name
        self.sets = sessionExercise.completedSets.sorted(by: { $0.position < $1.position }) // Sort sets by position
        self.plannedSets = sessionExercise.plannedSets
        self.plannedReps = sessionExercise.plannedReps
        self.plannedWeight = sessionExercise.plannedWeight
        self.currentSet = sessionExercise.currentSet
        self.timerRemaining = sessionExercise.restTimer
        self.isCompleted = sessionExercise.isCompleted
        self.position = sessionExercise.position
        self.supersetID = sessionExercise.supersetID
        
        // Determine if this is the head of a superset (first exercise in the group)
        self.isSupersetHead = sessionExercise.supersetID != nil && 
            sessionExercise.session?.sessionExercises
                .filter { $0.supersetID == sessionExercise.supersetID }
                .min(by: { $0.position < $1.position })?.id == sessionExercise.id
    }
}

// MARK: - LoggingViewModel Intent Actions
enum LoggingIntent {
    case selectPlan(UUID)
    case selectDay(Weekday)
    case editSet(exerciseID: UUID, setIndex: Int, reps: Int, weight: Double)
    case addSet(exerciseID: UUID)
    case toggleSetCompletion(exerciseID: UUID, setIndex: Int)
    case startRest(exerciseID: UUID, seconds: TimeInterval)
    case cancelRest(exerciseID: UUID)
    case markExerciseComplete(exerciseID: UUID)
    case finishSession
}

// MARK: - ViewState Enum
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}

// MARK: - LoggingError
enum LoggingError: Error, LocalizedError {
    case noPlanSelected
    case noDaySelected
    case sessionNotFound
    case exerciseNotFound
    case invalidSetIndex
    case sessionAlreadyCompleted
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .noPlanSelected:
            return "Please select a workout plan first"
        case .noDaySelected:
            return "Please select a day to log"
        case .sessionNotFound:
            return "No active session found"
        case .exerciseNotFound:
            return "Exercise not found in current session"
        case .invalidSetIndex:
            return "Invalid set index"
        case .sessionAlreadyCompleted:
            return "This session has already been completed"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - TimerFactory Protocol
protocol TimerFactory {
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer
}

// MARK: - DefaultTimerFactory
class DefaultTimerFactory: TimerFactory {
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
    }
}

// MARK: - LoggingViewModel
@MainActor
class LoggingViewModel: ObservableObject {
    // MARK: - Published State
    @Published var availablePlans: [WorkoutPlan] = []
    @Published var activePlan: WorkoutPlan?
    @Published var availableDays: [DayTemplate] = []
    @Published var selectedDay: DayTemplate?
    @Published var session: WorkoutSession?
    @Published var exercises: [SessionExerciseUI] = []
    @Published var isRestDay: Bool = false
    @Published var showTimerSheet: Bool = false
    @Published var error: Error?
    @Published var state: ViewState<String> = .idle
    
    // MARK: - Computed Properties
    var canFinishSession: Bool {
        guard session != nil else { return false }
        return !exercises.isEmpty && exercises.allSatisfy { $0.isCompleted }
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (Double(set.reps) * set.weight)
            }
        }
    }
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private let timerFactory: TimerFactory
    private var cancellables = Set<AnyCancellable>()
    private var restTimer: Timer?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    init(modelContext: ModelContext, timerFactory: TimerFactory = DefaultTimerFactory()) {
        self.modelContext = modelContext
        self.timerFactory = timerFactory
        print("🔄 [LoggingViewModel.init] Initialized with dependencies")
        
        loadAvailablePlans()
    }
    
    // MARK: - Auto-select current day after plans are loaded
    private func autoSelectCurrentDay() {
        print("🔄 [LoggingViewModel.autoSelectCurrentDay] Attempting to auto-select current day")
        
        guard !availableDays.isEmpty else {
            print("⚠️ [LoggingViewModel.autoSelectCurrentDay] No available days yet")
            return
        }
        
        let today = Calendar.current.component(.weekday, from: Date())
        if let todayWeekday = Weekday(rawValue: today) {
            // Check if today is available in the current plan
            if availableDays.contains(where: { $0.weekday == todayWeekday }) {
                print("🔄 [LoggingViewModel.autoSelectCurrentDay] Auto-selecting today: \(todayWeekday)")
                handleIntent(.selectDay(todayWeekday))
            } else {
                print("📊 [LoggingViewModel.autoSelectCurrentDay] Today (\(todayWeekday)) not available in plan, keeping manual selection")
            }
        }
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: LoggingIntent) {
        print("🔄 [LoggingViewModel.handleIntent] Processing intent: \(intent)")
        
        switch intent {
        case .selectPlan(let planID):
            selectPlan(planID)
            
        case .selectDay(let weekday):
            selectDay(weekday)
            
        case .editSet(let exerciseID, let setIndex, let reps, let weight):
            editSet(exerciseID: exerciseID, setIndex: setIndex, reps: reps, weight: weight)
            
        case .addSet(let exerciseID):
            addSet(exerciseID: exerciseID)
            
        case .toggleSetCompletion(let exerciseID, let setIndex):
            toggleSetCompletion(exerciseID: exerciseID, setIndex: setIndex)
            
        case .startRest(let exerciseID, let seconds):
            startRest(exerciseID: exerciseID, seconds: seconds)
            
        case .cancelRest(let exerciseID):
            cancelRest(exerciseID: exerciseID)
            
        case .markExerciseComplete(let exerciseID):
            markExerciseComplete(exerciseID: exerciseID)
            
        case .finishSession:
            finishSession()
        }
    }
    
    // MARK: - Data Loading Methods
    func loadAvailablePlans() {
        print("🔄 [LoggingViewModel.loadAvailablePlans] Loading available plans")
        do {
            let fetchDescriptor = FetchDescriptor<WorkoutPlan>()
            let allPlans = try modelContext.fetch(fetchDescriptor)
            
            // Sort manually: Active plans first, then by name
            availablePlans = allPlans.sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive {
                    return lhs.isActive && !rhs.isActive // Active plans first
                }
                return lhs.customName < rhs.customName // Then alphabetically
            }
            
            print("✅ [LoggingViewModel.loadAvailablePlans] Loaded \(availablePlans.count) plans")
            
            // Check if current active plan still exists
            if let currentActivePlan = activePlan,
               !availablePlans.contains(where: { $0.id == currentActivePlan.id }) {
                print("⚠️ [LoggingViewModel.loadAvailablePlans] Active plan was deleted - clearing state")
                // Current active plan was deleted, clear the state
                activePlan = nil
                availableDays = []
                selectedDay = nil
                session = nil
                exercises = []
                isRestDay = false
            }
            
            // Auto-select the first active plan if none selected
            if activePlan == nil, let newActivePlan = availablePlans.first(where: { $0.isActive }) {
                print("🔄 [LoggingViewModel.loadAvailablePlans] Auto-selecting active plan: \(newActivePlan.customName)")
                handleIntent(.selectPlan(newActivePlan.id))
            } else if activePlan != nil {
                // If we already have an active plan, auto-select current day
                autoSelectCurrentDay()
            }
        } catch {
            print("❌ [LoggingViewModel.loadAvailablePlans] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func loadLastPerformedData() {
        print("🔄 [LoggingViewModel.loadLastPerformedData] Loading last performed data")
        
        guard selectedDay != nil else {
            print("❌ [LoggingViewModel.loadLastPerformedData] No day selected")
            return
        }
        
        // This method would populate exercises with last performed values
        // Implementation would depend on your specific data access patterns
        print("✅ [LoggingViewModel.loadLastPerformedData] Last performed data loaded")
    }
    
    // MARK: - Private Methods
    private func selectPlan(_ planID: UUID) {
        print("🔄 [LoggingViewModel.selectPlan] Selecting plan: \(planID)")
        
        do {
            let fetchDescriptor = FetchDescriptor<WorkoutPlan>(
                predicate: #Predicate { $0.id == planID }
            )
            let plans = try modelContext.fetch(fetchDescriptor)
            
            guard let plan = plans.first else {
                print("❌ [LoggingViewModel.selectPlan] Plan not found")
                error = LoggingError.custom("Plan not found")
                return
            }
            
            activePlan = plan
            print("✅ [LoggingViewModel.selectPlan] Plan selected: \(plan.customName)")
            print("📊 [LoggingViewModel] Active plan changed to: \(plan.customName)")
            
            // Update available days from the selected plan's template
            availableDays = plan.template?.dayTemplates.sorted(by: { $0.weekday.rawValue < $1.weekday.rawValue }) ?? []
            print("📊 [LoggingViewModel.selectPlan] Loaded \(availableDays.count) days for plan")
            
            // Auto-select current day if no day is currently selected
            if selectedDay == nil {
                autoSelectCurrentDay()
            } else {
                // Refresh day selection if already selected
                if let selectedDay = selectedDay {
                    self.selectDay(selectedDay.weekday)
                }
            }
            
        } catch {
            print("❌ [LoggingViewModel.selectPlan] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func selectDay(_ weekday: Weekday) {
        print("🔄 [LoggingViewModel.selectDay] Selecting day: \(weekday)")
        
        guard let activePlan = activePlan,
              let template = activePlan.template else {
            print("❌ [LoggingViewModel.selectDay] No active plan or template")
            error = LoggingError.noPlanSelected
            return
        }
        
        // Find the day template for this weekday
        let dayTemplate = template.dayTemplates.first { $0.weekday == weekday }
        selectedDay = dayTemplate
        isRestDay = dayTemplate?.isRest ?? false
        
        print("📊 [LoggingViewModel] Selected day: \(weekday), isRestDay: \(isRestDay)")
        if let dayTemplate = dayTemplate {
            print("🏃‍♂️ [LoggingViewModel.selectDay] Day template has \(dayTemplate.exerciseTemplates.count) exercises")
            for template in dayTemplate.exerciseTemplates {
                print("  - Exercise: \(template.exercise.name)")
            }
        } else {
            print("❌ [LoggingViewModel.selectDay] No day template found for \(weekday)")
        }
        
        if isRestDay {
            print("🏃‍♂️ [LoggingViewModel.selectDay] Rest day selected")
            // Clear any existing session and exercises for rest days
            session = nil
            exercises = []
        } else {
            createOrResumeSession()
        }
    }
    
    private func createOrResumeSession() {
        print("🔄 [LoggingViewModel.createOrResumeSession] Starting session creation/resume")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            print("❌ [LoggingViewModel.createOrResumeSession] Missing plan or day")
            return
        }
        
        // Check for existing session today
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            // Only look for sessions from the current plan to avoid affecting other plans' history
            let fetchDescriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.date >= startOfDay &&
                    session.date < endOfDay
                }
            )
            let allTodaySessions = try modelContext.fetch(fetchDescriptor)
            
            // Filter for the current plan only
            let planSessions = allTodaySessions.filter { session in
                session.plan?.id == activePlan.id
            }
            
            // Further filter for the specific day/workout
            let daySpecificSessions = planSessions.filter { session in
                session.title.contains(selectedDay.weekday.fullName) || session.title.contains(selectedDay.weekday.abbreviation)
            }
            
            print("🔍 [LoggingViewModel.createOrResumeSession] Found \(daySpecificSessions.count) sessions for current plan and day")
            
            if let existingSession = daySpecificSessions.first {
                // Check if this session was already completed (has duration set)
                if existingSession.duration != nil && existingSession.duration! > 0 {
                    print("🔄 [LoggingViewModel.createOrResumeSession] Found completed session from same plan, creating fresh session instead")
                    createFreshSessionForSameDay(existingSession: existingSession)
                    return
                }
                
                print("✅ [LoggingViewModel.createOrResumeSession] Resuming existing session for \(selectedDay.weekday)")
                print("🔍 [LoggingViewModel.createOrResumeSession] Existing session has \(existingSession.sessionExercises.count) exercises")
                session = existingSession
                sessionStartTime = existingSession.createdAt
                
                // Ensure session exercises exist for resumed sessions
                if existingSession.sessionExercises.isEmpty {
                    print("⚠️ [LoggingViewModel.createOrResumeSession] Resumed session has no exercises, creating them")
                    createSessionExercises(for: existingSession, from: selectedDay)
                }
            } else {
                print("🔄 [LoggingViewModel.createOrResumeSession] Creating new session")
                let newSession = WorkoutSession(
                    date: today,
                    title: "\(selectedDay.weekday.fullName) - \(activePlan.customName)",
                    plan: activePlan
                )
                
                modelContext.insert(newSession)
                session = newSession
                sessionStartTime = Date()
                
                print("🔍 [LoggingViewModel.createOrResumeSession] New session created with ID: \(newSession.id)")
                print("🔍 [LoggingViewModel.createOrResumeSession] Session title: '\(newSession.title)'")
                
                // Create session exercises from day template
                createSessionExercises(for: newSession, from: selectedDay)
                
                // Save immediately to ensure the session persists
                do {
                    try modelContext.save()
                    print("✅ [LoggingViewModel.createOrResumeSession] New session saved successfully")
                } catch {
                    print("❌ [LoggingViewModel.createOrResumeSession] Failed to save new session: \(error.localizedDescription)")
                }
            }
            
            updateExercisesUI()
            print("✅ [LoggingViewModel.createOrResumeSession] Session ready")
            
        } catch {
            print("❌ [LoggingViewModel.createOrResumeSession] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func createFreshSession() {
        print("🔄 [LoggingViewModel.createFreshSession] Creating fresh session (no resume)")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            print("❌ [LoggingViewModel.createFreshSession] Missing plan or day")
            return
        }
        
        let today = Date()
        
        print("🔄 [LoggingViewModel.createFreshSession] Creating new session")
        let newSession = WorkoutSession(
            date: today,
            title: "\(selectedDay.weekday.fullName) - \(activePlan.customName)",
            plan: activePlan
        )
        
        modelContext.insert(newSession)
        session = newSession
        sessionStartTime = Date()
        
        // Create session exercises from day template
        createSessionExercises(for: newSession, from: selectedDay)
        
        updateExercisesUI()
        print("✅ [LoggingViewModel.createFreshSession] Fresh session ready")
    }
    
    private func createFreshSessionForSameDay(existingSession: WorkoutSession) {
        print("🔄 [LoggingViewModel.createFreshSessionForSameDay] Creating fresh session to replace completed one")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            print("❌ [LoggingViewModel.createFreshSessionForSameDay] Missing plan or day")
            return
        }
        
        // Delete the existing completed session since we're starting fresh
        // (This session is guaranteed to be from the same plan due to our filtering)
        print("🔄 [LoggingViewModel.createFreshSessionForSameDay] Deleting existing session from same plan")
        modelContext.delete(existingSession)
        
        let today = Date()
        let newSession = WorkoutSession(
            date: today,
            title: "\(selectedDay.weekday.fullName) - \(activePlan.customName)",
            plan: activePlan
        )
        
        modelContext.insert(newSession)
        session = newSession
        sessionStartTime = Date()
        
        // Create session exercises from day template
        createSessionExercises(for: newSession, from: selectedDay)
        
        // Save immediately
        do {
            try modelContext.save()
            print("✅ [LoggingViewModel.createFreshSessionForSameDay] Fresh session created and saved")
        } catch {
            print("❌ [LoggingViewModel.createFreshSessionForSameDay] Failed to save: \(error.localizedDescription)")
        }
        
        updateExercisesUI()
        print("✅ [LoggingViewModel.createFreshSessionForSameDay] Fresh session ready")
    }
    
    private func createSessionExercises(for session: WorkoutSession, from dayTemplate: DayTemplate) {
        print("🔄 [LoggingViewModel.createSessionExercises] Creating exercises for session")
        
        for exerciseTemplate in dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position }) {
            let sessionExercise = SessionExercise(
                exercise: exerciseTemplate.exercise,
                plannedSets: exerciseTemplate.setCount,
                plannedReps: exerciseTemplate.reps,
                plannedWeight: exerciseTemplate.weight,
                position: exerciseTemplate.position,
                supersetID: exerciseTemplate.supersetID,
                currentSet: 0,
                isCompleted: false, // Explicitly set to false for new sessions
                session: session,
                autoPopulateFromLastSession: true // Enable auto-population from last used values
            )
            
            modelContext.insert(sessionExercise)
            session.sessionExercises.append(sessionExercise)
            
            // Create planned sets as real sets that need to be completed
            for setIndex in 0..<exerciseTemplate.setCount {
                let plannedSet = CompletedSet(
                    reps: exerciseTemplate.reps,
                    weight: exerciseTemplate.weight ?? 0,
                    isCompleted: false, // Mark as not completed initially
                    position: setIndex, // Set proper position for ordering
                    sessionExercise: sessionExercise
                )
                modelContext.insert(plannedSet)
                sessionExercise.completedSets.append(plannedSet)
                print("🏃‍♂️ [LoggingViewModel.createSessionExercises] Created planned set \(setIndex + 1) for \(exerciseTemplate.exercise.name)")
            }
            
            print("🏃‍♂️ [LoggingViewModel.createSessionExercises] Added exercise: \(exerciseTemplate.exercise.name) with \(exerciseTemplate.setCount) planned sets")
        }
        
        print("✅ [LoggingViewModel.createSessionExercises] Created \(dayTemplate.exerciseTemplates.count) session exercises")
    }
    
    private func updateExercisesUI() {
        guard let session = session else {
            exercises = []
            return
        }
        
        exercises = session.sessionExercises
            .sorted(by: { $0.position < $1.position })
            .map { SessionExerciseUI(from: $0) }
        
        print("📊 [LoggingViewModel.updateExercisesUI] Updated UI with \(exercises.count) exercises")
    }
    
    private func editSet(exerciseID: UUID, setIndex: Int, reps: Int, weight: Double) {
        print("🔄 [LoggingViewModel.editSet] Editing set for exercise: \(exerciseID)")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            print("❌ [LoggingViewModel.editSet] Exercise not found")
            error = LoggingError.exerciseNotFound
            return
        }
        
        // Get ordered sets and ensure we have enough completed sets
        var orderedSets = sessionExercise.completedSets.sorted(by: { $0.position < $1.position })
        while orderedSets.count <= setIndex {
            let newPosition = orderedSets.count
            let newSet = CompletedSet(
                reps: sessionExercise.plannedReps,
                weight: sessionExercise.plannedWeight ?? 0,
                isCompleted: false,
                position: newPosition,
                sessionExercise: sessionExercise
            )
            modelContext.insert(newSet)
            sessionExercise.completedSets.append(newSet)
            // Update the ordered sets after adding new set
            orderedSets = sessionExercise.completedSets.sorted(by: { $0.position < $1.position })
        }
        
        guard setIndex < orderedSets.count else {
            print("❌ [LoggingViewModel.editSet] Invalid set index")
            error = LoggingError.invalidSetIndex
            return
        }
        
        let completedSet = orderedSets[setIndex]
        completedSet.reps = reps
        completedSet.weight = weight
        
        // Update current set if editing the current set
        if setIndex >= sessionExercise.currentSet {
            sessionExercise.currentSet = setIndex + 1
        }
        
        updateExercisesUI()
        
        do {
            try modelContext.save()
            print("✅ [LoggingViewModel.editSet] Set updated successfully")
        } catch {
            print("❌ [LoggingViewModel.editSet] Save error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func addSet(exerciseID: UUID) {
        print("🔄 [LoggingViewModel.addSet] Adding set for exercise: \(exerciseID)")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            print("❌ [LoggingViewModel.addSet] Exercise not found")
            error = LoggingError.exerciseNotFound
            return
        }
        
        let newPosition = sessionExercise.completedSets.count
        let newSet = CompletedSet(
            reps: sessionExercise.plannedReps,
            weight: sessionExercise.plannedWeight ?? 0,
            isCompleted: false,
            position: newPosition,
            sessionExercise: sessionExercise
        )
        
        modelContext.insert(newSet)
        sessionExercise.completedSets.append(newSet)
        sessionExercise.currentSet += 1
        updateExercisesUI()
        
        do {
            try modelContext.save()
            print("✅ [LoggingViewModel.addSet] Set added successfully")
        } catch {
            print("❌ [LoggingViewModel.addSet] Save error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func toggleSetCompletion(exerciseID: UUID, setIndex: Int) {
        print("🔄 [LoggingViewModel.toggleSetCompletion] Toggling completion for set \(setIndex) of exercise: \(exerciseID)")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            print("❌ [LoggingViewModel.toggleSetCompletion] Exercise not found")
            error = LoggingError.exerciseNotFound
            return
        }
        
        let orderedSets = sessionExercise.completedSets.sorted(by: { $0.position < $1.position })
        guard setIndex < orderedSets.count else {
            print("❌ [LoggingViewModel.toggleSetCompletion] Invalid set index")
            error = LoggingError.invalidSetIndex
            return
        }
        
        let completedSet = orderedSets[setIndex]
        completedSet.isCompleted.toggle()
        
        print("✅ [LoggingViewModel.toggleSetCompletion] Set \(setIndex + 1) completion toggled to: \(completedSet.isCompleted)")
        
        // Check if all sets are now completed and auto-complete the exercise
        let completedSetsCount = sessionExercise.completedSets.filter { $0.isCompleted }.count
        let totalSetsCount = sessionExercise.completedSets.count
        
        if completedSetsCount == totalSetsCount && !sessionExercise.isCompleted {
            print("🎉 [LoggingViewModel.toggleSetCompletion] All sets completed - auto-completing exercise")
            sessionExercise.isCompleted = true
            sessionExercise.updateExerciseCacheOnCompletion()
        } else if completedSetsCount < totalSetsCount && sessionExercise.isCompleted {
            print("⚠️ [LoggingViewModel.toggleSetCompletion] Not all sets completed - marking exercise as incomplete")
            sessionExercise.isCompleted = false
        }
        
        updateExercisesUI()
        
        do {
            try modelContext.save()
            print("✅ [LoggingViewModel.toggleSetCompletion] Set completion status saved")
        } catch {
            print("❌ [LoggingViewModel.toggleSetCompletion] Save error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func startRest(exerciseID: UUID, seconds: TimeInterval) {
        print("🔄 [LoggingViewModel.startRest] Starting rest timer: \(seconds)s for exercise: \(exerciseID)")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            print("❌ [LoggingViewModel.startRest] Exercise not found")
            error = LoggingError.exerciseNotFound
            return
        }
        
        // Cancel existing timer
        restTimer?.invalidate()
        
        sessionExercise.restTimer = seconds
        showTimerSheet = true
        updateExercisesUI()
        
        restTimer = timerFactory.createTimer(interval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                self?.tickTimer(exerciseID: exerciseID)
            }
        }
        
        print("🏃‍♂️ [LoggingViewModel.startRest] Rest timer started")
    }
    
    private func cancelRest(exerciseID: UUID) {
        print("🔄 [LoggingViewModel.cancelRest] Cancelling rest timer for exercise: \(exerciseID)")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            print("❌ [LoggingViewModel.cancelRest] Exercise not found")
            error = LoggingError.exerciseNotFound
            return
        }
        
        // Cancel and clean up timer
        restTimer?.invalidate()
        restTimer = nil
        sessionExercise.restTimer = nil
        showTimerSheet = false
        
        updateExercisesUI()
        
        print("✅ [LoggingViewModel.cancelRest] Rest timer cancelled successfully")
    }
    
    private func tickTimer(exerciseID: UUID) {
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }),
              let currentTimer = sessionExercise.restTimer,
              currentTimer > 0 else {
            return
        }
        
        sessionExercise.restTimer = currentTimer - 1
        updateExercisesUI()
        
        if sessionExercise.restTimer! <= 0 {
            print("✅ [LoggingViewModel.tickTimer] Rest timer completed")
            restTimer?.invalidate()
            sessionExercise.restTimer = nil
            showTimerSheet = false
            
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            updateExercisesUI()
        }
    }
    
    private func markExerciseComplete(exerciseID: UUID) {
        print("🔄 [LoggingViewModel.markExerciseComplete] Marking exercise complete: \(exerciseID)")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            print("❌ [LoggingViewModel.markExerciseComplete] Exercise not found")
            error = LoggingError.exerciseNotFound
            return
        }
        
        let totalSetsCount = sessionExercise.completedSets.count
        
        if totalSetsCount == 0 {
            print("❌ [LoggingViewModel.markExerciseComplete] Cannot mark complete - no sets available")
            error = LoggingError.custom("This exercise has no sets. Please add at least one set before marking it as complete.")
            return
        }
        
        // Mark all sets as completed
        for completedSet in sessionExercise.completedSets {
            completedSet.isCompleted = true
        }
        
        // Mark exercise as complete
        sessionExercise.isCompleted = true
        
        // Update the exercise's cache for future sessions
        sessionExercise.updateExerciseCacheOnCompletion()
        
        updateExercisesUI()
        
        do {
            try modelContext.save()
            print("✅ [LoggingViewModel.markExerciseComplete] Exercise marked complete with all \(totalSetsCount) sets completed")
            print("📊 [LoggingViewModel] Exercise completion status updated")
        } catch {
            print("❌ [LoggingViewModel.markExerciseComplete] Save error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func finishSession() {
        print("🔄 [LoggingViewModel.finishSession] Finishing session")
        
        guard let session = session else {
            print("❌ [LoggingViewModel.finishSession] No session to finish")
            error = LoggingError.sessionNotFound
            return
        }
        
        guard canFinishSession else {
            print("❌ [LoggingViewModel.finishSession] Session cannot be finished - not all exercises complete")
            error = LoggingError.custom("Please complete all exercises before finishing the session")
            return
        }
        
        // Calculate session duration
        if let startTime = sessionStartTime {
            session.duration = Date().timeIntervalSince(startTime)
        }
        
        // Convert SessionExercises to PerformedExercises for history
        for sessionExercise in session.sessionExercises {
            for completedSet in sessionExercise.completedSets {
                let performedExercise = PerformedExercise(
                    performedAt: session.date,
                    reps: completedSet.reps,
                    weight: completedSet.weight,
                    exercise: sessionExercise.exercise,
                    workoutSession: session
                )
                modelContext.insert(performedExercise)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ [LoggingViewModel.finishSession] Session completed successfully")
            print("📊 [LoggingViewModel] Session duration: \(session.duration ?? 0) seconds")
            print("🏃‍♂️ [LoggingViewModel.finishSession] Total volume: \(totalVolume) lbs")
            
            // Reset state for next session - DON'T create a fresh session automatically
            self.session = nil
            self.exercises = []
            self.sessionStartTime = nil
            
            print("✅ [LoggingViewModel.finishSession] Session state reset - ready for next workout")
            
        } catch {
            print("❌ [LoggingViewModel.finishSession] Save error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Cleanup
    deinit {
        restTimer?.invalidate()
        print("🔄 [LoggingViewModel.deinit] Cleaned up resources")
    }
} 