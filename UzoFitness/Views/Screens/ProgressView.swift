import SwiftUI
import SwiftData
import Charts
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif
import UzoFitnessCore
// Import extracted components

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

