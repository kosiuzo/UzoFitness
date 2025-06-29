import XCTest
import SwiftData
@testable import UzoFitness

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: HistoryViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: 
            WorkoutSession.self,
            PerformedExercise.self,
            Exercise.self,
            WorkoutPlan.self,
            WorkoutTemplate.self,
            SessionExercise.self,
            CompletedSet.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            ProgressPhoto.self,
            configurations: config
        )
        
        modelContext = modelContainer.mainContext
        viewModel = HistoryViewModel()
        viewModel.setModelContext(modelContext)
        
        print("✅ [HistoryViewModelTests.setUp] Test environment initialized")
    }
    
    override func tearDown() async throws {
        viewModel = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
        
        print("✅ [HistoryViewModelTests.tearDown] Test environment cleaned up")
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultState() async throws {
        // Then
        XCTAssertTrue(viewModel.calendarData.isEmpty)
        XCTAssertNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.dailyDetails.isEmpty)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.totalVolumeForDay, 0.0)
        XCTAssertNil(viewModel.longestSession)
        XCTAssertEqual(viewModel.streakCount, 0)
        
        print("✅ [HistoryViewModelTests.testInitialization_SetsDefaultState] Passed")
    }
    
    // MARK: - Calendar Data Tests
    
    func testLoadCalendarData_WithWorkoutSessions_PopulatesCalendarData() async throws {
        // Given
        let sessions = try createTestWorkoutSessions()
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then
        XCTAssertFalse(viewModel.calendarData.isEmpty)
        XCTAssertEqual(viewModel.calendarData.count, 3) // 3 different days
        XCTAssertEqual(viewModel.totalWorkoutDays, 3)
        XCTAssertGreaterThan(viewModel.totalVolume, 0)
        
        print("✅ [HistoryViewModelTests.testLoadCalendarData_WithWorkoutSessions_PopulatesCalendarData] Passed")
    }
    
    func testWorkoutSessionSummary_CreatesCorrectSummary() async throws {
        // Given
        let (session, _) = try createTestWorkoutSession(
            date: Date(),
            title: "Morning Workout",
            duration: 3600, // 1 hour
            exerciseCount: 3
        )
        
        // When
        let summary = WorkoutSessionSummary(from: session)
        
        // Then
        XCTAssertEqual(summary.id, session.id)
        XCTAssertEqual(summary.title, "Morning Workout")
        XCTAssertEqual(summary.duration, 3600)
        XCTAssertEqual(summary.exerciseCount, 3)
        XCTAssertEqual(summary.formattedDuration, "1h 0m")
        XCTAssertGreaterThan(summary.totalVolume, 0)
        
        print("✅ [HistoryViewModelTests.testWorkoutSessionSummary_CreatesCorrectSummary] Passed")
    }
    
    func testWorkoutSessionSummary_EmptyTitle_UsesDefaultTitle() async throws {
        // Given
        let (session, _) = try createTestWorkoutSession(
            date: Date(),
            title: "", // Empty title
            duration: 1800,
            exerciseCount: 2
        )
        
        // When
        let summary = WorkoutSessionSummary(from: session)
        
        // Then
        XCTAssertEqual(summary.title, "Workout") // Default title
        XCTAssertEqual(summary.formattedDuration, "30m")
        
        print("✅ [HistoryViewModelTests.testWorkoutSessionSummary_EmptyTitle_UsesDefaultTitle] Passed")
    }
    
    // MARK: - Date Selection Tests
    
    func testSelectDate_WithWorkoutData_SetsSelectedDateAndLoadsDetails() async throws {
        // Given
        let testDate = Date()
        let (_, performedExercises) = try createTestWorkoutSession(
            date: testDate,
            title: "Test Workout",
            duration: 3600,
            exerciseCount: 2
        )
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.selectDate(testDate))
        
        // Then
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertEqual(Calendar.current.startOfDay(for: viewModel.selectedDate!), 
                      Calendar.current.startOfDay(for: testDate))
        XCTAssertEqual(viewModel.dailyDetails.count, performedExercises.count)
        XCTAssertFalse(viewModel.selectedDateSessions.isEmpty)
        
        print("✅ [HistoryViewModelTests.testSelectDate_WithWorkoutData_SetsSelectedDateAndLoadsDetails] Passed")
    }
    
    func testSelectDate_WithNoWorkoutData_SetsSelectedDateWithEmptyDetails() async throws {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        // When
        viewModel.handleIntent(.selectDate(futureDate))
        
        // Then
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.dailyDetails.isEmpty)
        XCTAssertTrue(viewModel.selectedDateSessions.isEmpty)
        XCTAssertEqual(viewModel.totalVolumeForDay, 0.0)
        XCTAssertNil(viewModel.longestSession)
        
        print("✅ [HistoryViewModelTests.testSelectDate_WithNoWorkoutData_SetsSelectedDateWithEmptyDetails] Passed")
    }
    
    func testClearSelection_ClearsSelectedDateAndDetails() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Test", duration: 3600, exerciseCount: 1)
        viewModel.handleIntent(.loadData)
        viewModel.handleIntent(.selectDate(testDate))
        
        // When
        viewModel.handleIntent(.clearSelection)
        
        // Then
        XCTAssertNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.dailyDetails.isEmpty)
        XCTAssertTrue(viewModel.selectedDateSessions.isEmpty)
        
        print("✅ [HistoryViewModelTests.testClearSelection_ClearsSelectedDateAndDetails] Passed")
    }
    
    // MARK: - Analytics Tests
    
    func testTotalVolumeForDay_WithSelectedDate_CalculatesCorrectly() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Session 1", duration: 3600, exerciseCount: 2)
        try createTestWorkoutSession(date: testDate, title: "Session 2", duration: 1800, exerciseCount: 1)
        
        viewModel.handleIntent(.loadData)
        viewModel.handleIntent(.selectDate(testDate))
        
        // When
        let totalVolume = viewModel.totalVolumeForDay
        
        // Then
        XCTAssertGreaterThan(totalVolume, 0)
        
        // Verify it's the sum of both sessions
        let sessionsForDay = viewModel.selectedDateSessions
        let expectedVolume = sessionsForDay.reduce(0) { $0 + $1.totalVolume }
        XCTAssertEqual(totalVolume, expectedVolume, accuracy: 0.01)
        
        print("✅ [HistoryViewModelTests.testTotalVolumeForDay_WithSelectedDate_CalculatesCorrectly] Passed")
    }
    
    func testLongestSession_WithMultipleSessions_ReturnsLongestDuration() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Short", duration: 1800, exerciseCount: 1) // 30 min
        try createTestWorkoutSession(date: testDate, title: "Long", duration: 5400, exerciseCount: 3) // 90 min
        try createTestWorkoutSession(date: testDate, title: "Medium", duration: 3600, exerciseCount: 2) // 60 min
        
        viewModel.handleIntent(.loadData)
        viewModel.handleIntent(.selectDate(testDate))
        
        // When
        let longestSession = viewModel.longestSession
        
        // Then
        XCTAssertNotNil(longestSession)
        XCTAssertEqual(longestSession?.title, "Long")
        XCTAssertEqual(longestSession?.duration, 5400)
        XCTAssertEqual(longestSession?.formattedDuration, "1h 30m")
        
        print("✅ [HistoryViewModelTests.testLongestSession_WithMultipleSessions_ReturnsLongestDuration] Passed")
    }
    
    func testStreakCount_WithConsecutiveWorkouts_CalculatesCorrectStreak() async throws {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        try createTestWorkoutSession(date: today, title: "Today", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: yesterday, title: "Yesterday", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: twoDaysAgo, title: "Two days ago", duration: 3600, exerciseCount: 1)
        
        viewModel.handleIntent(.loadData)
        
        // When
        let streakCount = viewModel.streakCount
        
        // Then
        XCTAssertEqual(streakCount, 3)
        
        print("✅ [HistoryViewModelTests.testStreakCount_WithConsecutiveWorkouts_CalculatesCorrectStreak] Passed")
    }
    
    func testStreakCount_WithGapInWorkouts_CalculatesCorrectStreak() async throws {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)! // Gap here
        
        try createTestWorkoutSession(date: today, title: "Today", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: yesterday, title: "Yesterday", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: threeDaysAgo, title: "Three days ago", duration: 3600, exerciseCount: 1)
        
        viewModel.handleIntent(.loadData)
        
        // When
        let streakCount = viewModel.streakCount
        
        // Then
        XCTAssertEqual(streakCount, 2) // Should only count today and yesterday
        
        print("✅ [HistoryViewModelTests.testStreakCount_WithGapInWorkouts_CalculatesCorrectStreak] Passed")
    }
    
    func testAverageWorkoutDuration_WithMultipleSessions_CalculatesCorrectly() async throws {
        // Given
        try createTestWorkoutSession(date: Date(), title: "1", duration: 3600, exerciseCount: 1) // 60 min
        try createTestWorkoutSession(date: Date(), title: "2", duration: 1800, exerciseCount: 1) // 30 min
        try createTestWorkoutSession(date: Date(), title: "3", duration: 5400, exerciseCount: 1) // 90 min
        
        viewModel.handleIntent(.loadData)
        
        // When
        let averageDuration = viewModel.averageWorkoutDuration
        
        // Then
        XCTAssertNotNil(averageDuration)
        XCTAssertEqual(averageDuration!, 3600, accuracy: 1) // (60+30+90)/3 = 60 minutes
        
        print("✅ [HistoryViewModelTests.testAverageWorkoutDuration_WithMultipleSessions_CalculatesCorrectly] Passed")
    }
    
    // MARK: - Analytics Period Tests
    
    func testGetWorkoutFrequency_ForWeek_ReturnsCorrectData() async throws {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!
        
        try createTestWorkoutSession(date: today, title: "Today", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: threeDaysAgo, title: "3 days ago", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: sixDaysAgo, title: "6 days ago", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: tenDaysAgo, title: "10 days ago", duration: 3600, exerciseCount: 1) // Should be excluded
        
        viewModel.handleIntent(.loadData)
        
        // When
        let weeklyFrequency = viewModel.getWorkoutFrequency(for: .week)
        
        // Then
        XCTAssertEqual(weeklyFrequency.count, 3) // Only sessions within last 7 days
        XCTAssertTrue(weeklyFrequency.values.allSatisfy { $0 == 1 })
        
        print("✅ [HistoryViewModelTests.testGetWorkoutFrequency_ForWeek_ReturnsCorrectData] Passed")
    }
    
    func testGetVolumeHistory_ForMonth_ReturnsCorrectData() async throws {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: today)!
        
        try createTestWorkoutSession(date: today, title: "Recent", duration: 3600, exerciseCount: 2)
        try createTestWorkoutSession(date: twoWeeksAgo, title: "2 weeks ago", duration: 3600, exerciseCount: 2)
        try createTestWorkoutSession(date: twoMonthsAgo, title: "2 months ago", duration: 3600, exerciseCount: 2) // Should be excluded
        
        viewModel.handleIntent(.loadData)
        
        // When
        let monthlyVolume = viewModel.getVolumeHistory(for: .month)
        
        // Then
        XCTAssertEqual(monthlyVolume.count, 2) // Only sessions within last month
        XCTAssertTrue(monthlyVolume.values.allSatisfy { $0 > 0 })
        
        print("✅ [HistoryViewModelTests.testGetVolumeHistory_ForMonth_ReturnsCorrectData] Passed")
    }
    
    // MARK: - Helper Method Tests
    
    func testHasWorkoutData_WithData_ReturnsTrue() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Test", duration: 3600, exerciseCount: 1)
        viewModel.handleIntent(.loadData)
        
        // When
        let hasData = viewModel.hasWorkoutData(for: testDate)
        
        // Then
        XCTAssertTrue(hasData)
        
        print("✅ [HistoryViewModelTests.testHasWorkoutData_WithData_ReturnsTrue] Passed")
    }
    
    func testHasWorkoutData_WithoutData_ReturnsFalse() async throws {
        // Given
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        // When
        let hasData = viewModel.hasWorkoutData(for: futureDate)
        
        // Then
        XCTAssertFalse(hasData)
        
        print("✅ [HistoryViewModelTests.testHasWorkoutData_WithoutData_ReturnsFalse] Passed")
    }
    
    func testGetSessionCount_WithMultipleSessions_ReturnsCorrectCount() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Session 1", duration: 3600, exerciseCount: 1)
        try createTestWorkoutSession(date: testDate, title: "Session 2", duration: 1800, exerciseCount: 1)
        try createTestWorkoutSession(date: testDate, title: "Session 3", duration: 2700, exerciseCount: 1)
        
        viewModel.handleIntent(.loadData)
        
        // When
        let sessionCount = viewModel.getSessionCount(for: testDate)
        
        // Then
        XCTAssertEqual(sessionCount, 3)
        
        print("✅ [HistoryViewModelTests.testGetSessionCount_WithMultipleSessions_ReturnsCorrectCount] Passed")
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_WithError_ClearsError() async throws {
        // Given
        viewModel.error = HistoryError.dataLoadFailed
        
        // When
        viewModel.handleIntent(.clearError)
        
        // Then
        XCTAssertNil(viewModel.error)
        
        print("✅ [HistoryViewModelTests.testClearError_WithError_ClearsError] Passed")
    }
    
    func testRefreshData_ReloadsCalendarData() async throws {
        // Given
        try createTestWorkoutSession(date: Date(), title: "Test", duration: 3600, exerciseCount: 1)
        viewModel.handleIntent(.loadData)
        let initialCount = viewModel.calendarData.count
        
        // Add more data
        try createTestWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            title: "Another",
            duration: 1800,
            exerciseCount: 1
        )
        
        // When
        viewModel.handleIntent(.refreshData)
        
        // Then
        XCTAssertGreaterThanOrEqual(viewModel.calendarData.count, initialCount)
        
        print("✅ [HistoryViewModelTests.testRefreshData_ReloadsCalendarData] Passed")
    }
    
    // MARK: - Performance Tests
    
    func testCalendarDataLoading_WithManyWorkouts_PerformsEfficiently() async throws {
        // Given - Create many workout sessions across different dates
        let calendar = Calendar.current
        for i in 0..<100 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            try createTestWorkoutSession(
                date: date,
                title: "Workout \(i)",
                duration: TimeInterval(1800 + i * 60),
                exerciseCount: 1 + (i % 3)
            )
        }
        
        // When
        let startTime = Date()
        viewModel.handleIntent(.loadData)
        let endTime = Date()
        
        // Then
        let loadTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(loadTime, 1.0) // Should load in less than 1 second
        XCTAssertEqual(viewModel.calendarData.count, 100)
        XCTAssertEqual(viewModel.totalWorkoutDays, 100)
        
        print("✅ [HistoryViewModelTests.testCalendarDataLoading_WithManyWorkouts_PerformsEfficiently] Load time: \(loadTime)s")
    }
    
    // MARK: - Helper Methods
    
    private func createTestWorkoutSessions() throws -> [WorkoutSession] {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let sessions = [
            try createTestWorkoutSession(date: today, title: "Today's Workout", duration: 3600, exerciseCount: 3).0,
            try createTestWorkoutSession(date: yesterday, title: "Yesterday's Workout", duration: 2700, exerciseCount: 2).0,
            try createTestWorkoutSession(date: twoDaysAgo, title: "Previous Workout", duration: 1800, exerciseCount: 1).0
        ]
        
        return sessions
    }
    
    @discardableResult
    private func createTestWorkoutSession(
        date: Date,
        title: String,
        duration: TimeInterval,
        exerciseCount: Int
    ) throws -> (WorkoutSession, [PerformedExercise]) {
        
        // Create workout session
        let session = WorkoutSession(date: date, title: title, duration: duration)
        modelContext.insert(session)
        
        // Create exercises and performed exercises
        var performedExercises: [PerformedExercise] = []
        
        for i in 0..<exerciseCount {
            let exercise = Exercise(name: "Exercise \(i)", category: .strength)
            modelContext.insert(exercise)
            
            // Create session exercise
            let sessionExercise = SessionExercise(
                exercise: exercise,
                plannedSets: 3,
                plannedReps: 10,
                plannedWeight: 100.0 + Double(i * 10),
                position: Double(i + 1),
                session: session
            )
            modelContext.insert(sessionExercise)
            
            // Create completed sets
            for setNum in 1...3 {
                let completedSet = CompletedSet(
                    reps: 10,
                    weight: 100.0 + Double(i * 10) + Double(setNum),
                    sessionExercise: sessionExercise
                )
                modelContext.insert(completedSet)
            }
            
            session.sessionExercises.append(sessionExercise)
            
            // Create performed exercise for history
            let performedExercise = PerformedExercise(
                performedAt: date,
                reps: 30, // 3 sets x 10 reps
                weight: 100.0 + Double(i * 10),
                exercise: exercise,
                workoutSession: session
            )
            modelContext.insert(performedExercise)
            performedExercises.append(performedExercise)
        }
        
        try modelContext.save()
        return (session, performedExercises)
    }
    
    func testAnalyticsPeriod_DisplayNames_AreCorrect() async throws {
        // Then
        XCTAssertEqual(AnalyticsPeriod.week.displayName, "Week")
        XCTAssertEqual(AnalyticsPeriod.month.displayName, "Month")
        XCTAssertEqual(AnalyticsPeriod.threeMonths.displayName, "3 Months")
        XCTAssertEqual(AnalyticsPeriod.year.displayName, "Year")
        
        print("✅ [HistoryViewModelTests.testAnalyticsPeriod_DisplayNames_AreCorrect] Passed")
    }
    
    func testHistoryError_LocalizedDescriptions_AreCorrect() async throws {
        // Then
        XCTAssertEqual(HistoryError.dataLoadFailed.errorDescription, "Failed to load workout history data.")
        XCTAssertEqual(HistoryError.dateSelectionFailed.errorDescription, "Failed to select the requested date.")
        XCTAssertEqual(HistoryError.noDataFound.errorDescription, "No workout data found for the selected period.")
        XCTAssertEqual(HistoryError.invalidDateRange.errorDescription, "The selected date range is invalid.")
        XCTAssertEqual(HistoryError.custom("Test message").errorDescription, "Test message")
        
        print("✅ [HistoryViewModelTests.testHistoryError_LocalizedDescriptions_AreCorrect] Passed")
    }
    
    func testGetSessionCount_WithEmptyData_ReturnsZero() async throws {
        // Given
        let testDate = Date()
        
        // When
        let sessionCount = viewModel.getSessionCount(for: testDate)
        
        // Then
        XCTAssertEqual(sessionCount, 0)
        
        print("✅ [HistoryViewModelTests.testGetSessionCount_WithEmptyData_ReturnsZero] Passed")
    }
    
    func testTotalWorkoutDays_WithEmptyData_ReturnsZero() async throws {
        // When
        let totalDays = viewModel.totalWorkoutDays
        
        // Then
        XCTAssertEqual(totalDays, 0)
        
        print("✅ [HistoryViewModelTests.testTotalWorkoutDays_WithEmptyData_ReturnsZero] Passed")
    }
    
    func testAverageWorkoutDuration_WithEmptyData_ReturnsNil() async throws {
        // When
        let averageDuration = viewModel.averageWorkoutDuration
        
        // Then
        XCTAssertNil(averageDuration)
        
        print("✅ [HistoryViewModelTests.testAverageWorkoutDuration_WithEmptyData_ReturnsNil] Passed")
    }
    
    func testTotalVolume_WithEmptyData_ReturnsZero() async throws {
        // When
        let totalVolume = viewModel.totalVolume
        
        // Then
        XCTAssertEqual(totalVolume, 0.0)
        
        print("✅ [HistoryViewModelTests.testTotalVolume_WithEmptyData_ReturnsZero] Passed")
    }
} 