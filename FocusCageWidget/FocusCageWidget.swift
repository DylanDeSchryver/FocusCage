import WidgetKit
import SwiftUI

// MARK: - Shared Data Reading

struct WidgetData {
    let profileName: String?
    let profileIcon: String?
    let profileColor: String?
    let strictness: String?
    let endDate: Date?
    
    var isActive: Bool {
        guard let end = endDate else { return false }
        return Date() < end
    }
    
    var color: Color {
        switch profileColor {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
    
    static func load() -> WidgetData {
        let defaults = UserDefaults(suiteName: "group.com.focuscage.app")
        let name = defaults?.string(forKey: "shared_active_profile_name")
        let icon = defaults?.string(forKey: "shared_active_profile_icon")
        let color = defaults?.string(forKey: "shared_active_profile_color")
        let strictness = defaults?.string(forKey: "shared_active_strictness")
        let endTimestamp = defaults?.double(forKey: "shared_active_end_time") ?? 0
        let endDate: Date? = endTimestamp > 0 ? Date(timeIntervalSince1970: endTimestamp) : nil
        
        // Only return active data if session hasn't ended
        if let end = endDate, Date() >= end {
            return WidgetData(profileName: nil, profileIcon: nil, profileColor: nil, strictness: nil, endDate: nil)
        }
        
        return WidgetData(profileName: name, profileIcon: icon, profileColor: color, strictness: strictness, endDate: endDate)
    }
    
    static func loadUpcomingProfile() -> (name: String, startTime: String)? {
        let defaults = UserDefaults(suiteName: "group.com.focuscage.app")
        guard let data = defaults?.data(forKey: "shared_focuscage_profiles") else { return nil }
        
        struct MinimalProfile: Codable {
            let name: String
            let isEnabled: Bool
            let schedule: MinimalSchedule
        }
        struct MinimalSchedule: Codable {
            let startTime: DateComponents
            let endTime: DateComponents
            let activeDays: Set<Int>
        }
        
        guard let profiles = try? JSONDecoder().decode([MinimalProfile].self, from: data) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        let upcoming = profiles
            .filter { $0.isEnabled && $0.schedule.activeDays.contains(currentWeekday) }
            .filter {
                let startMinutes = ($0.schedule.startTime.hour ?? 0) * 60 + ($0.schedule.startTime.minute ?? 0)
                return startMinutes > currentMinutes
            }
            .sorted {
                let s1 = ($0.schedule.startTime.hour ?? 0) * 60 + ($0.schedule.startTime.minute ?? 0)
                let s2 = ($1.schedule.startTime.hour ?? 0) * 60 + ($1.schedule.startTime.minute ?? 0)
                return s1 < s2
            }
            .first
        
        guard let next = upcoming else { return nil }
        let hour = next.schedule.startTime.hour ?? 0
        let minute = next.schedule.startTime.minute ?? 0
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let date = calendar.date(from: components) ?? now
        return (name: next.name, startTime: formatter.string(from: date))
    }

    static func loadNextSession(now: Date = Date()) -> (startDate: Date, data: WidgetData)? {
        let defaults = UserDefaults(suiteName: "group.com.focuscage.app")
        guard let data = defaults?.data(forKey: "shared_focuscage_profiles") else { return nil }

        struct MinimalProfile: Codable {
            let name: String
            let iconName: String
            let color: String
            let strictnessLevel: String
            let isEnabled: Bool
            let schedule: MinimalSchedule
        }
        struct MinimalSchedule: Codable {
            let startTime: DateComponents
            let endTime: DateComponents
            let activeDays: Set<Int>
        }

        guard let profiles = try? JSONDecoder().decode([MinimalProfile].self, from: data) else { return nil }

        let enabled = profiles.filter { $0.isEnabled }
        guard !enabled.isEmpty else { return nil }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        var best: (startDate: Date, endDate: Date, profile: MinimalProfile)?

        for profile in enabled {
            let startHour = profile.schedule.startTime.hour ?? 0
            let startMinute = profile.schedule.startTime.minute ?? 0
            let endHour = profile.schedule.endTime.hour ?? 0
            let endMinute = profile.schedule.endTime.minute ?? 0

            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
                let weekday = calendar.component(.weekday, from: day)
                guard profile.schedule.activeDays.contains(weekday) else { continue }

                var startComponents = calendar.dateComponents([.year, .month, .day], from: day)
                startComponents.hour = startHour
                startComponents.minute = startMinute
                guard let startDate = calendar.date(from: startComponents) else { continue }

                var endComponents = calendar.dateComponents([.year, .month, .day], from: day)
                endComponents.hour = endHour
                endComponents.minute = endMinute
                var endDate = calendar.date(from: endComponents) ?? startDate
                if endDate <= startDate {
                    endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                }

                if startDate <= now, now < endDate {
                    best = (startDate: startDate, endDate: endDate, profile: profile)
                    break
                }

                guard startDate > now else { continue }

                if let currentBest = best {
                    if startDate < currentBest.startDate {
                        best = (startDate: startDate, endDate: endDate, profile: profile)
                    }
                } else {
                    best = (startDate: startDate, endDate: endDate, profile: profile)
                }
            }

            if let currentBest = best, currentBest.startDate <= now, now < currentBest.endDate {
                break
            }
        }

        guard let session = best else { return nil }

        let widgetData = WidgetData(
            profileName: session.profile.name,
            profileIcon: session.profile.iconName,
            profileColor: session.profile.color,
            strictness: session.profile.strictnessLevel,
            endDate: session.endDate
        )

        return (startDate: session.startDate, data: widgetData)
    }
}

// MARK: - Timeline Provider

struct FocusCageProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusCageEntry {
        FocusCageEntry(date: Date(), data: WidgetData(profileName: "Work Focus", profileIcon: "lock.fill", profileColor: "indigo", strictness: "strict", endDate: Date().addingTimeInterval(3600)))
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusCageEntry) -> ()) {
        let entry = FocusCageEntry(date: Date(), data: WidgetData.load())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusCageEntry>) -> ()) {
        let now = Date()
        let loaded = WidgetData.load()
        var entries: [FocusCageEntry] = []

        entries.append(FocusCageEntry(date: now, data: loaded))

        if let endDate = loaded.endDate, endDate > now {
            let expiredData = WidgetData(profileName: nil, profileIcon: nil, profileColor: nil, strictness: nil, endDate: nil)
            entries.append(FocusCageEntry(date: endDate, data: expiredData))
            completion(Timeline(entries: entries, policy: .atEnd))
            return
        }

        if let next = WidgetData.loadNextSession(now: now) {
            if next.startDate <= now {
                entries[0] = FocusCageEntry(date: now, data: next.data)
                if let endDate = next.data.endDate, endDate > now {
                    let expiredData = WidgetData(profileName: nil, profileIcon: nil, profileColor: nil, strictness: nil, endDate: nil)
                    entries.append(FocusCageEntry(date: endDate, data: expiredData))
                }
            } else {
                entries.append(FocusCageEntry(date: next.startDate, data: next.data))
                if let endDate = next.data.endDate, endDate > next.startDate {
                    let expiredData = WidgetData(profileName: nil, profileIcon: nil, profileColor: nil, strictness: nil, endDate: nil)
                    entries.append(FocusCageEntry(date: endDate, data: expiredData))
                }
            }
            completion(Timeline(entries: entries, policy: .atEnd))
            return
        }

        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(300))))
    }
}

