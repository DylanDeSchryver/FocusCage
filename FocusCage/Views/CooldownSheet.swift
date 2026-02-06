import SwiftUI

struct CooldownSheet: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    let profile: FocusProfile
    @State private var timeRemaining: TimeInterval
    @State private var isComplete = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let productiveSuggestions = [
        ("Drop and do 10 push-ups", "figure.strengthtraining.traditional"),
        ("Drink a glass of water", "drop.fill"),
        ("Take a quick walk", "figure.walk"),
        ("Do some stretching", "figure.flexibility"),
        ("Write down 3 things you're grateful for", "heart.fill"),
        ("Take 10 deep breaths", "wind"),
        ("Tidy up your desk", "desktopcomputer"),
        ("Read a page of a book", "book.fill"),
        ("Look out the window for a moment", "sun.max.fill"),
        ("Do a quick meditation", "brain.head.profile"),
    ]
    
    @State private var currentSuggestion: (String, String)
    
    init(profile: FocusProfile) {
        self.profile = profile
        let remaining: TimeInterval
        if let cooldownEnd = profile.cooldownEndDate {
            remaining = max(0, cooldownEnd.timeIntervalSinceNow)
        } else {
            remaining = profile.strictnessLevel.cooldownDuration
        }
        _timeRemaining = State(initialValue: remaining)
        
        let suggestions = [
            ("Drop and do 10 push-ups", "figure.strengthtraining.traditional"),
            ("Drink a glass of water", "drop.fill"),
            ("Take a quick walk", "figure.walk"),
            ("Do some stretching", "figure.flexibility"),
            ("Write down 3 things you're grateful for", "heart.fill"),
            ("Take 10 deep breaths", "wind"),
            ("Tidy up your desk", "desktopcomputer"),
            ("Read a page of a book", "book.fill"),
            ("Look out the window for a moment", "sun.max.fill"),
            ("Do a quick meditation", "brain.head.profile"),
        ]
        _currentSuggestion = State(initialValue: suggestions.randomElement()!)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if isComplete {
                completedView
            } else {
                countdownView
            }
            
            Spacer()
            
            if isComplete {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(profile.color.color)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                Button {
                    profileManager.cancelCooldown()
                    dismiss()
                } label: {
                    Text("Cancel — Stay Focused")
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
            if let cooldownEnd = profileManager.cooldownEndDate {
                timeRemaining = max(0, cooldownEnd.timeIntervalSinceNow)
                if timeRemaining <= 0 && !isComplete {
                    withAnimation(.spring()) {
                        isComplete = true
                    }
                }
            }
        }
    }
    
    private var countdownView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(profile.color.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .monospacedDigit()
                    
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                Text("Are you sure?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("While you wait, try this:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                Image(systemName: currentSuggestion.1)
                    .font(.title2)
                    .foregroundStyle(profile.color.color)
                    .frame(width: 44)
                
                Text(currentSuggestion.0)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(profile.color.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            let remaining = profileManager.remainingUnlocks(for: profile)
            Text("\(remaining) of \(profile.strictnessLevel.maxDailyUnlocks) unlocks remaining this session")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var completedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Blocking is paused for 15 minutes.\nIt will re-engage automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var progress: Double {
        let total = profile.strictnessLevel.cooldownDuration
        guard total > 0 else { return 1 }
        return 1 - (timeRemaining / total)
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
