import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct PicturesContentView: View {
    @ObservedObject var viewModel: ProgressViewModel
    let dateRange: DateRange
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var selectedPickerAngle: PhotoAngle?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if viewModel.isLoadingPhotos {
                    SwiftUI.ProgressView("Loading photos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if viewModel.totalPhotos == 0 {
                    emptyPhotosView
                } else {
                    photosContent
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.handleIntent(.loadPhotos)
        }
        .onChange(of: selectedPickerItems) { _, newItems in
            guard let angle = selectedPickerAngle else { return }
            
            Task {
                var photosToAdd: [(angle: PhotoAngle, image: UIImage, date: Date)] = []
                
                // Process all items first to collect photos to add
                for item in newItems {
                    var creationDate: Date? = nil
                    var assetIdentifier: String? = nil
                    
                    if let id = item.itemIdentifier {
                        assetIdentifier = id
                        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
                        if let asset = assets.firstObject {
                            creationDate = asset.creationDate
                        }
                    }
                    
                    if let data = try? await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        // Check for duplicate by assetIdentifier and angle
                        if let assetIdentifier = assetIdentifier, viewModel.photosByAngle[angle]?.contains(where: { $0.assetIdentifier == assetIdentifier && $0.angle == angle }) == true {
                            continue // skip duplicate
                        }
                        
                        photosToAdd.append((angle: angle, image: uiImage, date: creationDate ?? Date()))
                    }
                }
                
                // Add all photos in batch
                if !photosToAdd.isEmpty {
                    await viewModel.handleIntent(.addPhotosBatch(photosToAdd))
                }
                
                // Clear the selection after processing
                selectedPickerItems = []
                selectedPickerAngle = nil
            }
        }
    }
    
    private var emptyPhotosView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Progress Photos")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add your first progress photo to track your transformation")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Photo") {
                Task {
                    await viewModel.handleIntent(.showImagePicker(.front))
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.top, 100)
    }
    
    private var photosContent: some View {
        VStack(spacing: 24) {
            // Add Photo Buttons
            addPhotoSection
            
            // Comparison Section
            if viewModel.canCompare {
                photoComparisonSection
            }
            
            // Photo Grid by Angle
            ForEach(PhotoAngle.allCases, id: \.self) { angle in
                ProgressPhotoGrid(
                    angle: angle,
                    photos: viewModel.getPhotosForAngle(angle).filter { dateRange.contains($0.date) },
                    viewModel: viewModel
                )
            }
        }
    }
    
    private var addPhotoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Progress Photo").font(.headline)
            
            HStack(spacing: 12) {
                ForEach(PhotoAngle.allCases, id: \.self) { angle in
                    PhotosPicker(
                        selection: Binding<[PhotosPickerItem]>(
                            get: { selectedPickerAngle == angle ? selectedPickerItems : [] },
                            set: { newItems in
                                selectedPickerItems = newItems
                                selectedPickerAngle = angle
                            }
                        ),
                        maxSelectionCount: 10,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill").font(.title2)
                            Text(angle.displayName).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                        )
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var photoComparisonSection: some View {
        PhotoCompareView(viewModel: viewModel)
    }
} 