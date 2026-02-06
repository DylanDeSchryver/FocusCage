import Foundation
import Combine
import DeviceActivity

class ProfileManager: ObservableObject {
    @Published var profiles: [FocusProfile] = []
    @Published var activeProfileId: UUID?
    
    private let profilesKey = "focuscage_profiles"
    private let activeProfileKey = "focuscage_active_profile"
    private let activityCenter = DeviceActivityCenter()
    private var timer: Timer?
    
    init() {
        loadProfiles()
        startScheduleMonitor()
        scheduleAllProfiles()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            do {
                profiles = try JSONDecoder().decode([FocusProfile].self, from: data)
            } catch {
                print("[ProfileManager] Failed to load profiles: \(error)")
                profiles = []
            }
        }
        
        if let activeIdString = UserDefaults.standard.string(forKey: activeProfileKey),
           let activeId = UUID(uuidString: activeIdString) {
            activeProfileId = activeId
        }
        
        // Always sync to shared storage for the extension
        SharedDefaults.saveProfiles(profiles)
    }
    
    func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("[ProfileManager] Failed to save profiles: \(error)")
        }
        
        if let activeId = activeProfileId {
            UserDefaults.standard.set(activeId.uuidString, forKey: activeProfileKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileKey)
        }
        
        // Sync to shared storage for the extension
        SharedDefaults.saveProfiles(profiles)
        
        // Re-schedule all profiles when data changes
        scheduleAllProfiles()
    }
    
    func addProfile(_ profile: FocusProfile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    func updateProfile(_ profile: FocusProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }
    
    func deleteProfile(_ profile: FocusProfile) {
        // Stop monitoring this profile
        let activityName = DeviceActivityName(profile.id.uuidString)
        activityCenter.stopMonitoring([activityName])
        
        profiles.removeAll { $0.id == profile.id }
        if activeProfileId == profile.id {
            activeProfileId = nil
        }
        saveProfiles()
    }
    
    func toggleProfile(_ profile: FocusProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index].isEnabled.toggle()
            saveProfiles()
        }
    }
    
    var activeProfile: FocusProfile? {
        guard let activeId = activeProfileId else { return nil }
        return profiles.first { $0.id == activeId }
    }
    
    var scheduledActiveProfiles: [FocusProfile] {
        profiles.filter { $0.isEnabled && $0.schedule.isActiveNow() }
    }
    
    // MARK: - DeviceActivity Scheduling
    
    func scheduleAllProfiles() {
        // Stop all existing monitoring first
        activityCenter.stopMonitoring()
        
        for profile in profiles where profile.isEnabled {
            scheduleProfile(profile)
        }
        
        print("[ProfileManager] Scheduled \(profiles.filter { $0.isEnabled }.count) profiles with DeviceActivityCenter")
    }
    
    private func scheduleProfile(_ profile: FocusProfile) {
        let activityName = DeviceActivityName(profile.id.uuidString)
        
        let startHour = profile.schedule.startTime.hour ?? 0
        let startMinute = profile.schedule.startTime.minute ?? 0
        let endHour = profile.schedule.endTime.hour ?? 0
        let endMinute = profile.schedule.endTime.minute ?? 0
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute),
            intervalEnd: DateComponents(hour: endHour, minute: endMinute),
            repeats: true
        )
        
        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
            print("[ProfileManager] Scheduled monitoring for '\(profile.name)' (\(startHour):\(String(format: "%02d", startMinute)) - \(endHour):\(String(format: "%02d", endMinute)))")
        } catch {
            print("[ProfileManager] Failed to schedule monitoring for '\(profile.name)': \(error)")
        }
    }
    
    // MARK: - Foreground Schedule Monitor (belt-and-suspenders)
    
    func startScheduleMonitor() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
        // Immediate check on startup
        checkSchedules()
    }
    
    func checkSchedules() {
        let nowActive = scheduledActiveProfiles
        
        if let firstActive = nowActive.first {
            if activeProfileId != firstActive.id {
                activeProfileId = firstActive.id
                saveActiveState()
                NotificationCenter.default.post(name: .profileActivated, object: firstActive)
                print("[ProfileManager] Profile activated: \(firstActive.name)")
            }
        } else if activeProfileId != nil {
            let previousId = activeProfileId
            activeProfileId = nil
            saveActiveState()
            NotificationCenter.default.post(name: .profileDeactivated, object: previousId)
            print("[ProfileManager] Profile deactivated")
        }
    }
    
    private func saveActiveState() {
        if let activeId = activeProfileId {
            UserDefaults.standard.set(activeId.uuidString, forKey: activeProfileKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileKey)
        }
    }
    
    func getTimeUntilNextChange() -> String? {
        guard let active = activeProfile else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let endHour = active.schedule.endTime.hour ?? 0
        let endMinute = active.schedule.endTime.minute ?? 0
        
        let currentTotal = currentHour * 60 + currentMinute
        let endTotal = endHour * 60 + endMinute
        
        let remaining = endTotal - currentTotal
        
        if remaining <= 0 { return nil }
        
        let hours = remaining / 60
        let minutes = remaining % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}

extension Notification.Name {
    static let profileActivated = Notification.Name("profileActivated")
    static let profileDeactivated = Notification.Name("profileDeactivated")
}
