import Foundation

// MARK: - Progress Analysis Logic
public struct ProgressAnalysisLogic {
    
    // MARK: - Exercise Trend Analysis
    
    /// Creates exercise trends from performed exercises grouped by week
    public static func createExerciseTrends(
        from performedExercises: [PerformedExercise],
        exerciseID: UUID,
        exerciseName: String
    ) -> [ExerciseTrend] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: performedExercises) { exercise in
            calendar.dateInterval(of: .weekOfYear, for: exercise.performedAt)?.start ?? exercise.performedAt
        }
        
        return groupedByWeek.map { weekStartDate, exercises in
            ExerciseTrend(
                exerciseID: exerciseID,
                exerciseName: exerciseName,
                performedExercises: exercises,
                weekStartDate: weekStartDate
            )
        }.sorted { $0.weekStartDate < $1.weekStartDate }
    }
    
    /// Calculates workout streak from workout sessions
    public static func calculateWorkoutStreak(from sessions: [WorkoutSession]) -> Int {
        let calendar = Calendar.current
        let uniqueDates = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        
        guard !uniqueDates.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in uniqueDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if abs(calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0) > 1 {
                break
            }
        }
        
        return streak
    }
    
    /// Calculates total workout days from sessions
    public static func calculateTotalWorkoutDays(from sessions: [WorkoutSession]) -> Int {
        let calendar = Calendar.current
        let uniqueDates = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        return uniqueDates.count
    }
    
    /// Gets workout dates for calendar display
    public static func getWorkoutDates(from sessions: [WorkoutSession]) -> Set<Date> {
        let calendar = Calendar.current
        return Set(sessions.map { calendar.startOfDay(for: $0.date) })
    }
    
    /// Checks if there's workout data for a specific date
    public static func hasWorkoutData(for date: Date, in sessions: [WorkoutSession]) -> Bool {
        let calendar = Calendar.current
        return sessions.contains { 
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }
    
    // MARK: - Photo Progress Analysis
    
    /// Groups progress photos by angle
    public static func groupPhotosByAngle(_ photos: [ProgressPhoto]) -> [PhotoAngle: [ProgressPhoto]] {
        Dictionary(grouping: photos) { $0.angle }
    }
    
    /// Gets the latest photo from a collection
    public static func getLatestPhoto(from photos: [ProgressPhoto]) -> ProgressPhoto? {
        photos.max { $0.date < $1.date }
    }
    
    /// Counts photos taken this month
    public static func countPhotosThisMonth(_ photos: [ProgressPhoto]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return photos.filter { photo in
            photo.date >= startOfMonth
        }.count
    }
    
    // MARK: - Chart Data Generation
    
    /// Generates chart data points for exercise trends
    public static func generateChartData(
        from trends: [ExerciseTrend],
        metricType: MetricType
    ) -> [ChartDataPoint] {
        trends.map { trend in
            let value: Double
            switch metricType {
            case .maxWeight:
                value = trend.maxWeight
            case .totalVolume:
                value = trend.totalVolume
            case .totalSessions:
                value = Double(trend.totalSessions)
            case .totalReps:
                value = Double(trend.totalReps)
            }
            return ChartDataPoint(date: trend.weekStartDate, value: value)
        }
    }
}

// MARK: - ExerciseTrend Helper Struct
public struct ExerciseTrend: Identifiable, Hashable {
    public let id: UUID
    public let exerciseID: UUID
    public let exerciseName: String
    public let maxWeight: Double
    public let totalVolume: Double
    public let totalSessions: Int
    public let totalReps: Int
    public let weekStartDate: Date
    
    public init(
        exerciseID: UUID,
        exerciseName: String,
        performedExercises: [PerformedExercise],
        weekStartDate: Date
    ) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.weekStartDate = weekStartDate
        self.totalSessions = performedExercises.count
        
        if performedExercises.isEmpty {
            self.maxWeight = 0.0
            self.totalVolume = 0.0
            self.totalReps = 0
        } else {
            self.maxWeight = performedExercises.map { $0.weight }.max() ?? 0.0
            self.totalReps = performedExercises.reduce(0) { $0 + $1.reps }
            self.totalVolume = performedExercises.reduce(0) { total, exercise in
                total + (exercise.weight * Double(exercise.reps))
            }
        }
    }
    
    public var formattedMaxWeight: String {
        FormattingUtilities.formatWeight(maxWeight)
    }
    
    public var formattedTotalVolume: String {
        FormattingUtilities.formatVolume(totalVolume)
    }
}

// MARK: - Body Metrics Helper Struct
public struct BodyMetrics: Identifiable, Hashable {
    public let id: UUID
    public let photoID: UUID
    public let weight: Double? // in pounds
    public let bodyFat: Double? // as percentage (0-100)
    public let date: Date
    
    public init(
        photoID: UUID,
        weight: Double? = nil,
        bodyFat: Double? = nil,
        date: Date
    ) {
        self.id = UUID()
        self.photoID = photoID
        self.weight = weight
        self.bodyFat = bodyFat?.isNaN == false ? bodyFat : nil
        self.date = date
    }
    
    public var formattedWeight: String {
        guard let weight = weight else { return "N/A" }
        return FormattingUtilities.formatWeight(weight) + " lbs"
    }
    
    public var formattedBodyFat: String {
        guard let bodyFat = bodyFat else { return "N/A" }
        return String(format: "%.1f%%", bodyFat * 100)
    }
} 