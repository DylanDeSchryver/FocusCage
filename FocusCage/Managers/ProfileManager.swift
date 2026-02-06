import Foundation
import Combine
import DeviceActivity

class ProfileManager: ObservableObject {
    @Published var profiles: [FocusProfile] = []
    @Published var activeProfileId: UUID?
    @Published var nuclearActiveProfileId: UUID?
    @Published var nuclearEndDate: Date?
    @Published var isCooldownActive = false
    @Published var cooldownEndDate: Date?
    @Published var cooldownProfileId: UUID?
    
    private let profilesKey = "focuscage_profiles"
    private let activeProfileKey = "focuscage_active_profile"
    private let nuclearEndKey = "focuscage_nuclear_end"
    private let nuclearProfileKey = "focuscage_nuclear_profile"
    private let activityCenter = DeviceActivityCenter()
    private var timer: Timer?
    private var cooldownTimer: Timer?
    private var unlockExpiryTimer: Timer?
    private var nuclearTimer: Timer?
    
    init() {
        loadProfiles()
        loadNuclearState()
        startScheduleMonitor()
        scheduleAllProfiles()
    }
    
    deinit {
        timer?.invalidate()
        cooldownTimer?.invalidate()
        unlockExpiryTimer?.invalidate()
        nuclearTimer?.invalidate()
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
    
    // MARK: - Strictness & Unlock Logic
    
    /// Whether a profile can be freely toggled right now
    func canFreelyDisable(_ profile: FocusProfile) -> Bool {
        guard profile.schedule.isActiveNow() && activeProfileId == profile.id else { return true }
        return profile.strictnessLevel == .standard
    }
    
    /// Whether the profile is currently in a temporary unlock window
    func isTemporarilyUnlocked(_ profile: FocusProfile) -> Bool {
        guard let endDate = profile.temporaryUnlockEndDate else { return false }
        return Date() < endDate
    }
    
    /// Remaining unlocks for a profile in this session
    func remainingUnlocks(for profile: FocusProfile) -> Int {
        let used = profileWithResetUnlocks(profile).dailyUnlocksUsed
        return max(0, profile.strictnessLevel.maxDailyUnlocks - used)
    }
    
    /// Returns the profile with daily unlocks reset if the session has changed
    private func profileWithResetUnlocks(_ profile: FocusProfile) -> FocusProfile {
        var p = profile
        if let lastReset = p.lastUnlockResetDate {
            // Reset unlocks when the profile deactivates and reactivates (new session)
            if !p.schedule.isActiveNow() {
                p.dailyUnlocksUsed = 0
                p.lastUnlockResetDate = nil
            }
        }
        return p
    }
    
    /// Start a cooldown for a Strict profile. Returns false if no unlocks remain.
    func requestUnlock(for profileId: UUID) -> Bool {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else { return false }
        
        let profile = profiles[index]
        guard profile.strictnessLevel == .strict else { return false }
        
        // Reset unlocks if needed (new session)
        resetDailyUnlocksIfNeeded(for: index)
        
        guard profiles[index].dailyUnlocksUsed < profile.strictnessLevel.maxDailyUnlocks else { return false }
        
        // Start cooldown
        let endDate = Date().addingTimeInterval(profile.strictnessLevel.cooldownDuration)
        profiles[index].cooldownEndDate = endDate
        cooldownEndDate = endDate
        cooldownProfileId = profileId
        isCooldownActive = true
        saveProfiles()
        
        // Timer to complete cooldown
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: profile.strictnessLevel.cooldownDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.completeCooldown(for: profileId)
            }
        }
        
