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
                    ForEach(LibrarySegment.allCases, id: \.self) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Content Views
                Group {
                    switch viewModel.selectedSegment {
                    case .exercises:
                        ExercisesTabView(viewModel: viewModel)
                    case .workouts:
                        WorkoutsTabView(viewModel: viewModel)
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
            ExerciseEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingJSONImport) {
            JSONImportView(
                importAction: { jsonData in
                    try viewModel.importExercises(from: jsonData)
                },
                errorMessage: viewModel.importErrorMessage
            )
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
    
    var body: some View {
        List {
            // Workout Templates Section
            Section("Workout Templates") {
                if viewModel.workoutTemplates.isEmpty {
                    Text("No workout templates")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
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
                }
                
                Button("Create Template") {
                    showingTemplateCreator = true
                }
                .foregroundStyle(.blue)
            }
            
            // Workout Plans Section
            Section("Workout Plans") {
                if viewModel.workoutPlans.isEmpty {
                    Text("No workout plans")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.workoutPlans) { plan in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.customName)
                                    .font(.headline)
                                if let template = plan.template {
                                    Text("Based on: \(template.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
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
                
                Button("Create Plan") {
                    showingPlanCreator = true
                }
                .foregroundStyle(.blue)
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
    
    init(template: WorkoutTemplate, viewModel: LibraryViewModel) {
        self.template = template
        self.viewModel = viewModel
    }
    
    private var orderedWeekdays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
    
    var body: some View {
        List {
            // Template Info Section
            Section("Template Info") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.headline)
                    
                    if !template.summary.isEmpty {
                        Text(template.summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
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
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
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
                
                // Rest day toggle
                Toggle("Rest Day", isOn: Binding(
                    get: { dayTemplate?.isRest ?? false },
                    set: { _ in toggleRestDay() }
                ))
                .labelsHidden()
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
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
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
}

// MARK: - DayTemplate Superset Extension
extension DayTemplate {
    func getSupersetNumber(for supersetID: UUID) -> Int? {
        // Get all unique superset IDs in this day template, sorted consistently
        let allSupersetIDs = Set(exerciseTemplates.compactMap { $0.supersetID })
        let sortedSupersetIDs = allSupersetIDs.sorted { $0.uuidString < $1.uuidString }
        
        // Find the index (1-based) of this superset ID
        if let index = sortedSupersetIDs.firstIndex(of: supersetID) {
            return index + 1
        }
        return nil
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
                        
                        if let supersetID = supersetID {
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

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .modelContainer(PersistenceController.preview.container)
    }
}
