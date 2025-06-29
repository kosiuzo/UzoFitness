import SwiftUI

struct CustomDateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Text("Select a custom date range to filter your progress data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(startDate > endDate)
                }
            }
        }
    }
}

// MARK: - Preview

struct CustomDateRangePickerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomDateRangePickerView(
            startDate: .constant(Date().addingTimeInterval(-30 * 24 * 60 * 60)),
            endDate: .constant(Date()),
            isPresented: .constant(true)
        ) {
            // Handle save
        }
    }
} 