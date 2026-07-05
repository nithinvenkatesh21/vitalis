import SwiftUI
import VitalisCore

struct TodayView: View {
    @State var viewModel: TodayViewModel
    @State private var showingNutritionLog = false
    @State private var showingMoodDashboard = false
    @State private var animateRing = false
    
    private var readinessColor: Color {
        guard let score = viewModel.readinessScore else { return .gray }
        if score.compositeScore >= 70 {
            return .green
        } else if score.compositeScore >= 40 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Glow effect
                Circle()
                    .fill(readinessColor.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(y: -180)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Top Navigation Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TODAY")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                    .foregroundStyle(.purple)
                                
                                Text(viewModel.currentUser?.displayName ?? "Vitalis User")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            
                            // Sign Out
                            Button(action: {
                                withAnimation {
                                    Task { try? await viewModel.authRepository.signOut() }
                                }
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // 1. HERO CARD: Readiness Score
                        VStack(spacing: 16) {
                            Text("READINESS")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(3)
                                .foregroundStyle(.gray)
                            
                            // Interactive Circular Ring
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.05), lineWidth: 14)
                                    .frame(width: 140, height: 140)
                                
                                Circle()
                                    .trim(from: 0.0, to: animateRing ? CGFloat((viewModel.readinessScore?.compositeScore ?? 50.0) / 100.0) : 0.0)
                                    .stroke(
                                        AngularGradient(
                                            colors: [readinessColor, readinessColor.opacity(0.6), readinessColor],
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                    )
                                    .frame(width: 140, height: 140)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: 2) {
                                    Text("\(Int(viewModel.readinessScore?.compositeScore ?? 50.0))")
                                        .font(.system(size: 42, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    Text("SCORE")
                                        .font(.system(size: 9, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Component metrics indicators
                            HStack(spacing: 40) {
                                if let sleep = viewModel.readinessScore?.components["sleep"] {
                                    MetricIndicator(icon: "bed.double.fill", value: String(format: "%.1fh", sleep), label: "Sleep Duration", color: .purple)
                                } else {
                                    MetricIndicator(icon: "bed.double.fill", value: "--", label: "Sleep Duration", color: .gray)
                                }
                                
                                if let hrv = viewModel.readinessScore?.components["hrv"] {
                                    MetricIndicator(icon: "waveform.path.ecg", value: String(format: "%.0fms", hrv), label: "HRV (SDNN)", color: .green)
                                } else {
                                    MetricIndicator(icon: "waveform.path.ecg", value: "--", label: "HRV (SDNN)", color: .gray)
                                }
                            }
                            .padding(.top, 4)
                            
                            // Explanations/Analysis Checklist
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.readinessScore?.explanation ?? ["No HealthKit data synced yet."], id: \.self) { line in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                            .padding(.top, 2)
                                        Text(line)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(12)
                            
                            Button(action: {
                                viewModel.recomputeReadiness()
                            }) {
                                HStack {
                                    if viewModel.isComputingReadiness {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Recompute Readiness")
                                    }
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, height: 40)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // 2. NUTRITION SUMMARY CARD
                        VStack(spacing: 16) {
                            HStack {
                                Text("NUTRITION TARGETS")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(3)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            
                            // Calories progress
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.05), lineWidth: 10)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(min(1.0, viewModel.todayCalories / viewModel.calorieTarget)))
                                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                        .frame(width: 80, height: 80)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(spacing: 2) {
                                        Text("\(Int(viewModel.todayCalories))")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("kcal")
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Calorie Balance")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("\(Int(viewModel.calorieTarget - viewModel.todayCalories)) kcal left today")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            // Macros grids
                            HStack(spacing: 16) {
                                MacroProgressBar(label: "Protein", current: viewModel.todayProtein, target: viewModel.proteinTarget, color: .orange)
                                MacroProgressBar(label: "Carbs", current: viewModel.todayCarbs, target: viewModel.carbTarget, color: .green)
                                MacroProgressBar(label: "Fat", current: viewModel.todayFat, target: viewModel.fatTarget, color: .yellow)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // 3. ACTION SHORTCUTS ROW
                        HStack(spacing: 16) {
                            Button(action: {
                                showingNutritionLog = true
                            }) {
                                HStack {
                                    Image(systemName: "fork.knife")
                                    Text("Log Meal")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, height: 48)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingMoodDashboard = true
                            }) {
                                HStack {
                                    Image(systemName: "face.smiling")
                                    Text("Mood Timeline")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, height: 48)
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNutritionLog) {
            let logVM = NutritionLogViewModel(nutritionRepository: viewModel.nutritionRepository)
            NutritionLogView(viewModel: logVM)
        }
        .sheet(isPresented: $showingMoodDashboard) {
            // Reuses the DashboardView from Milestone 1 for Mood Logs
            let moodRepo = MoodRepository(authRepository: viewModel.authRepository)
            let vm = DashboardViewModel(
                authRepository: viewModel.authRepository,
                moodRepository: moodRepo,
                syncEngine: viewModel.readinessRepository as! ReadinessRepository == nil ? SyncEngine(authRepository: viewModel.authRepository) : (viewModel.readinessRepository as! ReadinessRepository).readinessScorePublisher.compactMap { $0 }.sink { _ in } as? SyncEngine ?? SyncEngine(authRepository: viewModel.authRepository) // Safe fallback
            )
            DashboardView(viewModel: vm)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateRing = true
            }
            viewModel.refreshAll()
        }
    }
}

struct MetricIndicator: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(Int(current))/\(Int(target))g")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(0, min(geo.size.width, CGFloat(current / target) * geo.size.width)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
