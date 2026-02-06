import SwiftUI

struct NuclearButtonSheet: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    
    let profile: FocusProfile
    
    @State private var confirmCountdown: Int = 5
    @State private var canConfirm = false
    @State private var activated = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if activated {
                activatedView
            } else {
                confirmView
            }
            
            Spacer()
            
            if activated {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.spring()) {
                            profileManager.activateNuclearButton(for: profile.id)
                            screenTimeManager.syncBlockingState(with: profileManager.profiles)
                            activated = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                            Text(canConfirm ? "Activate Now" : "Wait \(confirmCountdown)s...")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canConfirm ? Color.red : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canConfirm)
                    
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
        }
        .padding(24)
        .interactiveDismissDisabled()
        .onReceive(timer) { _ in
            if !canConfirm && confirmCountdown > 0 {
                confirmCountdown -= 1
                if confirmCountdown <= 0 {
                    withAnimation {
                        canConfirm = true
                    }
                }
            }
        }
    }
    
    private var confirmView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
            }
            
            VStack(spacing: 8) {
                Text("Nuclear Button")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This will immediately block all content in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(profile.name)
                    .font(.headline)
                    .foregroundStyle(profile.color.color)
                
                Text("for 1 hour. Are you sure?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                InfoBadge(icon: "clock.fill", text: "1 Hour", color: .orange)
                InfoBadge(icon: "lock.fill", text: "No Undo", color: .red)
                InfoBadge(icon: "shield.fill", text: "Full Block", color: profile.color.color)
            }
        }
    }
    
    private var activatedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
            }
            
            VStack(spacing: 8) {
                Text("Blocking Activated")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("All content in \(profile.name) is now blocked.\nBlocking will automatically end in 1 hour.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct InfoBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
