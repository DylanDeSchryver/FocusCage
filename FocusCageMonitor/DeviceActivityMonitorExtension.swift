import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import WidgetKit
import ActivityKit

struct FocusCageWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingMinutes: Int
        var isLocked: Bool
    }

    var profileName: String
    var profileIcon: String
    var profileColorHex: String
    var endTime: Date
}

class FocusCageMonitor: DeviceActivityMonitor {
    
    /// Use a named ManagedSettingsStore per activity so each profile's blocking
    /// is independent and doesn't conflict with the main app's default store.
    private func store(for activity: DeviceActivityName) -> ManagedSettingsStore {
        ManagedSettingsStore(named: .init(rawValue: activity.rawValue))
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        print("[FocusCageMonitor] intervalDidStart for: \(activity.rawValue)")
        SharedDefaults.saveMonitorEvent(event: "intervalDidStart", activity: activity.rawValue)
        
        let profiles = SharedDefaults.loadProfiles()
        
        guard let profile = profiles.first(where: { SharedDefaults.activityRawValue(for: $0.id) == activity.rawValue }),
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
        
        // 1. Always apply to the named store (correctness)
        applyBlocking(for: profile, activity: activity)
        
        // 2. Handle Default Store for robustness
        // Find all OTHER currently active profiles
        let otherActiveProfiles = profiles.filter { p in
            p.id != profile.id && p.isEnabled && p.schedule.activeDays.contains(weekday) && p.schedule.isActiveNow()
        }
        
        if otherActiveProfiles.isEmpty {
            // If we are the ONLY active profile, enforce on Default Store too.
            // This fixes the issue where background blocking might fail if named stores are ignored.
            applyBlockingToDefaultStore(for: profile)
            print("[FocusCageMonitor] Applied to Default Store for profile: \(profile.name)")
        } else {
            // If multiple profiles are active, clear Default Store to avoid conflicts/stale state
            // and rely on the union of Named Stores.
            ManagedSettingsStore().clearAllSettings()
            print("[FocusCageMonitor] Multiple profiles active, cleared Default Store (relying on Named Stores)")
        }
        
        // Update shared state so the widget reflects the active session
        SharedDefaults.saveActiveState(profile: profile)
        WidgetCenter.shared.reloadAllTimelines()

        startLiveActivity(for: profile)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        print("[FocusCageMonitor] intervalDidEnd for: \(activity.rawValue)")
        SharedDefaults.saveMonitorEvent(event: "intervalDidEnd", activity: activity.rawValue)
        
        // Clear this activity's named store
        let activityStore = store(for: activity)
        activityStore.clearAllSettings()
        print("[FocusCageMonitor] Cleared store for activity: \(activity.rawValue)")
        
        // Check what else is active
        let profiles = SharedDefaults.loadProfiles()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: Date())
        
        // Find all currently active profiles (excluding the one that just ended)
        let activeProfiles = profiles.filter { p in
            p.id.uuidString != activity.rawValue &&
            p.isEnabled &&
            p.schedule.activeDays.contains(where: { $0.rawValue == currentWeekday }) &&
            p.schedule.isActiveNow()
        }
        
        if activeProfiles.isEmpty {
            // No profiles active -> Clear Default Store
            ManagedSettingsStore().clearAllSettings()
            SharedDefaults.saveActiveState(profile: nil)
            print("[FocusCageMonitor] No active profiles, cleared Default Store")

            Task { await endLiveActivities() }
        } else if activeProfiles.count == 1, let activeProfile = activeProfiles.first {
            // Exactly one active -> Promote to Default Store
            let otherActivity = DeviceActivityName(SharedDefaults.activityRawValue(for: activeProfile.id))
            applyBlocking(for: activeProfile, activity: otherActivity) // Ensure named is set
            applyBlockingToDefaultStore(for: activeProfile) // Ensure default is set
            SharedDefaults.saveActiveState(profile: activeProfile)
            print("[FocusCageMonitor] One remaining profile active: \(activeProfile.name) (Applied to Default)")

            startLiveActivity(for: activeProfile)
        } else {
            // Multiple active -> Clear Default, ensure Named are set
            ManagedSettingsStore().clearAllSettings()
            // Re-assert named stores for all active (just in case)
            for profile in activeProfiles {
                let act = DeviceActivityName(SharedDefaults.activityRawValue(for: profile.id))
                applyBlocking(for: profile, activity: act)
            }
            // Pick one for the widget state (e.g. first)
            if let first = activeProfiles.first {
                SharedDefaults.saveActiveState(profile: first)
                startLiveActivity(for: first)
            }
            print("[FocusCageMonitor] Multiple remaining profiles, cleared Default Store")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startLiveActivity(for profile: FocusProfile) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[FocusCageMonitor] Live Activities not enabled")
            return
        }

        Task {
            await endLiveActivities()

            let now = Date()
            let endTime = liveActivityEndTime(for: profile, now: now)
            let remainingMinutes = max(0, Int(endTime.timeIntervalSince(now) / 60))

            let attributes = FocusCageWidgetAttributes(
                profileName: profile.name,
                profileIcon: profile.iconName,
                profileColorHex: profile.color.rawValue,
                endTime: endTime
            )

            let state = FocusCageWidgetAttributes.ContentState(
                remainingMinutes: remainingMinutes,
                isLocked: profile.strictnessLevel == .locked
            )

            let content = ActivityContent(state: state, staleDate: endTime)

            do {
                _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
                print("[FocusCageMonitor] Live Activity started for '\(profile.name)'")
            } catch {
                print("[FocusCageMonitor] Failed to start Live Activity: \(error)")
            }
        }
    }

    private func endLiveActivities() async {
        for activity in Activity<FocusCageWidgetAttributes>.activities {
            let finalState = FocusCageWidgetAttributes.ContentState(remainingMinutes: 0, isLocked: false)
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        print("[FocusCageMonitor] Live Activities ended")
    }

    private func liveActivityEndTime(for profile: FocusProfile, now: Date) -> Date {
        let calendar = Calendar.current
        let endHour = profile.schedule.endTime.hour ?? 0
        let endMinute = profile.schedule.endTime.minute ?? 0

        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = endHour
        endComponents.minute = endMinute

        let endDate = calendar.date(from: endComponents) ?? now

        // If schedule crosses midnight and our computed end is already in the past,
        // bump to the next day.
        if endDate <= now {
            return calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        return endDate
    }
    
    private func applyBlocking(for profile: FocusProfile, activity: DeviceActivityName) {
        let activityStore = store(for: activity)
        applyShields(to: activityStore, for: profile)
        print("[FocusCageMonitor] Blocking applied to Named Store for: \(profile.name)")
    }
    
    private func applyBlockingToDefaultStore(for profile: FocusProfile) {
        let defaultStore = ManagedSettingsStore()
        applyShields(to: defaultStore, for: profile)
    }
    
    private func applyShields(to store: ManagedSettingsStore, for profile: FocusProfile) {
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
    }
}
