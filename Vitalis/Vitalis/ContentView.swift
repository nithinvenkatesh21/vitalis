import SwiftUI
import Observation
import VitalisCore
import VitalisNetworking
import VitalisPersistence

struct ContentView: View {
    @State private var viewModel: DashboardViewModel
    
    init() {
        let authRepository = AuthRepository()
        let moodRepository = MoodRepository(authRepository: authRepository)
        let syncEngine = SyncEngine(authRepository: authRepository)
        
        // Wire dependencies
        moodRepository.setSyncEngine(syncEngine)
        
        let vm = DashboardViewModel(
            authRepository: authRepository,
            moodRepository: moodRepository,
            syncEngine: syncEngine
        )
        
        _viewModel = State(initialValue: vm)
    }
    
    var body: some View {
        Group {
            if viewModel.currentUser != nil {
                DashboardView(viewModel: viewModel)
            } else {
                OnboardingView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark) // Lock to Dark Mode to match Vitalis aesthetic
    }
}

#Preview {
    ContentView()
}
