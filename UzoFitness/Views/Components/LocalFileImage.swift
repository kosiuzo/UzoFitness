import SwiftUI
import UIKit

// MARK: - Local File Image Helper

struct LocalFileImage: View {
    let url: URL?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    }
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            if image != nil { await MainActor.run { image = nil } }
            return
        }

        // Check if image is already loaded
        guard image == nil else { return }

        do {
            let data = try Data(contentsOf: url)
            await MainActor.run {
                self.image = UIImage(data: data)
            }
        } catch {
            print("❌ [LocalFileImage] Error loading image from URL \(url): \(error.localizedDescription)")
            await MainActor.run { self.image = nil }
        }
    }
} 