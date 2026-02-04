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
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "lock.fill",
        color: ProfileColor = .indigo,
        schedule: ProfileSchedule = ProfileSchedule(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.color = color
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.blockedAppsData = nil
        self.blockedCategoriesData = nil
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
