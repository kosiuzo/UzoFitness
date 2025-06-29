//
//  MainTabView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/15/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            LoggingView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book")
                }
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            ProgressView(
                modelContext: PersistenceController.shared.container.mainContext,
                photoService: PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.shared.container.mainContext)),
                healthKitManager: HealthKitManager()
            )
            .tabItem {
                Label("Progress", systemImage: "photo")
            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }

            
        }
        .modelContainer(PersistenceController.shared.container)
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .modelContainer(PersistenceController.shared.container)
    }
}
#endif
