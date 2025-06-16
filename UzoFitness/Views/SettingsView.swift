import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationView {
            Text("⚙️ Settings View")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .modelContainer(PersistenceController.preview.container)
    }
}
