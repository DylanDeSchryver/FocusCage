import SwiftUI
import FamilyControls

@main
struct FocusCageApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileManager)
                .environmentObject(screenTimeManager)
                .onAppear {
                    Task {
                        await screenTimeManager.requestAuthorization()
                        // Sync blocking state immediately after authorization
                        screenTimeManager.syncBlockingState(with: profileManager.profiles)
                    }
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

