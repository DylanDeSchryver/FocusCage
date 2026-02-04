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
            .familyActivityPicker(isPresented: $showingAppPicker, selection: $blockedApps)
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $iconName, selectedColor: $color)
            }
        }
    }
    
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { step in
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
                    Text("Select Apps to Block")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("These apps will be completely inaccessible\nduring your focus time")
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
                        
                        if appCount > 0 || categoryCount > 0 {
                            Text("\(appCount) apps and \(categoryCount) categories selected")
                                .font(.headline)
                            
                            Text("Tap below to modify selection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No apps selected yet")
                                .font(.headline)
                            
                            Text("Tap below to select apps to block")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 24)
                
                Button {
                    showingAppPicker = true
                } label: {
                    Label("Choose Apps & Categories", systemImage: "apps.iphone")
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
                    
                    Text("Once a focus session starts, blocked apps cannot be accessed. There are no \"take a break\" options or emergency bypasses.")
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
                if currentStep < 2 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    createProfile()
                }
            } label: {
                Text(currentStep == 2 ? "Create Profile" : "Next")
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
        case 2:
            return true
        default:
            return false
        }
    }
    
    private func createProfile() {
        var newProfile = FocusProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            iconName: iconName,
            color: color,
            schedule: schedule
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
