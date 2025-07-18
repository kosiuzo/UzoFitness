import SwiftUI
import Photos
import UzoFitnessCore


struct GalleryPresentation: Identifiable {
    let id = UUID()
    let photos: [ProgressPhoto]
    let startIndex: Int
}

struct PhotoCompareView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var presentation: GalleryPresentation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Photo Comparison")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    Task {
                        await viewModel.handleIntent(.clearComparison)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            // Comparison Content
            if viewModel.canCompare {
                comparisonContent
            } else {
                instructionView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .fullScreenCover(item: $presentation, onDismiss: { presentation = nil }) { info in
            PhotoGalleryView(photos: info.photos, index: info.startIndex)
        }
    }
    
    private var instructionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("Select two photos to compare")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
    }
    
    private var comparisonContent: some View {
        let (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        
        return HStack(spacing: 16) {
            // First Photo
            if let photo = firstPhoto {
                PhotoCompareCard(
                    photo: photo,
                    metrics: viewModel.getMetricsForPhoto(photo.id),
                    label: "Before"
                )
                .onTapGesture {
                    prepareAndShowGallery(startingWith: photo)
                }
            }
            
            // Comparison Arrow
            Image(systemName: "arrow.right")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            // Second Photo
            if let photo = secondPhoto {
                PhotoCompareCard(
                    photo: photo,
                    metrics: viewModel.getMetricsForPhoto(photo.id),
                    label: "After"
                )
                .onTapGesture {
                    prepareAndShowGallery(startingWith: photo)
                }
            }
        }
    }

    private func prepareAndShowGallery(startingWith startPhoto: ProgressPhoto) {
        let (first, second) = viewModel.comparisonPhotos

        var photos: [ProgressPhoto] = []
        if let first { photos.append(first) }
        if let second { photos.append(second) }

        let index = photos.firstIndex(where: { $0.id == startPhoto.id }) ?? 0
        presentation = GalleryPresentation(photos: photos, startIndex: index)
    }
}

// MARK: - Photo Compare Card

struct PhotoCompareCard: View {
    let photo: ProgressPhoto
    let metrics: BodyMetrics?
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Photo
            LocalFileImage(url: photoURL)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Date and Metrics
            VStack(spacing: 4) {
                Text(dateFormatter.string(from: photo.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let metrics = metrics {
                    VStack(spacing: 2) {
                        if let weight = metrics.weight {
                            Text(String(format: "%.1f lbs", weight))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        if let bodyFat = metrics.bodyFat {
                            Text(String(format: "%.1f%% BF", bodyFat * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var photoURL: URL? {
        // First, check Application Support/ProgressPhotos (persistent home)
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
        // Final fallback: check the original cache directory
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
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Preview

struct PhotoCompareView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Empty state
            PhotoCompareView(
                viewModel: ProgressViewModel(
                    modelContext: PersistenceController.preview.container.mainContext,
                    photoService: PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext)),
                    healthKitManager: HealthKitManager()
                )
            )
        }
        .padding()
        .background(.regularMaterial)
    }
} 