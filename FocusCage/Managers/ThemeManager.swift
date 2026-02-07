import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let themeKey = "selectedTheme"
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
            updateAppIcon()
        }
    }
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: saved) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .indigo
        }
    }
    
    var accentColor: Color {
        currentTheme.primaryColor
    }
    
    var gradientColors: [Color] {
        currentTheme.gradientColors
    }
    
    var splashIconName: String {
        currentTheme.splashIconImageName
    }
    
    private func updateAppIcon() {
        let iconName = currentTheme.alternateIconName
        
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        // Only change if different from current
        let currentIcon = UIApplication.shared.alternateIconName
        if currentIcon == iconName { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("[ThemeManager] Failed to set app icon: \(error.localizedDescription)")
            } else {
                print("[ThemeManager] App icon updated to: \(iconName ?? "default")")
            }
        }
    }
}
