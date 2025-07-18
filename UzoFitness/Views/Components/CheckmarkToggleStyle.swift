import SwiftUI

struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                        .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    configuration.label
                }
            }
            .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

extension ToggleStyle where Self == CheckmarkToggleStyle {
    static var checkmark: CheckmarkToggleStyle {
        CheckmarkToggleStyle()
    }
} 