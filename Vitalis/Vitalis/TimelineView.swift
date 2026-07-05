import SwiftUI
import VitalisCore

struct TimelineView: View {
    @State var viewModel: TimelineViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header title
                    HStack {
                        Text("TIMELINE")
                            .font(.title2)
                            .fontWeight(.black)
                            .tracking(2)
                            .foregroundStyle(.white)
                        Spacer()
                        
                        Button(action: {
                            viewModel.refreshTimeline()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    // Filter Chips Row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.filters, id: \.self) { filter in
                                FilterChip(
                                    label: filter,
                                    isSelected: viewModel.selectedFilter == filter,
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    
                    Divider().background(Color.gray.opacity(0.2))
                    
                    // Events Stream
                    if viewModel.filteredEvents.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "list.bullet.indent")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("No Unified Logs Yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Entries you log in nutrition, training, or mood will appear chronologically here.")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.filteredEvents) { event in
                                TimelineRowView(event: event)
                                    .listRowBackground(Color.white.opacity(0.01))
                                    .listRowSeparatorTint(Color.gray.opacity(0.15))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshTimeline()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.white.opacity(0.05))
                .foregroundColor(.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.purple : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct TimelineRowView: View {
    let event: TimelineEvent
    
    private var eventConfig: (icon: String, color: Color, title: String) {
        switch event.type {
        case "mood_entry":
            return ("face.smiling.fill", .yellow, "Mood Check-in")
        case "nutrition_log":
            return ("fork.knife", .blue, "Nutrition Log")
        case "workout_session":
            return ("dumbbell.fill", .purple, "Workout Session")
        case "readiness_score":
            return ("sparkles", .green, "Readiness Score")
        default:
            return ("sparkles", .gray, "Health Event")
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: event.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Badge
            ZStack {
                Circle()
                    .fill(eventConfig.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: eventConfig.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(eventConfig.color)
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(eventConfig.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formattedTime)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                // Specific text formatting depending on event details
                Group {
                    if event.type == "mood_entry" {
                        let valencePercent = Int((Double(event.payload["valence"] ?? "0") ?? 0) * 100)
                        let text = event.payload["free_text"] ?? ""
                        Text("Felt \(valencePercent)%: \(text)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if event.type == "nutrition_log" {
                        let calories = event.payload["calories"] ?? "0"
                        let itemsCount = event.payload["items_count"] ?? "0"
                        Text("Logged \(itemsCount) items · \(calories) kcal total")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if event.type == "workout_session" {
                        let workoutType = event.payload["type"] ?? "STRENGTH"
                        let sets = event.payload["sets_count"] ?? "0"
                        let load = event.payload["training_load"] ?? "0"
                        Text("\(workoutType) · \(sets) sets logged (Load: \(load))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if event.type == "readiness_score" {
                        let score = event.payload["composite_score"] ?? "50"
                        let explanation = event.payload["explanation"] ?? ""
                        Text("Computed score: \(score). \(explanation.replacingOccurrences(of: "|", with: "·"))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text(event.payload.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
