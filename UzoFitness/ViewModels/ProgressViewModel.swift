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
    let totalSessions: Int
    let totalReps: Int
    let weekStartDate: Date
    
    init(exerciseID: UUID, exerciseName: String, performedExercises: [PerformedExercise], weekStartDate: Date) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.weekStartDate = weekStartDate
        self.totalSessions = performedExercises.count
        
        if performedExercises.isEmpty {
            self.maxWeight = 0.0
            self.totalVolume = 0.0
            self.totalReps = 0
        } else {
            self.maxWeight = performedExercises.map { $0.weight }.max() ?? 0.0
            self.totalReps = performedExercises.reduce(0) { $0 + $1.reps }
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

// ChartDataPoint is now imported from ProgressTypes.swift

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
        case .totalSessions:
            return exerciseSpecificTrends.map { trend in
                ChartDataPoint(date: trend.weekStartDate, value: Double(trend.totalSessions))
            }
        case .totalReps:
            return exerciseSpecificTrends.map { trend in
                ChartDataPoint(date: trend.weekStartDate, value: Double(trend.totalReps))
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
        AppLogger.debug("[ProgressViewModel.init] Initialized with dependencies", category: "ProgressViewModel")
        
        loadInitialData()
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: ProgressIntent) {
        AppLogger.debug("[ProgressViewModel.handleIntent] Processing intent: \(intent)", category: "ProgressViewModel")
        
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
                
            case .editPhoto(let photoID, let date, let weight):
                await editPhoto(photoID, date, weight)
            }
        }
    }
    
    // MARK: - Stats Tab Methods
    
    private func selectExercise(_ exerciseID: UUID) async {
        AppLogger.debug("[ProgressViewModel.selectExercise] Selecting exercise: \(exerciseID)", category: "ProgressViewModel")
        selectedExerciseID = exerciseID
        AppLogger.debug("[ProgressViewModel] Selected exercise changed to: \(exerciseID)", category: "ProgressViewModel")
    }
    
    private func toggleMetric(_ metricType: MetricType) {
        AppLogger.debug("[ProgressViewModel.toggleMetric] Toggling metric to: \(metricType)", category: "ProgressViewModel")
        selectedMetricType = metricType
        AppLogger.debug("[ProgressViewModel] Metric type changed to: \(metricType)", category: "ProgressViewModel")
    }
    
    private func loadExerciseTrends() async {
        AppLogger.debug("[ProgressViewModel.loadExerciseTrends] Starting exercise trends load", category: "ProgressViewModel")
        
        do {
            // Fetch all performed exercises
            let descriptor = FetchDescriptor<PerformedExercise>(
                sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
            )
            
            let performedExercises = try modelContext.fetch(descriptor)
            
            // Group by exercise and week
            let groupedByWeek = Dictionary(grouping: performedExercises) { exercise -> Date in
                return calendar.dateInterval(of: .weekOfYear, for: exercise.performedAt)?.start ?? exercise.performedAt
            }
            
            var trends: [ExerciseTrend] = []
            
            for (week, exercisesInWeek) in groupedByWeek {
                let exercisesByName = Dictionary(grouping: exercisesInWeek) { $0.exercise.name }
                for (name, exercises) in exercisesByName {
                    if let firstExercise = exercises.first {
                        let exerciseID = firstExercise.exercise.id
                        trends.append(ExerciseTrend(exerciseID: exerciseID, exerciseName: name, performedExercises: exercises, weekStartDate: week))
                    }
                }
            }
            
            self.exerciseTrends = trends
            AppLogger.info("[ProgressViewModel.loadExerciseTrends] Successfully loaded \(trends.count) exercise trends", category: "ProgressViewModel")
            
            // Load current weight from HealthKit
            await loadCurrentWeight()
            
        } catch {
            AppLogger.error("[ProgressViewModel.loadExerciseTrends] Error: \(error.localizedDescription)", category: "ProgressViewModel", error: error)
            self.error = error
        }
    }
    
    private func loadCurrentWeight() async {
        AppLogger.debug("[ProgressViewModel.loadCurrentWeight] Loading current weight from HealthKit", category: "ProgressViewModel")
        
        await withCheckedContinuation { continuation in
            healthKitManager.fetchLatestBodyMassInPounds { [weak self] weight, error in
                DispatchQueue.main.async {
                    if let error = error {
                        AppLogger.error("[ProgressViewModel.loadCurrentWeight] HealthKit error: \(error.localizedDescription)", category: "ProgressViewModel", error: error)
                    } else if let weight = weight {
                        AppLogger.info("[ProgressViewModel.loadCurrentWeight] Current weight: \(weight) lbs", category: "ProgressViewModel")
                        self?.currentWeight = weight
                    } else {
                        AppLogger.debug("[ProgressViewModel.loadCurrentWeight] No weight data available", category: "ProgressViewModel")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Photos Tab Methods
    
    private func loadPhotos() async {
        AppLogger.debug("[ProgressViewModel.loadPhotos] Starting photos load", category: "ProgressViewModel")
        
        guard !isLoadingPhotos else {
            AppLogger.debug("[ProgressViewModel.loadPhotos] Already loading photos, skipping", category: "ProgressViewModel")
            return
        }
        
        isLoadingPhotos = true
        
        do {
            AppLogger.debug("[ProgressViewModel.loadPhotos] Creating FetchDescriptor for ProgressPhoto", category: "ProgressViewModel")
            let descriptor = FetchDescriptor<ProgressPhoto>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            AppLogger.debug("[ProgressViewModel.loadPhotos] Fetching photos from modelContext", category: "ProgressViewModel")
            let photos = try modelContext.fetch(descriptor)
            AppLogger.debug("[ProgressViewModel.loadPhotos] Fetched \(photos.count) photos from database", category: "ProgressViewModel")
            
            // Group photos by angle
            AppLogger.debug("[ProgressViewModel.loadPhotos] Grouping photos by angle", category: "ProgressViewModel")
            var groupedPhotos: [PhotoAngle: [ProgressPhoto]] = [:]
            
            for angle in PhotoAngle.allCases {
                let photosForAngle = photos.filter { $0.angle == angle }
                groupedPhotos[angle] = photosForAngle
                AppLogger.debug("[ProgressViewModel.loadPhotos] Found \(photosForAngle.count) photos for angle \(angle)", category: "ProgressViewModel")
            }
            
            AppLogger.debug("[ProgressViewModel.loadPhotos] Updating photosByAngle property", category: "ProgressViewModel")
            photosByAngle = groupedPhotos
            
            AppLogger.info("[ProgressViewModel.loadPhotos] Successfully loaded \(photos.count) photos", category: "ProgressViewModel")
            
            // Load body metrics for each photo
            if !photos.isEmpty {
                AppLogger.debug("[ProgressViewModel.loadPhotos] Loading body metrics for photos", category: "ProgressViewModel")
                await loadPhotoMetrics(for: photos)
            } else {
                AppLogger.debug("[ProgressViewModel.loadPhotos] No photos to load metrics for", category: "ProgressViewModel")
            }
            
            isLoadingPhotos = false
            AppLogger.info("[ProgressViewModel.loadPhotos] Photo loading completed successfully", category: "ProgressViewModel")
            
        } catch {
            AppLogger.error("[ProgressViewModel.loadPhotos] Error: \(error)", category: "ProgressViewModel", error: error)
            AppLogger.error("[ProgressViewModel.loadPhotos] Error type: \(type(of: error))", category: "ProgressViewModel", error: error)
            AppLogger.error("[ProgressViewModel.loadPhotos] Error description: \(error.localizedDescription)", category: "ProgressViewModel", error: error)
            self.error = error
            isLoadingPhotos = false
        }
    }
    
    private func loadPhotoMetrics(for photos: [ProgressPhoto]) async {
        AppLogger.debug("[ProgressViewModel.loadPhotoMetrics] Loading metrics for \(photos.count) photos", category: "ProgressViewModel")
        
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
        AppLogger.info("[ProgressViewModel.loadPhotoMetrics] Loaded metrics for \(metrics.count) photos", category: "ProgressViewModel")
    }
    
    private func addPhoto(angle: PhotoAngle, image: UIImage) async {
        AppLogger.debug("[ProgressViewModel.addPhoto] Adding photo for angle: \(angle)", category: "ProgressViewModel")
        
        do {
            try photoService.save(image: image, angle: angle)
            
            AppLogger.info("[ProgressViewModel.addPhoto] Successfully saved photo", category: "ProgressViewModel")
            
            // Reload photos to update UI
            await loadPhotos()
            
        } catch {
            AppLogger.error("[ProgressViewModel.addPhoto] Error: \(error.localizedDescription)", category: "ProgressViewModel", error: error)
            self.error = error
        }
    }
    
    private func deletePhoto(_ photoID: UUID) async {
        AppLogger.debug("[ProgressViewModel.deletePhoto] Deleting photo: \(photoID)", category: "ProgressViewModel")
        
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
            
            AppLogger.info("[ProgressViewModel.deletePhoto] Successfully deleted photo", category: "ProgressViewModel")
            
        } catch {
            AppLogger.error("[ProgressViewModel.deletePhoto] Error: \(error.localizedDescription)", category: "ProgressViewModel", error: error)
            self.error = error
        }
    }
    
    private func selectForCompare(_ photoID: UUID) {
        AppLogger.debug("[ProgressViewModel.selectForCompare] Selecting photo for comparison: \(photoID)", category: "ProgressViewModel")
        
        let (first, second) = compareSelection
        
        if first == nil {
            compareSelection.0 = photoID
            AppLogger.debug("[ProgressViewModel] First comparison photo selected: \(photoID)", category: "ProgressViewModel")
        } else if second == nil && first != photoID {
            compareSelection.1 = photoID
            AppLogger.debug("[ProgressViewModel] Second comparison photo selected: \(photoID)", category: "ProgressViewModel")
        } else {
            // Reset and start fresh
            compareSelection = (photoID, nil)
            AppLogger.debug("[ProgressViewModel] Comparison reset, first photo selected: \(photoID)", category: "ProgressViewModel")
        }
    }
    
    private func clearComparison() {
        AppLogger.debug("[ProgressViewModel.clearComparison] Clearing photo comparison", category: "ProgressViewModel")
        compareSelection = (nil, nil)
        AppLogger.debug("[ProgressViewModel] Comparison cleared", category: "ProgressViewModel")
    }
    
    private func showImagePicker(for angle: PhotoAngle) {
        AppLogger.debug("[ProgressViewModel.showImagePicker] Showing image picker for angle: \(angle)", category: "ProgressViewModel")
        selectedPhotoAngle = angle
        showImagePicker = true
    }
    
    private func hideImagePicker() {
        AppLogger.debug("[ProgressViewModel.hideImagePicker] Hiding image picker", category: "ProgressViewModel")
        showImagePicker = false
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        AppLogger.debug("[ProgressViewModel.loadInitialData] Loading initial data", category: "ProgressViewModel")
        Task {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        AppLogger.debug("[ProgressViewModel.refreshData] Refreshing all data", category: "ProgressViewModel")
        state = .loading
        
        async let statsLoad: () = loadExerciseTrends()
        async let photosLoad: () = loadPhotos()
        
        _ = await [statsLoad, photosLoad]
        
        // Update state based on whether data is available
        if exerciseTrends.isEmpty && photosByAngle.allSatisfy({ $0.value.isEmpty }) {
            state = .empty
        } else {
            state = .loaded
        }
        AppLogger.info("[ProgressViewModel.refreshData] All data refreshed", category: "ProgressViewModel")
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
    
    /// Edit an existing photo's date and manual weight, then reload.
    private func editPhoto(_ photoID: UUID, _ newDate: Date, _ manualWeight: Double?) async {
        AppLogger.debug("[ProgressViewModel.editPhoto] Editing photo: \(photoID)", category: "ProgressViewModel")
        do {
            // Find the photo entity
            let allPhotos = photosByAngle.values.flatMap { $0 }
            guard let photo = allPhotos.first(where: { $0.id == photoID }) else {
                throw ProgressError.photoNotFound
            }
            // Update properties
            photo.date = newDate
            photo.manualWeight = manualWeight
            // Save to SwiftData
            try modelContext.save()
            AppLogger.info("[ProgressViewModel.editPhoto] Photo updated successfully", category: "ProgressViewModel")
            // Reload data to reflect changes
            await loadPhotos()
        } catch {
            AppLogger.error("[ProgressViewModel.editPhoto] Error: \(error.localizedDescription)", category: "ProgressViewModel", error: error)
            self.error = error
        }
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
    case editPhoto(UUID, Date, Double?)
}

enum ProgressLoadingState {
    case idle
    case loading
    case loaded
    case empty
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