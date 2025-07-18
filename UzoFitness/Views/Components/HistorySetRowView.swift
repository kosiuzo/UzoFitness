import SwiftUI
import UzoFitnessCore

struct HistorySetRowView: View {
    let setNumber: Int
    let completedSet: CompletedSet
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .leading)
            
            Text("\(completedSet.reps)")
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            Text(formatWeight(completedSet.weight))
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(formatVolume(Double(completedSet.reps) * completedSet.weight))
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(completedSet.isCompleted ? Color.clear : Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return (formatter.string(from: NSNumber(value: weight)) ?? "0") + " lbs"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
} 