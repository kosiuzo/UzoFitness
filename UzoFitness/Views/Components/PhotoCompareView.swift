import SwiftUI
import UIKit

struct PhotoCompareView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var selectedPhoto: ProgressPhoto?  // Track which photo to show full screen
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Photo Comparison")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    Task {
                        viewModel.handleIntent(.clearComparison)
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
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoGalleryView(photos: [photo], index: 0)
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
                    selectedPhoto = photo
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
                    selectedPhoto = photo
                }
            }
        }
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
        if let url = URL(string: photo.assetIdentifier), url.isFileURL {
            return url
        }
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return cacheDir?.appendingPathComponent(photo.assetIdentifier)
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