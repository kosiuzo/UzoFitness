//
//  UzoFitnessWatchApp.swift
//  UzoFitnessWatch Watch App
//
//  Created by Kosi Uzodinma on 7/28/25.
//

import SwiftUI
import SwiftData
import UzoFitnessCore

@main
struct UzoFitnessWatchApp: App {
    
    // MARK: - SwiftData Model Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutPlan.self,
            WorkoutTemplate.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            Exercise.self,
            WorkoutSession.self,
            SessionExercise.self,
            PerformedExercise.self,
            CompletedSet.self,
            ProgressPhoto.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.kosiuzodinma.UzoFitness")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
