import SwiftUI
import SwiftData

@main
struct MyFitnessAppApp: App {
    @StateObject private var persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(persistence.container)
        }
    }
}
