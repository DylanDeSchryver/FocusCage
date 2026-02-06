import SwiftUI
import FamilyControls

struct CreateProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    
    @State private var name = ""
    @State private var iconName = "lock.fill"
    @State private var color: ProfileColor = .indigo
    @State private var schedule = ProfileSchedule()
    @State private var blockedApps = FamilyActivitySelection()
    @State private var blockedWebsites: [BlockedWebsite] = []
    @State private var strictnessLevel: StrictnessLevel = .strict
    @State private var showingAppPicker = false
    @State private var showingIconPicker = false
    @State private var currentStep = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                
                TabView(selection: $currentStep) {
                    nameStep.tag(0)
                    scheduleStep.tag(1)
                    appsStep.tag(2)
                    strictnessStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                bottomButtons
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAppPicker) {
                AppSelectionView(selection: $blockedApps, blockedWebsites: $blockedWebsites)
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $iconName, selectedColor: $color)
            }
        }
    }
    
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { step in
                Capsule()
                    .fill(step <= currentStep ? color.color : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var nameStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Name Your Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Give your focus profile a descriptive name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                
                Button {
                    showingIconPicker = true
                } label: {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.color.gradient)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: iconName)
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                        
                        Text("Tap to customize")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                VStack(spacing: 8) {
                    TextField("Profile Name", text: $name)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("e.g., Work Focus, Study Time, Deep Work")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }
    
    private var scheduleStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Set Your Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose when this profile should be active")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Start Time")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        var components = DateComponents()
                                        components.hour = schedule.startTime.hour
                                        components.minute = schedule.startTime.minute
                                        return Calendar.current.date(from: components) ?? Date()
                                    },
                                    set: { date in
                                        schedule.startTime.hour = Calendar.current.component(.hour, from: date)
                                        schedule.startTime.minute = Calendar.current.component(.minute, from: date)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("End Time")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        var components = DateComponents()
                                        components.hour = schedule.endTime.hour
                                        components.minute = schedule.endTime.minute
                                        return Calendar.current.date(from: components) ?? Date()
                                    },
                                    set: { date in
                                        schedule.endTime.hour = Calendar.current.component(.hour, from: date)
                                        schedule.endTime.minute = Calendar.current.component(.minute, from: date)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(spacing: 12) {
                        Text("Active Days")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                DayToggle(
                                    day: day,
                                    isSelected: schedule.activeDays.contains(day),
                                    color: color.color
                                ) {
                                    if schedule.activeDays.contains(day) {
                                        schedule.activeDays.remove(day)
                                    } else {
                                        schedule.activeDays.insert(day)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    private var appsStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Select Content to Block")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose apps and websites that will be\ncompletely blocked during focus time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(color.color)
                    
                    VStack(spacing: 4) {
                        let appCount = blockedApps.applicationTokens.count
                        let categoryCount = blockedApps.categoryTokens.count
                        let websiteCount = blockedWebsites.count
                        
                        if appCount > 0 || categoryCount > 0 || websiteCount > 0 {
                            Text("\(appCount) apps, \(categoryCount) categories, \(websiteCount) websites")
                                .font(.headline)
                            
                            Text("Tap below to modify selection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No content selected yet")
                                .font(.headline)
                            
                            Text("Tap below to select apps and websites to block")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 24)
                
                Button {
                    showingAppPicker = true
                } label: {
                    Label("Choose Apps & Websites", systemImage: "apps.iphone")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color.color)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("No Bypass")
                            .fontWeight(.semibold)
                    }
                    
                    Text("Once a focus session starts, blocked content cannot be accessed. There are no \"take a break\" options or emergency bypasses.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Button {
                if currentStep < 3 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    createProfile()
                }
            } label: {
                Text(currentStep == 3 ? "Create Profile" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProceed ? color.color : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1:
            return !schedule.activeDays.isEmpty
        case 2, 3:
            return true
        default:
            return false
        }
    }
    
    private var strictnessStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Choose Strictness")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How hard should it be to bypass\nblocking during focus time?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                VStack(spacing: 12) {
                    ForEach(StrictnessLevel.allCases) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                strictnessLevel = level
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(strictnessLevel == level ? color.color : Color(.systemGray4))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: level.iconName)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(level.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        if level == .strict {
                                            Text("RECOMMENDED")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(color.color)
                                                .foregroundStyle(.white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if strictnessLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(color.color)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(strictnessLevel == level ? color.color : .clear, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                
                if strictnessLevel == .locked {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text("Full Lockdown")
                                .fontWeight(.semibold)
                        }
                        
                        Text("You will NOT be able to disable blocking during scheduled time. The only escape is deleting the entire profile, which requires a 5-minute waiting period.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
    }
    
    private func createProfile() {
        var newProfile = FocusProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            iconName: iconName,
            color: color,
            schedule: schedule,
            blockedWebsites: blockedWebsites,
            strictnessLevel: strictnessLevel
        )
        newProfile.blockedApps = blockedApps
        
        profileManager.addProfile(newProfile)
        dismiss()
    }
}

struct DayToggle: View {
    let day: Weekday
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, height: 40)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateProfileView()
        .environmentObject(ProfileManager())
        .environmentObject(ScreenTimeManager())
}
