import Foundation
import Observation
import SwiftUI
import VitalisCore
import VitalisPersistence

@Observable
public final class WorkoutLogViewModel {
    private let workoutRepository: WorkoutRepositoryProtocol
    
    public var selectedType: WorkoutType = .strength
    public var sets: [SetLog] = []
    public var workoutRPE: Double = 7.0
    
    // Add set form bindings
    public var loadInput: String = ""
    public var repsInput: String = ""
    public var tempoInput: String = "3010"
    public var rpeInput: String = "7.0"
    public var restInput: String = "90"
    
    // UI state
    public var isLoading = false
    public var errorMessage: String? = nil
    public var successMessage: String? = nil
    
    public init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }
    
    public func addSet() {
        errorMessage = nil
        successMessage = nil
        
        let reps = Int(repsInput) ?? 8
        let load = Double(loadInput) // nil is fine for bodyweight
        let tempo = tempoInput.isEmpty ? nil : tempoInput
        let rpe = Double(rpeInput)
        let rest = Int(restInput)
        
        let set = SetLog(
            load: load,
            reps: reps,
            tempo: tempo,
            rpe: rpe,
            restSeconds: rest
        )
        
        sets.append(set)
        
        // Clear set entry values (keep tempo/rest defaults for convenience)
        loadInput = ""
        repsInput = ""
        rpeInput = "7.0"
        
        successMessage = "Set \(sets.count) added!"
    }
    
    public func removeSet(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }
    
    public func submitWorkout() {
        guard !sets.isEmpty else {
            errorMessage = "Please add at least one set"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await workoutRepository.logWorkout(
                    type: selectedType,
                    sets: sets,
                    rpe: workoutRPE
                )
                await MainActor.run {
                    self.sets.removeAll()
                    self.isLoading = false
                    self.successMessage = "Workout logged successfully!"
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
