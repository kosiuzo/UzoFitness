import Foundation
import SwiftData
import Combine
import UIKit
import UzoFitnessCore

// SessionExerciseUI moved to UzoFitnessCore

// MARK: - LoggingViewModel Intent Actions
enum LoggingIntent {
    case selectPlan(UUID)
    case selectDay(Weekday)
    case startSession
    case editSet(exerciseID: UUID, setIndex: Int, reps: Int, weight: Double)
    case bulkEditSets(exerciseID: UUID, reps: Int, weight: Double)
    case addSet(exerciseID: UUID)
    case toggleSetCompletion(exerciseID: UUID, setIndex: Int)
    case startRest(exerciseID: UUID, seconds: TimeInterval)
    case cancelRest(exerciseID: UUID)
    case markExerciseComplete(exerciseID: UUID)
    case finishSession
    case cancelSession
    case advanceToNextExercise
    case setCurrentExercise(index: Int)
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

// TimerFactory moved to UzoFitnessCore

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
    
    // MARK: - Current Exercise Tracking State
    @Published var currentExerciseIndex: Int = 0
    @Published var isWorkoutInProgress: Bool = false
    @Published var hasIncompleteSession: Bool = false
    
    // MARK: - Computed Properties
    var canFinishSession: Bool {
        guard let session = session else { return false }
        return WorkoutSessionLogic.canFinishSession(session)
    }
    
    var currentExercise: SessionExerciseUI? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    var sessionButtonText: String {
        if session != nil {
            return "Workout In Progress"
        } else if hasIncompleteSession {
            return "Continue Session"
        } else {
            return "Start Workout Session"
        }
    }
    
    var groupedExercises: [(Int?, [SessionExerciseUI])] {
        // Sort exercises by position to ensure consistent ordering
        let sortedExercises = exercises.sorted { $0.position < $1.position }
        var result: [(Int?, [SessionExerciseUI])] = []
        var currentSupersetID: UUID? = nil
        var currentGroup: [SessionExerciseUI] = []
        
        for exercise in sortedExercises {
            if let supersetID = exercise.supersetID {
                if supersetID != currentSupersetID {
                    // Finish previous group if any
                    if !currentGroup.isEmpty {
                        result.append((currentSupersetID != nil ? getSupersetNumber(for: currentSupersetID!) : nil, currentGroup))
                        currentGroup = []
                    }
                    currentSupersetID = supersetID
                }
                currentGroup.append(exercise)
            } else {
                // Finish previous group if any
                if !currentGroup.isEmpty {
                    result.append((currentSupersetID != nil ? getSupersetNumber(for: currentSupersetID!) : nil, currentGroup))
                    currentGroup = []
                    currentSupersetID = nil
                }
                // Add non-superset exercise as its own group
                result.append((nil, [exercise]))
            }
        }
        // Add last group if any
        if !currentGroup.isEmpty {
            result.append((currentSupersetID != nil ? getSupersetNumber(for: currentSupersetID!) : nil, currentGroup))
        }
        return result
    }
    
    var totalVolume: Double {
        guard let session = session else { return 0 }
        return WorkoutSessionLogic.calculateTotalVolume(session)
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
        AppLogger.info("[LoggingViewModel.init] Initialized with dependencies", category: "LoggingViewModel")
        
        loadAvailablePlans()
    }
    
    // MARK: - Auto-select current day after plans are loaded
    private func autoSelectCurrentDay() {
        AppLogger.info("[LoggingViewModel.autoSelectCurrentDay] Attempting to auto-select current day", category: "LoggingViewModel")
        
        guard !availableDays.isEmpty else {
            AppLogger.debug("[LoggingViewModel.autoSelectCurrentDay] No available days yet", category: "LoggingViewModel")
            return
        }
        
        let today = Calendar.current.component(.weekday, from: Date())
        if let todayWeekday = Weekday(rawValue: today) {
            // Check if today is available in the current plan
            if availableDays.contains(where: { $0.weekday == todayWeekday }) {
                AppLogger.info("[LoggingViewModel.autoSelectCurrentDay] Auto-selecting today: \(todayWeekday)", category: "LoggingViewModel")
                handleIntent(.selectDay(todayWeekday))
            } else {
                AppLogger.debug("[LoggingViewModel.autoSelectCurrentDay] Today (\(todayWeekday)) not available in plan, keeping manual selection", category: "LoggingViewModel")
            }
        }
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: LoggingIntent) {
        AppLogger.info("[LoggingViewModel.handleIntent] Processing intent: \(intent)", category: "LoggingViewModel")
        
        switch intent {
        case .selectPlan(let planID):
            selectPlan(planID)
            
        case .selectDay(let weekday):
            selectDay(weekday)
            
        case .startSession:
            startWorkoutSession()
            
        case .editSet(let exerciseID, let setIndex, let reps, let weight):
            editSet(exerciseID: exerciseID, setIndex: setIndex, reps: reps, weight: weight)
            
        case .bulkEditSets(let exerciseID, let reps, let weight):
            bulkEditSets(exerciseID: exerciseID, reps: reps, weight: weight)
            
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
            
        case .cancelSession:
            cancelSession()
            
        case .advanceToNextExercise:
            advanceToNextExercise()
            
        case .setCurrentExercise(let index):
            setCurrentExercise(index: index)
        }
    }
    
