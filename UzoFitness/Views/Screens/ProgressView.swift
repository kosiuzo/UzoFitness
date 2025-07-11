import SwiftUI
import SwiftData
import Charts
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct ProgressView: View {
    @StateObject private var viewModel: ProgressViewModel
    @State private var selectedSegment: ProgressSegment = .stats
    @State private var selectedDateRange: DateRange = .sixMonths
    @State private var showingDatePicker = false
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    
    init(modelContext: ModelContext, photoService: PhotoService, healthKitManager: HealthKitManager) {
        AppLogger.info("[ProgressView.init] Initializing with dependencies", category: "ProgressView")
        self._viewModel = StateObject(wrappedValue: ProgressViewModel(
            modelContext: modelContext,
            photoService: photoService,
            healthKitManager: healthKitManager
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control and Date Range Picker
                headerSection
                
                // Content based on selected segment
                contentView
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                AppLogger.info("[ProgressView] Task started - loading initial data", category: "ProgressView")
                await viewModel.handleIntent(.refreshData)
            }
            .sheet(isPresented: $showingDatePicker) {
                CustomDateRangePickerView(
                    startDate: $customStartDate,
                    endDate: $customEndDate,
                    isPresented: $showingDatePicker
                ) {
                    selectedDateRange = .custom(customStartDate, customEndDate)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Segmented Control
            Picker("Progress Type", selection: $selectedSegment) {
                ForEach(ProgressSegment.allCases, id: \.self) { segment in
                    Text(segment.displayName).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Date Range Picker
            HStack {
                Text("Date Range:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    ForEach(DateRange.presets, id: \.displayName) { range in
                        Button(range.displayName) {
                            selectedDateRange = range
                        }
                    }
                    
                    Divider()
                    
                    Button("Custom Range...") {
                        showingDatePicker = true
                    }
                } label: {
                    HStack {
                        Text(selectedDateRange.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSegment {
        case .stats:
            StatsContentView(
                viewModel: viewModel,
                dateRange: selectedDateRange
            )
        case .pictures:
            PicturesContentView(
                viewModel: viewModel,
                dateRange: selectedDateRange
            )
        }
    }
}

// MARK: - Stats Content View

struct StatsContentView: View {
    @ObservedObject var viewModel: ProgressViewModel
    let dateRange: DateRange
    @State private var selectedMetrics: Set<MetricType> = [.totalReps, .maxWeight, .totalVolume, .totalSessions]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if viewModel.isLoadingStats {
                    SwiftUI.ProgressView("Loading stats...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if viewModel.exerciseTrends.isEmpty {
                    emptyStatsView
                } else {
                    statsContent
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.handleIntent(.loadStats)
        }
    }
    
    private var emptyStatsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Exercise Data")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Complete some workouts to see your progress trends")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    private var statsContent: some View {
        VStack(spacing: 24) {
            // Exercise Selection
            exerciseSelectionCard
            
            // Metric Selection
            if viewModel.selectedExerciseID != nil {
                metricSelectionCard
                
                // Charts
                chartsSection
            }
        }
    }
    
    private var exerciseSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Exercise")
                .font(.headline)
                .padding(.horizontal)

            Menu {
                ForEach(viewModel.getExerciseOptions(), id: \.0) { exerciseID, exerciseName in
                    Button {
                        Task {
                            await viewModel.handleIntent(.selectExercise(exerciseID))
                        }
                    } label: {
                        HStack {
                            Text(exerciseName)
                            if viewModel.selectedExerciseID == exerciseID {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedExerciseName ?? "Choose an exercise")
                        .font(.subheadline)
                        .foregroundColor(viewModel.selectedExerciseID != nil ? .primary : .secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var metricSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metrics to Display")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(MetricType.allCases, id: \.self) { metric in
                    Toggle(isOn: Binding(
                        get: { selectedMetrics.contains(metric) },
                        set: { isOn in
                            if isOn {
                                selectedMetrics.insert(metric)
                            } else {
                                selectedMetrics.remove(metric)
                            }
                        }
                    )) {
                        Text(metric.displayName)
                            .font(.subheadline)
                    }
                    .toggleStyle(.checkmark)
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
    
    private var chartsSection: some View {
        ConsolidatedMetricChart(
            title: viewModel.selectedExerciseName ?? "Exercise Progress",
            selectedMetrics: selectedMetrics,
            data: getConsolidatedChartData(),
            dateRange: dateRange
        )
    }
    
    private func getConsolidatedChartData() -> [MetricType: [ChartDataPoint]] {
        guard let exerciseID = viewModel.selectedExerciseID else { return [:] }
        
        let filteredTrends = viewModel.exerciseTrends
            .filter { $0.exerciseID == exerciseID && dateRange.contains($0.weekStartDate) }
            .sorted { $0.weekStartDate < $1.weekStartDate }
        
        var data: [MetricType: [ChartDataPoint]] = [:]
        
        for metric in selectedMetrics {
            switch metric {
            case .maxWeight:
                data[metric] = filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: $0.maxWeight) }
            case .totalVolume:
                data[metric] = filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: $0.totalVolume) }
            case .totalSessions:
                data[metric] = filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: Double($0.totalSessions)) }
            case .totalReps:
                data[metric] = filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: Double($0.totalReps)) }
            }
        }
        
        return data
    }
    
    private func getChartData(for metric: MetricType) -> [ChartDataPoint] {
        guard let exerciseID = viewModel.selectedExerciseID else { return [] }
        
        let filteredTrends = viewModel.exerciseTrends
            .filter { $0.exerciseID == exerciseID && dateRange.contains($0.weekStartDate) }
            .sorted { $0.weekStartDate < $1.weekStartDate }
        
        switch metric {
        case .maxWeight:
            return filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: $0.maxWeight) }
        case .totalVolume:
            return filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: $0.totalVolume) }
        case .totalSessions:
            return filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: Double($0.totalSessions)) }
        case .totalReps:
            return filteredTrends.map { ChartDataPoint(date: $0.weekStartDate, value: Double($0.totalReps)) }
        }
    }
}

// MARK: - Toggle Styles

struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                        .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    configuration.label
                }
            }
            .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

extension ToggleStyle where Self == CheckmarkToggleStyle {
    static var checkmark: CheckmarkToggleStyle {
        CheckmarkToggleStyle()
    }
}

// MARK: - Pictures Content View

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
                    photosContent
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

// Types are now imported from ProgressTypes.swift

// MARK: - Preview

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView(
            modelContext: PersistenceController.preview.container.mainContext,
            photoService: PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext)),
            healthKitManager: HealthKitManager()
        )
        .modelContainer(PersistenceController.preview.container)
    }
}

