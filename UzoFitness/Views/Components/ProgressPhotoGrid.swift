import SwiftUI
import UIKit

struct ProgressPhotoGrid: View {
    let angle: PhotoAngle
    let photos: [ProgressPhoto]
    @ObservedObject var viewModel: ProgressViewModel
    
    @State private var selectedPhoto: ProgressPhoto?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("\(angle.displayName) View")
                    .font(.headline)
                
                Spacer()
                
                Text("\(photos.count) photos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if photos.isEmpty {
                emptyPhotoView
            } else {
                photoGrid
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var emptyPhotoView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("No \(angle.displayName.lowercased()) photos yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
    
    private var photoGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 8)
        ], spacing: 8) {
            ForEach(photos.sorted { $0.date > $1.date }) { photo in
                PhotoThumbnailView(
                    photo: photo,
                    isSelected: isSelected(photo),
                    metrics: viewModel.getMetricsForPhoto(photo.id),
                    onTap: {
                        // Open photo in full-screen
                        selectedPhoto = photo
                    },
                    onCompare: {
                        Task {
                            viewModel.handleIntent(.selectForCompare(photo.id))
                        }
                    },
                    onDelete: {
                        Task {
                            viewModel.handleIntent(.deletePhoto(photo.id))
                        }
                    }
                )
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            FullScreenPhotoView(photo: photo)
        }
    }
    
    private func isSelected(_ photo: ProgressPhoto) -> Bool {
        let (first, second) = viewModel.compareSelection
        return photo.id == first || photo.id == second
    }
}

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    let photo: ProgressPhoto
    let isSelected: Bool
    let metrics: BodyMetrics?
    let onTap: () -> Void
    let onCompare: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Photo thumbnail
            LocalFileImage(url: photoURL)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .onTapGesture {
                    onTap()
                }
                .contextMenu {
                    Button("View Full Screen") {
                        onTap()
                    }
                    
                    Button("Select for Comparison") {
                        onCompare()
                    }
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            
            // Date and metrics
            VStack(spacing: 2) {
                Text(dateFormatter.string(from: photo.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let metrics = metrics, let weight = metrics.weight {
                    Text(String(format: "%.1f lbs", weight))
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var photoURL: URL? {
        // If assetIdentifier is already an absolute path/URL string, use it directly.
        if let url = URL(string: photo.assetIdentifier), url.isFileURL {
            return url
        }

        // Fallback: treat assetIdentifier as relative filename inside Cache directory.
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return cacheDir?.appendingPathComponent(photo.assetIdentifier)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

// MARK: - Local File Image Helper

struct LocalFileImage: View {
    let url: URL?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
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
            if image != nil { image = nil }
            return
        }

        Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("❌ [LocalFileImage] File does not exist at path: \(url.path)")
                await MainActor.run { image = nil }
                return
            }

            do {
                let data = try Data(contentsOf: url)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run { image = loadedImage }
                } else {
                    print("❌ [LocalFileImage] Failed to create UIImage from data at: \(url.path)")
                    await MainActor.run { image = nil }
                }
            } catch {
                print("❌ [LocalFileImage] Failed to load image data from \(url): \(error.localizedDescription)")
                await MainActor.run { image = nil }
            }
        }
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let photo: ProgressPhoto
    @Environment(\.dismiss) private var dismiss

    private var photoURL: URL? {
        if let url = URL(string: photo.assetIdentifier), url.isFileURL { return url }
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return cacheDir?.appendingPathComponent(photo.assetIdentifier)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            LocalFileImage(url: photoURL)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

// MARK: - Preview

struct ProgressPhotoGrid_Previews: PreviewProvider {
    static var previews: some View {
        ProgressPhotoGrid(
            angle: .front,
            photos: [],
            viewModel: ProgressViewModel(
                modelContext: PersistenceController.preview.container.mainContext,
                photoService: PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext)),
                healthKitManager: HealthKitManager()
            )
        )
        .padding()
        .background(.regularMaterial)
    }
} 