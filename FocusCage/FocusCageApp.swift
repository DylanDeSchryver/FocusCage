import SwiftUI
import FamilyControls
import BackgroundTasks
import ManagedSettings
import WidgetKit

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
                    } else {
                        Task {
                            await screenTimeManager.requestAuthorization()
                            profileManager.scheduleAllProfiles()
                            screenTimeManager.syncBlockingState(with: profileManager.profiles)
                        }
                    }
                }
        }
        .onChange(of: hasSeenOnboarding) { _, seen in
            if seen {
                showingOnboarding = false
                profileManager.scheduleAllProfiles()
                screenTimeManager.syncBlockingState(with: profileManager.profiles)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Every time the app comes to foreground, re-register schedules and sync blocking
                profileManager.scheduleAllProfiles()
                profileManager.checkSchedules()
                screenTimeManager.syncBlockingState(with: profileManager.profiles)
            }
            if newPhase == .background {
                // Schedule background refresh to apply blocking while app is closed
                FocusCageApp.scheduleBackgroundRefresh()
            }
        }
        .backgroundTask(.appRefresh("com.focuscage.app.refresh")) {
            await FocusCageApp.handleBackgroundRefresh()
        }
    }
    
    // MARK: - Background Refresh
    
    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.focuscage.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60) // 2 minutes
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[FocusCageApp] Scheduled background refresh")
        } catch {
            print("[FocusCageApp] Failed to schedule background refresh: \(error)")
        }
    }
    
    @Sendable
    static func handleBackgroundRefresh() async {
        let profiles = SharedDefaults.loadProfiles()
        let store = ManagedSettingsStore()
        
        let activeProfile = profiles.first { profile in
            guard profile.isEnabled else { return false }
            return profile.schedule.isActiveNow()
        }
        
        if let profile = activeProfile {
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
            
            SharedDefaults.saveActiveState(profile: profile)
            print("[FocusCageApp] Background refresh: blocking applied for '\(profile.name)'")
        } else {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
            store.webContent.blockedByFilter = nil
            SharedDefaults.saveActiveState(profile: nil)
            print("[FocusCageApp] Background refresh: no active profile, blocking cleared")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        
        // Schedule next refresh
        scheduleBackgroundRefresh()
    }
}
