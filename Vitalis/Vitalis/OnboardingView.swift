import SwiftUI
import AuthenticationServices
import VitalisCore
import VitalisPersistence

struct OnboardingView: View {
    let viewModel: DashboardViewModel
    @State private var animateItems = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Visual ambient glow
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -100)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo & Branding
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateItems ? 1.0 : 0.8)
                        .opacity(animateItems ? 1.0 : 0.0)
                    
                    Text("VITALIS")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.black)
                        .tracking(3)
                        .foregroundStyle(.white)
                        .opacity(animateItems ? 1.0 : 0.0)
                        .offset(y: animateItems ? 0 : 20)
                    
                    Text("The Unified Health Operating System")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(animateItems ? 1.0 : 0.0)
                        .offset(y: animateItems ? 0 : 20)
                }
                
                Spacer()
                
                // Onboarding Info Cards
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(icon: "lock.shield.fill", title: "Privacy First", description: "Your data is encrypted and completely under your control.")
                    InfoRow(icon: "arrow.triangle.2.circlepath", title: "Offline Sync", description: "Log data offline. It automatically syncs when you reconnect.")
                }
                .padding(.horizontal, 30)
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(y: animateItems ? 0 : 30)
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 12) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { _ in
                            // Apple Sign In Success
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                    
                    #if DEBUG
                    // Compile-time Gated Mock Authentications
                    VStack(spacing: 8) {
                        Text("Debug Mock Sign-In")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    viewModel.loginMockUser(name: "User A")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                    Text("User A")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.purple.opacity(0.3))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                                )
                            }
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.loginMockUser(name: "User B")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                    Text("User B")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.cyan.opacity(0.3))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Text("Mock User sessions simulate discrete database accounts to verify RLS.")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    #endif
                }
                .padding(.bottom, 30)
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(y: animateItems ? 0 : 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateItems = true
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.purple)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct OnboardingViewPreviewContainer: View {
    let vm: DashboardViewModel
    
    init() {
        let auth = AuthRepository()
        let moodRepo = MoodRepository(authRepository: auth)
        self.vm = DashboardViewModel(authRepository: auth, moodRepository: moodRepo)
    }
    
    var body: some View {
        OnboardingView(viewModel: vm)
    }
}

#Preview {
    OnboardingViewPreviewContainer()
}
