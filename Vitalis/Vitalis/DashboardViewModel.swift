import Foundation
import Combine
import Observation
import VitalisCore
import VitalisPersistence

@Observable
public final class DashboardViewModel {
    public let authRepository: AuthRepositoryProtocol
    public let moodRepository: MoodRepositoryProtocol
    
    public var currentUser: User? = nil
    public var moodEntries: [MoodEntry] = []
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        authRepository: AuthRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.moodRepository = moodRepository
        
        // Listen to auth changes
        authRepository.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
            
        // Listen to mood cache changes
        moodRepository.moodEntriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.moodEntries = entries
            }
            .store(in: &cancellables)
    }
    
    public func logTestMood() {
        guard currentUser != nil else { return }
        isLoading = true
        errorMessage = nil
        
        let randomValence = Double.random(in: 0.1...1.0)
        let moods = ["Super Energized", "Calm and Focused", "A Bit Tired", "Stressed", "Restless", "Feeling Great"]
        let randomText = "Milestone 1 Test: \(moods.randomElement()!)"
        
        Task {
            do {
                try await moodRepository.logMood(valence: randomValence, freeText: randomText, tags: ["milestone1", "test"])
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func refreshData() {
        guard currentUser != nil else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await moodRepository.syncWithRemote()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func loginLocalUser() {
        isLoading = true
        errorMessage = nil
        
        let localUserId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        
        Task {
            do {
                _ = try await authRepository.signInMock(userId: localUserId, displayName: "Local User")
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: loginLocalUser failed with error: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
