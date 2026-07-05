import SwiftUI
import VitalisCore

struct WorkoutLogView: View {
    @Bindable var viewModel: WorkoutLogViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ScrollView {
                        VStack(spacing: 20) {
                            workoutDetailsSection
                            
                            statusMessagesSection
                            
                            addSetSection
                            
                            currentSetsSection
                        }
                    }
                    
                    submitButton
                }
            }
            .navigationTitle("Log Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    // MARK: - Sub-views
    
    private var workoutDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WORKOUT DETAILS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.gray)
            
            Picker("Workout Type", selection: $viewModel.selectedType) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .accentColor(.purple)
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Overall Workout RPE")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.1f", viewModel.workoutRPE))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Slider(value: $viewModel.workoutRPE, in: 1.0...10.0, step: 0.5)
                    .tint(.purple)
            }
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var statusMessagesSection: some View {
        Group {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            if let success = viewModel.successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            }
        }
    }
    
    private var addSetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADD EXERCISE SET")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.gray)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight (lbs)").font(.caption2).foregroundColor(.gray)
                    TextField("Bodyweight", text: $viewModel.loadInput)
                        .numericKeyboard()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps").font(.caption2).foregroundColor(.gray)
                    TextField("8", text: $viewModel.repsInput)
                        .integerKeyboard()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tempo").font(.caption2).foregroundColor(.gray)
                    TextField("3010", text: $viewModel.tempoInput)
                }
            }
            .textFieldStyle(.plain)
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set RPE").font(.caption2).foregroundColor(.gray)
                    TextField("7.0", text: $viewModel.rpeInput)
                        .numericKeyboard()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest (sec)").font(.caption2).foregroundColor(.gray)
                    TextField("90", text: $viewModel.restInput)
                        .integerKeyboard()
                }
            }
            .textFieldStyle(.plain)
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.addSet()
            }) {
                Text("Add Set")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var currentSetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETS ON WORKOUT CARD (\(viewModel.sets.count))")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.gray)
                .padding(.horizontal)
            
            if viewModel.sets.isEmpty {
                Text("No sets logged. Add your lifting metrics or cardio sets above to document this session.")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.01))
                    .cornerRadius(10)
                    .padding(.horizontal)
            } else {
                ForEach(Array(viewModel.sets.enumerated()), id: \.offset) { index, set in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            if let load = set.load {
                                HStack(spacing: 4) {
                                    Text("\(Int(load)) lbs")
                                        .foregroundColor(.white)
                                    if let maxEst = set.estimatedOneRepMax {
                                        Text("(1RM: \(Int(maxEst)) lbs)")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            } else {
                                Text("Bodyweight")
                                    .foregroundColor(.white)
                            }
                            
                            Text("× \(set.reps) reps")
                                .foregroundColor(.white)
                            
                            if let tempo = set.tempo {
                                Text("@\(tempo)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            if let rpe = set.rpe {
                                Text("RPE \(Int(rpe))")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                            
                            Button(action: {
                                viewModel.removeSet(at: IndexSet(integer: index))
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.8))
                                    .font(.system(size: 14))
                                    .padding(6)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            viewModel.submitWorkout()
            dismiss()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Log Workout")
                }
            }
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.sets.isEmpty ? Color.gray : Color.purple)
            .cornerRadius(15)
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .disabled(viewModel.sets.isEmpty || viewModel.isLoading)
    }
}
