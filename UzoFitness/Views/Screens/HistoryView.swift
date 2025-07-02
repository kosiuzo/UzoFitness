//
//  HistoryView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/18/25.
//

import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date?
    @State private var currentMonth = Date()
    @State private var workoutSessions: [WorkoutSession] = []
    @State private var streakCount = 0
    @State private var totalWorkoutDays = 0
    @State private var templateUsageCounts: [UUID: Int] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with streak
                headerView
                
                // Calendar
                calendarView
                
                // Bottom sheet with workout details
                bottomSheetView
            }
            .navigationTitle("History")
            .task {
                await loadWorkoutData()
            }
            .refreshable {
                await loadWorkoutData()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await loadWorkoutData()
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(streakCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(streakCount == 1 ? "day" : "days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalWorkoutDays)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("days trained")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Error message if any
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Retry") {
                        Task { await loadWorkoutData() }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Calendar View
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .disabled(isLoading)
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(canNavigateToNextMonth ? .primary : .secondary)
                }
                .disabled(!canNavigateToNextMonth || isLoading)
            }
            .padding(.horizontal, 24)
            
            // Loading indicator
            if isLoading {
                SwiftUI.ProgressView()
                    .scaleEffect(0.8)
                    .padding(.vertical, 8)
            }
            
            // Calendar grid
            CalendarGridView(
                currentMonth: currentMonth,
                selectedDate: $selectedDate,
                workoutDates: Set(workoutSessions.map { calendar.startOfDay(for: $0.date) }),
                onDateSelected: { date in
                    selectedDate = date
                }
            )
            .padding(.horizontal, 24)
            .disabled(isLoading)
        }
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Bottom Sheet View
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
            
            // Content
            if let selectedDate = selectedDate {
                selectedDateContent(for: selectedDate)
            } else {
                emptyStateView
            }
        }
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
    }
    
    // MARK: - Selected Date Content
    private func selectedDateContent(for date: Date) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Date header
                VStack(spacing: 6) {
                    Text(DateFormatter.dayMonth.string(from: date))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(DateFormatter.weekday.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Workout sessions for selected date
                let sessionsForDate = workoutSessions.filter { 
                    calendar.isDate($0.date, inSameDayAs: date) 
                }
                
                if sessionsForDate.isEmpty {
                    noWorkoutsView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sessionsForDate) { session in
                            WorkoutSessionCard(
                                session: session,
                                templateUsageCount: templateUsageCounts[session.plan?.template?.id ?? UUID()] ?? 0
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Empty States
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Select a date")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Tap on a date to see your workout history")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 60)
    }
    
    private var noWorkoutsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No workouts logged")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("You didn't log any workouts on this day")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Navigation
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        guard canNavigateToNextMonth else { return }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private var canNavigateToNextMonth: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        let now = Date()
        return calendar.compare(nextMonth, to: now, toGranularity: .month) != .orderedDescending
    }
    
    private var monthYearString: String {
        DateFormatter.monthYear.string(from: currentMonth)
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadWorkoutData() async {
        AppLogger.info("[HistoryView.loadWorkoutData] Starting data load", category: "HistoryView")
        isLoading = true
        errorMessage = nil
        
        do {
            // Load workout sessions with all relationships
            let sessionDescriptor = FetchDescriptor<WorkoutSession>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allSessions = try modelContext.fetch(sessionDescriptor)
            
            // Filter out sessions that have no completed sets
            // Show any session that has at least one completed set, regardless of whether it was formally finished
            workoutSessions = allSessions.filter { session in
                let hasCompletedSets = session.sessionExercises.contains { sessionExercise in
                    sessionExercise.completedSets.contains { $0.isCompleted }
                }
                
                if !hasCompletedSets && !session.sessionExercises.isEmpty {
                    AppLogger.debug("[HistoryView.loadWorkoutData] Filtering out session with no completed sets: \(session.title)", category: "HistoryView")
                }
                
                return hasCompletedSets
            }
            
            // Calculate streak and total days
            calculateStreakAndTotals()
            
            // Calculate template usage counts
            await calculateTemplateUsageCounts()
            
            AppLogger.info("[HistoryView.loadWorkoutData] Successfully loaded \(workoutSessions.count) sessions", category: "HistoryView")
            
        } catch {
            AppLogger.error("[HistoryView.loadWorkoutData] Error", category: "HistoryView", error: error)
            errorMessage = "Failed to load workout data"
        }
        
        isLoading = false
    }
    
    private func calculateStreakAndTotals() {
        let uniqueDates = Set(workoutSessions.map { calendar.startOfDay(for: $0.date) })
        totalWorkoutDays = uniqueDates.count
        
        // Calculate streak
        let sortedDates = uniqueDates.sorted(by: >)
        guard !sortedDates.isEmpty else { 
            streakCount = 0
            return 
        }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if abs(calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0) > 1 {
                break
            }
        }
        
        streakCount = streak
        AppLogger.debug("[HistoryView] Calculated streak: \(streak), total days: \(totalWorkoutDays)", category: "HistoryView")
    }
    
    // MARK: - Template Usage Calculation
    private func calculateTemplateUsageCounts() async {
        AppLogger.info("[HistoryView.calculateTemplateUsageCounts] Calculating template usage", category: "HistoryView")
        
        var counts: [UUID: Int] = [:]
        
        for session in workoutSessions {
            if let templateId = session.plan?.template?.id {
                counts[templateId, default: 0] += 1
            }
        }
        
        templateUsageCounts = counts
        AppLogger.debug("[HistoryView] Template usage counts: \(counts.count) templates tracked", category: "HistoryView")
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date?
    let workoutDates: Set<Date>
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 12) {
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                            hasWorkout: workoutDates.contains(calendar.startOfDay(for: date)),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            isToday: calendar.isDateInToday(date),
                            onTap: {
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
    
    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let range = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<32
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasWorkout: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: fontWeight))
                    .foregroundColor(textColor)
                
                // Workout indicator
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 44)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var indicatorColor: Color {
        if hasWorkout {
            return isSelected ? .white : .blue
        } else {
            return .clear
        }
    }
    
    private var fontWeight: Font.Weight {
        if isSelected || isToday {
            return .semibold
        } else {
            return .regular
        }
    }
}

