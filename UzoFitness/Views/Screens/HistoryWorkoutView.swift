//
//  HistoryWorkoutView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 7/9/25.
//

import SwiftUI
import SwiftData

struct HistoryWorkoutView: View {
    let session: WorkoutSession
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(session.title.isEmpty ? "Workout" : session.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(DateFormatter.fullDate.string(from: session.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Workout summary
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(session.sessionExercises.count)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Exercises")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let duration = session.duration {
                            VStack(spacing: 4) {
                                Text(formatDuration(duration))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Duration")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(formatVolume(session.totalVolume))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Volume")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                
                // Exercises
                LazyVStack(spacing: 16) {
                    ForEach(session.sessionExercises.sorted(by: { $0.position < $1.position })) { sessionExercise in
                        ExerciseDetailCard(sessionExercise: sessionExercise)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Formatting Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let sessionExercise: SessionExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(sessionExercise.exercise.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Sets
            let actuallyCompletedSets = sessionExercise.completedSets.filter { $0.isCompleted }
            if actuallyCompletedSets.isEmpty {
                Text("No sets completed")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(actuallyCompletedSets.sorted(by: { $0.position < $1.position })) { set in
                        SetDetailRow(set: set)
                    }
                }
            }
            
            // Exercise volume
            if sessionExercise.totalVolume > 0 {
                HStack {
                    Text("Total Volume:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatVolume(sessionExercise.totalVolume))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
}

// MARK: - Set Detail Row
struct SetDetailRow: View {
    let set: CompletedSet
    
    var body: some View {
        HStack {
            // Set number
            Text("Set \(set.position + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Reps
            VStack(alignment: .leading, spacing: 2) {
                Text("\(set.reps)")
                    .font(.body)
                    .fontWeight(.medium)
                Text("reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, alignment: .leading)
            
            // Weight
            VStack(alignment: .leading, spacing: 2) {
                Text(formatWeight(set.weight))
                    .font(.body)
                    .fontWeight(.medium)
                Text("lbs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Volume for this set
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatVolume(Double(set.reps) * set.weight))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Text("volume")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Completion status
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: weight)) ?? "0"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "0"
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
}