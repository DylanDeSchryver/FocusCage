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
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
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
            var endComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            endComponents.hour = endHour
            endComponents.minute = endMinute
            if let endDate = calendar.date(from: endComponents) {
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
