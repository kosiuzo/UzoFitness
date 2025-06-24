import Foundation
import SwiftData
import Combine
import UIKit
import HealthKit

// MARK: - ExerciseTrend Helper Struct
struct ExerciseTrend: Identifiable, Hashable {
    let id: UUID
    let exerciseID: UUID
    let exerciseName: String
    let maxWeight: Double
    let totalVolume: Double
    let weekStartDate: Date
    let sessionCount: Int
    
    init(exerciseID: UUID, exerciseName: String, performedExercises: [PerformedExercise], weekStartDate: Date) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.weekStartDate = weekStartDate
        self.sessionCount = performedExercises.count
        
        if performedExercises.isEmpty {
            self.maxWeight = 0.0
            self.totalVolume = 0.0
        } else {
            self.maxWeight = performedExercises.map { $0.weight }.max() ?? 0.0
            self.totalVolume = performedExercises.reduce(0) { total, exercise in
                total + (exercise.weight * Double(exercise.reps))
            }
        }
    }
    
    var formattedMaxWeight: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: maxWeight)) ?? "0"
    }
    
    var formattedTotalVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalVolume)) ?? "0"
    }
}

// MARK: - Body Metrics Helper Struct
struct BodyMetrics: Identifiable, Hashable {
    let id: UUID
    let photoID: UUID
    let weight: Double? // in pounds
    let bodyFat: Double? // as percentage (0-100)
    let date: Date
    
    init(photoID: UUID, weight: Double? = nil, bodyFat: Double? = nil, date: Date) {
        self.id = UUID()
        self.photoID = photoID
        self.weight = weight
        self.bodyFat = bodyFat?.isNaN == false ? bodyFat : nil
        self.date = date
    }
    
    var formattedWeight: String {
        guard let weight = weight else { return "N/A" }
        return String(format: "%.1f lbs", weight)
    }
    
    var formattedBodyFat: String {
        guard let bodyFat = bodyFat else { return "N/A" }
        return String(format: "%.1f%%", bodyFat * 100)
    }
}

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

@MainActor
class ProgressViewModel: ObservableObject {
    // MARK: - Published State (Stats Tab)
    @Published var exerciseTrends: [ExerciseTrend] = []
    @Published var selectedExerciseID: UUID?
    @Published var selectedMetricType: MetricType = .maxWeight
    @Published var currentWeight: Double?
    @Published var isLoadingStats: Bool = false
    
    // MARK: - Published State (Photos Tab)
    @Published var photosByAngle: [PhotoAngle: [ProgressPhoto]] = [:]
    @Published var compareSelection: (UUID?, UUID?) = (nil, nil)
    @Published var photoMetrics: [UUID: BodyMetrics] = [:]
    @Published var isLoadingPhotos: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var selectedPhotoAngle: PhotoAngle = .front
    
    // MARK: - Published State (General)
    @Published var error: Error?
    @Published var state: ProgressLoadingState = .idle
    
    // MARK: - Computed Properties
    var trendChartData: [ChartDataPoint] {
        guard let selectedExerciseID = selectedExerciseID else { return [] }
        
        let exerciseSpecificTrends = exerciseTrends.filter { $0.exerciseID == selectedExerciseID }
            .sorted { $0.weekStartDate < $1.weekStartDate }
        
        switch selectedMetricType {
        case .maxWeight:
            return exerciseSpecificTrends.map { trend in
                ChartDataPoint(date: trend.weekStartDate, value: trend.maxWeight)
            }
        case .totalVolume:
            return exerciseSpecificTrends.map { trend in
                ChartDataPoint(date: trend.weekStartDate, value: trend.totalVolume)
            }
        case .sessionCount:
            return exerciseSpecificTrends.map { trend in
                ChartDataPoint(date: trend.weekStartDate, value: Double(trend.sessionCount))
            }
        }
    }
    
    var canCompare: Bool {
        let (first, second) = compareSelection
        return first != nil && second != nil && first != second
    }
    
    var selectedExerciseName: String? {
        guard let selectedExerciseID = selectedExerciseID else { return nil }
        return exerciseTrends.first { $0.exerciseID == selectedExerciseID }?.exerciseName
    }
    
    var totalPhotos: Int {
        photosByAngle.values.flatMap { $0 }.count
    }
    
