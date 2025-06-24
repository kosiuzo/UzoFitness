import SwiftUI
import SwiftData

struct ProgressPhotosView: View {
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

struct ProgressPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressPhotosView()
            .modelContainer(for: [ProgressPhoto.self])
    }
}
