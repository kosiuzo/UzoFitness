import SwiftUI
import PhotosUI
import UIKit

// This view now correctly uses Application Support for storage, ensuring photos are persistent.
struct ProgressPhotoGrid: View {
    let angle: PhotoAngle
    let photos: [ProgressPhoto]
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedPickerItems: [PhotosPickerItem]
    
    @State private var selectedPhoto: ProgressPhoto?
    @State private var photoToEdit: ProgressPhoto?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header with Add Button
            HStack {
                Text("\(angle.displayName) View")
                    .font(.headline)
                
                Spacer()
                
                Text("\(photos.count) photos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PhotosPicker(
                    selection: $selectedPickerItems,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
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
                let sortedPhotos = photos.sorted { $0.date > $1.date }
                ForEach(sortedPhotos) { photo in
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
                            Task {
                                await viewModel.handleIntent(.selectForCompare(photo.id))
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.handleIntent(.deletePhoto(photo.id))
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            let sortedPhotos = photos.sorted { $0.date > $1.date }
            if let index = sortedPhotos.firstIndex(where: { $0.id == photo.id }) {
                PhotoGalleryView(photos: sortedPhotos, index: index)
            }
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
                if metrics.weight != nil {
                    Text(metrics.formattedWeight)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if metrics.bodyFat != nil {
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
            ),
            selectedPickerItems: .constant([])
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
} 