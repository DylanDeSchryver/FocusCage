import SwiftUI
import FamilyControls

struct ProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    
    @State private var profile: FocusProfile
    @State private var showingAppPicker = false
    @State private var showingIconPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCooldownSheet = false
    @State private var showingLockedDeleteCooldown = false
    @State private var lockedDeleteCountdown: Int = 300
    @State private var canConfirmLockedDelete = false
    
    private let deleteTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var isActiveLockedProfile: Bool {
        profile.strictnessLevel == .locked &&
        profile.schedule.isActiveNow() &&
        profileManager.activeProfileId == profile.id
    }
    
    private var isActiveStrictProfile: Bool {
        profile.strictnessLevel == .strict &&
        profile.schedule.isActiveNow() &&
        profileManager.activeProfileId == profile.id
    }
    
    init(profile: FocusProfile) {
        _profile = State(initialValue: profile)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                profileInfoSection
                strictnessSection
                scheduleSection
                blockedAppsSection
                dangerZoneSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        profileManager.updateProfile(profile)
                        profileManager.checkSchedules()
                        screenTimeManager.syncBlockingState(with: profileManager.profiles)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAppPicker) {
                AppSelectionView(
                    selection: $profile.blockedApps,
                    blockedWebsites: $profile.blockedWebsites
                )
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $profile.iconName, selectedColor: $profile.color)
            }
            .sheet(isPresented: $showingCooldownSheet) {
                CooldownSheet(profile: profile)
            }
            .sheet(isPresented: $showingLockedDeleteCooldown) {
                LockedDeleteCooldownSheet(profile: profile) {
                    profileManager.deleteProfile(profile)
                    profileManager.checkSchedules()
                    screenTimeManager.syncBlockingState(with: profileManager.profiles)
                    dismiss()
                }
            }
            .confirmationDialog(
                "Delete Profile",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    profileManager.deleteProfile(profile)
                    profileManager.checkSchedules()
                    screenTimeManager.syncBlockingState(with: profileManager.profiles)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone. The profile and all its settings will be permanently deleted.")
            }
        }
    }
    
    private var profileInfoSection: some View {
        Section {
            HStack {
                Button {
                    showingIconPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(profile.color.color.gradient)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: profile.iconName)
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                
                TextField("Profile Name", text: $profile.name)
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 8)
            
            if isActiveLockedProfile {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.red)
                    Text("Cannot be disabled during active session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if isActiveStrictProfile {
                Button {
                    if profileManager.remainingUnlocks(for: profile) > 0 {
                        if profileManager.requestUnlock(for: profile.id) {
                            showingCooldownSheet = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Request Emergency Unlock")
                                .font(.subheadline)
                            let remaining = profileManager.remainingUnlocks(for: profile)
                            Text("\(remaining) of \(profile.strictnessLevel.maxDailyUnlocks) unlocks remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(profileManager.remainingUnlocks(for: profile) <= 0)
            } else {
                Toggle("Profile Enabled", isOn: $profile.isEnabled)
            }
        } header: {
            Text("Profile")
        } footer: {
            if isActiveLockedProfile {
                Text("This profile uses Locked strictness and cannot be disabled during its scheduled time.")
            } else if isActiveStrictProfile {
                Text("This profile uses Strict strictness. You can request a temporary unlock with a 10-minute cooldown.")
            } else {
                Text("When disabled, this profile will not activate during its scheduled time.")
            }
        }
    }
    
    private var isActiveProtectedSession: Bool {
        isActiveSession && profile.strictnessLevel != .standard
    }
    
    private var scheduleSection: some View {
        Section {
            if isActiveProtectedSession {
                HStack {
                    Label("Schedule", systemImage: "clock")
                    Spacer()
                    Text("\(profile.schedule.startTimeString) - \(profile.schedule.endTimeString)")
                        .foregroundStyle(.secondary)
                }
            } else {
                NavigationLink {
                    ScheduleView(schedule: $profile.schedule, color: profile.color)
                } label: {
                    HStack {
                        Label("Schedule", systemImage: "clock")
                        
                        Spacer()
                        
                        Text("\(profile.schedule.startTimeString) - \(profile.schedule.endTimeString)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack {
                Label("Active Days", systemImage: "calendar")
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(Weekday.allCases) { day in
                        Text(day.initial)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .frame(width: 20, height: 20)
                            .background(
                                profile.schedule.activeDays.contains(day)
                                    ? profile.color.color
                                    : Color.gray.opacity(0.2)
                            )
                            .foregroundStyle(
                                profile.schedule.activeDays.contains(day)
                                    ? .white
                                    : .gray
                            )
                            .clipShape(Circle())
                    }
                }
            }
        } header: {
            Text("Schedule")
        } footer: {
            if isActiveProtectedSession {
                Text("Schedule cannot be changed during an active \(profile.strictnessLevel.displayName) session.")
            } else {
                Text("Apps will be blocked during the scheduled time on selected days. No exceptions, no bypasses.")
            }
        }
    }
    
    private var blockedAppsSection: some View {
        Section {
            if isActiveProtectedSession {
                HStack {
                    Label("Blocked Content", systemImage: "apps.iphone")
                    Spacer()
                    let appCount = profile.blockedApps.applicationTokens.count
                    let categoryCount = profile.blockedApps.categoryTokens.count
                    let websiteCount = profile.blockedWebsites.count
                    Text("\(appCount + categoryCount + websiteCount) items")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showingAppPicker = true
                } label: {
                    HStack {
                        Label("Select Content to Block", systemImage: "apps.iphone")
                        
                        Spacer()
                        
                        let appCount = profile.blockedApps.applicationTokens.count
                        let categoryCount = profile.blockedApps.categoryTokens.count
                        let websiteCount = profile.blockedWebsites.count
                        
                        if appCount > 0 || categoryCount > 0 || websiteCount > 0 {
                            Text("\(appCount + categoryCount + websiteCount) items")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("None selected")
                                .foregroundStyle(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Blocked Content")
        } footer: {
            if isActiveProtectedSession {
                Text("Blocked content cannot be changed during an active \(profile.strictnessLevel.displayName) session.")
            } else {
                Text("Selected apps, categories, and websites will be completely inaccessible during focus time. Website blocking works system-wide across all browsers.")
            }
        }
    }
    
    private var isActiveSession: Bool {
        profile.isEnabled &&
        profile.schedule.isActiveNow() &&
        profileManager.activeProfileId == profile.id
    }
    
    private var strictnessSection: some View {
        Section {
            if isActiveSession && profile.strictnessLevel != .standard {
                HStack {
                    Image(systemName: profile.strictnessLevel.iconName)
                        .foregroundStyle(profile.color.color)
                    Text(profile.strictnessLevel.displayName)
                        .font(.subheadline)
                    Spacer()
                    Text("Cannot change during active session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if isActiveSession && profile.strictnessLevel == .standard {
                Picker("Strictness Level", selection: $profile.strictnessLevel) {
                    ForEach(StrictnessLevel.allCases) { level in
                        Label(level.displayName, systemImage: level.iconName)
                            .tag(level)
                    }
                }
            } else {
                Picker("Strictness Level", selection: $profile.strictnessLevel) {
                    ForEach(StrictnessLevel.allCases) { level in
                        Label(level.displayName, systemImage: level.iconName)
                            .tag(level)
                    }
                }
            }
        } header: {
            Text("Strictness")
        } footer: {
            if isActiveSession && profile.strictnessLevel != .standard {
                Text("Strictness cannot be lowered during an active session. You can upgrade to a stricter level outside of scheduled time.")
            } else {
                Text(profile.strictnessLevel.description)
            }
        }
    }
    
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                if isActiveProtectedSession {
                    showingLockedDeleteCooldown = true
                } else {
                    showingDeleteConfirmation = true
                }
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Profile", systemImage: "trash")
                    Spacer()
                }
            }
        }
    }
}

struct LockedDeleteCooldownSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let profile: FocusProfile
    let onDelete: () -> Void
    
    @State private var timeRemaining: Int = 300 // 5 minutes
    @State private var canDelete = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
            }
            
            VStack(spacing: 8) {
                Text("Delete Locked Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This profile is currently active and locked.\nDeleting it will immediately remove all blocking.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                if !canDelete {
                    Text("You must wait before confirming deletion.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
            
            if !canDelete {
                Text(deleteTimeString)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Text(canDelete ? "Delete Profile" : "Wait \(deleteTimeString)...")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canDelete ? Color.red : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canDelete)
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(24)
        .interactiveDismissDisabled()
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    withAnimation {
                        canDelete = true
                    }
                }
            }
        }
    }
    
    private var deleteTimeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    @Binding var selectedColor: ProfileColor
    
    let icons = [
        "lock.fill", "lock.shield.fill", "shield.fill", "hand.raised.fill",
        "eye.slash.fill", "bell.slash.fill", "moon.fill", "sun.max.fill",
        "brain.head.profile", "book.fill", "pencil", "graduationcap.fill",
        "briefcase.fill", "hammer.fill", "wrench.and.screwdriver.fill", "paintbrush.fill",
        "figure.run", "figure.mind.and.body", "heart.fill", "star.fill",
        "bolt.fill", "flame.fill", "leaf.fill", "drop.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(selectedColor.color.gradient)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: selectedIcon)
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                        
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(ProfileColor.allCases, id: \.self) { color in
                                Circle()
                                    .fill(color.color.gradient)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? selectedColor.color : Color.gray.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: icon)
                                        .font(.body)
                                        .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                }
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Appearance")
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

#Preview {
    ProfileDetailView(profile: FocusProfile(name: "Work Focus"))
        .environmentObject(ProfileManager())
        .environmentObject(ScreenTimeManager())
}
