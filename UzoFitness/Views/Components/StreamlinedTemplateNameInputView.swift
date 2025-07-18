import SwiftUI

struct StreamlinedTemplateNameInputView: View {
    let onSave: (String) -> Void
    @State private var templateName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TextField("Workout Name", text: $templateName)
            .autocapitalization(.words)
        Button("Create & Setup") {
            let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                onSave(trimmedName)
                dismiss()
            }
        }
        .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        Button("Cancel", role: .cancel) {
            dismiss()
        }
    }
} 