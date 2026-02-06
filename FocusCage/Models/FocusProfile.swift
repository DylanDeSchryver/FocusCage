import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct FocusProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var iconName: String
    var color: ProfileColor
    var schedule: ProfileSchedule
    var isEnabled: Bool
    var blockedAppsData: Data?
    var blockedCategoriesData: Data?
    var blockedWebsites: [BlockedWebsite]
    var strictnessLevel: StrictnessLevel
    var dailyUnlocksUsed: Int
    var lastUnlockResetDate: Date?
    var cooldownEndDate: Date?
    var nuclearButtonEndDate: Date?
    var temporaryUnlockEndDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "lock.fill",
        color: ProfileColor = .indigo,
        schedule: ProfileSchedule = ProfileSchedule(),
        isEnabled: Bool = true,
        blockedWebsites: [BlockedWebsite] = [],
        strictnessLevel: StrictnessLevel = .strict
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.color = color
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.blockedAppsData = nil
        self.blockedCategoriesData = nil
        self.blockedWebsites = blockedWebsites
        self.strictnessLevel = strictnessLevel
        self.dailyUnlocksUsed = 0
        self.lastUnlockResetDate = nil
        self.cooldownEndDate = nil
        self.nuclearButtonEndDate = nil
        self.temporaryUnlockEndDate = nil
    }
    
    var blockedApps: FamilyActivitySelection {
        get {
            guard let data = blockedAppsData else {
                return FamilyActivitySelection()
            }
            do {
                return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            } catch {
                return FamilyActivitySelection()
            }
        }
        set {
            do {
                blockedAppsData = try JSONEncoder().encode(newValue)
            } catch {
                blockedAppsData = nil
            }
        }
    }
    
    static func == (lhs: FocusProfile, rhs: FocusProfile) -> Bool {
        lhs.id == rhs.id
    }
}

struct ProfileSchedule: Codable, Equatable {
    var startTime: DateComponents
    var endTime: DateComponents
    var activeDays: Set<Weekday>
    
    init(
        startTime: DateComponents = DateComponents(hour: 9, minute: 0),
        endTime: DateComponents = DateComponents(hour: 17, minute: 0),
        activeDays: Set<Weekday> = Set(Weekday.allCases)
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.activeDays = activeDays
    }
    
    var startTimeString: String {
        let hour = startTime.hour ?? 0
        let minute = startTime.minute ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
    
    var endTimeString: String {
        let hour = endTime.hour ?? 0
        let minute = endTime.minute ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
    
    func isActiveNow() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        guard let weekday = Weekday(rawValue: currentWeekday),
              activeDays.contains(weekday) else {
            return false
        }
        
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        let startHour = startTime.hour ?? 0
        let startMinute = startTime.minute ?? 0
        let startTotalMinutes = startHour * 60 + startMinute
        
        let endHour = endTime.hour ?? 0
        let endMinute = endTime.minute ?? 0
        let endTotalMinutes = endHour * 60 + endMinute
        
        return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var initial: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

enum StrictnessLevel: String, Codable, CaseIterable, Identifiable {
    case standard
    case strict
    case locked
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .strict: return "Strict"
        case .locked: return "Locked"
        }
    }
    
    var description: String {
        switch self {
        case .standard: return "You can freely disable blocking at any time."
        case .strict: return "Disabling requires a 10-minute cooldown. Max 2 unlocks per session, 15 minutes each."
        case .locked: return "Blocking cannot be disabled during scheduled time. No exceptions."
        }
    }
    
    var iconName: String {
        switch self {
        case .standard: return "lock.open.fill"
        case .strict: return "shield.fill"
        case .locked: return "lock.fill"
        }
    }
    
    var maxDailyUnlocks: Int {
        switch self {
        case .standard: return .max
        case .strict: return 2
        case .locked: return 0
        }
    }
    
    var cooldownDuration: TimeInterval {
        switch self {
        case .standard: return 0
        case .strict: return 10 * 60 // 10 minutes
        case .locked: return 0
        }
    }
    
    var unlockDuration: TimeInterval {
        switch self {
        case .standard: return .infinity
        case .strict: return 15 * 60 // 15 minutes
        case .locked: return 0
        }
    }
}

enum ProfileColor: String, Codable, CaseIterable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink
    
    var color: SwiftUI.Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

struct BlockedWebsite: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var domain: String
    var displayName: String
    var iconName: String
    var isSuggested: Bool
    
    init(id: UUID = UUID(), domain: String, displayName: String, iconName: String = "globe", isSuggested: Bool = false) {
        self.id = id
        self.domain = domain
        self.displayName = displayName
        self.iconName = iconName
        self.isSuggested = isSuggested
    }
    
    static let suggestions: [BlockedWebsite] = [
        BlockedWebsite(domain: "youtube.com", displayName: "YouTube", iconName: "play.rectangle.fill", isSuggested: true),
        BlockedWebsite(domain: "instagram.com", displayName: "Instagram", iconName: "camera.fill", isSuggested: true),
        BlockedWebsite(domain: "facebook.com", displayName: "Facebook", iconName: "person.2.fill", isSuggested: true),
        BlockedWebsite(domain: "twitter.com", displayName: "Twitter/X", iconName: "bubble.left.fill", isSuggested: true),
        BlockedWebsite(domain: "x.com", displayName: "X", iconName: "bubble.left.fill", isSuggested: true),
        BlockedWebsite(domain: "tiktok.com", displayName: "TikTok", iconName: "music.note", isSuggested: true),
        BlockedWebsite(domain: "reddit.com", displayName: "Reddit", iconName: "text.bubble.fill", isSuggested: true),
        BlockedWebsite(domain: "snapchat.com", displayName: "Snapchat", iconName: "camera.viewfinder", isSuggested: true),
        BlockedWebsite(domain: "pinterest.com", displayName: "Pinterest", iconName: "pin.fill", isSuggested: true),
        BlockedWebsite(domain: "linkedin.com", displayName: "LinkedIn", iconName: "briefcase.fill", isSuggested: true),
        BlockedWebsite(domain: "twitch.tv", displayName: "Twitch", iconName: "gamecontroller.fill", isSuggested: true),
        BlockedWebsite(domain: "discord.com", displayName: "Discord", iconName: "message.fill", isSuggested: true),
        BlockedWebsite(domain: "netflix.com", displayName: "Netflix", iconName: "tv.fill", isSuggested: true),
        BlockedWebsite(domain: "hulu.com", displayName: "Hulu", iconName: "tv.fill", isSuggested: true),
        BlockedWebsite(domain: "disneyplus.com", displayName: "Disney+", iconName: "tv.fill", isSuggested: true),
        BlockedWebsite(domain: "amazon.com", displayName: "Amazon", iconName: "cart.fill", isSuggested: true),
        BlockedWebsite(domain: "ebay.com", displayName: "eBay", iconName: "cart.fill", isSuggested: true),
        BlockedWebsite(domain: "news.ycombinator.com", displayName: "Hacker News", iconName: "newspaper.fill", isSuggested: true),
    ]
}
