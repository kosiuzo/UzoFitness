import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: LibraryViewModel
    
    init() {
        // We'll inject the modelContext in the body
        let context = ModelContext(PersistenceController.shared.container)
        self._viewModel = StateObject(wrappedValue: LibraryViewModel(modelContext: context))
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
            .navigationTitle("Library")
            .task {
                print("🔄 [LibraryView] Task started - loading data")
                viewModel.handleIntent(.loadData)
            }
        }
    }
}

// MARK: - ExercisesTabView
struct ExercisesTabView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingExerciseEditor = false
    @State private var showingJSONImport = false
    @State private var selectedExerciseForEdit: Exercise?
    
    var body: some View {
        VStack(spacing: 0) {
            // List of exercises
            if viewModel.exercises.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises to get started")
                    )
                    
                    Button("Import from JSON") {
                        showingJSONImport = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(viewModel.exercises) { exercise in
                        ExerciseRowView(exercise: exercise)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExerciseForEdit = exercise
                                showingExerciseEditor = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    viewModel.deleteExercise(exercise)
                                }
                                
                                Button("Edit") {
                                    selectedExerciseForEdit = exercise
                                    showingExerciseEditor = true
                                }
                                .tint(.blue)
                            }
                    }
                    .onDelete(perform: deleteExercises)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingExerciseEditor = true
                    } label: {
                        Label("Create Exercise", systemImage: "plus")
                    }
                    
                    Button {
                        showingJSONImport = true
                    } label: {
                        Label("Import from JSON", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingExerciseEditor) {
            ExerciseEditorView(exercise: selectedExerciseForEdit, viewModel: viewModel)
        }
        .sheet(isPresented: $showingJSONImport) {
            JSONImportView(
                importAction: { jsonData in
                    try viewModel.importExercises(from: jsonData)
                },
                errorMessage: viewModel.importErrorMessage
            )
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func deleteExercises(offsets: IndexSet) {
        for index in offsets {
            let exercise = viewModel.exercises[index]
            viewModel.deleteExercise(exercise)
        }
    }
}

// MARK: - WorkoutsTabView
struct WorkoutsTabView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingTemplateCreator = false
    @State private var showingPlanCreator = false
    @State private var showingJSONImport = false


    
    var body: some View {
        VStack(spacing: 0) {
            // List of workouts
            if viewModel.workoutTemplates.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Add workouts to get started")
                    )
                    
                    Button("Import from JSON") {
                        showingJSONImport = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    // Workout Templates Section
                    Section("My Workouts") {
                        ForEach(viewModel.workoutTemplates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template, viewModel: viewModel)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text(template.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Button("Add Workout") {
                            showingTemplateCreator = true
                        }
                        .foregroundStyle(.blue)
                    }
                    
                    // Workout Plans Section
                    Section("My Schedule") {
                        if viewModel.workoutPlans.isEmpty {
                            Text("No schedules")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(viewModel.workoutPlans) { plan in
                                WorkoutPlanRowView(plan: plan, viewModel: viewModel)
                            }
                        }
                        
                        Button("Schedule Workout") {
                            showingPlanCreator = true
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingTemplateCreator = true
                    } label: {
                        Label("Create Template", systemImage: "plus")
                    }
                    
                    Button {
                        showingJSONImport = true
                    } label: {
                        Label("Import Template from JSON", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .alert("Create Template", isPresented: $showingTemplateCreator) {
            TemplateNameInputView { name in
                viewModel.createWorkoutTemplate(name: name)
            }
        }
        .actionSheet(isPresented: $showingPlanCreator) {
            ActionSheet(
                title: Text("Create Plan From Template"),
                buttons: viewModel.workoutTemplates.map { template in
                .default(Text(template.name)) {
                    viewModel.createPlan(from: template)
                }
            } + [.cancel()]
        )
    }
    .sheet(isPresented: $showingJSONImport) {
        WorkoutTemplateJSONImportView(viewModel: viewModel)
    }
    .alert("Error", isPresented: .constant(viewModel.error != nil)) {
        Button("OK") {
            viewModel.error = nil
        }
    } message: {
        if let error = viewModel.error {
            Text(error.localizedDescription)
        }
    }

}
}

// MARK: - Supporting Views
struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "dumbbell")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TemplateNameInputView: View {
    let onSave: (String) -> Void
    @State private var templateName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TextField("Template Name", text: $templateName)
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

// MARK: - ExerciseEditorView (Create/Edit Exercise)
struct ExerciseEditorView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise? // nil for create mode
    
    @State private var name: String = ""
    @State private var category: ExerciseCategory = .strength
    @State private var instructions: String = ""
    
    init(exercise: Exercise? = nil, viewModel: LibraryViewModel) {
        self.exercise = exercise
        self.viewModel = viewModel
        self._name = State(initialValue: exercise?.name ?? "")
        self._category = State(initialValue: exercise?.category ?? .strength)
        self._instructions = State(initialValue: exercise?.instructions ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                        .autocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
                
                if exercise != nil {
                    Section {
                        Button("Delete Exercise", role: .destructive) {
                            if let exercise = exercise {
                                viewModel.deleteExercise(exercise)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            if let existingExercise = exercise {
                // Edit mode
                try viewModel.updateExercise(existingExercise, name: trimmedName, category: category, instructions: instructions)
            } else {
                // Create mode
                try viewModel.createExercise(name: trimmedName, category: category, instructions: instructions)
            }
        } catch {
            print("❌ [ExerciseEditorView] Error: \(error.localizedDescription)")
            viewModel.error = error
        }
    }
}



struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @ObservedObject var viewModel: LibraryViewModel
    
    @State private var name: String
    @State private var summary: String
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    
    init(template: WorkoutTemplate, viewModel: LibraryViewModel) {
        self.template = template
        self.viewModel = viewModel
        self._name = State(initialValue: template.name)
        self._summary = State(initialValue: template.summary)
    }
    
    private var orderedWeekdays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
    
    var body: some View {
        List {
            // Template Info Section
            Section("Template Info") {
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        TextField("Template Name", text: $name)
                            .font(.headline)
                            .autocapitalization(.words)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Summary", text: $summary, axis: .vertical)
                            .font(.body)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(template.name)
                            .font(.headline)
                        
                        if !template.summary.isEmpty {
                            Text(template.summary)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Created: \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            
            // Days Section
            Section("Weekly Schedule") {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    DayRowView(
                        weekday: weekday,
                        dayTemplate: template.dayTemplateFor(weekday),
                        viewModel: viewModel
                    )
                }
            }
            
            // Delete Template Section
            Section {
                Button("Delete Template", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isEditing ? "Edit Template" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            // Reset values
                            name = template.name
                            summary = template.summary
                            isEditing = false
                        }
                        
                        Button("Save") {
                            saveTemplate()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteTemplate(template)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this workout template? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func saveTemplate() {
        print("🔄 [TemplateDetailView.saveTemplate] Saving template changes")
        
        do {
            try viewModel.updateTemplate(
                template,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            print("✅ [TemplateDetailView.saveTemplate] Successfully saved template")
            isEditing = false
        } catch {
            print("❌ [TemplateDetailView.saveTemplate] Error: \(error.localizedDescription)")
            viewModel.error = error
        }
    }
}

// MARK: - DayRowView
struct DayRowView: View {
    let weekday: Weekday
    let dayTemplate: DayTemplate?
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayName)
                        .font(.headline)
                    
                    if let dayTemplate = dayTemplate {
                        if dayTemplate.isRest {
                            Text("Rest Day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(dayTemplate.exerciseTemplates.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                // Rest/Workout capsule button
                RestWorkoutCapsuleButton(
                    isRest: dayTemplate?.isRest ?? false,
                    onToggle: toggleRestDay
                )
            }
        }
    }
    
    private var dayName: String {
        weekday.fullName
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let dayTemplate = dayTemplate {
            DayDetailView(dayTemplate: dayTemplate, viewModel: viewModel)
        } else {
            Text("Day not configured")
                .foregroundStyle(.secondary)
        }
    }
    
    private func toggleRestDay() {
        if let dayTemplate = dayTemplate {
            viewModel.toggleRestDay(for: dayTemplate)
        }
    }
}

// MARK: - RestWorkoutCapsuleButton
struct RestWorkoutCapsuleButton: View {
    let isRest: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 0) {
                // Rest option
                Text("Rest")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isRest ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRest ? .blue : .clear)
                    .clipShape(Capsule())
                
                // Workout option
                Text("Workout")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(!isRest ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!isRest ? .blue : .clear)
                    .clipShape(Capsule())
            }
            .background(.quaternary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DayDetailView
struct DayDetailView: View {
    let dayTemplate: DayTemplate
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingExercisePicker = false
    
    var body: some View {
        List {
            if dayTemplate.isRest {
                Section {
                    HStack {
                        Image(systemName: "bed.double")
                            .foregroundStyle(.blue)
                        Text("This is a rest day")
                            .font(.body)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else {
                if dayTemplate.exerciseTemplates.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            
                            Text("No exercises added")
                                .font(.headline)
                            
                            Text("Tap 'Add Exercise' to get started")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    Section("Exercises") {
                        ForEach(dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })) { exerciseTemplate in
                            NavigationLink(destination: ExerciseTemplateEditorView(exerciseTemplate: exerciseTemplate, viewModel: viewModel)) {
                                ExerciseTemplateRowView(exerciseTemplate: exerciseTemplate)
                            }
                        }
                        .onMove(perform: moveExercises)
                        .onDelete(perform: deleteExercises)
                    }
                }
            }
            
            // Notes section
            if !dayTemplate.notes.isEmpty {
                Section("Notes") {
                    Text(dayTemplate.notes)
                        .font(.body)
                }
            }
        }
        .navigationTitle(dayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !dayTemplate.isRest {
                    HStack {
                        EditButton()
                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(viewModel: viewModel) { selectedExercises in
                viewModel.addExercises(selectedExercises, to: dayTemplate)
            }
        }
    }
    
    private var dayName: String {
        dayTemplate.weekday.fullName
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        viewModel.reorderExerciseTemplates(in: dayTemplate, from: source, to: destination)
    }
    
    private func deleteExercises(offsets: IndexSet) {
        print("🔄 [DayDetailView.deleteExercises] Deleting exercises at offsets: \(offsets)")
        
        let sortedExercises = dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })
        for index in offsets {
            let exerciseTemplate = sortedExercises[index]
            viewModel.deleteExerciseTemplate(exerciseTemplate)
        }
    }
}


// MARK: - ExerciseTemplateRowView
struct ExerciseTemplateRowView: View {
    let exerciseTemplate: ExerciseTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(exerciseTemplate.exercise.name)
                    .font(.headline)
                
                Spacer()
                
                if let supersetID = exerciseTemplate.supersetID,
                   let dayTemplate = exerciseTemplate.dayTemplate,
                   let supersetNumber = dayTemplate.getSupersetNumber(for: supersetID) {
                    Text("SS\(supersetNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 16) {
                Text("\(exerciseTemplate.setCount) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(exerciseTemplate.reps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let weight = exerciseTemplate.weight {
                    Text("\(weight, specifier: "%.1f") lbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ExercisePickerView (Multi-select)
struct ExercisePickerView: View {
    let onSelection: ([Exercise]) -> Void
    @ObservedObject var viewModel: LibraryViewModel
    @State private var selectedExercises: Set<Exercise> = []
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: LibraryViewModel, onSelection: @escaping ([Exercise]) -> Void) {
        self.viewModel = viewModel
        self.onSelection = onSelection
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.exercises) { exercise in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text(exercise.category.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedExercises.contains(exercise) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedExercises.contains(exercise) {
                        selectedExercises.remove(exercise)
                    } else {
                        selectedExercises.insert(exercise)
                    }
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedExercises.count))") {
                        onSelection(Array(selectedExercises))
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }
}

// MARK: - ExerciseTemplateEditorView
struct ExerciseTemplateEditorView: View {
    let exerciseTemplate: ExerciseTemplate
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var setCount: Int
    @State private var reps: Int
    @State private var weight: String
    @State private var restDuration: Double = 60 // Default 60 seconds
    @State private var supersetID: UUID?
    @State private var showingSuperset = false
    
    init(exerciseTemplate: ExerciseTemplate, viewModel: LibraryViewModel) {
        self.exerciseTemplate = exerciseTemplate
        self.viewModel = viewModel
        self._setCount = State(initialValue: exerciseTemplate.setCount)
        self._reps = State(initialValue: exerciseTemplate.reps)
        self._weight = State(initialValue: exerciseTemplate.weight?.formatted() ?? "")
        self._supersetID = State(initialValue: exerciseTemplate.supersetID)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Exercise Info Section
                Section("Exercise") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exerciseTemplate.exercise.name)
                                .font(.headline)
                            
                            Text(exerciseTemplate.exercise.category.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // Parameters Section
                Section("Parameters") {
                    // Sets
                    HStack {
                        Text("Sets")
                        Spacer()
                        Stepper(value: $setCount, in: 1...20) {
                            Text("\(setCount)")
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Reps
                    HStack {
                        Text("Reps")
                        Spacer()
                        Stepper(value: $reps, in: 1...100) {
                            Text("\(reps)")
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Weight
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("Optional", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    // Rest Duration
                    HStack {
                        Text("Rest")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatRestDuration(restDuration))
                                .fontWeight(.medium)
                            Slider(value: $restDuration, in: 30...300, step: 15)
                                .frame(width: 120)
                        }
                    }
                }
                
                // Superset Section
                Section("Superset") {
                    HStack {
                        Text("Superset")
                        Spacer()
                        
                        if supersetID != nil {
                            Button("Remove") {
                                self.supersetID = nil
                            }
                            .foregroundStyle(.red)
                        } else {
                            Button("Add to Superset") {
                                showingSuperset = true
                            }
                        }
                    }
                    
                    if supersetID != nil {
                        Text("This exercise is part of a superset")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Instructions Section (if available)
                if !exerciseTemplate.exercise.instructions.isEmpty {
                    Section("Instructions") {
                        Text(exerciseTemplate.exercise.instructions)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingSuperset) {
                SupersetPickerView(exerciseTemplate: exerciseTemplate) { selectedSupersetID in
                    self.supersetID = selectedSupersetID
                }
            }
        }
    }
    
    private func formatRestDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(Int(seconds))s"
        }
    }
    
    private func saveChanges() {
        let weightValue = weight.isEmpty ? nil : Double(weight)
        
        viewModel.updateExerciseTemplate(
            exerciseTemplate,
            setCount: setCount,
            reps: reps,
            weight: weightValue,
            rest: restDuration,
            supersetID: supersetID
        )
        
        print("✅ [ExerciseTemplateEditorView] Saved changes for \(exerciseTemplate.exercise.name)")
    }
}

// MARK: - SupersetPickerView
struct SupersetPickerView: View {
    let exerciseTemplate: ExerciseTemplate
    let onSelection: (UUID?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(exerciseTemplate: ExerciseTemplate, onSelection: @escaping (UUID?) -> Void) {
        self.exerciseTemplate = exerciseTemplate
        self.onSelection = onSelection
    }
    
    private var existingSupersets: [UUID] {
        guard let dayTemplate = exerciseTemplate.dayTemplate else { return [] }
        let supersetIDs = dayTemplate.exerciseTemplates.compactMap { $0.supersetID }
        return Array(Set(supersetIDs)) // Remove duplicates
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Actions") {
                    Button("Create New Superset") {
                        onSelection(UUID())
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                    
                    Button("Remove from Superset") {
                        onSelection(nil)
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
                
                if !existingSupersets.isEmpty {
                    Section("Existing Supersets") {
                        ForEach(existingSupersets, id: \.self) { supersetID in
                            SupersetRowView(
                                supersetID: supersetID,
                                exerciseTemplate: exerciseTemplate
                            ) {
                                onSelection(supersetID)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Superset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - SupersetRowView
struct SupersetRowView: View {
    let supersetID: UUID
    let exerciseTemplate: ExerciseTemplate
    let onTap: () -> Void
    
    private var exercisesInSuperset: [ExerciseTemplate] {
        guard let dayTemplate = exerciseTemplate.dayTemplate else { return [] }
        return dayTemplate.exerciseTemplates.filter { $0.supersetID == supersetID }
    }
    
    private var supersetNumber: Int? {
        guard let dayTemplate = exerciseTemplate.dayTemplate else { return nil }
        return dayTemplate.getSupersetNumber(for: supersetID)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let number = supersetNumber {
                        Text("Superset \(number)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Superset")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Text("\(exercisesInSuperset.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(exercisesInSuperset.prefix(3), id: \.id) { template in
                        HStack {
                            Text("• \(template.exercise.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    
                    if exercisesInSuperset.count > 3 {
                        Text("... and \(exercisesInSuperset.count - 3) more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WorkoutPlanRowView
struct WorkoutPlanRowView: View {
    let plan: WorkoutPlan
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: WorkoutPlanEditorView(plan: plan, viewModel: viewModel)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.customName)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        if let template = plan.template {
                            Text("Based on: \(template.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(plan.durationWeeks) weeks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if plan.isActive {
                        Text("ACTIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WorkoutPlanEditorView
struct WorkoutPlanEditorView: View {
    let plan: WorkoutPlan
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var customName: String
    @State private var durationWeeks: Int
    @State private var isActive: Bool
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    
    init(plan: WorkoutPlan, viewModel: LibraryViewModel) {
        self.plan = plan
        self.viewModel = viewModel
        self._customName = State(initialValue: plan.customName)
        self._durationWeeks = State(initialValue: plan.durationWeeks)
        self._isActive = State(initialValue: plan.isActive)
    }
    
    var body: some View {
        List {
            // Plan Info Section
            Section("Plan Details") {
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        TextField("Plan Name", text: $customName)
                            .font(.headline)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Text("Duration (weeks)")
                                .font(.body)
                            Spacer()
                            Stepper(value: $durationWeeks, in: 1...52) {
                                Text("\(durationWeeks)")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Toggle("Active Plan", isOn: $isActive)
                            .font(.body)
                    } else {
                        Text(plan.customName)
                            .font(.headline)
                        
                        HStack {
                            Text("Duration:")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("\(plan.durationWeeks) weeks")
                                .font(.body)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Status:")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(plan.isActive ? "Active" : "Inactive")
                                .font(.body)
                                .fontWeight(plan.isActive ? .semibold : .regular)
                                .foregroundStyle(plan.isActive ? .blue : .primary)
                            Spacer()
                        }
                    }
                    
                    Text("Created: \(plan.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            
            // Template Info Section
            if let template = plan.template {
                Section("Based on Template") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.headline)
                        
                        if !template.summary.isEmpty {
                            Text(template.summary)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Template created: \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Delete Plan Section
            Section {
                Button("Delete Plan", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isEditing ? "Edit Plan" : plan.customName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            // Reset values
                            customName = plan.customName
                            durationWeeks = plan.durationWeeks
                            isActive = plan.isActive
                            isEditing = false
                        }
                        
                        Button("Save") {
                            savePlan()
                        }
                        .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .alert("Delete Plan", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deletePlan()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this workout plan? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func savePlan() {
        print("🔄 [WorkoutPlanEditorView.savePlan] Saving plan changes")
        
        do {
            try viewModel.updateWorkoutPlan(
                plan,
                customName: customName.trimmingCharacters(in: .whitespacesAndNewlines),
                durationWeeks: durationWeeks,
                isActive: isActive
            )
            print("✅ [WorkoutPlanEditorView.savePlan] Successfully saved plan")
            isEditing = false
        } catch {
            print("❌ [WorkoutPlanEditorView.savePlan] Error: \(error.localizedDescription)")
            viewModel.error = error
        }
    }
    
    private func deletePlan() {
        print("🔄 [WorkoutPlanEditorView.deletePlan] Deleting plan")
        
        do {
            try viewModel.deleteWorkoutPlan(plan)
            print("✅ [WorkoutPlanEditorView.deletePlan] Successfully deleted plan")
            dismiss()
        } catch {
            print("❌ [WorkoutPlanEditorView.deletePlan] Error: \(error.localizedDescription)")
            viewModel.error = error
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .modelContainer(PersistenceController.preview.container)
    }
}
