//
//  HistoryView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/18/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HistoryViewModel
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    
    init() {
        // Initialize with a temporary context that will be replaced in .task
        self._viewModel = StateObject(wrappedValue: HistoryViewModel(modelContext: PersistenceController.shared.context))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with streak info
                headerView
                
                // Calendar
                calendarView
                
                // Scrollable workout cards
                workoutCardsView
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await viewModel.loadWorkoutSessions()
            }
            .refreshable {
                await viewModel.loadWorkoutSessions()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.streakCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.streakCount == 1 ? "day" : "days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Workouts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.totalWorkoutDays)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("days trained")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Error message if any
            if let errorMessage = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Retry") {
                        Task { await viewModel.loadWorkoutSessions() }
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Calendar View
    private var calendarView: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                Text(monthYearString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(canNavigateToNextMonth ? .primary : .secondary)
                }
                .disabled(!canNavigateToNextMonth || viewModel.isLoading)
            }
            .padding(.horizontal, 20)
            
            // Loading indicator
            if viewModel.isLoading {
                SwiftUI.ProgressView()
                    .scaleEffect(0.7)
                    .padding(.vertical, 4)
            }
            
            // Calendar grid
            CalendarGridView(
                currentMonth: currentMonth,
                selectedDate: $viewModel.selectedDate,
                workoutDates: viewModel.workoutDates,
                onDateSelected: { date in
                    viewModel.selectDate(date)
                }
            )
            .padding(.horizontal, 20)
            .disabled(viewModel.isLoading)
        }
        .padding(.vertical, 12)
        .background(.thickMaterial)
    }
    
    // MARK: - Workout Cards View
    private var workoutCardsView: some View {
        VStack(spacing: 0) {
            // Subtle divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
            
            // Content
            if let selectedDate = viewModel.selectedDate {
                selectedDateContent(for: selectedDate)
            } else {
                emptyStateView
            }
        }
        .frame(maxHeight: .infinity)
        .background(.regularMaterial)
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
                if viewModel.sessionsForSelectedDate.isEmpty {
                    noWorkoutsView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sessionsForSelectedDate) { session in
                            NavigationLink(destination: HistoryWorkoutView(session: session)) {
                                WorkoutSessionSimpleCard(session: session)
                            }
                            .buttonStyle(PlainButtonStyle())
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
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 6) {
                Text("Select a date")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Tap on a date to see your workout history")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
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

// MARK: - Simple Workout Session Card
struct WorkoutSessionSimpleCard: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and exercise count
            HStack {
                Text(session.title.isEmpty ? "Workout" : session.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Exercise count and basic info
            Text("\(session.sessionExercises.count) Exercises Completed")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Additional info row
            HStack(spacing: 16) {
                if let duration = session.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(formatVolume(session.totalVolume))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
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