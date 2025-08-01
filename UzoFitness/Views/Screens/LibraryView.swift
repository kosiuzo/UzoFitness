import SwiftUI
import SwiftData
// Import extracted components

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        LibraryViewContent(modelContext: modelContext)
    }
}

struct LibraryViewContent: View {
    let modelContext: ModelContext
    @StateObject private var viewModel: LibraryViewModel
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self._viewModel = StateObject(wrappedValue: LibraryViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Picker
                Picker("Library Section", selection: $viewModel.selectedSegment) {
                    ForEach([LibrarySegment.workouts, LibrarySegment.exercises], id: \.self) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Content Views
                Group {
                    switch viewModel.selectedSegment {
                    case .workouts:
                        WorkoutsTabView(viewModel: viewModel)
                    case .exercises:
                        ExercisesTabView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                AppLogger.info("[LibraryView] Task started - loading data", category: "LibraryView")
                viewModel.handleIntent(.loadData)
            }
        }
    }
}
