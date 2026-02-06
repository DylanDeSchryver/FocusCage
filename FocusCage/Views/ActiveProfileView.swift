import SwiftUI

struct ActiveProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var currentTime = Date()
    @State private var showingCooldownSheet = false
    @State private var showingNuclearSheet = false
    @State private var nuclearProfile: FocusProfile?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if let activeProfile = profileManager.activeProfile {
                        activeProfileCard(activeProfile)
                    } else {
                        noActiveProfileView
                    }
                    
                    upcomingProfilesSection
                }
                .padding()
            }
            .navigationTitle("Active Session")
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .sheet(isPresented: $showingCooldownSheet) {
                if let activeProfile = profileManager.activeProfile {
                    CooldownSheet(profile: activeProfile)
                }
            }
            .sheet(isPresented: $showingNuclearSheet) {
                if let nuclearProfile {
                    NuclearButtonSheet(profile: nuclearProfile)
                }
            }
        }
    }
    
    private func activeProfileCard(_ profile: FocusProfile) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(profile.color.color.gradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: profile.color.color.opacity(0.4), radius: 20, y: 10)
                    
                    Image(systemName: profile.iconName)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                    
                    Circle()
                        .stroke(profile.color.color.opacity(0.3), lineWidth: 4)
                        .frame(width: 140, height: 140)
                }
                
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Focus Session Active")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(profile.color.color)
                    
                    Text("\(profile.schedule.startTimeString) - \(profile.schedule.endTimeString)")
                        .font(.headline)
                }
                
                if let remaining = profileManager.getTimeUntilNextChange() {
                    Text(remaining)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(profile.color.color)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(profile.color.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    
                    Text("Content Blocked")
                        .font(.headline)
                    
                    Spacer()
                }
                
                let appCount = profile.blockedApps.applicationTokens.count
                let categoryCount = profile.blockedApps.categoryTokens.count
                let websiteCount = profile.blockedWebsites.count
                
                HStack(spacing: 24) {
                    VStack {
                        Text("\(appCount)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Apps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(categoryCount)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Categories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(websiteCount)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Websites")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            strictnessCard(for: profile)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
    }
    
    @ViewBuilder
    private func strictnessCard(for profile: FocusProfile) -> some View {
        switch profile.strictnessLevel {
        case .standard:
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "lock.open.fill")
                        .foregroundStyle(.green)
                    Text("Standard Mode")
                        .font(.headline)
                }
                
                Text("You can disable this profile at any time from the profile settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
        case .strict:
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.orange)
                    Text("Strict Mode")
                        .font(.headline)
                }
                
                let remaining = profileManager.remainingUnlocks(for: profile)
                
                if profileManager.isTemporarilyUnlocked(profile) {
                    VStack(spacing: 4) {
                        Text("Temporarily Unlocked")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                        if let endDate = profile.temporaryUnlockEndDate {
                            Text("Blocking resumes at \(endDate, style: .time)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if remaining > 0 {
                    Button {
                        if profileManager.requestUnlock(for: profile.id) {
                            showingCooldownSheet = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Emergency Unlock")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    Text("\(remaining) of \(profile.strictnessLevel.maxDailyUnlocks) unlocks remaining this session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No unlocks remaining. Stay focused until \(profile.schedule.endTimeString).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
        case .locked:
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.red)
                    Text("Full Lockdown")
                        .font(.headline)
                }
                
                Text("This profile cannot be bypassed. Blocking ends at \(profile.schedule.endTimeString).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var noActiveProfileView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.gray)
            }
            
            VStack(spacing: 8) {
                Text("No Active Session")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You're currently outside of any scheduled\nfocus sessions. Enjoy your free time!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text(currentTime, style: .time)
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundStyle(.secondary)
            
            if !profileManager.profiles.isEmpty && !profileManager.isNuclearActive {
                Button {
                    if let firstProfile = profileManager.profiles.first {
                        nuclearProfile = firstProfile
                        showingNuclearSheet = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                        Text("Nuclear Button")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            
            if profileManager.isNuclearActive {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundStyle(.red)
                        Text("Nuclear Mode Active")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    if let endDate = profileManager.nuclearEndDate {
                        Text("Ends at \(endDate, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var upcomingProfilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Schedule")
                .font(.headline)
            
            let todayProfiles = getTodayProfiles()
            
            if todayProfiles.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.minus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("No focus sessions scheduled for today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(todayProfiles) { profile in
                    ScheduleRow(
                        profile: profile,
                        isActive: profileManager.activeProfileId == profile.id
                    )
                }
            }
        }
    }
    
    private func getTodayProfiles() -> [FocusProfile] {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: Date())
        
        guard let weekday = Weekday(rawValue: currentWeekday) else { return [] }
        
        return profileManager.profiles.filter { profile in
            profile.isEnabled && profile.schedule.activeDays.contains(weekday)
        }.sorted { p1, p2 in
            let start1 = (p1.schedule.startTime.hour ?? 0) * 60 + (p1.schedule.startTime.minute ?? 0)
            let start2 = (p2.schedule.startTime.hour ?? 0) * 60 + (p2.schedule.startTime.minute ?? 0)
            return start1 < start2
        }
    }
}

struct ScheduleRow: View {
    let profile: FocusProfile
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(profile.color.color.opacity(isActive ? 1 : 0.3))
                    .frame(width: 44, height: 44)
                
                Image(systemName: profile.iconName)
                    .font(.body)
                    .foregroundStyle(isActive ? .white : profile.color.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isActive {
                        Text("NOW")
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isPast(profile) && !isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if !isActive {
                Text("Upcoming")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(isActive ? profile.color.color.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func isPast(_ profile: FocusProfile) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let endMinutes = (profile.schedule.endTime.hour ?? 0) * 60 + (profile.schedule.endTime.minute ?? 0)
        return currentMinutes > endMinutes
    }
}

#Preview {
    ActiveProfileView()
        .environmentObject(ProfileManager())
        .environmentObject(ScreenTimeManager())
}
