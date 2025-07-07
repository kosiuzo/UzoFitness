import SwiftUI

struct SupersetBadgeView: View {
    let supersetNumber: Int
    let isHead: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundColor(.blue)
            Text("\(supersetNumber)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
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