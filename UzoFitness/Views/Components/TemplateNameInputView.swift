import SwiftUI

struct TemplateNameInputView: View {
    let onSave: (String) -> Void
    @State private var templateName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TextField("Workout Name", text: $templateName)
        Button("Create") {
            if !templateName.isEmpty {
                onSave(templateName)
                dismiss()
            }
        }
        .disabled(templateName.isEmpty)
        Button("Cancel", role: .cancel) {
            dismiss()
        }
    }
} 