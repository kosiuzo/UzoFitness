import SwiftUI

// MARK: - Logging Exercise Row View
struct LoggingExerciseRowView: View {
    let exercise: SessionExerciseUI
    let onEditSet: (Int, Int, Double) -> Void
    let onBulkEditSets: (Int, Double) -> Void
    let onAddSet: () -> Void
    let onToggleSetCompletion: (Int) -> Void
    let onMarkComplete: () -> Void
    let getSupersetNumber: ((UUID) -> Int?)?
    let isCurrentExercise: Bool
    
    @State private var editingSetIndex: Int? = nil
    @State private var tempReps: String = ""
    @State private var tempWeight: String = ""
    @State private var isExpanded: Bool = true
    @State private var showingBulkEdit: Bool = false
    @State private var showingExerciseInfo: Bool = false
    @State private var bulkReps: String = ""
    @State private var bulkWeight: String = ""
    
    // Computed property to determine if exercise should be expanded by default
    private var shouldBeExpandedByDefault: Bool {
        // Always expand current exercise
        if isCurrentExercise { return true }
        // Always expand incomplete exercises
        if !exercise.isCompleted { return true }
        // Collapse completed exercises by default
        return false
    }
    
    private func getDefaultBulkEditValues() -> (reps: String, weight: String) {
        let completedSets = exercise.sets.filter { $0.isCompleted }
        
        if let firstCompletedSet = completedSets.first {
            return ("\(firstCompletedSet.reps)", "\(Int(firstCompletedSet.weight))")
        } else if let lastCompletedSet = completedSets.last {
            return ("\(lastCompletedSet.reps)", "\(Int(lastCompletedSet.weight))")
        } else {
            return ("\(exercise.plannedReps)", "\(Int(exercise.plannedWeight ?? 0))")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header (Always visible and tappable)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Info button
                            Button {
                                showingExerciseInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("\(exercise.plannedSets) sets × \(exercise.plannedReps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !exercise.isCompleted && exercise.sets.count > 1 {
                            Button("Edit All Sets") {
                                let defaults = getDefaultBulkEditValues()
                                bulkReps = defaults.reps
                                bulkWeight = defaults.weight
                                showingBulkEdit = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Completion status and expand/collapse indicator
                    HStack(spacing: 12) {
                        if exercise.isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("Complete")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        } else {
                            VStack(alignment: .trailing, spacing: 4) {
                                if let supersetID = exercise.supersetID,
                                   let getSupersetNumber = getSupersetNumber,
                                   let supersetNumber = getSupersetNumber(supersetID) {
                                    SupersetBadgeView(
                                        supersetNumber: supersetNumber,
                                        isHead: exercise.isSupersetHead
                                    )
                                }
                                let completedSets = exercise.sets.filter { $0.isCompleted }.count
                                let totalSets = exercise.sets.count
                                
                                Text("\(completedSets)/\(totalSets) sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("Complete All Sets") {
                                    onMarkComplete()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Expand/collapse chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(16)
            
            // Sets List (Collapsible)
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 8) {
                        ForEach(0..<exercise.sets.count, id: \.self) { setIndex in
                            SetRowView(
                                setIndex: setIndex,
                                set: exercise.sets[setIndex],
                                plannedReps: exercise.plannedReps,
                                plannedWeight: exercise.plannedWeight ?? 0,
                                isEditing: editingSetIndex == setIndex,
                                tempReps: $tempReps,
                                tempWeight: $tempWeight,
                                onEdit: {
                                    editingSetIndex = setIndex
                                    tempReps = "\(exercise.sets[setIndex].reps)"
                                    tempWeight = "\(Int(exercise.sets[setIndex].weight))"
                                },
                                onSave: {
                                    guard let reps = Int(tempReps),
                                          let weight = Double(tempWeight) else { return }
                                    onEditSet(setIndex, reps, weight)
                                    editingSetIndex = nil
                                },
                                onCancel: {
                                    editingSetIndex = nil
                                },
                                onToggleCompletion: {
                                    onToggleSetCompletion(setIndex)
                                }
                            )
                        }
                        
                        // Add Set Button
                        if !exercise.isCompleted {
                            Button {
                                onAddSet()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Set")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isCurrentExercise ? Color.blue.opacity(0.07) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isCurrentExercise ? Color.blue.opacity(0.4) : Color(.systemGray4), lineWidth: isCurrentExercise ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(isCurrentExercise ? 0.10 : 0.06), radius: isCurrentExercise ? 8 : 4, x: 0, y: 2)
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .scaleEffect(isCurrentExercise ? 1.025 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCurrentExercise)
        .onAppear {
            // Set initial expansion state based on completion status
            isExpanded = shouldBeExpandedByDefault
        }
        .onChange(of: isCurrentExercise) { oldValue, newValue in
            // Auto-expand when exercise becomes current
            if newValue && !isExpanded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded = true
                }
            }
        }
        .onChange(of: exercise.isCompleted) { oldValue, newValue in
            // Auto-collapse when exercise is completed (unless it's current)
            if newValue && !isCurrentExercise && isExpanded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded = false
                }
            }
        }
        .alert("Edit All Sets", isPresented: $showingBulkEdit) {
            TextField("Reps", text: $bulkReps)
                .keyboardType(.numberPad)
            TextField("Weight", text: $bulkWeight)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard let reps = Int(bulkReps),
                      let weight = Double(bulkWeight) else { return }
                onBulkEditSets(reps, weight)
            }
        } message: {
            Text("This will update the reps and weight for all sets in this exercise.")
        }
        .sheet(isPresented: $showingExerciseInfo) {
            ExerciseInfoSheet(exercise: exercise.exercise)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}