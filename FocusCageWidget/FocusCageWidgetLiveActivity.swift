import ActivityKit
import WidgetKit
import SwiftUI

struct FocusCageWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingMinutes: Int
        var isLocked: Bool
    }

    var profileName: String
    var profileIcon: String
    var profileColorHex: String
    var endTime: Date
}

struct FocusCageWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusCageWidgetAttributes.self) { context in
            // Lock Screen / Banner UI
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color(from: context.attributes.profileColorHex).opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: context.attributes.profileIcon)
                        .font(.title3)
                        .foregroundStyle(color(from: context.attributes.profileColorHex))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.profileName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isLocked ? "lock.fill" : "shield.fill")
                            .font(.caption2)
                        Text(context.state.isLocked ? "Locked" : "Strict")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.attributes.endTime, style: .timer)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(color(from: context.attributes.profileColorHex))
                    
                    Text("Ends \(context.attributes.endTime, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(color(from: context.attributes.profileColorHex))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.profileIcon)
                            .font(.subheadline)
                            .foregroundStyle(color(from: context.attributes.profileColorHex))
                        
                        Text(context.attributes.profileName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isLocked ? "lock.fill" : "shield.fill")
                            .font(.caption2)
                        Text(context.state.isLocked ? "Locked" : "Strict")
                            .font(.caption)
                    }
                    .foregroundStyle(context.state.isLocked ? .red : .orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Ends at")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(context.attributes.endTime, style: .timer)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(color(from: context.attributes.profileColorHex))
                    }
                }
            } compactLeading: {
                Image(systemName: "lock.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(color(from: context.attributes.profileColorHex))
            } compactTrailing: {
                Text(context.attributes.endTime, style: .timer)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(color(from: context.attributes.profileColorHex))
            } minimal: {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(color(from: context.attributes.profileColorHex))
            }
            .widgetURL(URL(string: "focuscage://active"))
            .keylineTint(color(from: context.attributes.profileColorHex))
        }
    }
    
    private func color(from hex: String) -> Color {
        switch hex {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .indigo
        }
    }
}

extension FocusCageWidgetAttributes {
    fileprivate static var preview: FocusCageWidgetAttributes {
        FocusCageWidgetAttributes(
            profileName: "Work Focus",
            profileIcon: "lock.fill",
            profileColorHex: "indigo",
            endTime: Date().addingTimeInterval(3600)
        )
    }
}

extension FocusCageWidgetAttributes.ContentState {
    fileprivate static var active: FocusCageWidgetAttributes.ContentState {
        FocusCageWidgetAttributes.ContentState(remainingMinutes: 45, isLocked: false)
    }
    
    fileprivate static var locked: FocusCageWidgetAttributes.ContentState {
        FocusCageWidgetAttributes.ContentState(remainingMinutes: 30, isLocked: true)
    }
}

#Preview("Notification", as: .content, using: FocusCageWidgetAttributes.preview) {
    FocusCageWidgetLiveActivity()
} contentStates: {
    FocusCageWidgetAttributes.ContentState.active
    FocusCageWidgetAttributes.ContentState.locked
}
