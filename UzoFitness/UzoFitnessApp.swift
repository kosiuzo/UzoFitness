import SwiftUI
import SwiftData
import UzoFitnessCore

@main
struct UzoFitnessApp: App {
    @StateObject private var persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(persistence.container)
        }
    }
}
