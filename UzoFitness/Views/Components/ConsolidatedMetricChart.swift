import SwiftUI
import Charts

struct ConsolidatedMetricChart: View {
    let title: String
    let selectedMetrics: Set<MetricType>
    let data: [MetricType: [ChartDataPoint]]
    let dateRange: DateRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Metrics Summary Cards
            if !selectedMetrics.isEmpty {
                metricsCardsView
            }
            
            // Consolidated Chart
            if hasData {
                Text("Progress Over Time")
                    .font(.headline)
                    .padding(.horizontal)
                
                consolidatedChartView
            } else {
                emptyChartView
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Metrics Cards
    private var metricsCardsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(Array(selectedMetrics.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { metric in
                MetricCard(
                    metric: metric,
                    value: getLatestValue(for: metric),
                    isEstimated: metric == .totalSessions
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Consolidated Chart
    private var consolidatedChartView: some View {
        Chart {
            ForEach(Array(selectedMetrics), id: \.self) { metric in
                ForEach(data[metric] ?? [], id: \.id) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(metric.displayName, dataPoint.value)
                    )
                    .foregroundStyle(metric.color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(metric.displayName, dataPoint.value)
                    )
                    .foregroundStyle(metric.color)
                    .symbolSize(40)
                }
            }
        }
        .frame(height: 300)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray4))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .foregroundStyle(Color(.label))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray4))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatValue(doubleValue))
                            .foregroundStyle(Color(.label))
                    }
                }
            }
        }
        .chartXScale(domain: dateRange.startDate...dateRange.endDate)
        .chartLegend(position: .bottom, alignment: .center) {
            HStack(spacing: 16) {
                ForEach(Array(selectedMetrics.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { metric in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(metric.color)
                            .frame(width: 8, height: 8)
                        Text(metric.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    private var emptyChartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No data available for selected period")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Properties
    private var hasData: Bool {
        selectedMetrics.contains { metric in
            !(data[metric] ?? []).isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func getLatestValue(for metric: MetricType) -> Double {
        return data[metric]?.last?.value ?? 0.0
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let metric: MetricType
    let value: Double
    let isEstimated: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Metric Icon and Title
            HStack(spacing: 8) {
                Circle()
                    .fill(metric.color)
                    .frame(width: 12, height: 12)
                
                Text(metric.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if isEstimated {
                    Text("~")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Value
            Text(formatDisplayValue())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(metric.color)
                .lineLimit(1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(metric.color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(metric.color.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatDisplayValue() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        // Format large numbers with commas
        if value >= 1000 {
            formatter.maximumFractionDigits = 0
            let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
            return "\(formattedNumber) \(metric.unit)"
        } else {
            formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
            let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
            return "\(formattedNumber) \(metric.unit)"
        }
    }
}

// MARK: - Preview
struct ConsolidatedMetricChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ConsolidatedMetricChart(
                title: "Bench Press",
                selectedMetrics: [.maxWeight, .totalVolume, .totalReps, .totalSessions],
                data: sampleData,
                dateRange: DateRange.sixMonths
            )
            .padding()
        }
        .background(Color(.systemGray6))
    }
    
    static var sampleData: [MetricType: [ChartDataPoint]] {
        let calendar = Calendar.current
        let now = Date()
        
        var data: [MetricType: [ChartDataPoint]] = [:]
        
        // Generate sample data for each metric
        for metric in MetricType.allCases {
            let points: [ChartDataPoint] = (0..<6).compactMap { monthOffset in
                guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { return nil }
                
                let baseValue: Double
                switch metric {
                case .maxWeight:
                    baseValue = 135.0 + Double.random(in: -10...20)
                case .totalVolume:
                    baseValue = 4320.0 + Double.random(in: -500...800)
                case .totalReps:
                    baseValue = 32.0 + Double.random(in: -8...15)
                case .totalSessions:
                    baseValue = 12.0 + Double.random(in: -3...5)
                }
                
                return ChartDataPoint(date: date, value: baseValue)
            }
            
            data[metric] = Array(points.reversed())
        }
        
        return data
    }
} 