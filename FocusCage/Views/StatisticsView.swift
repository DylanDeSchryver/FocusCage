import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var statisticsManager: StatisticsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCards
                    weeklyChart
                    streakSection
                    recentSessionsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Today",
                value: String(format: "%.1fh", statisticsManager.totalFocusHoursToday),
                icon: "sun.max.fill",
                color: .orange
            )
            
            StatCard(
                title: "This Week",
                value: String(format: "%.1fh", statisticsManager.totalFocusHoursThisWeek),
                icon: "calendar",
                color: themeManager.accentColor
            )
            
            StatCard(
                title: "Completion",
                value: "\(Int(statisticsManager.completionRate * 100))%",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Total Sessions",
                value: "\(statisticsManager.totalSessions)",
                icon: "flame.fill",
                color: .red
            )
        }
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Focus")
                .font(.headline)
            
            let data = statisticsManager.dailyHours()
            
            if data.isEmpty || data.allSatisfy({ $0.hours == 0 }) {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No data yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                Chart(data, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(themeManager.accentColor.gradient)
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(statisticsManager.currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("\(statisticsManager.longestStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Text("Longest Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if let mostUsed = statisticsManager.mostUsedProfile {
                VStack(spacing: 4) {
                    Text("\(mostUsed.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(mostUsed.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
            
            let recent = Array(statisticsManager.sessions.suffix(10).reversed())
            
            if recent.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No sessions recorded yet.\nStart a focus session to see your history.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(recent) { session in
                    SessionRow(session: session)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SessionRow: View {
    let session: FocusSession
    
    private var profileColor: Color {
        ProfileColor(rawValue: session.profileColorRaw)?.color ?? .gray
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(profileColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: session.profileIconName)
                    .font(.subheadline)
                    .foregroundStyle(profileColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.profileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.startDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                    Text(session.wasCompleted ? "Completed" : "Ended early")
                        .font(.caption)
                }
                .foregroundStyle(session.wasCompleted ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    StatisticsView()
        .environmentObject(StatisticsManager())
        .environmentObject(ThemeManager())
}
