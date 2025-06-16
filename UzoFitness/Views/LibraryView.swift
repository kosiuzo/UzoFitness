import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationView {
            Text("📚 Library View")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Exercise Library")
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .modelContainer(PersistenceController.preview.container)
    }
}
