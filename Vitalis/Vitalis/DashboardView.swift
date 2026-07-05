import SwiftUI
import VitalisCore

struct DashboardView: View {
    let viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header User Profile Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome,")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            
                            Text(viewModel.currentUser?.displayName ?? "Vitalis User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text("ID: \(viewModel.currentUser?.id.uuidString.prefix(8) ?? "")...")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        // Sign Out Button
                        Button(action: {
                            withAnimation {
                                viewModel.signOut()
                            }
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .padding(10)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Outbox Sync & Refresh Actions
                    HStack {
                        Text("Timeline & Mood Logs")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.refreshData()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text("Sync")
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Active Error Messaging
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Main Action: Log Mood Test Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.logTestMood()
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Log Mood Entry (Test)")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, y: 5)
                        .padding(.horizontal)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Logs List
                    if viewModel.moodEntries.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No Mood Entries Yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Tap the button above to log a new entry locally. It will automatically queue and sync to Supabase.")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.moodEntries) { entry in
                                MoodRow(entry: entry)
                                    .listRowBackground(Color.white.opacity(0.03))
                                    .listRowSeparatorTint(Color.gray.opacity(0.2))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
    }
}

struct MoodRow: View {
    let entry: MoodEntry
    
    private var valenceColor: Color {
        if entry.valence >= 0.7 {
            return .green
        } else if entry.valence >= 0.4 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: entry.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Valence score indicator badge
            ZStack {
                Circle()
                    .fill(valenceColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Text("\(Int(entry.valence * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(valenceColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.freeText ?? "Mood Log")
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if !entry.tags.isEmpty {
                        Text(entry.tags.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundColor(.purple.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Sync status indicator
            if entry.isSynced {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
            } else {
                HStack(spacing: 4) {
                    Text("Pending")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}
