import SwiftUI

struct ContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ProfileListView()
                .tabItem {
                    Label("Profiles", systemImage: "list.bullet.rectangle")
                }
                .tag(0)
            
            ActiveProfileView()
                .tabItem {
                    Label("Active", systemImage: "lock.shield.fill")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        // tint is set at the app level via ThemeManager
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileManager())
        .environmentObject(ScreenTimeManager())
}
