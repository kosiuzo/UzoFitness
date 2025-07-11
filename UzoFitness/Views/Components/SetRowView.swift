import SwiftUI

// MARK: - Set Row View
struct SetRowView: View {
    let setIndex: Int
    let set: CompletedSet?
    let plannedReps: Int
    let plannedWeight: Double
    let isEditing: Bool
    @Binding var tempReps: String
    @Binding var tempWeight: String
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(setIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            if isEditing {
                HStack(spacing: 8) {
                    CustomNumberPadTextField(text: $tempReps, placeholder: "Reps", keyboardType: .numberPad, onDone: {
                        onSave()
                    })
                    .frame(width: 60)
                    
                    Text("×")
                        .foregroundColor(.secondary)
                    
                    CustomNumberPadTextField(text: $tempWeight, placeholder: "(lbs)", keyboardType: .decimalPad, onDone: {
                        onSave()
                    })
                    .frame(width: 60)
                    
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        onToggleCompletion()
                    } label: {
                        Image(systemName: set?.isCompleted == true ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set?.isCompleted == true ? .green : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: 4) {
                            if let set = set {
                                Text("\(set.reps)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 30)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            } else {
                                Text("\(plannedReps)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 30)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            }
                            
                            Text("×")
                                .foregroundColor(.secondary)
                            
                            if let set = set {
                                Text("\(Int(set.weight))")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 40)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            } else {
                                Text("\(Int(plannedWeight))")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 40)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(.quaternary)
                                    .cornerRadius(6)
                            }
                            
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Completion toggle button
                    Button {
                        onToggleCompletion()
                    } label: {
                        Image(systemName: set?.isCompleted == true ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set?.isCompleted == true ? .green : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
        .toolbar {
            if isEditing {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        onSave()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}