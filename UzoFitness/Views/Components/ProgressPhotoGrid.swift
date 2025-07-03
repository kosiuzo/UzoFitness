import SwiftUI
import UIKit

// This view now correctly uses Application Support for storage, ensuring photos are persistent.
struct ProgressPhotoGrid: View {
    let angle: PhotoAngle
    let photos: [ProgressPhoto]
    @ObservedObject var viewModel: ProgressViewModel
    
    @State private var selectedPhoto: ProgressPhoto?
    @State private var photoToEdit: ProgressPhoto?
    
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
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .sheet(item: $photoToEdit) { photo in
            EditProgressPhotoView(photo: photo, viewModel: viewModel)
        }
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
        // Horizontal swipeable photo thumbnails (Task 6.2)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos.sorted { $0.date > $1.date }) { photo in
                    PhotoThumbnailView(
                        photo: photo,
                        isSelected: isSelected(photo),
                        metrics: viewModel.getMetricsForPhoto(photo.id),
                        onTap: {
                            selectedPhoto = photo
                        },
                        onEdit: {
                            photoToEdit = photo
                        },
                        onCompare: {
                            viewModel.handleIntent(.selectForCompare(photo.id))
                        },
                        onDelete: {
                            viewModel.handleIntent(.deletePhoto(photo.id))
                        }
                    )
                }
            }
            .padding(.vertical, 8)
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
    let onEdit: () -> Void
    let onCompare: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    /// Determines which weight to display, prioritizing the user's manual entry.
    private var weightToDisplay: Double? {
        if let manualWeight = photo.manualWeight, manualWeight > 0 {
            return manualWeight
        }
        if let metricsWeight = metrics?.weight {
            return metricsWeight
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                LocalFileImage(url: photoURL)
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            .onTapGesture(perform: onTap)
            .contextMenu {
                Button("View Full Screen", systemImage: "arrow.up.left.and.arrow.down.right", action: onTap)
                Button("Edit Details", systemImage: "pencil", action: onEdit)
                Button("Select for Comparison", systemImage: "square.on.square", action: onCompare)
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
            
            // Date below thumbnail
            Text(dateFormatter.string(from: photo.date))
                .font(.caption2)
                .foregroundColor(.secondary)
            // Display weight if available
            if let metrics = metrics {
                if let weight = metrics.weight {
                    Text(metrics.formattedWeight)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let bodyFat = metrics.bodyFat {
                    Text(metrics.formattedBodyFat)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var photoURL: URL? {
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

// MARK: - Weight Overlay View

struct WeightOverlay: View {
    let weight: Double
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(String(format: "%.1f lbs", weight))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(5)
            }
        }
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
                AppLogger.error("[LocalFileImage] File does not exist at path: \(url.path)", category: "ProgressPhotoGrid")
                return nil
            }
            do {
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            } catch {
                AppLogger.error("[LocalFileImage] Failed to load image data from \(url)", category: "ProgressPhotoGrid", error: error)
                return nil
            }
        }.value
        
        await MainActor.run {
            self.image = loadedImage
        }
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let photo: ProgressPhoto
    @Environment(\.dismiss) private var dismiss

    private var photoURL: URL? {
        if let url = URL(string: photo.assetIdentifier), url.isFileURL { return url }
        
        if let appSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let persistentURL = appSupportDir.appendingPathComponent("ProgressPhotos/\(photo.assetIdentifier)")
            if FileManager.default.fileExists(atPath: persistentURL.path) {
                return persistentURL
            }
        }
        
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
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.black.opacity(0.6))
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
        .background(Color(.systemGroupedBackground))
    }
} 