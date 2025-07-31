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
    

    
    private var photosContent: some View {
        VStack(spacing: 24) {
            // Comparison Section
            if viewModel.canCompare {
                photoComparisonSection
            }
            
            // Photo Grid by Angle - now with integrated add photo functionality
            ForEach(PhotoAngle.allCases, id: \.self) { angle in
                ProgressPhotoGrid(
                    angle: angle,
                    photos: viewModel.getPhotosForAngle(angle).filter { dateRange.contains($0.date) },
                    viewModel: viewModel,
                    selectedPickerItems: Binding<[PhotosPickerItem]>(
                        get: { selectedPickerAngle == angle ? selectedPickerItems : [] },
                        set: { newItems in
                            selectedPickerItems = newItems
                            selectedPickerAngle = angle
                        }
                    )
                )
            }
        }
    }
    
    
    private var photoComparisonSection: some View {
        PhotoCompareView(viewModel: viewModel)
    }
} 