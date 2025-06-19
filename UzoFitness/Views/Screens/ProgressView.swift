import SwiftUI
import SwiftData

struct ProgressView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationView {
            Text("📸 Progress View")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Progress Photos")
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
            .modelContainer(PersistenceController.preview.container)
    }
}
