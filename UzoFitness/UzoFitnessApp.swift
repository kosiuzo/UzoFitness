import SwiftUI
import SwiftData
import UzoFitnessCore

@main
struct UzoFitnessApp: App {
    @StateObject private var persistence = PersistenceController.shared

    init() {
        // Initialize WatchConnectivity on iPhone app launch
        Task { @MainActor in
            WatchConnectivityManager.shared.activateSession()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(persistence.container)
        }
    }
}
