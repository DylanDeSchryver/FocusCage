import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case indigo = "Indigo"
    case ocean = "Ocean"
    case emerald = "Emerald"
    case sunset = "Sunset"
    case rose = "Rose"
    
    var id: String { rawValue }
    
    var primaryColor: Color {
        switch self {
        case .indigo:  return Color(red: 0.345, green: 0.318, blue: 0.898)
        case .ocean:   return Color(red: 0.039, green: 0.518, blue: 1.0)
        case .emerald: return Color(red: 0.188, green: 0.820, blue: 0.345)
        case .sunset:  return Color(red: 1.0, green: 0.420, blue: 0.173)
        case .rose:    return Color(red: 1.0, green: 0.176, blue: 0.333)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .indigo:  return [Color(red: 0.345, green: 0.318, blue: 0.898), .purple]
        case .ocean:   return [Color(red: 0.039, green: 0.518, blue: 1.0), Color(red: 0.0, green: 0.35, blue: 0.85)]
        case .emerald: return [Color(red: 0.188, green: 0.820, blue: 0.345), Color(red: 0.0, green: 0.6, blue: 0.35)]
        case .sunset:  return [Color(red: 1.0, green: 0.420, blue: 0.173), Color(red: 0.9, green: 0.25, blue: 0.15)]
        case .rose:    return [Color(red: 1.0, green: 0.176, blue: 0.333), Color(red: 0.85, green: 0.1, blue: 0.4)]
        }
    }
    
    /// The alternate icon name registered in Info.plist. nil = default icon.
    var alternateIconName: String? {
        switch self {
        case .indigo:  return nil
        case .ocean:   return "AppIcon-Ocean"
        case .emerald: return "AppIcon-Emerald"
        case .sunset:  return "AppIcon-Sunset"
        case .rose:    return "AppIcon-Rose"
        }
    }
    
    /// Image set name for the splash screen icon
    var splashIconImageName: String {
        switch self {
        case .indigo:  return "AppIconImage"
        case .ocean:   return "AppIconImage-Ocean"
        case .emerald: return "AppIconImage-Emerald"
        case .sunset:  return "AppIconImage-Sunset"
        case .rose:    return "AppIconImage-Rose"
        }
    }
    
    var displayIcon: String {
        "lock.shield.fill"
    }
}
