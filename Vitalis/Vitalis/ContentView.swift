import SwiftUI
import Observation
import VitalisCore
import VitalisNetworking
import VitalisPersistence
import VitalisHealthKit

struct ContentView: View {
    @State private var dashboardViewModel: DashboardViewModel
    @State private var todayViewModel: TodayViewModel
    
    init() {
        let authRepository = AuthRepository()
        let moodRepository = MoodRepository(authRepository: authRepository)
        let healthKitService = HealthKitService()
        let readinessRepo = ReadinessRepository(authRepository: authRepository, healthKitService: healthKitService)
        let nutritionRepo = NutritionRepository(authRepository: authRepository)
        
        let syncEngine = SyncEngine(authRepository: authRepository)
        moodRepository.setSyncEngine(syncEngine)
        readinessRepo.setSyncEngine(syncEngine)
        nutritionRepo.setSyncEngine(syncEngine)
        
        let dbVM = DashboardViewModel(
            authRepository: authRepository,
            moodRepository: moodRepository,
            syncEngine: syncEngine
        )
        
        let tVM = TodayViewModel(
            authRepository: authRepository,
            readinessRepository: readinessRepo,
            nutritionRepository: nutritionRepo,
            healthKitService: healthKitService
        )
        
        _dashboardViewModel = State(initialValue: dbVM)
        _todayViewModel = State(initialValue: tVM)
    }
    
    var body: some View {
        Group {
            if dashboardViewModel.currentUser != nil {
                TodayView(viewModel: todayViewModel)
            } else {
                OnboardingView(viewModel: dashboardViewModel)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
