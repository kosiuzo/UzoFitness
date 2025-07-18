import SwiftUI
import UzoFitnessCore

struct SupersetBadgeView: View {
    let supersetNumber: Int
    let isHead: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundColor(.red)
            Text("SS\(supersetNumber)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        SupersetBadgeView(supersetNumber: 1, isHead: true)
        SupersetBadgeView(supersetNumber: 2, isHead: false)
        SupersetBadgeView(supersetNumber: 3, isHead: true)
    }
    .padding()
}