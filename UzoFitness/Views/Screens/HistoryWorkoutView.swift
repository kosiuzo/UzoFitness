//
//  HistoryWorkoutView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 7/13/25.
//

import SwiftUI
import SwiftData
// Import the new components
// These are in Views/Components

struct HistoryWorkoutView: View {
    let session: WorkoutSession
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workout Session Header
                WorkoutSessionHeaderView(
                    date: session.date,
                    duration: session.duration,
                    totalVolume: session.totalVolume,
                    exerciseCount: session.sessionExercises.count,
                    totalSets: totalSets
                )
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