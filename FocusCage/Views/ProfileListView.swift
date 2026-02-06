import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var showingCreateProfile = false
    @State private var profileToEdit: FocusProfile?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if profileManager.profiles.isEmpty {
                    emptyStateView
                } else {
                    profileList
                }
            }
            .navigationTitle("Focus Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateProfile = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateProfile) {
                CreateProfileView()
            }
            .sheet(item: $profileToEdit) { profile in
                ProfileDetailView(profile: profile)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundStyle(.indigo.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Focus Profiles")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first profile to start\nblocking distracting apps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingCreateProfile = true
            } label: {
                Label("Create Profile", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding()
    }
    
    private var profileList: some View {
        List {
            if !screenTimeManager.isAuthorized {
                authorizationBanner
            }
            
            ForEach(profileManager.profiles) { profile in
                ProfileRow(profile: profile) {
                    profileToEdit = profile
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation {
                            profileManager.deleteProfile(profile)
                            profileManager.checkSchedules()
                            screenTimeManager.syncBlockingState(with: profileManager.profiles)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        profileManager.toggleProfile(profile)
                        profileManager.checkSchedules()
                        screenTimeManager.syncBlockingState(with: profileManager.profiles)
                    } label: {
                        Label(
                            profile.isEnabled ? "Disable" : "Enable",
                            systemImage: profile.isEnabled ? "pause" : "play"
                        )
                    }
                    .tint(profile.isEnabled ? .orange : .green)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var authorizationBanner: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Time Access Required")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Tap to authorize app blocking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                Task {
                    await screenTimeManager.requestAuthorization()
                }
            }
        }
    }
}

struct ProfileRow: View {
    let profile: FocusProfile
    let onTap: () -> Void
    @EnvironmentObject var profileManager: ProfileManager
    
    var isActive: Bool {
        profileManager.activeProfileId == profile.id
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(profile.color.color.gradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: profile.iconName)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if isActive {
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(profile.schedule.startTimeString) - \(profile.schedule.endTimeString)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.initial)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .frame(width: 18, height: 18)
                                .background(
                                    profile.schedule.activeDays.contains(day)
                                        ? profile.color.color.opacity(0.2)
                                        : Color.gray.opacity(0.1)
                                )
                                .foregroundStyle(
                                    profile.schedule.activeDays.contains(day)
                                        ? profile.color.color
                                        : .gray
                                )
                                .clipShape(Circle())
                        }
                    }
                }
                
                Spacer()
                
                if !profile.isEnabled {
                    Image(systemName: "pause.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileListView()
        .environmentObject(ProfileManager())
        .environmentObject(ScreenTimeManager())
}
