import Foundation

/// Shared data layer using App Group UserDefaults for communication
/// between the main app and the DeviceActivityMonitor extension.
class SharedDefaults {
    static let appGroup = "group.com.focuscage.app"
    static let profilesKey = "shared_focuscage_profiles"
    static let activeProfileKey = "shared_active_profile_id"
    static let activeEndTimeKey = "shared_active_end_time"
    static let activeProfileNameKey = "shared_active_profile_name"
    static let activeProfileIconKey = "shared_active_profile_icon"
    static let activeProfileColorKey = "shared_active_profile_color"
    static let activeStrictnessKey = "shared_active_strictness"

    static let nextProfileNameKey = "shared_next_profile_name"
    static let nextProfileIconKey = "shared_next_profile_icon"
    static let nextProfileColorKey = "shared_next_profile_color"
    static let nextProfileStrictnessKey = "shared_next_profile_strictness"
    static let nextProfileStartTimeKey = "shared_next_profile_start_time"
    static let nextProfileEndTimeKey = "shared_next_profile_end_time"

    static let next2ProfileNameKey = "shared_next2_profile_name"
    static let next2ProfileIconKey = "shared_next2_profile_icon"
    static let next2ProfileColorKey = "shared_next2_profile_color"
    static let next2ProfileStrictnessKey = "shared_next2_profile_strictness"
    static let next2ProfileStartTimeKey = "shared_next2_profile_start_time"
    static let next2ProfileEndTimeKey = "shared_next2_profile_end_time"

    static let liveActivityLastEventKey = "shared_live_activity_last_event"
    static let liveActivityLastMessageKey = "shared_live_activity_last_message"
    static let liveActivityLastTimestampKey = "shared_live_activity_last_timestamp"

    static let widgetReloadLastSourceKey = "shared_widget_reload_last_source"
    static let widgetReloadLastTimestampKey = "shared_widget_reload_last_timestamp"

    static let monitorLastEventKey = "shared_monitor_last_event"
    static let monitorLastActivityKey = "shared_monitor_last_activity"
    static let monitorLastTimestampKey = "shared_monitor_last_timestamp"
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    static func activityRawValue(for profileId: UUID) -> String {
        "profile_" + profileId.uuidString.replacingOccurrences(of: "-", with: "")
    }

