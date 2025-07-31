import SwiftUI
import SwiftData

struct WorkoutTemplateEditorView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    // Template being edited (nil for new template)
    let template: WorkoutTemplate?
    
    // Form state
    @State private var workoutName: String = ""
    @State private var description: String = ""
    @State private var dayTemplates: [DayTemplate] = []
    @State private var showingExercisePicker = false
    @State private var selectedDayForExercisePicker: DayTemplate?
    @State private var showingRestDayConfirmation = false
    @State private var dayForRestConfirmation: DayTemplate?
    @State private var showingExerciseEditor = false
    @State private var exerciseTemplateToEdit: ExerciseTemplate?
    
    init(template: WorkoutTemplate? = nil, viewModel: LibraryViewModel) {
        self.template = template
        self.viewModel = viewModel
        
        // Initialize form state
        if let template = template {
            self._workoutName = State(initialValue: template.name)
            self._description = State(initialValue: template.summary)
            self._dayTemplates = State(initialValue: template.dayTemplates.sorted { $0.weekday.rawValue < $1.weekday.rawValue })
        } else {
            // Create default day templates for new template
            let defaultDays = Weekday.allCases.map { weekday in
                DayTemplate(
                    weekday: weekday,
                    isRest: false,
                    notes: "",
                    workoutTemplate: nil
                )
            }
            self._dayTemplates = State(initialValue: defaultDays)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    WorkoutHeaderView(
                        workoutName: $workoutName,
                        description: $description
                    )
                    
                    daysSection
                    
                    AddDayButton(onAddDay: addNewDay)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGray6))
            .onChange(of: workoutName) { _, _ in
                if template != nil { autoSaveTemplate() }
            }
            .onChange(of: description) { _, _ in
                if template != nil { autoSaveTemplate() }
            }
            .toolbar {
                if template == nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { saveTemplate() }
                            .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            if let selectedDay = selectedDayForExercisePicker {
                ExercisePickerView(viewModel: viewModel) { selectedExercises in
                    addExercisesToDay(selectedExercises, to: selectedDay)
                }
            }
        }
        .sheet(isPresented: $showingExerciseEditor) {
            if let exerciseTemplate = exerciseTemplateToEdit {
                ExerciseTemplateEditorView(exerciseTemplate: exerciseTemplate, viewModel: viewModel)
            }
        }
        .alert("Mark as Rest Day?", isPresented: $showingRestDayConfirmation) {
            Button("Continue") {
                if let day = dayForRestConfirmation {
                    confirmRestDayToggle(for: day)
                }
            }
            Button("Cancel", role: .cancel) {
                if let day = dayForRestConfirmation {
                    day.isRest.toggle()
                }
            }
        } message: {
            Text("This will hide all exercises for this day. You can toggle again to bring them back.")
        }
    }
    
    // MARK: - Days Section
    private var daysSection: some View {
        VStack(spacing: 16) {
            ForEach(dayTemplates) { dayTemplate in
                DayTemplateView(
                    dayTemplate: dayTemplate,
                    onRestDayToggle: { toggleRestDay(for: dayTemplate) },
                    onAddExercise: { showExercisePicker(for: dayTemplate) },
                    onEditExercise: { exerciseTemplate in
                        exerciseTemplateToEdit = exerciseTemplate
                        showingExerciseEditor = true
                    },
                    onDeleteExercise: { exerciseTemplate in
                        deleteExerciseTemplate(exerciseTemplate)
                    },
                    onReorderExercises: { source, destination in
                        reorderExerciseTemplates(in: dayTemplate, from: source, to: destination)
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleRestDay(for dayTemplate: DayTemplate) {
        dayTemplate.isRest.toggle()
        
        if dayTemplate.isRest && !dayTemplate.exerciseTemplates.isEmpty {
            dayForRestConfirmation = dayTemplate
            showingRestDayConfirmation = true
        }
        
        if template != nil { autoSaveTemplate() }
    }
    
    private func confirmRestDayToggle(for dayTemplate: DayTemplate) {
        if template != nil { autoSaveTemplate() }
    }
    
    private func showExercisePicker(for dayTemplate: DayTemplate) {
        selectedDayForExercisePicker = dayTemplate
        showingExercisePicker = true
    }
    
    private func addExercisesToDay(_ exercises: [Exercise], to dayTemplate: DayTemplate) {
        let currentPosition = Double(dayTemplate.exerciseTemplates.count + 1)
        
        for (index, exercise) in exercises.enumerated() {
            let exerciseTemplate = ExerciseTemplate(
                exercise: exercise,
                setCount: 3,
                reps: 8,
                weight: nil,
                position: currentPosition + Double(index),
                supersetID: nil,
                dayTemplate: dayTemplate
            )
            
            context.insert(exerciseTemplate)
            dayTemplate.exerciseTemplates.append(exerciseTemplate)
        }
        
        do {
            try context.save()
            if template != nil { autoSaveTemplate() }
        } catch {
            viewModel.error = error
        }
    }
    
    private func deleteExerciseTemplate(_ exerciseTemplate: ExerciseTemplate) {
        AppLogger.info("[WorkoutTemplateEditorView.deleteExerciseTemplate] Deleting exercise template", category: "WorkoutTemplateEditor")
        viewModel.deleteExerciseTemplate(exerciseTemplate)
    }
    
    private func reorderExerciseTemplates(in dayTemplate: DayTemplate, from source: IndexSet, to destination: Int) {
        AppLogger.info("[WorkoutTemplateEditorView.reorderExerciseTemplates] Reordering exercises in \(dayTemplate.weekday)", category: "WorkoutTemplateEditor")
        viewModel.reorderExerciseTemplates(in: dayTemplate, from: source, to: destination)
    }
    
    private func addNewDay() {
        let existingWeekdays = Set(dayTemplates.map { $0.weekday })
        let nextWeekday = Weekday.allCases.first { !existingWeekdays.contains($0) } ?? .monday
        
        let newDay = DayTemplate(
            weekday: nextWeekday,
            isRest: false,
            notes: "",
            workoutTemplate: template
        )
        
        context.insert(newDay)
        dayTemplates.append(newDay)
        dayTemplates.sort { $0.weekday.rawValue < $1.weekday.rawValue }
        
        do {
            try context.save()
            if template != nil { autoSaveTemplate() }
        } catch {
            viewModel.error = error
        }
    }
    
    private func autoSaveTemplate() {
        guard let existingTemplate = template else { return }
        
        do {
            existingTemplate.name = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
            existingTemplate.summary = description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for dayTemplate in dayTemplates {
                dayTemplate.workoutTemplate = existingTemplate
                context.insert(dayTemplate)
            }
            
            try existingTemplate.validateAndSave(in: context)
        } catch {
            viewModel.error = error
        }
    }
    
    private func saveTemplate() {
        do {
            if let existingTemplate = template {
                existingTemplate.name = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
                existingTemplate.summary = description.trimmingCharacters(in: .whitespacesAndNewlines)
                
                for dayTemplate in dayTemplates {
                    dayTemplate.workoutTemplate = existingTemplate
                    context.insert(dayTemplate)
                }
                
                try existingTemplate.validateAndSave(in: context)
            } else {
                let newTemplate = WorkoutTemplate(
                    name: workoutName.trimmingCharacters(in: .whitespacesAndNewlines),
                    summary: description.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                context.insert(newTemplate)
                
                for dayTemplate in dayTemplates {
                    dayTemplate.workoutTemplate = newTemplate
                    context.insert(dayTemplate)
                }
                
                try newTemplate.validateAndSave(in: context)
                viewModel.templates.insert(newTemplate, at: 0)
            }
            
            dismiss()
        } catch {
            viewModel.error = error
        }
    }
}

// MARK: - Day Template View
struct DayTemplateView: View {
    let dayTemplate: DayTemplate
    let onRestDayToggle: () -> Void
    let onAddExercise: () -> Void
    let onEditExercise: (ExerciseTemplate) -> Void
    let onDeleteExercise: (ExerciseTemplate) -> Void
    let onReorderExercises: (IndexSet, Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Day Header
            HStack {
                Text(dayTemplate.weekday.fullName)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("Rest Day")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Toggle("", isOn: Binding(
                        get: { dayTemplate.isRest },
                        set: { _ in onRestDayToggle() }
                    ))
                    .labelsHidden()
                }
            }
            
            // Day Content
            if dayTemplate.isRest {
                RestDayView()
            } else {
                VStack(spacing: 12) {
                    if !dayTemplate.exerciseTemplates.isEmpty {
                        List {
                            ForEach(Array(dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position }).enumerated()), id: \.element.id) { index, exerciseTemplate in
                                VStack(spacing: 0) {
                                    ExerciseTemplateRowView(
                                        exerciseTemplate: exerciseTemplate,
                                        onEditExercise: onEditExercise
                                    )
                                    .onTapGesture {
                                        onEditExercise(exerciseTemplate)
                                    }
                                    
                                    // Add divider if not the last item
                                    if index < dayTemplate.exerciseTemplates.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color(.systemBackground))
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: { offsets in
                                for index in offsets {
                                    let sortedExercises = dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })
                                    let exerciseTemplate = sortedExercises[index]
                                    onDeleteExercise(exerciseTemplate)
                                }
                            })
                            .onMove(perform: onReorderExercises)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .frame(height: CGFloat(dayTemplate.exerciseTemplates.count * 80))
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    AddExerciseButton(onAddExercise: onAddExercise)
                }
            }
        }
    }
}

 