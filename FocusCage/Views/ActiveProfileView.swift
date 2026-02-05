import SwiftUI

struct ActiveProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var currentTime = Date()
    
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
            
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.orange)
                    Text("No Bypass Available")
                        .font(.headline)
                }
                
                Text("Stay focused. Blocked apps will become available when your session ends at \(profile.schedule.endTimeString).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
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
