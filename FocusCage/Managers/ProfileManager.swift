import Foundation
import Combine

class ProfileManager: ObservableObject {
    @Published var profiles: [FocusProfile] = []
    @Published var activeProfileId: UUID?
    
    private let profilesKey = "focuscage_profiles"
    private let activeProfileKey = "focuscage_active_profile"
    private var timer: Timer?
    
    init() {
        loadProfiles()
        startScheduleMonitor()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            do {
                profiles = try JSONDecoder().decode([FocusProfile].self, from: data)
            } catch {
                print("Failed to load profiles: \(error)")
                profiles = []
            }
        }
        
        if let activeIdString = UserDefaults.standard.string(forKey: activeProfileKey),
           let activeId = UUID(uuidString: activeIdString) {
            activeProfileId = activeId
        }
    }
    
    func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("Failed to save profiles: \(error)")
        }
        
        if let activeId = activeProfileId {
            UserDefaults.standard.set(activeId.uuidString, forKey: activeProfileKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileKey)
        }
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
    
    func startScheduleMonitor() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
        checkSchedules()
    }
    
    func checkSchedules() {
        let nowActive = scheduledActiveProfiles
        
        if let firstActive = nowActive.first {
            if activeProfileId != firstActive.id {
                activeProfileId = firstActive.id
                NotificationCenter.default.post(name: .profileActivated, object: firstActive)
            }
        } else if activeProfileId != nil {
            let previousId = activeProfileId
            activeProfileId = nil
            NotificationCenter.default.post(name: .profileDeactivated, object: previousId)
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
