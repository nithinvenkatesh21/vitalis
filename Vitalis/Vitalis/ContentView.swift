import SwiftUI
import Observation
import VitalisCore
import VitalisNetworking
import VitalisPersistence
import VitalisHealthKit

struct ContentView: View {
    @State private var viewModel: DashboardViewModel
    
    init() {
        let authRepository = AuthRepository()
        let moodRepository = MoodRepository(authRepository: authRepository)
        let syncEngine = SyncEngine(authRepository: authRepository)
        
        // Wire dependencies for mood
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
                let healthKitService = HealthKitService()
                let readinessRepo = ReadinessRepository(authRepository: viewModel.authRepository, healthKitService: healthKitService)
                let nutritionRepo = NutritionRepository(authRepository: viewModel.authRepository)
                
                let syncEngine = SyncEngine(authRepository: viewModel.authRepository)
                readinessRepo.setSyncEngine(syncEngine)
                nutritionRepo.setSyncEngine(syncEngine)
                
                let todayVM = TodayViewModel(
                    authRepository: viewModel.authRepository,
                    readinessRepository: readinessRepo,
                    nutritionRepository: nutritionRepo,
                    healthKitService: healthKitService
                )
                
                TodayView(viewModel: todayVM)
            } else {
                OnboardingView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