    // MARK: - Data Loading Methods
    func loadAvailablePlans() {
        AppLogger.info("[LoggingViewModel.loadAvailablePlans] Loading available plans", category: "LoggingViewModel")
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
            
            AppLogger.info("[LoggingViewModel.loadAvailablePlans] Loaded \(availablePlans.count) plans", category: "LoggingViewModel")
            
            // Check if current active plan still exists (use object identity first, then ID)
            if let currentActivePlan = activePlan {
                // Use object identity comparison to avoid ID access crashes
                let planStillExists = availablePlans.contains { plan in
                    plan === currentActivePlan
                }
                
                if !planStillExists {
                    AppLogger.debug("[LoggingViewModel.loadAvailablePlans] Active plan was deleted - clearing state", category: "LoggingViewModel")
                    // Current active plan was deleted, clear the state
                    activePlan = nil
                    availableDays = []
                    selectedDay = nil
                    session = nil
                    exercises = []
                    isRestDay = false
                    hasIncompleteSession = false
                }
            }
            
            // Auto-select the first active plan if none selected
            if activePlan == nil, let newActivePlan = availablePlans.first(where: { $0.isActive }) {
                AppLogger.info("[LoggingViewModel.loadAvailablePlans] Auto-selecting active plan: \(newActivePlan.customName)", category: "LoggingViewModel")
                // Use object reference directly instead of ID
                activePlan = newActivePlan
                autoSelectCurrentDay()
            } else if activePlan != nil {
                // If we already have an active plan, auto-select current day
                autoSelectCurrentDay()
            }
        } catch {
            AppLogger.error("[LoggingViewModel.loadAvailablePlans] Error: \(error.localizedDescription)", category: "LoggingViewModel")
            self.error = error
        }
    }
    
    func loadLastPerformedData() {
        AppLogger.info("[LoggingViewModel.loadLastPerformedData] Loading last performed data", category: "LoggingViewModel")
        
        guard selectedDay != nil else {
            AppLogger.error("[LoggingViewModel.loadLastPerformedData] No day selected", category: "LoggingViewModel")
            return
        }
        
        // This method would populate exercises with last performed values
        // Implementation would depend on your specific data access patterns
        AppLogger.info("[LoggingViewModel.loadLastPerformedData] Last performed data loaded", category: "LoggingViewModel")
    }
    
    func refreshSessionWithAutoPopulation() {
        AppLogger.info("[LoggingViewModel.refreshSessionWithAutoPopulation] Refreshing session with auto-populated values", category: "LoggingViewModel")
        
        guard activePlan != nil,
              selectedDay != nil else {
            AppLogger.error("[LoggingViewModel.refreshSessionWithAutoPopulation] Missing plan or day", category: "LoggingViewModel")
            return
        }
        
        // Clear current session
        if let existingSession = session {
            modelContext.delete(existingSession)
        }
        
        // Create fresh session with auto-population
        createFreshSessionWithAutoPopulation()
        
        AppLogger.info("[LoggingViewModel.refreshSessionWithAutoPopulation] Session refreshed with auto-populated values", category: "LoggingViewModel")
    }
    
    // MARK: - Private Methods
    private func checkForIncompleteSession() {
        AppLogger.info("[LoggingViewModel.checkForIncompleteSession] Checking for incomplete session", category: "LoggingViewModel")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            hasIncompleteSession = false
            return
        }
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let fetchDescriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.date >= startOfDay &&
                    session.date < endOfDay &&
                    session.duration == nil // No duration means incomplete
                }
            )
            let todaySessions = try modelContext.fetch(fetchDescriptor)
            
            // Filter for the current plan and day (with safe ID comparison)
            let incompleteSessions = todaySessions.filter { session in
                guard let sessionPlan = session.plan else { return false }
                
                // Use object identity comparison to avoid ID access crashes
                let planMatches = sessionPlan === activePlan
                
                return planMatches &&
                (session.title.contains(selectedDay.weekday.fullName) || session.title.contains(selectedDay.weekday.abbreviation))
            }
            
            hasIncompleteSession = !incompleteSessions.isEmpty
            
            AppLogger.debug("[LoggingViewModel.checkForIncompleteSession] Found \(incompleteSessions.count) incomplete sessions for current plan and day", category: "LoggingViewModel")
            
        } catch {
            AppLogger.error("[LoggingViewModel.checkForIncompleteSession] Error checking for incomplete sessions", category: "LoggingViewModel", error: error)
            hasIncompleteSession = false
        }
    }
    
    private func selectPlan(_ planID: UUID) {
        AppLogger.info("[LoggingViewModel.selectPlan] Selecting plan: \(planID)", category: "LoggingViewModel")
        
        do {
            let fetchDescriptor = FetchDescriptor<WorkoutPlan>(
                predicate: #Predicate { $0.id == planID }
            )
            let plans = try modelContext.fetch(fetchDescriptor)
            
            guard let plan = plans.first else {
                AppLogger.error("[LoggingViewModel.selectPlan] Plan not found", category: "LoggingViewModel")
                error = LoggingError.custom("Plan not found")
                return
            }
            
            activePlan = plan
            AppLogger.info("[LoggingViewModel.selectPlan] Plan selected: \(plan.customName)", category: "LoggingViewModel")
            AppLogger.debug("[LoggingViewModel] Active plan changed to: \(plan.customName)", category: "LoggingViewModel")
            
            // Custom sort: Mon-Fri (2-6), then Sat (7), then Sun (1)
            let weekdayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
            availableDays = plan.template?.dayTemplates.sorted {
                guard let firstIndex = weekdayOrder.firstIndex(of: $0.weekday),
                      let secondIndex = weekdayOrder.firstIndex(of: $1.weekday) else {
                    return $0.weekday.rawValue < $1.weekday.rawValue
                }
                return firstIndex < secondIndex
            } ?? []
            AppLogger.debug("[LoggingViewModel.selectPlan] Loaded \(availableDays.count) days for plan", category: "LoggingViewModel")
            
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
            AppLogger.error("[LoggingViewModel.selectPlan] Error: \(error.localizedDescription)", category: "LoggingViewModel")
            self.error = error
        }
    }
    
    private func selectDay(_ weekday: Weekday) {
        AppLogger.info("[LoggingViewModel.selectDay] Selecting day: \(weekday)", category: "LoggingViewModel")
        
        guard let activePlan = activePlan,
              let template = activePlan.template else {
            AppLogger.error("[LoggingViewModel.selectDay] No active plan or template", category: "LoggingViewModel")
            error = LoggingError.noPlanSelected
            return
        }
        
        // Find the day template for this weekday
        let dayTemplate = template.dayTemplates.first { $0.weekday == weekday }
        selectedDay = dayTemplate
        isRestDay = dayTemplate?.isRest ?? false
        
        AppLogger.debug("[LoggingViewModel] Selected day: \(weekday), isRestDay: \(isRestDay)", category: "LoggingViewModel")
        if let dayTemplate = dayTemplate {
            AppLogger.debug("[LoggingViewModel.selectDay] Day template has \(dayTemplate.exerciseTemplates.count) exercises", category: "LoggingViewModel")
            for template in dayTemplate.exerciseTemplates {
                AppLogger.debug("  - Exercise: \(template.exercise.name)", category: "LoggingViewModel")
            }
        } else {
            AppLogger.error("[LoggingViewModel.selectDay] No day template found for \(weekday)", category: "LoggingViewModel")
        }
        
        if isRestDay {
            AppLogger.debug("[LoggingViewModel.selectDay] Rest day selected", category: "LoggingViewModel")
            // Clear any existing session and exercises for rest days
            session = nil
            exercises = []
            hasIncompleteSession = false
        } else {
            // Check for incomplete session when day is selected
            checkForIncompleteSession()
            AppLogger.debug("[LoggingViewModel.selectDay] Day selected, waiting for user to start session", category: "LoggingViewModel")
        }
    }
    
    func startWorkoutSession() {
        AppLogger.info("[LoggingViewModel.startWorkoutSession] 🚀 Starting workout session manually", category: "LoggingViewModel")
        
        // Check if there's already an active session in progress
        if let existingSession = session, existingSession.duration == nil {
            AppLogger.debug("[LoggingViewModel.startWorkoutSession] Session already in progress, continuing existing session", category: "LoggingViewModel")
            updateExercisesUI()
            return
        }
        
        // Check for incomplete session from today
        checkForIncompleteSession()
        
        if hasIncompleteSession {
            AppLogger.info("[LoggingViewModel.startWorkoutSession] 📋 Continuing incomplete session", category: "LoggingViewModel")
            createOrResumeSession()
        } else {
            AppLogger.info("[LoggingViewModel.startWorkoutSession] 🆕 Creating new session", category: "LoggingViewModel")
            createFreshSessionWithAutoPopulation()
        }
    }
    
    private func createOrResumeSession() {
        AppLogger.info("[LoggingViewModel.createOrResumeSession] Starting session creation/resume", category: "LoggingViewModel")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            AppLogger.error("[LoggingViewModel.createOrResumeSession] Missing plan or day", category: "LoggingViewModel")
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
            
            // Filter for the current plan only (with safe ID comparison)
            let planSessions = allTodaySessions.filter { session in
                guard let sessionPlan = session.plan else { return false }
                
                // Use object identity comparison to avoid ID access crashes
                return sessionPlan === activePlan
            }
            
            // Further filter for the specific day/workout
            let daySpecificSessions = planSessions.filter { session in
                session.title.contains(selectedDay.weekday.fullName) || session.title.contains(selectedDay.weekday.abbreviation)
            }
            
            AppLogger.debug("[LoggingViewModel.createOrResumeSession] Found \(daySpecificSessions.count) sessions for current plan and day", category: "LoggingViewModel")
            
            if let existingSession = daySpecificSessions.first {
                // Check if this session was already completed (has duration set)
                if existingSession.duration != nil && existingSession.duration! > 0 {
                    AppLogger.info("[LoggingViewModel.createOrResumeSession] Found completed session from same plan, creating fresh session instead", category: "LoggingViewModel")
                    createFreshSessionForSameDay(existingSession: existingSession)
                    return
                }
                
                AppLogger.info("[LoggingViewModel.createOrResumeSession] Resuming existing session for \(selectedDay.weekday)", category: "LoggingViewModel")
                AppLogger.debug("[LoggingViewModel.createOrResumeSession] Existing session has \(existingSession.sessionExercises.count) exercises", category: "LoggingViewModel")
                session = existingSession
                sessionStartTime = existingSession.createdAt
                
                // Ensure session exercises exist for resumed sessions
                if existingSession.sessionExercises.isEmpty {
                    AppLogger.debug("[LoggingViewModel.createOrResumeSession] Resumed session has no exercises, creating them", category: "LoggingViewModel")
                    createSessionExercises(for: existingSession, from: selectedDay)
                }
                
                // Sync workout session to Watch after resuming
                syncWorkoutSessionToWatch(existingSession)
            } else {
                AppLogger.info("[LoggingViewModel.createOrResumeSession] Creating new session", category: "LoggingViewModel")
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
                
                // Save immediately to ensure the session persists
                do {
                    try modelContext.save()
                    // Access ID only after save operation completes
                    AppLogger.debug("[LoggingViewModel.createOrResumeSession] New session created with ID: \(newSession.id)", category: "LoggingViewModel")
                    AppLogger.debug("[LoggingViewModel.createOrResumeSession] Session title: '\(newSession.title)'", category: "LoggingViewModel")
                    AppLogger.info("[LoggingViewModel.createOrResumeSession] New session saved successfully", category: "LoggingViewModel")
                    
                    // Sync workout session to Watch after successful save
                    syncWorkoutSessionToWatch(newSession)
                    
                } catch {
                    AppLogger.error("[LoggingViewModel.createOrResumeSession] Failed to save new session", category: "LoggingViewModel", error: error)
                }
            }
            
            updateExercisesUI()
            AppLogger.info("[LoggingViewModel.createOrResumeSession] Session ready", category: "LoggingViewModel")
            
        } catch {
            AppLogger.error("[LoggingViewModel.createOrResumeSession] Error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    private func createFreshSession() {
        AppLogger.info("[LoggingViewModel.createFreshSession] Creating fresh session (no resume)", category: "LoggingViewModel")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            AppLogger.error("[LoggingViewModel.createFreshSession] Missing plan or day", category: "LoggingViewModel")
            return
        }
        
        let today = Date()
        
        AppLogger.info("[LoggingViewModel.createFreshSession] Creating new session", category: "LoggingViewModel")
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
        AppLogger.info("[LoggingViewModel.createFreshSession] Fresh session ready", category: "LoggingViewModel")
    }
    
    private func createFreshSessionForSameDay(existingSession: WorkoutSession) {
        AppLogger.info("[LoggingViewModel.createFreshSessionForSameDay] Creating fresh session to replace completed one", category: "LoggingViewModel")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            AppLogger.error("[LoggingViewModel.createFreshSessionForSameDay] Missing plan or day", category: "LoggingViewModel")
            return
        }
        
        // Delete the existing completed session since we're starting fresh
        // (This session is guaranteed to be from the same plan due to our filtering)
        AppLogger.info("[LoggingViewModel.createFreshSessionForSameDay] Deleting existing session from same plan", category: "LoggingViewModel")
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
            AppLogger.info("[LoggingViewModel.createFreshSessionForSameDay] Fresh session created and saved", category: "LoggingViewModel")
            
            // Sync workout session to Watch after successful save
            syncWorkoutSessionToWatch(newSession)
            
        } catch {
            AppLogger.error("[LoggingViewModel.createFreshSessionForSameDay] Failed to save", category: "LoggingViewModel", error: error)
        }
        
        updateExercisesUI()
        AppLogger.info("[LoggingViewModel.createFreshSessionForSameDay] Fresh session ready", category: "LoggingViewModel")
    }
    
    private func createSessionExercises(for session: WorkoutSession, from dayTemplate: DayTemplate) {
        AppLogger.info("[LoggingViewModel.createSessionExercises] Creating exercises for session", category: "LoggingViewModel")
        
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
                AppLogger.debug("[LoggingViewModel.createSessionExercises] Created planned set \(setIndex + 1) for \(exerciseTemplate.exercise.name)", category: "LoggingViewModel")
            }
            
            AppLogger.debug("[LoggingViewModel.createSessionExercises] Added exercise: \(exerciseTemplate.exercise.name) with \(exerciseTemplate.setCount) planned sets", category: "LoggingViewModel")
        }
        
        AppLogger.info("[LoggingViewModel.createSessionExercises] Created \(dayTemplate.exerciseTemplates.count) session exercises", category: "LoggingViewModel")
    }
    
    private func createFreshSessionWithAutoPopulation() {
        AppLogger.info("[LoggingViewModel.createFreshSessionWithAutoPopulation] Creating new session with auto-populated values", category: "LoggingViewModel")
        
        guard let activePlan = activePlan,
              let selectedDay = selectedDay else {
            AppLogger.error("[LoggingViewModel.createFreshSessionWithAutoPopulation] Missing plan or day", category: "LoggingViewModel")
            return
        }
        
        let today = Date()
        let newSession = WorkoutSession(
            date: today,
            title: "\(selectedDay.weekday.fullName) - \(activePlan.customName)",
            plan: activePlan
        )
        
        modelContext.insert(newSession)
        session = newSession
        sessionStartTime = Date()
        
        // Create session exercises with auto-population enabled
        createSessionExercisesWithAutoPopulation(for: newSession, from: selectedDay)
        
        // Save immediately to ensure the session persists
        do {
            try modelContext.save()
            // Access ID only after save operation completes
            AppLogger.debug("[LoggingViewModel.createFreshSessionWithAutoPopulation] New session created with ID: \(newSession.id)", category: "LoggingViewModel")
            AppLogger.info("[LoggingViewModel.createFreshSessionWithAutoPopulation] New session with auto-populated values saved successfully", category: "LoggingViewModel")
            
            // Sync workout session to Watch after successful save (ID is now available)
            syncWorkoutSessionToWatch(newSession)
            
        } catch {
            AppLogger.error("[LoggingViewModel.createFreshSessionWithAutoPopulation] Failed to save new session", category: "LoggingViewModel", error: error)
        }
        
        updateExercisesUI()
        AppLogger.info("[LoggingViewModel.createFreshSessionWithAutoPopulation] Fresh session with auto-populated values ready", category: "LoggingViewModel")
    }
    
    private func createSessionExercisesWithAutoPopulation(for session: WorkoutSession, from dayTemplate: DayTemplate) {
        AppLogger.info("[LoggingViewModel.createSessionExercisesWithAutoPopulation] Creating exercises with auto-population", category: "LoggingViewModel")
        
        for exerciseTemplate in dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position }) {
            let sessionExercise = SessionExercise(
                exercise: exerciseTemplate.exercise,
                plannedSets: exerciseTemplate.setCount,
                plannedReps: nil, // Don't override, let auto-population handle it
                plannedWeight: nil, // Don't override, let auto-population handle it
                position: exerciseTemplate.position,
                supersetID: exerciseTemplate.supersetID,
                currentSet: 0,
                isCompleted: false,
                session: session,
                autoPopulateFromLastSession: true // Enable auto-population from last used values
            )
            
            modelContext.insert(sessionExercise)
            session.sessionExercises.append(sessionExercise)
            
            // Create planned sets using auto-populated values
            for setIndex in 0..<exerciseTemplate.setCount {
                let plannedSet = CompletedSet(
                    reps: sessionExercise.plannedReps, // Use auto-populated reps
                    weight: sessionExercise.plannedWeight ?? 0, // Use auto-populated weight
                    isCompleted: false,
                    position: setIndex,
                    sessionExercise: sessionExercise
                )
                modelContext.insert(plannedSet)
                sessionExercise.completedSets.append(plannedSet)
                AppLogger.debug("[LoggingViewModel.createSessionExercisesWithAutoPopulation] Created auto-populated set \(setIndex + 1) for \(exerciseTemplate.exercise.name) - Reps: \(sessionExercise.plannedReps), Weight: \(sessionExercise.plannedWeight ?? 0)", category: "LoggingViewModel")
            }
            
            AppLogger.debug("[LoggingViewModel.createSessionExercisesWithAutoPopulation] Added exercise: \(exerciseTemplate.exercise.name) with auto-populated values", category: "LoggingViewModel")
        }
        
        AppLogger.info("[LoggingViewModel.createSessionExercisesWithAutoPopulation] Created \(dayTemplate.exerciseTemplates.count) session exercises with auto-population", category: "LoggingViewModel")
    }
    
    private func updateExercisesUI() {
        guard let session = session else {
            exercises = []
            isWorkoutInProgress = false
            currentExerciseIndex = 0
            return
        }
        
        exercises = session.sessionExercises
            .sorted(by: { $0.position < $1.position })
            .map { WorkoutSessionLogic.convertToSessionExerciseUI($0) }
        
        // Update workout progress state
        isWorkoutInProgress = !exercises.isEmpty
        
        // Update current exercise index
        updateCurrentExercise()
        
        AppLogger.debug("[LoggingViewModel.updateExercisesUI] Updated UI with \(exercises.count) exercises", category: "LoggingViewModel")
    }
    
    // MARK: - Current Exercise Management
    private func updateCurrentExercise() {
        guard !exercises.isEmpty else {
            currentExerciseIndex = 0
            return
        }
        
        // Find the first incomplete exercise
        if let firstIncompleteIndex = exercises.firstIndex(where: { !$0.isCompleted }) {
            currentExerciseIndex = firstIncompleteIndex
        } else {
            // All exercises completed - keep current index if valid
            currentExerciseIndex = min(currentExerciseIndex, exercises.count - 1)
        }
    }
    
    private func advanceToNextExercise() {
        guard let currentExercise = currentExercise else { return }
        
        AppLogger.info("[LoggingViewModel.advanceToNextExercise] Advancing from exercise: \(currentExercise.name)", category: "LoggingViewModel")
        
        // If current exercise is part of a superset
        if let supersetID = currentExercise.supersetID {
            if isCurrentSupersetCompleted() {
                // Move to next exercise after superset
                moveToNextExerciseAfterSuperset(supersetID)
            } else {
                // Move to next exercise in same superset
                moveToNextExerciseInSuperset(supersetID)
            }
        } else {
            // Regular exercise - move to next
            moveToNextExercise()
        }
    }
    
    private func setCurrentExercise(index: Int) {
        guard index >= 0 && index < exercises.count else { return }
        currentExerciseIndex = index
        AppLogger.info("[LoggingViewModel.setCurrentExercise] Current exercise set to index: \(index)", category: "LoggingViewModel")
    }
    
    private func isCurrentSupersetCompleted() -> Bool {
        guard let currentExercise = currentExercise,
              let supersetID = currentExercise.supersetID else { return false }
        
        let supersetExercises = exercises.filter { $0.supersetID == supersetID }
        return supersetExercises.allSatisfy { $0.isCompleted }
    }
    
    private func moveToNextExerciseAfterSuperset(_ supersetID: UUID) {
        // Find the last exercise in the superset
        let supersetExercises = exercises.enumerated().filter { $0.element.supersetID == supersetID }
        guard let lastSupersetIndex = supersetExercises.map({ $0.offset }).max() else { return }
        
        // Move to next exercise after the superset
        let nextIndex = lastSupersetIndex + 1
        if nextIndex < exercises.count {
            currentExerciseIndex = nextIndex
        }
    }
    
    private func moveToNextExerciseInSuperset(_ supersetID: UUID) {
        // Find next exercise in the same superset
        let supersetExercises = exercises.enumerated().filter { $0.element.supersetID == supersetID }
        let currentIndexInSuperset = supersetExercises.firstIndex { $0.offset == currentExerciseIndex }
        
        if let currentIndexInSuperset = currentIndexInSuperset,
           currentIndexInSuperset + 1 < supersetExercises.count {
            currentExerciseIndex = supersetExercises[currentIndexInSuperset + 1].offset
        }
    }
    
    private func moveToNextExercise() {
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            currentExerciseIndex = nextIndex
        }
    }
    
    private func getNextExerciseIndex() -> Int? {
        guard let currentExercise = currentExercise else { return nil }
        
        if let supersetID = currentExercise.supersetID {
            if isCurrentSupersetCompleted() {
                // Get next exercise after superset
                let supersetExercises = exercises.enumerated().filter { $0.element.supersetID == supersetID }
                guard let lastSupersetIndex = supersetExercises.map({ $0.offset }).max() else { return nil }
                let nextIndex = lastSupersetIndex + 1
                return nextIndex < exercises.count ? nextIndex : nil
            } else {
                // Get next exercise in same superset
                let supersetExercises = exercises.enumerated().filter { $0.element.supersetID == supersetID }
                let currentIndexInSuperset = supersetExercises.firstIndex { $0.offset == currentExerciseIndex }
                
                if let currentIndexInSuperset = currentIndexInSuperset,
                   currentIndexInSuperset + 1 < supersetExercises.count {
                    return supersetExercises[currentIndexInSuperset + 1].offset
                }
            }
        } else {
            // Regular exercise
            let nextIndex = currentExerciseIndex + 1
            return nextIndex < exercises.count ? nextIndex : nil
        }
        
        return nil
    }
    
    func getSupersetNumber(for supersetID: UUID) -> Int? {
        return selectedDay?.getSupersetNumber(for: supersetID)
    }
    
    private func editSet(exerciseID: UUID, setIndex: Int, reps: Int, weight: Double) {
        AppLogger.info("[LoggingViewModel.editSet] Editing set for exercise: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.editSet] Exercise not found", category: "LoggingViewModel")
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
            AppLogger.error("[LoggingViewModel.editSet] Invalid set index", category: "LoggingViewModel")
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
            AppLogger.info("[LoggingViewModel.editSet] Set updated successfully", category: "LoggingViewModel")
        } catch {
            AppLogger.error("[LoggingViewModel.editSet] Save error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    private func bulkEditSets(exerciseID: UUID, reps: Int, weight: Double) {
        AppLogger.info("[LoggingViewModel.bulkEditSets] Bulk editing sets for exercise: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.bulkEditSets] Exercise not found", category: "LoggingViewModel")
            error = LoggingError.exerciseNotFound
            return
        }
        
        // Get ordered sets
        let orderedSets = sessionExercise.completedSets.sorted(by: { $0.position < $1.position })
        
        // Update all existing sets with new reps and weight
        for completedSet in orderedSets {
            completedSet.reps = reps
            completedSet.weight = weight
        }
        
        updateExercisesUI()
        
        do {
            try modelContext.save()
            AppLogger.info("[LoggingViewModel.bulkEditSets] All sets updated successfully", category: "LoggingViewModel")
        } catch {
            AppLogger.error("[LoggingViewModel.bulkEditSets] Save error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    private func addSet(exerciseID: UUID) {
        AppLogger.info("[LoggingViewModel.addSet] Adding set for exercise: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.addSet] Exercise not found", category: "LoggingViewModel")
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
            AppLogger.info("[LoggingViewModel.addSet] Set added successfully", category: "LoggingViewModel")
        } catch {
            AppLogger.error("[LoggingViewModel.addSet] Save error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    private func toggleSetCompletion(exerciseID: UUID, setIndex: Int) {
        AppLogger.info("[LoggingViewModel.toggleSetCompletion] Toggling completion for set \(setIndex) of exercise: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.toggleSetCompletion] Exercise not found", category: "LoggingViewModel")
            error = LoggingError.exerciseNotFound
            return
        }
        
        let orderedSets = sessionExercise.completedSets.sorted(by: { $0.position < $1.position })
        guard setIndex < orderedSets.count else {
            AppLogger.error("[LoggingViewModel.toggleSetCompletion] Invalid set index", category: "LoggingViewModel")
            error = LoggingError.invalidSetIndex
            return
        }
        
        let completedSet = orderedSets[setIndex]
        completedSet.isCompleted.toggle()
        
        AppLogger.info("[LoggingViewModel.toggleSetCompletion] Set \(setIndex + 1) completion toggled to: \(completedSet.isCompleted)", category: "LoggingViewModel")
        
        // Check if all sets are now completed and auto-complete the exercise
        let completedSetsCount = sessionExercise.completedSets.filter { $0.isCompleted }.count
        let totalSetsCount = sessionExercise.completedSets.count
        
        if completedSetsCount == totalSetsCount && !sessionExercise.isCompleted {
            AppLogger.info("[LoggingViewModel.toggleSetCompletion] All sets completed - auto-completing exercise", category: "LoggingViewModel")
            sessionExercise.isCompleted = true
            
            // Auto-advance to next exercise if this exercise is the current one
            if let currentExerciseUI = currentExercise,
               currentExerciseUI.id == exerciseID {
                advanceToNextExercise()
            }
        } else if completedSetsCount < totalSetsCount && sessionExercise.isCompleted {
            AppLogger.debug("[LoggingViewModel.toggleSetCompletion] Not all sets completed - marking exercise as incomplete", category: "LoggingViewModel")
            sessionExercise.isCompleted = false
        }
        
        updateExercisesUI()
        
        do {
            try modelContext.save()
            AppLogger.info("[LoggingViewModel.toggleSetCompletion] Set completion status saved", category: "LoggingViewModel")
        } catch {
            AppLogger.error("[LoggingViewModel.toggleSetCompletion] Save error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    private func startRest(exerciseID: UUID, seconds: TimeInterval) {
        AppLogger.info("[LoggingViewModel.startRest] Starting rest timer: \(seconds)s for exercise: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.startRest] Exercise not found", category: "LoggingViewModel")
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
        
        AppLogger.debug("[LoggingViewModel.startRest] Rest timer started", category: "LoggingViewModel")
    }
    
    private func cancelRest(exerciseID: UUID) {
        AppLogger.info("[LoggingViewModel.cancelRest] Cancelling rest timer for exercise: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.cancelRest] Exercise not found", category: "LoggingViewModel")
            error = LoggingError.exerciseNotFound
            return
        }
        
        // Cancel and clean up timer
        restTimer?.invalidate()
        restTimer = nil
        sessionExercise.restTimer = nil
        showTimerSheet = false
        
        updateExercisesUI()
        
        AppLogger.info("[LoggingViewModel.cancelRest] Rest timer cancelled successfully", category: "LoggingViewModel")
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
            AppLogger.info("[LoggingViewModel.tickTimer] Rest timer completed", category: "LoggingViewModel")
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
        AppLogger.info("[LoggingViewModel.markExerciseComplete] Marking exercise complete: \(exerciseID)", category: "LoggingViewModel")
        
        guard let session = session,
              let sessionExercise = session.sessionExercises.first(where: { $0.id == exerciseID }) else {
            AppLogger.error("[LoggingViewModel.markExerciseComplete] Exercise not found", category: "LoggingViewModel")
            error = LoggingError.exerciseNotFound
            return
        }
        
        let totalSetsCount = sessionExercise.completedSets.count
        
        if totalSetsCount == 0 {
            AppLogger.error("[LoggingViewModel.markExerciseComplete] Cannot mark complete - no sets available", category: "LoggingViewModel")
            error = LoggingError.custom("This exercise has no sets. Please add at least one set before marking it as complete.")
            return
        }
        
        // Mark all sets as completed
        for completedSet in sessionExercise.completedSets {
            completedSet.isCompleted = true
        }
        
        // Mark exercise as complete
        sessionExercise.isCompleted = true
        
        // Auto-advance to next exercise if this exercise is the current one
        if let currentExerciseUI = currentExercise,
           currentExerciseUI.id == exerciseID {
            advanceToNextExercise()
        }
        
        updateExercisesUI()
        
        do {
            try modelContext.save()
            AppLogger.info("[LoggingViewModel.markExerciseComplete] Exercise marked complete with all \(totalSetsCount) sets completed", category: "LoggingViewModel")
            AppLogger.debug("[LoggingViewModel] Exercise completion status updated", category: "LoggingViewModel")
        } catch {
            AppLogger.error("[LoggingViewModel.markExerciseComplete] Save error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    /// Batch update all exercise cache values when workout is completed
    /// This prevents conflicts from individual updates during the workout
    private func updateAllExerciseCacheValuesOnWorkoutCompletion() {
        AppLogger.info("[LoggingViewModel.updateAllExerciseCacheValuesOnWorkoutCompletion] Starting batch update of exercise cache values", category: "LoggingViewModel")
        
        guard let session = session else {
            AppLogger.debug("[LoggingViewModel.updateAllExerciseCacheValuesOnWorkoutCompletion] No session to update", category: "LoggingViewModel")
            return
        }
        
        var updatedCount = 0
        
        for sessionExercise in session.sessionExercises {
            // Only update completed exercises with sets
            guard sessionExercise.isCompleted && !sessionExercise.completedSets.isEmpty else {
                AppLogger.debug("[LoggingViewModel.updateAllExerciseCacheValuesOnWorkoutCompletion] Skipping \(sessionExercise.exercise.name) - not completed or no sets", category: "LoggingViewModel")
                continue
            }
            
            AppLogger.debug("[LoggingViewModel.updateAllExerciseCacheValuesOnWorkoutCompletion] Updating exercise cache for: \(sessionExercise.exercise.name)", category: "LoggingViewModel")
            
            // Update exercise's cached values with this session's data
            let totalVolume = sessionExercise.totalVolume
            
            if let lastSet = sessionExercise.completedSets.last {
                sessionExercise.exercise.lastUsedWeight = lastSet.weight
                sessionExercise.exercise.lastUsedReps = lastSet.reps
            }
            
            sessionExercise.exercise.lastTotalVolume = totalVolume
            sessionExercise.exercise.lastUsedDate = session.date
            
            updatedCount += 1
            
            AppLogger.debug("[LoggingViewModel.updateAllExerciseCacheValuesOnWorkoutCompletion] Updated cache for \(sessionExercise.exercise.name) - Weight: \(sessionExercise.exercise.lastUsedWeight ?? 0), Reps: \(sessionExercise.exercise.lastUsedReps ?? 0), Volume: \(sessionExercise.exercise.lastTotalVolume ?? 0)", category: "LoggingViewModel")
        }
        
        AppLogger.info("[LoggingViewModel.updateAllExerciseCacheValuesOnWorkoutCompletion] Batch update completed for \(updatedCount) exercises", category: "LoggingViewModel")
    }
    
    private func finishSession() {
        AppLogger.info("[LoggingViewModel.finishSession] Finishing session", category: "LoggingViewModel")
        
        guard let session = session else {
            AppLogger.error("[LoggingViewModel.finishSession] No session to finish", category: "LoggingViewModel")
            error = LoggingError.sessionNotFound
            return
        }
        
        guard canFinishSession else {
            AppLogger.error("[LoggingViewModel.finishSession] Session cannot be finished - not all exercises complete", category: "LoggingViewModel")
            error = LoggingError.custom("Please complete all exercises before finishing the session")
            return
        }
        
        // Calculate session duration
        if let startTime = sessionStartTime {
            session.duration = Date().timeIntervalSince(startTime)
        }
        
        // Batch update all exercise cache values now that workout is completed
        updateAllExerciseCacheValuesOnWorkoutCompletion()
        
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
            AppLogger.info("[LoggingViewModel.finishSession] Session completed successfully", category: "LoggingViewModel")
            AppLogger.debug("[LoggingViewModel] Session duration: \(session.duration ?? 0) seconds", category: "LoggingViewModel")
            AppLogger.debug("[LoggingViewModel.finishSession] Total volume: \(totalVolume) lbs", category: "LoggingViewModel")
            
            // Reset state for next session
            self.session = nil
            self.exercises = []
            self.sessionStartTime = nil
            self.isWorkoutInProgress = false
            self.currentExerciseIndex = 0
            self.hasIncompleteSession = false
            
            AppLogger.info("[LoggingViewModel.finishSession] Session completed successfully", category: "LoggingViewModel")
            
        } catch {
            AppLogger.error("[LoggingViewModel.finishSession] Save error", category: "LoggingViewModel", error: error)
            self.error = error
        }
    }
    
    private func cancelSession() {
        AppLogger.info("[LoggingViewModel.cancelSession] Cancelling current session", category: "LoggingViewModel")
        
        guard session != nil else {
            AppLogger.error("[LoggingViewModel.cancelSession] No session to cancel", category: "LoggingViewModel")
            return
        }
        
        // Save the session in its current incomplete state (no duration set)
        do {
            try modelContext.save()
            AppLogger.info("[LoggingViewModel.cancelSession] Session saved in incomplete state", category: "LoggingViewModel")
        } catch {
            AppLogger.error("[LoggingViewModel.cancelSession] Failed to save incomplete session", category: "LoggingViewModel", error: error)
        }
        
        // Reset UI state but keep session available for resuming
        self.session = nil
        self.exercises = []
        self.sessionStartTime = nil
        self.isWorkoutInProgress = false
        self.currentExerciseIndex = 0
        
        // Check if we now have an incomplete session (should be true after cancel)
        checkForIncompleteSession()
        
        AppLogger.info("[LoggingViewModel.cancelSession] Session cancelled and UI reset, hasIncompleteSession: \(hasIncompleteSession)", category: "LoggingViewModel")
    }
    
    // MARK: - Watch Synchronization
    private func syncWorkoutSessionToWatch(_ session: WorkoutSession) {
        AppLogger.info("[LoggingViewModel.syncWorkoutSessionToWatch] 🚀 Starting sync for workout session to Watch", category: "LoggingViewModel")
        AppLogger.debug("[LoggingViewModel.syncWorkoutSessionToWatch] 📊 Session details - ID: \(session.id), Title: '\(session.title)', Exercises: \(session.sessionExercises.count)", category: "LoggingViewModel")
        
        // Convert SessionExercises to SharedSessionExercises
        let sharedExercises = session.sessionExercises.map { sessionExercise in
            let sharedCompletedSets = sessionExercise.completedSets.map { completedSet in
                SharedCompletedSet(
                    id: completedSet.id,
                    reps: completedSet.reps,
                    weight: completedSet.weight,
                    timestamp: Date() // Use current date since CompletedSet doesn't have a timestamp property
                )
            }
            
            AppLogger.debug("[LoggingViewModel.syncWorkoutSessionToWatch] 🏋️ Converting exercise: \(sessionExercise.exercise.name) with \(sessionExercise.completedSets.count) sets", category: "LoggingViewModel")
            
            return SharedSessionExercise(
                id: sessionExercise.id,
                exerciseId: sessionExercise.exercise.id,
                name: sessionExercise.exercise.name,
                category: sessionExercise.exercise.category.rawValue,
                plannedSets: sessionExercise.plannedSets,
                plannedReps: sessionExercise.plannedReps,
                plannedWeight: sessionExercise.plannedWeight,
                position: sessionExercise.position,
                currentSet: sessionExercise.currentSet,
                isCompleted: sessionExercise.isCompleted,
                completedSets: sharedCompletedSets
            )
        }
        
        AppLogger.info("[LoggingViewModel.syncWorkoutSessionToWatch] 📋 Converted \(sharedExercises.count) exercises for shared session", category: "LoggingViewModel")
        
        // Create SharedWorkoutSession
        let sharedSession = SharedWorkoutSession(
            id: session.id,
            title: session.title,
            startTime: session.date,
            duration: session.duration,
            currentExerciseIndex: 0,
            totalExercises: sharedExercises.count,
            exercises: sharedExercises
        )
        
        AppLogger.info("[LoggingViewModel.syncWorkoutSessionToWatch] 🔄 Created SharedWorkoutSession with \(sharedSession.exercises.count) exercises", category: "LoggingViewModel")
        AppLogger.debug("[LoggingViewModel.syncWorkoutSessionToWatch] 📊 SharedSession details - Current exercise index: \(sharedSession.currentExerciseIndex), Total exercises: \(sharedSession.totalExercises)", category: "LoggingViewModel")
        
        // Sync to Watch via SyncCoordinator
        AppLogger.info("[LoggingViewModel.syncWorkoutSessionToWatch] 📡 Calling SyncCoordinator.syncWorkoutStart", category: "LoggingViewModel")
        SyncCoordinator.shared.syncWorkoutStart(sharedSession)
        
        AppLogger.info("[LoggingViewModel.syncWorkoutSessionToWatch] ✅ Workout session synced to Watch: '\(session.title)' with \(sharedExercises.count) exercises", category: "LoggingViewModel")
    }
    
    // MARK: - Cleanup
    deinit {
        restTimer?.invalidate()
        AppLogger.info("[LoggingViewModel.deinit] Cleaned up resources", category: "LoggingViewModel")
    }
} 