struct FocusCageEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Widget Views

struct FocusCageSmallView: View {
    var entry: FocusCageEntry
    
    var body: some View {
        if entry.data.isActive {
            activeSmallView
        } else {
            inactiveSmallView
        }
    }
    
    private var activeSmallView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: entry.data.profileIcon ?? "lock.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(entry.data.color)
                
                Text(entry.data.profileName ?? "Focus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            
            if let endDate = entry.data.endDate {
                Text(endDate, style: .timer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.data.color)
                    .monospacedDigit()
            }
            
            HStack(spacing: 4) {
                Image(systemName: strictnessIcon)
                    .font(.caption2)
                Text(entry.data.strictness?.capitalized ?? "")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }
    
    private var inactiveSmallView: some View {
        VStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundStyle(.secondary)
            
            Text("Free Time")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(Date(), style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var strictnessIcon: String {
        switch entry.data.strictness {
        case "locked": return "lock.fill"
        case "strict": return "shield.fill"
        default: return "lock.open.fill"
        }
    }
}

struct FocusCageMediumView: View {
    var entry: FocusCageEntry
    
    var body: some View {
        if entry.data.isActive {
            activeMediumView
        } else {
            inactiveMediumView
        }
    }
    
    private var activeMediumView: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(entry.data.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: entry.data.profileIcon ?? "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(entry.data.color)
                }
                
                Text(entry.data.profileName ?? "Focus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Focus Session Active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let endDate = entry.data.endDate {
                    Text(endDate, style: .timer)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.data.color)
                        .monospacedDigit()
                    
                    Text("Ends at \(endDate, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    private var inactiveMediumView: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("Free Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let upcoming = WidgetData.loadUpcomingProfile() {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(upcoming.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(upcoming.startTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("No upcoming sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct FocusCageLockScreenView: View {
    var entry: FocusCageEntry
    
    var body: some View {
        if entry.data.isActive {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                    Text(entry.data.profileName ?? "Focus")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                if let endDate = entry.data.endDate {
                    Text(endDate, style: .timer)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.caption)
                    Text("Free Time")
                        .font(.caption)
                }
                Text(Date(), style: .time)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Widget Definition

struct FocusCageWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusCageEntry
    
    var body: some View {
        switch family {
        case .systemMedium:
            FocusCageMediumView(entry: entry)
        case .accessoryRectangular:
            FocusCageLockScreenView(entry: entry)
        default:
            FocusCageSmallView(entry: entry)
        }
    }
}

struct FocusCageWidget: Widget {
    let kind: String = "FocusCageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusCageProvider()) { entry in
            if #available(iOS 17.0, *) {
                FocusCageWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                FocusCageWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Focus Session")
        .description("Shows your current focus session status and remaining time.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    FocusCageWidget()
} timeline: {
    FocusCageEntry(date: .now, data: WidgetData(profileName: "Work Focus", profileIcon: "lock.fill", profileColor: "indigo", strictness: "strict", endDate: Date().addingTimeInterval(3600)))
    FocusCageEntry(date: .now, data: WidgetData(profileName: nil, profileIcon: nil, profileColor: nil, strictness: nil, endDate: nil))
}
