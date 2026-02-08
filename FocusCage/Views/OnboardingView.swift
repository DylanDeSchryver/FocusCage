import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            themeManager.accentColor.opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    screenTimePage.tag(1)
                    profilesPage.tag(2)
                    strictnessPage.tag(3)
                    getStartedPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                pageIndicatorAndButtons
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Page Indicator & Buttons
    
    private var pageIndicatorAndButtons: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? themeManager.accentColor : Color(.systemGray4))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                }
            }
            
            if currentPage < totalPages - 1 {
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation { currentPage -= 1 }
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(themeManager.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.gradient)
                    .frame(width: 140, height: 140)
                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 30, y: 10)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to FocusCage")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Take back your focus.\nBlock distracting apps with zero bypasses.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Page 2: Screen Time Permission
    
    private var screenTimePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "hourglass")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 12) {
                Text("Screen Time Access")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("FocusCage uses Apple's Screen Time API to block apps during your focus sessions. This permission is required for the app to work.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if screenTimeManager.isAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Access Granted")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 14)
            } else {
                Button {
                    Task {
                        await screenTimeManager.requestAuthorization()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                        Text("Grant Access")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Page 3: Profiles
    
    private var profilesPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 12) {
                Text("Create Focus Profiles")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Set up profiles for different parts of your day — work, study, or winding down. Each profile has its own schedule, blocked apps, and strictness level.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                OnboardingFeatureRow(icon: "clock.fill", color: .blue, text: "Custom start & end times")
                OnboardingFeatureRow(icon: "app.fill", color: .purple, text: "Choose apps & categories to block")
                OnboardingFeatureRow(icon: "calendar", color: .green, text: "Set active days of the week")
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Page 4: Strictness Levels
    
    private var strictnessPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Choose Your Discipline")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Each profile has a strictness level that controls how hard it is to disable blocking.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                StrictnessInfoCard(
                    icon: "lock.open.fill",
                    color: .green,
                    title: "Standard",
                    description: "Freely disable at any time. Good for testing."
                )
                
                StrictnessInfoCard(
                    icon: "shield.fill",
                    color: .orange,
                    title: "Strict",
                    description: "10-minute cooldown + max 2 unlocks per session."
                )
                
                StrictnessInfoCard(
                    icon: "lock.fill",
                    color: .red,
                    title: "Locked",
                    description: "Cannot be disabled during scheduled time. Period."
                )
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Page 5: Get Started
    
    private var getStartedPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: themeManager.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 30, y: 10)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 12) {
                Text("No Bypasses. No Excuses.")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("FocusCage is built for people who are serious about reclaiming their time. When your focus session starts, blocked apps stay blocked.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                hasSeenOnboarding = true
            } label: {
                Text("Let's Go")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(themeManager.accentColor.gradient)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 12, y: 6)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Supporting Views

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 32)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StrictnessInfoCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ScreenTimeManager())
        .environmentObject(ThemeManager())
}
