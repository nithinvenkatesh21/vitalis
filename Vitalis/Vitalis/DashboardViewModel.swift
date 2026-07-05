import Foundation
import Combine
import Observation
import VitalisCore
import VitalisNetworking
import VitalisPersistence

@Observable
public final class DashboardViewModel {
    public let authRepository: AuthRepositoryProtocol
    public let moodRepository: MoodRepositoryProtocol
    public let syncEngine: SyncEngine
    
    public var currentUser: User? = nil
    public var moodEntries: [MoodEntry] = []
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        authRepository: AuthRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol,
        syncEngine: SyncEngine
    ) {
        self.authRepository = authRepository
        self.moodRepository = moodRepository
        self.syncEngine = syncEngine
        
        // Listen to auth changes
        authRepository.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                if user != nil {
                    // Try to sync on login
                    Task {
                        try? await moodRepository.syncWithRemote()
                    }
                }
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
    
    public func signOut() {
        Task {
            try? await authRepository.signOut()
        }
    }
    
    #if DEBUG
    /// Gated mock logins for User A and User B.
    /// Uses static deterministic UUID seeds to ensure User A and User B are consistent across runs/devices.
    public func loginMockUser(name: String) {
        isLoading = true
        errorMessage = nil
        
        let uuidSeed = name == "User A" 
            ? UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")! 
            : UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
            
        Task {
            do {
                _ = try await authRepository.signInMock(userId: uuidSeed, displayName: name)
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: loginMockUser failed with error: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    #endif
}
