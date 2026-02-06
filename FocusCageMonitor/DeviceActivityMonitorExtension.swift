import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class FocusCageMonitor: DeviceActivityMonitor {
    
    private let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        print("[FocusCageMonitor] intervalDidStart for: \(activity.rawValue)")
        
        let profiles = SharedDefaults.loadProfiles()
        
        guard let profile = profiles.first(where: { $0.id.uuidString == activity.rawValue }),
              profile.isEnabled else {
            print("[FocusCageMonitor] No matching enabled profile found for activity: \(activity.rawValue)")
            return
        }
        
        // Check if today is an active day for this profile
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: Date())
        guard let weekday = Weekday(rawValue: currentWeekday),
              profile.schedule.activeDays.contains(weekday) else {
            print("[FocusCageMonitor] Today is not an active day for profile: \(profile.name)")
            return
        }
        
        applyBlocking(for: profile)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        print("[FocusCageMonitor] intervalDidEnd for: \(activity.rawValue)")
        
        // Check if any OTHER profile should still be active
        let profiles = SharedDefaults.loadProfiles()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: Date())
        
        let stillActive = profiles.first { profile in
            guard profile.isEnabled,
                  profile.id.uuidString != activity.rawValue,
                  let weekday = Weekday(rawValue: currentWeekday),
                  profile.schedule.activeDays.contains(weekday) else {
                return false
            }
            return profile.schedule.isActiveNow()
        }
        
        if let activeProfile = stillActive {
            print("[FocusCageMonitor] Another profile is still active: \(activeProfile.name)")
            applyBlocking(for: activeProfile)
        } else {
            removeBlocking()
        }
    }
    
    private func applyBlocking(for profile: FocusProfile) {
        let selection = profile.blockedApps
        
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        
        let blockedDomains: Set<WebDomain> = Set(profile.blockedWebsites.map { WebDomain(domain: $0.domain) })
        if !blockedDomains.isEmpty {
            store.webContent.blockedByFilter = .specific(blockedDomains)
        } else {
            store.webContent.blockedByFilter = nil
        }
        
        print("[FocusCageMonitor] Blocking applied for profile: \(profile.name)")
    }
    
    private func removeBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.webContent.blockedByFilter = nil
        
        print("[FocusCageMonitor] All blocking removed")
    }
}