    static func saveMonitorEvent(event: String, activity: String, date: Date = Date()) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(event, forKey: monitorLastEventKey)
        defaults.set(activity, forKey: monitorLastActivityKey)
        defaults.set(date.timeIntervalSince1970, forKey: monitorLastTimestampKey)
    }

    static func loadLastMonitorEvent() -> (event: String, activity: String, date: Date)? {
        guard let defaults = sharedDefaults,
              let event = defaults.string(forKey: monitorLastEventKey),
              let activity = defaults.string(forKey: monitorLastActivityKey) else {
            return nil
        }
        let ts = defaults.double(forKey: monitorLastTimestampKey)
        guard ts > 0 else { return nil }
        return (event: event, activity: activity, date: Date(timeIntervalSince1970: ts))
    }

    static func saveLiveActivityEvent(event: String, message: String? = nil, date: Date = Date()) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(event, forKey: liveActivityLastEventKey)
        if let message {
            defaults.set(message, forKey: liveActivityLastMessageKey)
        } else {
            defaults.removeObject(forKey: liveActivityLastMessageKey)
        }
        defaults.set(date.timeIntervalSince1970, forKey: liveActivityLastTimestampKey)
    }

    static func loadLastLiveActivityEvent() -> (event: String, message: String?, date: Date)? {
        guard let defaults = sharedDefaults,
              let event = defaults.string(forKey: liveActivityLastEventKey) else {
            return nil
        }
        let message = defaults.string(forKey: liveActivityLastMessageKey)
        let ts = defaults.double(forKey: liveActivityLastTimestampKey)
        guard ts > 0 else { return nil }
        return (event: event, message: message, date: Date(timeIntervalSince1970: ts))
    }

    static func saveWidgetReloadEvent(source: String, date: Date = Date()) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(source, forKey: widgetReloadLastSourceKey)
        defaults.set(date.timeIntervalSince1970, forKey: widgetReloadLastTimestampKey)
    }

    static func loadLastWidgetReloadEvent() -> (source: String, date: Date)? {
        guard let defaults = sharedDefaults,
              let source = defaults.string(forKey: widgetReloadLastSourceKey) else {
            return nil
        }
        let ts = defaults.double(forKey: widgetReloadLastTimestampKey)
        guard ts > 0 else { return nil }
        return (source: source, date: Date(timeIntervalSince1970: ts))
    }
    
    // MARK: - Active State (for Widget)
    
    static func saveActiveState(profile: FocusProfile?) {
        guard let defaults = sharedDefaults else { return }
        if let profile = profile {
            defaults.set(profile.id.uuidString, forKey: activeProfileKey)
            defaults.set(profile.name, forKey: activeProfileNameKey)
            defaults.set(profile.iconName, forKey: activeProfileIconKey)
            defaults.set(profile.color.rawValue, forKey: activeProfileColorKey)
            defaults.set(profile.strictnessLevel.rawValue, forKey: activeStrictnessKey)
            
            let endHour = profile.schedule.endTime.hour ?? 0
            let endMinute = profile.schedule.endTime.minute ?? 0
            let calendar = Calendar.current
            let now = Date()
            var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
            endComponents.hour = endHour
            endComponents.minute = endMinute
            if let rawEndDate = calendar.date(from: endComponents) {
                let endDate = rawEndDate <= now ? (calendar.date(byAdding: .day, value: 1, to: rawEndDate) ?? rawEndDate) : rawEndDate
                defaults.set(endDate.timeIntervalSince1970, forKey: activeEndTimeKey)
            }
        } else {
            defaults.removeObject(forKey: activeProfileKey)
            defaults.removeObject(forKey: activeProfileNameKey)
            defaults.removeObject(forKey: activeProfileIconKey)
            defaults.removeObject(forKey: activeProfileColorKey)
            defaults.removeObject(forKey: activeStrictnessKey)
            defaults.removeObject(forKey: activeEndTimeKey)
        }
    }
    
    static func loadActiveState() -> (name: String, icon: String, color: String, strictness: String, endDate: Date)? {
        guard let defaults = sharedDefaults,
              let name = defaults.string(forKey: activeProfileNameKey),
              let icon = defaults.string(forKey: activeProfileIconKey),
              let color = defaults.string(forKey: activeProfileColorKey),
              let strictness = defaults.string(forKey: activeStrictnessKey) else {
            return nil
        }
        let endTimestamp = defaults.double(forKey: activeEndTimeKey)
        guard endTimestamp > 0 else { return nil }
        let endDate = Date(timeIntervalSince1970: endTimestamp)
        guard endDate > Date() else { return nil }
        return (name: name, icon: icon, color: color, strictness: strictness, endDate: endDate)
    }

    static func saveUpcomingSessions(_ sessions: [(profile: FocusProfile, startDate: Date, endDate: Date)]?) {
        guard let defaults = sharedDefaults else { return }

        if let first = sessions?.first {
            defaults.set(first.profile.name, forKey: nextProfileNameKey)
            defaults.set(first.profile.iconName, forKey: nextProfileIconKey)
            defaults.set(first.profile.color.rawValue, forKey: nextProfileColorKey)
            defaults.set(first.profile.strictnessLevel.rawValue, forKey: nextProfileStrictnessKey)
            defaults.set(first.startDate.timeIntervalSince1970, forKey: nextProfileStartTimeKey)
            defaults.set(first.endDate.timeIntervalSince1970, forKey: nextProfileEndTimeKey)
        } else {
            defaults.removeObject(forKey: nextProfileNameKey)
            defaults.removeObject(forKey: nextProfileIconKey)
            defaults.removeObject(forKey: nextProfileColorKey)
            defaults.removeObject(forKey: nextProfileStrictnessKey)
            defaults.removeObject(forKey: nextProfileStartTimeKey)
            defaults.removeObject(forKey: nextProfileEndTimeKey)
        }

        if let second = sessions?.dropFirst().first {
            defaults.set(second.profile.name, forKey: next2ProfileNameKey)
            defaults.set(second.profile.iconName, forKey: next2ProfileIconKey)
            defaults.set(second.profile.color.rawValue, forKey: next2ProfileColorKey)
            defaults.set(second.profile.strictnessLevel.rawValue, forKey: next2ProfileStrictnessKey)
            defaults.set(second.startDate.timeIntervalSince1970, forKey: next2ProfileStartTimeKey)
            defaults.set(second.endDate.timeIntervalSince1970, forKey: next2ProfileEndTimeKey)
        } else {
            defaults.removeObject(forKey: next2ProfileNameKey)
            defaults.removeObject(forKey: next2ProfileIconKey)
            defaults.removeObject(forKey: next2ProfileColorKey)
            defaults.removeObject(forKey: next2ProfileStrictnessKey)
            defaults.removeObject(forKey: next2ProfileStartTimeKey)
            defaults.removeObject(forKey: next2ProfileEndTimeKey)
        }
    }

    static func refreshUpcomingSessions(from profiles: [FocusProfile], now: Date = Date()) {
        let computed = computeUpcomingSessions(from: profiles, now: now, limit: 2)
        saveUpcomingSessions(computed.isEmpty ? nil : computed)
    }

    static func computeUpcomingSessions(from profiles: [FocusProfile], now: Date = Date(), limit: Int) -> [(profile: FocusProfile, startDate: Date, endDate: Date)] {
        guard limit > 0 else { return [] }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        var candidates: [(profile: FocusProfile, startDate: Date, endDate: Date)] = []

        for profile in profiles where profile.isEnabled {
            let startHour = profile.schedule.startTime.hour ?? 0
            let startMinute = profile.schedule.startTime.minute ?? 0
            let endHour = profile.schedule.endTime.hour ?? 0
            let endMinute = profile.schedule.endTime.minute ?? 0

            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
                let weekday = calendar.component(.weekday, from: day)
                guard let weekdayEnum = Weekday(rawValue: weekday), profile.schedule.activeDays.contains(weekdayEnum) else { continue }

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

                guard startDate > now else { continue }

                candidates.append((profile: profile, startDate: startDate, endDate: endDate))
            }
        }

        candidates.sort { $0.startDate < $1.startDate }
        if candidates.count > limit {
            return Array(candidates.prefix(limit))
        }
        return candidates
    }
    
    // MARK: - Profiles
    
    static func saveProfiles(_ profiles: [FocusProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            sharedDefaults?.set(data, forKey: profilesKey)
        } catch {
            print("[SharedDefaults] Failed to save profiles: \(error)")
        }
    }
    
    static func loadProfiles() -> [FocusProfile] {
        guard let data = sharedDefaults?.data(forKey: profilesKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([FocusProfile].self, from: data)
        } catch {
            print("[SharedDefaults] Failed to load profiles: \(error)")
            return []
        }
    }
}
