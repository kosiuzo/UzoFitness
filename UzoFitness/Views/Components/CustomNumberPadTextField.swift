import SwiftUI
import UzoFitnessCore

/// A minimalist, iOS-native number pad text field with a custom "Done" button above the keyboard.
/// - Parameters:
///   - text: The bound string value.
///   - placeholder: The placeholder text.
///   - keyboardType: The keyboard type (default: .numberPad).
///   - onDone: Called when the Done button is tapped.
struct CustomNumberPadTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .numberPad
    var onDone: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.delegate = context.coordinator
        textField.borderStyle = .roundedRect
        textField.inputAccessoryView = context.coordinator.createAccessoryView()
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.inputAccessoryView = context.coordinator.createAccessoryView()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomNumberPadTextField
        private weak var textField: UITextField?

        init(_ parent: CustomNumberPadTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            self.textField = textField
        }

        func createAccessoryView() -> UIView {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.barStyle = .default
            toolbar.isTranslucent = true
            toolbar.backgroundColor = .clear

            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
            done.tintColor = UIColor.systemBlue
            toolbar.items = [flex, done]
            return toolbar
        }

        @objc func doneTapped() {
            textField?.resignFirstResponder()
            parent.onDone?()
        }
    }
}

// MARK: - SwiftUI Preview
#if DEBUG
struct CustomNumberPadTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            CustomNumberPadTextField(text: .constant(""), placeholder: "Reps")
            CustomNumberPadTextField(text: .constant(""), placeholder: "Weight", keyboardType: .decimalPad)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif 