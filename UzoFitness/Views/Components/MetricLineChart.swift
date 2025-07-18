import SwiftUI
import Charts
import UzoFitnessCore

struct MetricLineChart: View {
    let title: String
    let unit: String
    let data: [ChartDataPoint]
    let dateRange: DateRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let latestValue = data.last?.value {
                    Text("\(formatValue(latestValue)) \(unit)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                }
            }
            
            // Chart
            if data.isEmpty {
                emptyChartView
            } else {
                chartView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("No data available for selected period")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value(title, dataPoint.value)
            )
            .foregroundStyle(Color.accentColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value(title, dataPoint.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value(title, dataPoint.value)
            )
            .foregroundStyle(Color.accentColor)
            .symbolSize(30)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(formatValue(doubleValue))")
                    }
                }
            }
        }
        .chartXScale(domain: dateRange.startDate...dateRange.endDate)
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// MARK: - Preview

struct MetricLineChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
                         MetricLineChart(
                 title: "Max Weight",
                 unit: "lbs",
                 data: sampleData,
                 dateRange: DateRange.sixMonths
             )
            
                         MetricLineChart(
                 title: "Total Volume",
                 unit: "lbs",
                 data: [],
                 dateRange: DateRange.sixMonths
             )
        }
        .padding()
                                   .background(.regularMaterial)
    }
    
    static var sampleData: [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<12).compactMap { weekOffset in
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { return nil }
            let value = 135.0 + Double.random(in: -10...20)
            return ChartDataPoint(date: date, value: value)
        }.reversed()
    }
} 