import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            Form {
                screenTimeSection
                aboutSection
                supportSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private var screenTimeSection: some View {
        Section {
            HStack {
                Label {
                    Text("Screen Time Access")
                } icon: {
                    Image(systemName: "hourglass")
                        .foregroundStyle(.indigo)
                }
                
                Spacer()
                
                if screenTimeManager.isAuthorized {
                    Label("Authorized", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                } else {
                    Button("Authorize") {
                        Task {
                            await screenTimeManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if let error = screenTimeManager.authorizationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Permissions")
        } footer: {
            Text("Screen Time access is required to block apps. This permission allows FocusCage to manage which apps can be opened during focus sessions.")
        }
    }
    
    private var aboutSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Label("About FocusCage", systemImage: "info.circle")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }
    
    private var supportSection: some View {
        Section {
            Link(destination: URL(string: "https://apple.com")!) {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            
            Link(destination: URL(string: "https://apple.com")!) {
                HStack {
                    Label("Terms of Service", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Legal")
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("FocusCage")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 32)
                    
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "lock.fill",
                            title: "Unbreakable Blocking",
                            description: "No bypasses, no breaks, no exceptions. When focus time starts, blocked apps stay blocked."
                        )
                        
                        FeatureRow(
                            icon: "clock.fill",
                            title: "Scheduled Profiles",
                            description: "Create multiple focus profiles with custom schedules. Perfect for work hours, study time, or winding down."
                        )
                        
                        FeatureRow(
                            icon: "shield.fill",
                            title: "True Focus",
                            description: "Unlike other apps, FocusCage doesn't offer \"just 5 more minutes\" options. Your willpower is reinforced, not tested."
                        )
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        Text("Built with determination.")
                            .font(.headline)
                        
                        Text("FocusCage is designed for people who are serious about reclaiming their time and attention from addictive apps and social media.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.indigo)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SettingsView()
        .environmentObject(ScreenTimeManager())
}
