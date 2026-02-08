import Foundation
import Combine

class StatisticsManager: ObservableObject {
    @Published var sessions: [FocusSession] = []
    @Published var currentSession: FocusSession?
    
    private let sessionsKey = "focuscage_sessions"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSessions()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .profileActivated)
            .compactMap { $0.object as? FocusProfile }
            .sink { [weak self] profile in
                self?.startSession(for: profile)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .profileDeactivated)
            .sink { [weak self] _ in
                self?.endCurrentSession(completed: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey) {
            do {
                sessions = try JSONDecoder().decode([FocusSession].self, from: data)
            } catch {
                print("[StatisticsManager] Failed to load sessions: \(error)")
                sessions = []
            }
        }
    }
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
        } catch {
            print("[StatisticsManager] Failed to save sessions: \(error)")
        }
    }
    
    // MARK: - Session Tracking
    
    func startSession(for profile: FocusProfile) {
        // Don't start a duplicate session
        if let current = currentSession, current.profileId == profile.id {
            return
        }
        
        // End any existing session first
        if currentSession != nil {
            endCurrentSession(completed: false)
        }
        
        let calendar = Calendar.current
        let now = Date()
        let endHour = profile.schedule.endTime.hour ?? 0
        let endMinute = profile.schedule.endTime.minute ?? 0
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = endHour
        endComponents.minute = endMinute
        let scheduledEnd = calendar.date(from: endComponents) ?? now
        
        let session = FocusSession(
            profileId: profile.id,
            profileName: profile.name,
            profileIconName: profile.iconName,
            profileColorRaw: profile.color.rawValue,
            startDate: now,
            scheduledEndDate: scheduledEnd,
            blockedAppCount: profile.blockedApps.applicationTokens.count + profile.blockedApps.categoryTokens.count,
            blockedWebsiteCount: profile.blockedWebsites.count
        )
        
        currentSession = session
        print("[StatisticsManager] Session started for '\(profile.name)'")
    }
    
    func endCurrentSession(completed: Bool) {
        guard var session = currentSession else { return }
        
        session.endDate = Date()
        session.wasCompleted = completed
        sessions.append(session)
        saveSessions()
        
        print("[StatisticsManager] Session ended for '\(session.profileName)' (completed: \(completed))")
        currentSession = nil
    }
    
    // MARK: - Computed Statistics
    
    var todaysSessions: [FocusSession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDateInToday($0.startDate) }
    }
    
    var thisWeekSessions: [FocusSession] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        return sessions.filter { $0.startDate >= weekStart }
    }
    
    var totalFocusHoursToday: Double {
        todaysSessions.reduce(0) { $0 + $1.durationHours }
    }
    
    var totalFocusHoursThisWeek: Double {
        thisWeekSessions.reduce(0) { $0 + $1.durationHours }
    }
    
    var completionRate: Double {
        let completed = sessions.filter { $0.wasCompleted }
        guard !sessions.isEmpty else { return 0 }
        return Double(completed.count) / Double(sessions.count)
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Check if today has a completed session
        let todayCompleted = sessions.contains { session in
            calendar.isDate(session.startDate, inSameDayAs: checkDate) && session.wasCompleted
        }
        
        if !todayCompleted {
            // If no completed session today, start checking from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }
        
        while true {
            let dayCompleted = sessions.contains { session in
                calendar.isDate(session.startDate, inSameDayAs: checkDate) && session.wasCompleted
            }
            
            if dayCompleted {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = Set(sessions.filter { $0.wasCompleted }.map { calendar.startOfDay(for: $0.startDate) }).sorted()
        
        guard !sortedDays.isEmpty else { return 0 }
        
        var longest = 1
        var current = 1
        
        for i in 1..<sortedDays.count {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]),
               calendar.isDate(nextDay, inSameDayAs: sortedDays[i]) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        
        return longest
    }
    
    var mostUsedProfile: (name: String, count: Int)? {
        let grouped = Dictionary(grouping: sessions, by: { $0.profileName })
        guard let top = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return (name: top.key, count: top.value.count)
    }
    
    func dailyHours(for daysBack: Int = 7) -> [(date: Date, hours: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<daysBack).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let daySessions = sessions.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            let hours = daySessions.reduce(0.0) { $0 + $1.durationHours }
            return (date: date, hours: hours)
        }
    }
    
    var totalSessions: Int {
        sessions.count
    }
}
