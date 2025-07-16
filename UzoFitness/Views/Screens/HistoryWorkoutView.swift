//
//  HistoryWorkoutView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 7/13/25.
//

import SwiftUI
import SwiftData

struct HistoryWorkoutView: View {
    let session: WorkoutSession
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workout Header (now minimalist, no title here)
                workoutHeaderView
                // Exercise List
                exerciseListView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .navigationTitle(planNameOnly)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
    
    // Extract only the plan name from the session title (removes weekday prefix and dash)
    private var planNameOnly: String {
        let title = session.title
        // Look for a dash and remove the prefix if present
        if let dashRange = title.range(of: " - ") {
            return String(title[dashRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return title.isEmpty ? "Workout" : title
    }
    
    // MARK: - Workout Header
    private var workoutHeaderView: some View {
        VStack(spacing: 12) {
            // Date and Duration (stacked vertically)
            VStack(alignment: .leading, spacing: 4) {
                Text(DateFormatter.fullDate.string(from: session.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let duration = session.duration {
                    Text("Duration: \(formatDuration(duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats Row
            HStack(spacing: 24) {
                StatView(
                    title: "Total Volume",
                    value: formatVolume(session.totalVolume),
                    color: .blue
                )
                StatView(
                    title: "Exercises",
                    value: "\(session.sessionExercises.count)",
                    color: .green
                )
                if !session.sessionExercises.isEmpty {
                    StatView(
                        title: "Sets",
                        value: "\(totalSets)",
                        color: .orange
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Exercise List
    private var exerciseListView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Exercises")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            LazyVStack(spacing: 16) {
                ForEach(session.sessionExercises.sorted(by: { $0.position < $1.position })) { sessionExercise in
                    ExerciseDetailCard(sessionExercise: sessionExercise)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalSets: Int {
        session.sessionExercises.reduce(0) { $0 + $1.completedSets.count }
    }
    
    // MARK: - Formatting Helpers
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

// MARK: - Stat View
struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let sessionExercise: SessionExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Name and Volume
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionExercise.exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if sessionExercise.totalVolume > 0 {
                        Text("Volume: \(formatVolume(sessionExercise.totalVolume))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if sessionExercise.completedSets.isEmpty {
                    Text("Not Completed")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
            }
            
            // Sets List
            if !sessionExercise.completedSets.isEmpty {
                VStack(spacing: 8) {
                    // Headers
                    HStack {
                        Text("Set")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("Reps")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text("Weight")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Text("Volume")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    
                    // Set Rows
                    ForEach(sessionExercise.completedSets.sorted(by: { $0.position < $1.position }), id: \.id) { completedSet in
                        HistorySetRowView(
                            setNumber: completedSet.position + 1,
                            completedSet: completedSet
                        )
                    }
                }
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(.thickMaterial)
        .cornerRadius(12)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
}

// MARK: - History Set Row View
struct HistorySetRowView: View {
    let setNumber: Int
    let completedSet: CompletedSet
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .leading)
            
            Text("\(completedSet.reps)")
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            Text(formatWeight(completedSet.weight))
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(formatVolume(Double(completedSet.reps) * completedSet.weight))
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(completedSet.isCompleted ? Color.clear : Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return (formatter.string(from: NSNumber(value: weight)) ?? "0") + " lbs"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}