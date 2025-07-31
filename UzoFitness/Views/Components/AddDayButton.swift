import SwiftUI

struct AddDayButton: View {
    let onAddDay: () -> Void
    
    var body: some View {
        Button(action: onAddDay) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
                Text("Add Day")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
} 