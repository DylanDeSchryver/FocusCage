import Foundation

/// Shared data layer using App Group UserDefaults for communication
/// between the main app and the DeviceActivityMonitor extension.
class SharedDefaults {
    static let appGroup = "group.com.focuscage.app"
    static let profilesKey = "shared_focuscage_profiles"
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }
    
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
