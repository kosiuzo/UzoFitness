import SwiftUI
import SwiftData

struct LoggingView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationView {
            Text("📝 Logging View")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Log Workout")
        }
    }
}

struct LoggingView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingView()
            .modelContainer(PersistenceController.preview.container)
    }
}
