import SwiftUI
import UniformTypeIdentifiers

struct WorkoutTemplateJSONImportView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFilePicker = true
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingSuccessToast = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Import Workout Template")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Select a JSON file containing your workout template")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                if !showingFilePicker {
                    // Manual Import Button
                    Button {
                        showingFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text("Select JSON File")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Import Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        AppLogger.info("[WorkoutTemplateJSONImportView] Cancel button tapped", category: "WorkoutTemplateJSONImportView")
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .overlay(
                // Success Toast
                Group {
                    if showingSuccessToast {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(successMessage)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding()
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showingSuccessToast)
            )
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        AppLogger.info("[WorkoutTemplateJSONImportView.handleFileImport] Starting file import", category: "WorkoutTemplateJSONImportView")
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showError(title: "No File Selected", message: "Please select a JSON file to import.")
                return
            }
            
            AppLogger.info("[WorkoutTemplateJSONImportView] Selected file: \(url.lastPathComponent)", category: "WorkoutTemplateJSONImportView")
            importWorkoutTemplate(from: url)
            
        case .failure(let error):
            AppLogger.error("[WorkoutTemplateJSONImportView.handleFileImport] File picker error", category: "WorkoutTemplateJSONImportView", error: error)
            showError(title: "File Selection Error", message: error.localizedDescription)
        }
    }
    
    private func importWorkoutTemplate(from url: URL) {
        AppLogger.info("[WorkoutTemplateJSONImportView.importWorkoutTemplate] Starting import from: \(url.lastPathComponent)", category: "WorkoutTemplateJSONImportView")
        
        Task {
            do {
                // Start accessing the security-scoped resource
                let accessGranted = url.startAccessingSecurityScopedResource()
                defer {
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                // Read file data
                let data = try Data(contentsOf: url)
                AppLogger.info("[WorkoutTemplateJSONImportView] Read \(data.count) bytes from file", category: "WorkoutTemplateJSONImportView")
                
                // Decode JSON
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: data)
                AppLogger.info("[WorkoutTemplateJSONImportView] Successfully decoded JSON", category: "WorkoutTemplateJSONImportView")
                
                // Validate imported data
                try importDTO.validate()
                AppLogger.info("[WorkoutTemplateJSONImportView] Validation successful", category: "WorkoutTemplateJSONImportView")
                
                // Import into the app
                await MainActor.run {
                    do {
                        _ = try viewModel.importWorkoutTemplate(from: importDTO)
                        AppLogger.info("[WorkoutTemplateJSONImportView] Successfully imported template", category: "WorkoutTemplateJSONImportView")
                        
                        showSuccess(message: "Imported 1 template with \(importDTO.days.count) days")
                        
                        // Dismiss after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                        
                    } catch {
                        AppLogger.error("[WorkoutTemplateJSONImportView] Import error", category: "WorkoutTemplateJSONImportView", error: error)
                        showError(title: "Import Failed", message: error.localizedDescription)
                    }
                }
                
            } catch let decodingError as DecodingError {
                AppLogger.error("[WorkoutTemplateJSONImportView] JSON decoding error", category: "WorkoutTemplateJSONImportView", error: decodingError)
                await MainActor.run {
                    showError(title: "Invalid JSON Format", message: formatDecodingError(decodingError))
                }
                
            } catch let importError as ImportError {
                AppLogger.error("[WorkoutTemplateJSONImportVew] Validation error", category: "WorkoutTemplateJSONImportView", error: importError)
                await MainActor.run {
                    showError(title: "Validation Failed", message: importError.localizedDescription)
                }
                
            } catch {
                AppLogger.error("[WorkoutTemplateJSONImportView] Unexpected error", category: "WorkoutTemplateJSONImportView", error: error)
                await MainActor.run {
                    showError(title: "Import Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
        showingFilePicker = false
    }
    
    private func showSuccess(message: String) {
        successMessage = message
        showingSuccessToast = true
        
        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingSuccessToast = false
        }
    }
    
    private func formatDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _):
            return "Missing required field: '\(key.stringValue)'"
        case .typeMismatch(let type, let context):
            return "Type mismatch for field '\(context.codingPath.last?.stringValue ?? "unknown")'. Expected \(type)."
        case .valueNotFound(let type, let context):
            return "Missing value for field '\(context.codingPath.last?.stringValue ?? "unknown")' of type \(type)."
        case .dataCorrupted(let context):
            return "Invalid data format: \(context.debugDescription)"
        @unknown default:
            return "JSON format error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview
#Preview {
    WorkoutTemplateJSONImportView(viewModel: LibraryViewModel(modelContext: PersistenceController.shared.container.mainContext))
} 