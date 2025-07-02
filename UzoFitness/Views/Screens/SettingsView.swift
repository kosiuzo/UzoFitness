import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var appSettingsStore = AppSettingsStore()
    @State private var showingRestoreConfirmation = false
    @State private var showingErrorAlert = false
    
    init() {
        AppLogger.info("[SettingsView.init] Initializing settings view", category: "SettingsView")
        
        // Create services step by step with logging
        AppLogger.info("[SettingsView.init] Creating HealthKitManager...", category: "SettingsView")
        let healthKitManager = HealthKitManager()
        
        AppLogger.info("[SettingsView.init] Creating AppSettingsStore...", category: "SettingsView")
        let appSettings = AppSettingsStore()
        
        // Try to safely get the model context
        AppLogger.info("[SettingsView.init] Attempting to get PersistenceController...", category: "SettingsView")
        let persistenceController: PersistenceController
        let modelContext: ModelContext
        let dataPersistenceService: DefaultDataPersistenceService
        let photoService: PhotoService
        
        // Get the persistence controller
        AppLogger.info("[SettingsView.init] Getting shared PersistenceController...", category: "SettingsView")
        persistenceController = PersistenceController.shared
        modelContext = persistenceController.container.mainContext
        AppLogger.info("[SettingsView.init] Successfully got model context", category: "SettingsView")
        
        dataPersistenceService = DefaultDataPersistenceService(modelContext: modelContext)
        photoService = PhotoService(dataPersistenceService: dataPersistenceService)
        
        AppLogger.info("[SettingsView.init] Creating SettingsViewModel...", category: "SettingsView")
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            healthKitManager: healthKitManager,
            photoService: photoService,
            appSettingsStore: appSettings,
            modelContext: modelContext
        ))
        
        AppLogger.info("[SettingsView.init] Settings view initialization completed successfully", category: "SettingsView")
    }
    
    var body: some View {
        NavigationView {
            List {
                permissionsSection
                dataSyncSection
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .task {
                AppLogger.info("[SettingsView] Task started - loading initial state", category: "SettingsView")
                viewModel.handleIntent(.loadInitialState)
            }
            .alert("Restore Data", isPresented: $showingRestoreConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore", role: .destructive) {
                    AppLogger.info("[SettingsView] User confirmed restore", category: "SettingsView")
                    viewModel.handleIntent(.performRestore)
                }
            } message: {
                Text("This will replace your current data with the backup. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") {
                    viewModel.handleIntent(.clearError)
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .onChange(of: viewModel.error != nil) { _, hasError in
                showingErrorAlert = hasError
            }
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        Section {
            healthKitToggle
            photoLibraryToggle
        } header: {
            Text("Permissions")
        } footer: {
            Text("Grant permissions to sync fitness data and save progress photos.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var healthKitToggle: some View {
        HStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit Sync")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Sync body measurements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.state == .loading {
                SwiftUI.ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: Binding(
                    get: { viewModel.isHealthKitEnabled },
                    set: { newValue in
                        if newValue != viewModel.isHealthKitEnabled {
                            // Haptic feedback on toggle
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            AppLogger.info("[SettingsView] HealthKit toggle changed to: \(newValue)", category: "SettingsView")
                            if newValue {
                                viewModel.handleIntent(.requestHealthKitAccess)
                            } else {
                                // For HealthKit, we can't really "disable" it once granted,
                                // but we can update our internal state
                                viewModel.isHealthKitEnabled = false
                                AppLogger.debug("[SettingsView] HealthKit disabled by user", category: "SettingsView")
                            }
                        }
                    }
                ))
                .disabled(viewModel.state == .loading)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var photoLibraryToggle: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Photo Library Access")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Save progress photos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.state == .loading {
                SwiftUI.ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: Binding(
                    get: { viewModel.isPhotoAccessGranted },
                    set: { newValue in
                        if newValue != viewModel.isPhotoAccessGranted {
                            // Haptic feedback on toggle
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            AppLogger.info("[SettingsView] Photo access toggle changed to: \(newValue)", category: "SettingsView")
                            if newValue {
                                viewModel.handleIntent(.togglePhotoAccess)
                            } else {
                                // For photo access, we can't revoke system permissions,
                                // but we can update our internal state
                                viewModel.isPhotoAccessGranted = false
                                AppLogger.debug("[SettingsView] Photo access disabled by user", category: "SettingsView")
                            }
                        }
                    }
                ))
                .disabled(viewModel.state == .loading)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Data Sync Section
    
    private var dataSyncSection: some View {
        Section {
            syncToCloudButton
            lastBackupTimestamp
            restoreFromCloudButton
        } header: {
            Text("Data Sync")
        } footer: {
            Text(viewModel.backupStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var syncToCloudButton: some View {
        Button(action: {
            AppLogger.info("[SettingsView] Sync to iCloud button tapped", category: "SettingsView")
            viewModel.handleIntent(.performBackup)
        }) {
            HStack(spacing: 16) {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync to iCloud Backup")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if viewModel.isLoadingBackup {
                        SwiftUI.ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 0.5)
                    }
                }
                
                Spacer()
                
                if viewModel.isLoadingBackup {
                    SwiftUI.ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(viewModel.isLoadingBackup || viewModel.isLoadingRestore || !viewModel.canPerformBackup)
    }
    
    private var lastBackupTimestamp: some View {
        HStack {
            Text("Last backup:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(viewModel.formattedLastBackupDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
    
    private var restoreFromCloudButton: some View {
        Button(action: {
            AppLogger.info("[SettingsView] Restore from iCloud button tapped", category: "SettingsView")
            showingRestoreConfirmation = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore from iCloud Backup")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if viewModel.isLoadingRestore {
                        SwiftUI.ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 0.5)
                    }
                }
                
                Spacer()
                
                if viewModel.isLoadingRestore {
                    SwiftUI.ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(viewModel.isLoadingBackup || viewModel.isLoadingRestore)
    }
}

// MARK: - Supporting Views

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .modelContainer(PersistenceController.preview.container)
    }
}
