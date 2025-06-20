import SwiftUI

struct JSONImportView: View {
    @State private var jsonText: String = """
[
    {
        "name": "Push-ups",
        "category": "strength",
        "instructions": "Start in a plank position with hands shoulder-width apart. Lower your body until your chest nearly touches the floor, then push back up.",
        "mediaAssetID": null
    },
    {
        "name": "Squats",
        "category": "strength", 
        "instructions": "Stand with feet shoulder-width apart. Lower your body as if sitting back into a chair, keeping your chest up and weight on your heels.",
        "mediaAssetID": null
    }
]
"""
    @Environment(\.dismiss) private var dismiss
    
    let importAction: (Data) throws -> Void
    let errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                Text("Import Exercises from JSON")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top)
                
                Text("Paste your JSON exercise data below")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // JSON Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON Data")
                        .font(.headline)
                    
                    TextEditor(text: $jsonText)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Error Message
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Import Button
                Button {
                    print("🔄 [JSONImportView] Import button tapped")
                    performImport()
                } label: {
                    Text("Import Exercises")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(jsonText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(jsonText.isEmpty)
            }
            .padding()
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        print("🔄 [JSONImportView] Cancel button tapped")
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performImport() {
        print("🔄 [JSONImportView.performImport] Starting import process")
        
        guard let jsonData = jsonText.data(using: .utf8) else {
            print("❌ [JSONImportView.performImport] Failed to convert text to data")
            return
        }
        
        do {
            try importAction(jsonData)
            print("✅ [JSONImportView.performImport] Import successful, dismissing view")
            dismiss()
        } catch {
            print("❌ [JSONImportView.performImport] Import failed: \(error.localizedDescription)")
            // Error is handled by the importAction and will show in errorMessage
        }
    }
}

// MARK: - Preview
#Preview {
    JSONImportView(
        importAction: { data in
            print("Preview import action called with \(data.count) bytes")
        },
        errorMessage: nil as String?
    )
} 