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
        
        // Use private API to suppress the "You have changed the icon" alert
        let selectorString = "_setAlternateIconName:completionHandler:"
        let selector = NSSelectorFromString(selectorString)
        
        if UIApplication.shared.responds(to: selector) {
            typealias SetIconMethod = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError?) -> Void) -> Void
            let imp = UIApplication.shared.method(for: selector)
            let method = unsafeBitCast(imp, to: SetIconMethod.self)
            method(UIApplication.shared, selector, iconName as NSString?, { error in
                if let error = error {
                    print("[ThemeManager] Failed to set app icon: \(error.localizedDescription)")
                }
            })
        } else {
            // Fallback to public API (will show alert)
            UIApplication.shared.setAlternateIconName(iconName)
        }
    }
}
