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
    
    init(profile: FocusProfile) {
        _profile = State(initialValue: profile)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                profileInfoSection
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
                        if profileManager.activeProfileId == profile.id {
                            screenTimeManager.activateBlocking(for: profile)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .familyActivityPicker(
                isPresented: $showingAppPicker,
                selection: Binding(
                    get: { profile.blockedApps },
                    set: { profile.blockedApps = $0 }
                )
            )
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $profile.iconName, selectedColor: $profile.color)
            }
            .confirmationDialog(
                "Delete Profile",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    profileManager.deleteProfile(profile)
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
            
            Toggle("Profile Enabled", isOn: $profile.isEnabled)
        } header: {
            Text("Profile")
        } footer: {
            Text("When disabled, this profile will not activate during its scheduled time.")
        }
    }
    
    private var scheduleSection: some View {
        Section {
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
            Text("Apps will be blocked during the scheduled time on selected days. No exceptions, no bypasses.")
        }
    }
    
    private var blockedAppsSection: some View {
        Section {
            Button {
                showingAppPicker = true
            } label: {
                HStack {
                    Label("Select Apps to Block", systemImage: "apps.iphone")
                    
                    Spacer()
                    
                    let appCount = profile.blockedApps.applicationTokens.count
                    let categoryCount = profile.blockedApps.categoryTokens.count
                    
                    if appCount > 0 || categoryCount > 0 {
                        Text("\(appCount) apps, \(categoryCount) categories")
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
        } header: {
            Text("Blocked Apps")
        } footer: {
            Text("Selected apps and categories will be completely inaccessible during focus time. There is no way to bypass this block.")
        }
    }
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
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