// MARK: - Workout Session Card
struct WorkoutSessionCard: View {
    let session: WorkoutSession
    let templateUsageCount: Int
    @State private var isExpanded = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(session.title.isEmpty ? "Workout" : session.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            // Plan progress indicator
                            if let progress = calculatePlanProgress() {
                                Text("Week \(progress.currentWeek) of \(progress.totalWeeks)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Template usage count
                        if templateUsageCount > 0 {
                            Text("Logged \(templateUsageCount) times")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        HStack(spacing: 16) {
                            if let planName = session.plan?.customName {
                                Text(planName)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("\(formatVolume(session.totalVolume))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(session.sessionExercises.count) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let duration = session.duration {
                                Text(formatDuration(duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(session.sessionExercises.prefix(10)) { sessionExercise in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sessionExercise.exercise.name)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                        
                                        // Show exercise volume
                                        let exerciseVolume = sessionExercise.totalVolume
                                        if exerciseVolume > 0 {
                                            Text("Volume: \(formatVolume(exerciseVolume))")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        if sessionExercise.completedSets.isEmpty {
                                            Text("0 sets")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("Not completed")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        } else {
                                            Text("\(sessionExercise.completedSets.count) sets")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            // Show weight range or individual weights
                                            let weights = sessionExercise.completedSets.map { $0.weight }.sorted()
                                            let uniqueWeights = Array(Set(weights))
                                            
                                            if uniqueWeights.count == 1 {
                                                // All sets same weight
                                                if let weight = uniqueWeights.first, let reps = sessionExercise.completedSets.first?.reps {
                                                    Text("\(reps) × \(formatWeight(weight))")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            } else if uniqueWeights.count <= 3 {
                                                // Show all unique weights
                                                let weightStrings = uniqueWeights.sorted().map { formatWeight($0) }
                                                Text(weightStrings.joined(separator: ", "))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                // Show range
                                                if let minWeight = uniqueWeights.min(), let maxWeight = uniqueWeights.max() {
                                                    Text("\(formatWeight(minWeight)) - \(formatWeight(maxWeight))")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        if session.sessionExercises.count > 10 {
                            Text("+ \(session.sessionExercises.count - 10) more exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                        }
                        
                        // Total volume breakdown
                        Divider()
                            .padding(.horizontal, 16)
                        
                        HStack {
                            Text("Total Volume")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(formatVolume(session.totalVolume))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Plan Progress Calculation
    private func calculatePlanProgress() -> (currentWeek: Int, totalWeeks: Int)? {
        guard let plan = session.plan else { return nil }
        
        let daysSinceStart = calendar.dateComponents([.day], from: plan.startedAt, to: session.date).day ?? 0
        let currentWeek = min((daysSinceStart / 7) + 1, plan.durationWeeks)
        
        return (currentWeek: currentWeek, totalWeeks: plan.durationWeeks)
    }
    
    // MARK: - Formatting Helpers
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return (formatter.string(from: NSNumber(value: weight)) ?? "0") + " lbs"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()
    
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

