import SwiftUI
import SwiftData
import UzoFitnessCore

/// A full-screen gallery for a specific angle
struct PhotoGalleryView: View {
    let photos: [ProgressPhoto]          // all images for the angle
    @State var index: Int                // start at the one the user tapped
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $index) {
                ForEach(0..<photos.count, id: \.self) { i in
                    LocalFileImage(url: url(for: photos[i]))
                        .scaledToFit()
                        .tag(i)                     // Tag needed for paging
                        .background(Color.black)   // looks better on OLED
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // horizontal swipe

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding()
            }
        }
    }

    private func url(for photo: ProgressPhoto) -> URL? {
        // Always resolve as filename in Application Support/ProgressPhotos
        if let appSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let persistentURL = appSupportDir.appendingPathComponent("ProgressPhotos/")
            let fileURL = persistentURL.appendingPathComponent(photo.assetIdentifier)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }

        // Fallback: if assetIdentifier is an absolute file URL string
        if let url = URL(string: photo.assetIdentifier), url.isFileURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        // Final fallback for very old data: check the original cache directory.
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let legacyURL = cacheDir.appendingPathComponent(photo.assetIdentifier)
            if FileManager.default.fileExists(atPath: legacyURL.path) {
                return legacyURL
            }
        }
        
        return nil
    }
} 