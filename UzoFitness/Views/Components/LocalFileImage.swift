import SwiftUI
import UIKit
import UzoFitnessCore

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

        // Perform file-loading off the main thread.
        let loadedImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard FileManager.default.fileExists(atPath: url.path) else {
                AppLogger.debug("[LocalFileImage] File does not exist at path: \(url.path)", category: "LocalFileImage")
                return nil
            }
            do {
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            } catch {
                AppLogger.error("[LocalFileImage] Failed to load image data from \(url)", category: "LocalFileImage", error: error)
                return nil
            }
        }.value
        
        await MainActor.run {
            self.image = loadedImage
        }
    }
} 