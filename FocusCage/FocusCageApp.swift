import SwiftUI
import FamilyControls

@main
struct FocusCageApp: App {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var screenTimeManager = ScreenTimeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileManager)
                .environmentObject(screenTimeManager)
                .onAppear {
                    Task {
                        await screenTimeManager.requestAuthorization()
                    }
                }
        }
    }
}
