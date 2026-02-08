import SwiftUI
import FamilyControls

@main
struct FocusCageApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var statisticsManager = StatisticsManager()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(profileManager)
                    .environmentObject(screenTimeManager)
                    .environmentObject(themeManager)
                    .environmentObject(statisticsManager)
                    .tint(themeManager.accentColor)
                
                SplashScreenView()
                    .environmentObject(themeManager)
            }
                .fullScreenCover(isPresented: $showingOnboarding) {
                    OnboardingView()
                        .environmentObject(screenTimeManager)
                        .environmentObject(themeManager)
                }
                .onAppear {
                    if !hasSeenOnboarding {
                        showingOnboarding = true
                    }
                    Task {
                        await screenTimeManager.requestAuthorization()
                        screenTimeManager.syncBlockingState(with: profileManager.profiles)
                    }
                }
        }
        .onChange(of: hasSeenOnboarding) { _, seen in
            if seen {
                showingOnboarding = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            
            if newPhase == .active {
                // Every time the app comes to foreground, sync blocking state
                profileManager.checkSchedules()
                screenTimeManager.syncBlockingState(with: profileManager.profiles)
            }
        }
    }
}