    var photosThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return photosByAngle.values.flatMap { $0 }.filter { photo in
            photo.date >= startOfMonth
        }.count
    }
    
    var latestPhoto: ProgressPhoto? {
        photosByAngle.values.flatMap { $0 }.max { $0.date < $1.date }
    }
    
    var comparisonPhotos: (ProgressPhoto?, ProgressPhoto?) {
        let (firstID, secondID) = compareSelection
        
        let firstPhoto = photosByAngle.values.flatMap { $0 }.first { $0.id == firstID }
        let secondPhoto = photosByAngle.values.flatMap { $0 }.first { $0.id == secondID }
        
        return (firstPhoto, secondPhoto)
    }
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private let photoService: PhotoService
    private let healthKitManager: HealthKitManager
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init(modelContext: ModelContext, photoService: PhotoService, healthKitManager: HealthKitManager) {
        self.modelContext = modelContext
        self.photoService = photoService
        self.healthKitManager = healthKitManager
        print("🔄 [ProgressViewModel.init] Initialized with dependencies")
        
        loadInitialData()
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: ProgressIntent) {
        print("🔄 [ProgressViewModel.handleIntent] Processing intent: \(intent)")
        
        Task {
            switch intent {
            case .selectExercise(let exerciseID):
                await selectExercise(exerciseID)
                
            case .toggleMetric(let metricType):
                toggleMetric(metricType)
                
            case .loadStats:
                await loadExerciseTrends()
                
            case .loadPhotos:
                await loadPhotos()
                
            case .addPhoto(let angle, let image):
                await addPhoto(angle: angle, image: image)
                
            case .deletePhoto(let photoID):
                await deletePhoto(photoID)
                
            case .selectForCompare(let photoID):
                selectForCompare(photoID)
                
            case .clearComparison:
                clearComparison()
                
            case .refreshData:
                await refreshData()
                
            case .clearError:
                error = nil
                
            case .showImagePicker(let angle):
                showImagePicker(for: angle)
                
            case .hideImagePicker:
                hideImagePicker()
            }
        }
    }
    
    // MARK: - Stats Tab Methods
    
    private func selectExercise(_ exerciseID: UUID) async {
        print("🔄 [ProgressViewModel.selectExercise] Selecting exercise: \(exerciseID)")
        selectedExerciseID = exerciseID
        print("📊 [ProgressViewModel] Selected exercise changed to: \(exerciseID)")
    }
    
    private func toggleMetric(_ metricType: MetricType) {
        print("🔄 [ProgressViewModel.toggleMetric] Toggling metric to: \(metricType)")
        selectedMetricType = metricType
        print("📊 [ProgressViewModel] Metric type changed to: \(metricType)")
    }
    
    private func loadExerciseTrends() async {
        print("🔄 [ProgressViewModel.loadExerciseTrends] Starting exercise trends load")
        isLoadingStats = true
        state = .loading
        
        do {
            // Fetch all performed exercises
            let descriptor = FetchDescriptor<PerformedExercise>(
                sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
            )
            
            let performedExercises = try modelContext.fetch(descriptor)
            
            // Group by exercise and week
            var trendsDict: [String: [PerformedExercise]] = [:]
            
            for exercise in performedExercises {
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: exercise.performedAt)?.start ?? exercise.performedAt
                let key = "\(exercise.exercise.id.uuidString)_\(weekStart.timeIntervalSince1970)"
                
                if trendsDict[key] != nil {
                    trendsDict[key]?.append(exercise)
                } else {
                    trendsDict[key] = [exercise]
                }
            }
            
            // Convert to ExerciseTrend objects
            var trends: [ExerciseTrend] = []
            
            for (_, exercisesInWeek) in trendsDict {
                guard let firstExercise = exercisesInWeek.first else { continue }
                
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: firstExercise.performedAt)?.start ?? firstExercise.performedAt
                
                let trend = ExerciseTrend(
                    exerciseID: firstExercise.exercise.id,
                    exerciseName: firstExercise.exercise.name,
                    performedExercises: exercisesInWeek,
                    weekStartDate: weekStart
                )
                
                trends.append(trend)
            }
            
            exerciseTrends = trends.sorted { $0.weekStartDate > $1.weekStartDate }
            
            print("✅ [ProgressViewModel.loadExerciseTrends] Successfully loaded \(trends.count) exercise trends")
            print("📊 [ProgressViewModel] State changed to: loaded")
            
            state = .loaded
            isLoadingStats = false
            
            // Load current weight from HealthKit
            await loadCurrentWeight()
            
        } catch {
            print("❌ [ProgressViewModel.loadExerciseTrends] Error: \(error.localizedDescription)")
            print("📊 [ProgressViewModel] State changed to: error")
            
            self.error = error
            state = .error
            isLoadingStats = false
        }
    }
    
    private func loadCurrentWeight() async {
        print("🔄 [ProgressViewModel.loadCurrentWeight] Loading current weight from HealthKit")
        
        await withCheckedContinuation { continuation in
            healthKitManager.fetchLatestBodyMassInPounds { [weak self] weight, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [ProgressViewModel.loadCurrentWeight] HealthKit error: \(error.localizedDescription)")
                    } else if let weight = weight {
                        print("✅ [ProgressViewModel.loadCurrentWeight] Current weight: \(weight) lbs")
                        self?.currentWeight = weight
                    } else {
                        print("📊 [ProgressViewModel.loadCurrentWeight] No weight data available")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Photos Tab Methods
    
    private func loadPhotos() async {
        print("🔄 [ProgressViewModel.loadPhotos] Starting photos load")
        
        guard !isLoadingPhotos else {
            print("⚠️ [ProgressViewModel.loadPhotos] Already loading photos, skipping")
            return
        }
        
        isLoadingPhotos = true
        
        do {
            print("🔄 [ProgressViewModel.loadPhotos] Creating FetchDescriptor for ProgressPhoto")
            let descriptor = FetchDescriptor<ProgressPhoto>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            print("🔄 [ProgressViewModel.loadPhotos] Fetching photos from modelContext")
            let photos = try modelContext.fetch(descriptor)
            print("🔄 [ProgressViewModel.loadPhotos] Fetched \(photos.count) photos from database")
            
            // Group photos by angle
            print("🔄 [ProgressViewModel.loadPhotos] Grouping photos by angle")
            var groupedPhotos: [PhotoAngle: [ProgressPhoto]] = [:]
            
            for angle in PhotoAngle.allCases {
                let photosForAngle = photos.filter { $0.angle == angle }
                groupedPhotos[angle] = photosForAngle
                print("🔄 [ProgressViewModel.loadPhotos] Found \(photosForAngle.count) photos for angle \(angle)")
            }
            
            print("🔄 [ProgressViewModel.loadPhotos] Updating photosByAngle property")
            photosByAngle = groupedPhotos
            
            print("✅ [ProgressViewModel.loadPhotos] Successfully loaded \(photos.count) photos")
            
            // Load body metrics for each photo
            if !photos.isEmpty {
                print("🔄 [ProgressViewModel.loadPhotos] Loading body metrics for photos")
                await loadPhotoMetrics(for: photos)
            } else {
                print("🔄 [ProgressViewModel.loadPhotos] No photos to load metrics for")
            }
            
            isLoadingPhotos = false
            print("✅ [ProgressViewModel.loadPhotos] Photo loading completed successfully")
            
        } catch {
            print("❌ [ProgressViewModel.loadPhotos] Error: \(error)")
            print("❌ [ProgressViewModel.loadPhotos] Error type: \(type(of: error))")
            print("❌ [ProgressViewModel.loadPhotos] Error description: \(error.localizedDescription)")
            self.error = error
            isLoadingPhotos = false
        }
    }
    
    private func loadPhotoMetrics(for photos: [ProgressPhoto]) async {
        print("🔄 [ProgressViewModel.loadPhotoMetrics] Loading metrics for \(photos.count) photos")
        
        var metrics: [UUID: BodyMetrics] = [:]
        
        for photo in photos {
            await withCheckedContinuation { continuation in
                // Load weight for photo date
                healthKitManager.fetchBodyMassInPounds(on: photo.date) { weight, _ in
                    // Load body fat for photo date
                    self.healthKitManager.fetchBodyFat(on: photo.date) { bodyFat, _ in
                        DispatchQueue.main.async {
                            let bodyMetrics = BodyMetrics(
                                photoID: photo.id,
                                weight: weight,
                                bodyFat: bodyFat,
                                date: photo.date
                            )
                            metrics[photo.id] = bodyMetrics
                            continuation.resume()
                        }
                    }
                }
            }
        }
        
        photoMetrics = metrics
        print("✅ [ProgressViewModel.loadPhotoMetrics] Loaded metrics for \(metrics.count) photos")
    }
    
    private func addPhoto(angle: PhotoAngle, image: UIImage) async {
        print("🔄 [ProgressViewModel.addPhoto] Adding photo for angle: \(angle)")
        
        do {
            try photoService.save(image: image, angle: angle)
            
            print("✅ [ProgressViewModel.addPhoto] Successfully saved photo")
            
            // Reload photos to update UI
            await loadPhotos()
            
        } catch {
            print("❌ [ProgressViewModel.addPhoto] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func deletePhoto(_ photoID: UUID) async {
        print("🔄 [ProgressViewModel.deletePhoto] Deleting photo: \(photoID)")
        
        do {
            // Find the photo in our data
            guard let photo = photosByAngle.values.flatMap({ $0 }).first(where: { $0.id == photoID }) else {
                throw ProgressError.photoNotFound
            }
            
            // Remove from SwiftData
            modelContext.delete(photo)
            try modelContext.save()
            
            // Remove from local state
            for (angle, photos) in photosByAngle {
                photosByAngle[angle] = photos.filter { $0.id != photoID }
            }
            
            // Remove from metrics
            photoMetrics.removeValue(forKey: photoID)
            
            // Clear comparison if this photo was selected
            if compareSelection.0 == photoID {
                compareSelection.0 = nil
            }
            if compareSelection.1 == photoID {
                compareSelection.1 = nil
            }
            
            print("✅ [ProgressViewModel.deletePhoto] Successfully deleted photo")
            
        } catch {
            print("❌ [ProgressViewModel.deletePhoto] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func selectForCompare(_ photoID: UUID) {
        print("🔄 [ProgressViewModel.selectForCompare] Selecting photo for comparison: \(photoID)")
        
        let (first, second) = compareSelection
        
        if first == nil {
            compareSelection.0 = photoID
            print("📊 [ProgressViewModel] First comparison photo selected: \(photoID)")
        } else if second == nil && first != photoID {
            compareSelection.1 = photoID
            print("📊 [ProgressViewModel] Second comparison photo selected: \(photoID)")
        } else {
            // Reset and start fresh
            compareSelection = (photoID, nil)
            print("📊 [ProgressViewModel] Comparison reset, first photo selected: \(photoID)")
        }
    }
    
    private func clearComparison() {
        print("🔄 [ProgressViewModel.clearComparison] Clearing photo comparison")
        compareSelection = (nil, nil)
        print("📊 [ProgressViewModel] Comparison cleared")
    }
    
    private func showImagePicker(for angle: PhotoAngle) {
        print("🔄 [ProgressViewModel.showImagePicker] Showing image picker for angle: \(angle)")
        selectedPhotoAngle = angle
        showImagePicker = true
    }
    
    private func hideImagePicker() {
        print("🔄 [ProgressViewModel.hideImagePicker] Hiding image picker")
        showImagePicker = false
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        print("🔄 [ProgressViewModel.loadInitialData] Loading initial data")
        
        Task {
            await loadExerciseTrends()
            await loadPhotos()
        }
    }
    
    private func refreshData() async {
        print("🔄 [ProgressViewModel.refreshData] Refreshing all data")
        
        await loadExerciseTrends()
        await loadPhotos()
    }
    
    // MARK: - Helper Methods
    
    func getPhotosForAngle(_ angle: PhotoAngle) -> [ProgressPhoto] {
        photosByAngle[angle] ?? []
    }
    
    func getMetricsForPhoto(_ photoID: UUID) -> BodyMetrics? {
        photoMetrics[photoID]
    }
    
    func getExerciseOptions() -> [(UUID, String)] {
        var uniqueExercises: [UUID: String] = [:]
        
        for trend in exerciseTrends {
            uniqueExercises[trend.exerciseID] = trend.exerciseName
        }
        
        return uniqueExercises.map { ($0.key, $0.value) }.sorted { $0.1 < $1.1 }
    }
    
    func getLatestTrendForExercise(_ exerciseID: UUID) -> ExerciseTrend? {
        exerciseTrends
            .filter { $0.exerciseID == exerciseID }
            .max { $0.weekStartDate < $1.weekStartDate }
    }
}

// MARK: - Supporting Types

enum ProgressIntent {
    case selectExercise(UUID)
    case toggleMetric(MetricType)
    case loadStats
    case loadPhotos
    case addPhoto(PhotoAngle, UIImage)
    case deletePhoto(UUID)
    case selectForCompare(UUID)
    case clearComparison
    case refreshData
    case clearError
    case showImagePicker(PhotoAngle)
    case hideImagePicker
}

enum MetricType: String, CaseIterable {
    case maxWeight = "Max Weight"
    case totalVolume = "Total Volume"
    case sessionCount = "Session Count"
    
    var displayName: String {
        return self.rawValue
    }
    
    var unit: String {
        switch self {
        case .maxWeight:
            return "lbs"
        case .totalVolume:
            return "lbs"
        case .sessionCount:
            return "sessions"
        }
    }
}

enum ProgressLoadingState {
    case idle
    case loading
    case loaded
    case error
}

enum ProgressError: Error, LocalizedError, Equatable {
    case photoNotFound
    case healthKitUnavailable
    case photoServiceError(String)
    case dataLoadFailed
    case invalidImageData
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .photoNotFound:
            return "The requested photo could not be found."
        case .healthKitUnavailable:
            return "HealthKit is not available on this device."
        case .photoServiceError(let message):
            return "Photo service error: \(message)"
        case .dataLoadFailed:
            return "Failed to load progress data."
        case .invalidImageData:
            return "The selected image data is invalid."
        case .custom(let message):
            return message
        }
    }
} 