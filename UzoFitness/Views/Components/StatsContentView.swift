import SwiftUI

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
} 