        return true
    }
    
    /// Cancel an in-progress cooldown
    func cancelCooldown() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        isCooldownActive = false
        cooldownEndDate = nil
        
        if let pid = cooldownProfileId,
           let index = profiles.firstIndex(where: { $0.id == pid }) {
            profiles[index].cooldownEndDate = nil
            saveProfiles()
        }
        cooldownProfileId = nil
    }
    
    /// Called when cooldown completes — temporarily disable blocking
    func completeCooldown(for profileId: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else { return }
        
        isCooldownActive = false
        cooldownEndDate = nil
        cooldownProfileId = nil
        cooldownTimer?.invalidate()
        
        profiles[index].dailyUnlocksUsed += 1
        profiles[index].cooldownEndDate = nil
        
        let unlockEnd = Date().addingTimeInterval(profiles[index].strictnessLevel.unlockDuration)
        profiles[index].temporaryUnlockEndDate = unlockEnd
        saveProfiles()
        
        // Deactivate blocking temporarily
        NotificationCenter.default.post(name: .profileDeactivated, object: nil)
        print("[ProfileManager] Temporary unlock started for '\(profiles[index].name)', expires at \(unlockEnd)")
        
        // Schedule re-engagement
        unlockExpiryTimer?.invalidate()
        unlockExpiryTimer = Timer.scheduledTimer(withTimeInterval: profiles[index].strictnessLevel.unlockDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.expireTemporaryUnlock(for: profileId)
            }
        }
    }
    
    /// Re-engage blocking after temporary unlock expires
    func expireTemporaryUnlock(for profileId: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else { return }
        
        profiles[index].temporaryUnlockEndDate = nil
        unlockExpiryTimer?.invalidate()
        unlockExpiryTimer = nil
        saveProfiles()
        
        // Re-check schedules to re-engage blocking if still in scheduled window
        checkSchedules()
        print("[ProfileManager] Temporary unlock expired for '\(profiles[index].name)'")
    }
    
    private func resetDailyUnlocksIfNeeded(for index: Int) {
        if let lastReset = profiles[index].lastUnlockResetDate {
            // If profile was inactive since last reset, reset the counter
            if !profiles[index].schedule.isActiveNow() {
                profiles[index].dailyUnlocksUsed = 0
                profiles[index].lastUnlockResetDate = nil
            }
        } else {
            // First unlock of this session
            profiles[index].lastUnlockResetDate = Date()
        }
    }
    
    // MARK: - Nuclear Button
    
    /// Activate nuclear blocking for 1 hour using the first available profile
    func activateNuclearButton(for profileId: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else { return }
        
        let endDate = Date().addingTimeInterval(60 * 60) // 1 hour
        nuclearEndDate = endDate
        nuclearActiveProfileId = profileId
        
        // Persist nuclear state
        UserDefaults.standard.set(endDate.timeIntervalSince1970, forKey: nuclearEndKey)
        UserDefaults.standard.set(profileId.uuidString, forKey: nuclearProfileKey)
        
        // Force activate this profile
        activeProfileId = profileId
        saveActiveState()
        NotificationCenter.default.post(name: .profileActivated, object: profiles[index])
        print("[ProfileManager] Nuclear button activated for '\(profiles[index].name)' until \(endDate)")
        
        // Timer to deactivate
        nuclearTimer?.invalidate()
        nuclearTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.deactivateNuclearButton()
            }
        }
    }
    
    func deactivateNuclearButton() {
        nuclearTimer?.invalidate()
        nuclearTimer = nil
        nuclearEndDate = nil
        nuclearActiveProfileId = nil
        
        UserDefaults.standard.removeObject(forKey: nuclearEndKey)
        UserDefaults.standard.removeObject(forKey: nuclearProfileKey)
        
        // Re-check what should actually be active now
        checkSchedules()
        print("[ProfileManager] Nuclear button deactivated")
    }
    
    var isNuclearActive: Bool {
        guard let endDate = nuclearEndDate else { return false }
        return Date() < endDate
    }
    
    private func loadNuclearState() {
        let endTimestamp = UserDefaults.standard.double(forKey: nuclearEndKey)
        if endTimestamp > 0 {
            let endDate = Date(timeIntervalSince1970: endTimestamp)
            if Date() < endDate {
                nuclearEndDate = endDate
                if let profileIdStr = UserDefaults.standard.string(forKey: nuclearProfileKey),
                   let profileId = UUID(uuidString: profileIdStr) {
                    nuclearActiveProfileId = profileId
                    
                    // Resume nuclear timer for remaining time
                    let remaining = endDate.timeIntervalSinceNow
                    nuclearTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.deactivateNuclearButton()
                        }
                    }
                }
            } else {
                // Nuclear expired while app was closed
                UserDefaults.standard.removeObject(forKey: nuclearEndKey)
                UserDefaults.standard.removeObject(forKey: nuclearProfileKey)
            }
        }
    }
    
    // MARK: - Locked Profile Delete Cooldown
    
    /// Whether a locked active profile can be deleted (requires 5-min cooldown tracked externally)
    func canDeleteLockedProfile(_ profile: FocusProfile) -> Bool {
        guard profile.strictnessLevel == .locked,
              profile.schedule.isActiveNow(),
              activeProfileId == profile.id else { return true }
        return false // Must go through delete cooldown flow
    }
    
    var activeProfile: FocusProfile? {
        guard let activeId = activeProfileId else { return nil }
        return profiles.first { $0.id == activeId }
    }
    
    var scheduledActiveProfiles: [FocusProfile] {
        profiles.filter { profile in
            profile.isEnabled && profile.schedule.isActiveNow() && !isTemporarilyUnlocked(profile)
        }
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
        // Don't override nuclear mode
        if isNuclearActive {
            if let nuclearId = nuclearActiveProfileId, activeProfileId != nuclearId {
                activeProfileId = nuclearId
                saveActiveState()
                if let profile = profiles.first(where: { $0.id == nuclearId }) {
                    NotificationCenter.default.post(name: .profileActivated, object: profile)
                }
            }
            return
        }
        
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
