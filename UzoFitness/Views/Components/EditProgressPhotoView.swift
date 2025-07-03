import SwiftUI

/// A view to edit the date and manual weight of a `ProgressPhoto`.
///
/// This view is presented as a sheet and provides a clean, native-feeling
/// form for making adjustments. Changes are saved via the `ProgressViewModel`.
struct EditProgressPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgressViewModel
    
    let photo: ProgressPhoto
    
    @State private var date: Date
    @State private var weight: String
    
    init(photo: ProgressPhoto, viewModel: ProgressViewModel) {
        self.photo = photo
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._date = State(initialValue: photo.date)
        
        // Initialize weight string from the photo's manual weight, if it exists.
        if let manualWeight = photo.manualWeight {
            self._weight = State(initialValue: String(format: "%.1f", manualWeight))
        } else {
            self._weight = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("Optional", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Photo Details")
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveChanges)
                }
            }
        }
    }

    private func saveChanges() {
        // Convert the string back to an optional Double.
        // If the text is empty or invalid, it correctly becomes nil.
        let newWeight = Double(weight.trimmingCharacters(in: .whitespaces))
        
        Task {
            await viewModel.handleIntent(.editPhoto(photo.id, date, newWeight))
        }
        dismiss()
    }
} 