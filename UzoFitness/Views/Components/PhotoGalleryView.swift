import SwiftUI
import SwiftData

/// A full-screen gallery for a specific angle
struct PhotoGalleryView: View {
    let photos: [ProgressPhoto]          // all images for the angle
    @State var index: Int                // start at the one the user tapped
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $index) {
                ForEach(photos.indices, id: \.self) { i in
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
        // First, check for an absolute file URL string, which is the current format.
        if let url = URL(string: photo.assetIdentifier), url.isFileURL {
            return url
        }

        // Fallback for older data: check Application Support (the new persistent home).
        if let appSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let persistentURL = appSupportDir.appendingPathComponent("ProgressPhotos/\(photo.assetIdentifier)")
            if FileManager.default.fileExists(atPath: persistentURL.path) {
                return persistentURL
            }
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