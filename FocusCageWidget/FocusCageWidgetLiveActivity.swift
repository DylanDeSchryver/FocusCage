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
            TimelineView(.periodic(from: Date(), by: 30)) { _ in
                let active = AppGroupState.loadActiveState()
                let next = AppGroupState.loadNextState()
                let name = active?.name ?? next?.name ?? context.attributes.profileName
                let icon = active?.icon ?? next?.icon ?? context.attributes.profileIcon
                let colorHex = active?.colorHex ?? next?.colorHex ?? context.attributes.profileColorHex
                let strictness = active?.strictness ?? next?.strictness
                let endDate = active?.endDate
                let startDate = next?.startDate

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(color(from: colorHex).opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color(from: colorHex))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if let strictness {
                            HStack(spacing: 4) {
                                Image(systemName: strictness.icon)
                                    .font(.caption2)
                                Text(strictness.label)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        } else {
                            Text("Not Active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        if let endDate {
                            Text(endDate, style: .timer)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(color(from: colorHex))

                            Text("Ends \(endDate, style: .time)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let startDate {
                            Text(startDate, style: .timer)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(color(from: colorHex))

                            Text("Starts \(startDate, style: .time)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(color(from: colorHex))

                            Text("No Schedule")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .activityBackgroundTint(Color(.systemBackground))
                .activitySystemActionForegroundColor(color(from: colorHex))
            }

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimelineView(.periodic(from: Date(), by: 30)) { _ in
                        let active = AppGroupState.loadActiveState()
                        let next = AppGroupState.loadNextState()
                        let name = active?.name ?? next?.name ?? context.attributes.profileName
                        let icon = active?.icon ?? next?.icon ?? context.attributes.profileIcon
                        let colorHex = active?.colorHex ?? next?.colorHex ?? context.attributes.profileColorHex

                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.subheadline)
                                .foregroundStyle(color(from: colorHex))

                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimelineView(.periodic(from: Date(), by: 30)) { _ in
                        let active = AppGroupState.loadActiveState()
                        let next = AppGroupState.loadNextState()
                        let colorHex = active?.colorHex ?? next?.colorHex ?? context.attributes.profileColorHex
                        let strictness = active?.strictness ?? next?.strictness
                        let endDate = active?.endDate
                        let startDate = next?.startDate

                        VStack(alignment: .trailing, spacing: 2) {
                            if let strictness {
                                HStack(spacing: 4) {
                                    Image(systemName: strictness.icon)
                                        .font(.caption2)
                                    Text(strictness.label)
                                        .font(.caption)
                                }
                                .foregroundStyle(strictness.isLocked ? .red : .orange)
                            }

                            if let endDate {
                                Text(endDate, style: .timer)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundStyle(color(from: colorHex))
                            } else if let startDate {
                                Text(startDate, style: .timer)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundStyle(color(from: colorHex))
                            }
                        }
                    }
                }
            } compactLeading: {
                TimelineView(.periodic(from: Date(), by: 30)) { _ in
                    let active = AppGroupState.loadActiveState()
                    let next = AppGroupState.loadNextState()
                    let colorHex = active?.colorHex ?? next?.colorHex ?? context.attributes.profileColorHex
                    let icon = active?.icon ?? next?.icon ?? "lock.shield.fill"

                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(color(from: colorHex))
                }
            } compactTrailing: {
                TimelineView(.periodic(from: Date(), by: 30)) { _ in
                    let active = AppGroupState.loadActiveState()
                    let next = AppGroupState.loadNextState()
                    let colorHex = active?.colorHex ?? next?.colorHex ?? context.attributes.profileColorHex
                    let endDate = active?.endDate
                    let startDate = next?.startDate

                    Group {
                        if let endDate {
                            Text(endDate, style: .timer)
                        } else if let startDate {
                            Text(startDate, style: .timer)
                        } else {
                            Text("—")
                        }
                    }
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 56, alignment: .trailing)
                    .foregroundStyle(color(from: colorHex))
                }
            } minimal: {
                TimelineView(.periodic(from: Date(), by: 30)) { _ in
                    let active = AppGroupState.loadActiveState()
                    let next = AppGroupState.loadNextState()
                    let colorHex = active?.colorHex ?? next?.colorHex ?? context.attributes.profileColorHex
                    let icon = active?.icon ?? next?.icon ?? "lock.shield.fill"

                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color(from: colorHex))
                }
            }
            .widgetURL(URL(string: "focuscage://active"))
            .keylineTint(color(from: AppGroupState.loadActiveState()?.colorHex ?? AppGroupState.loadNextState()?.colorHex ?? context.attributes.profileColorHex))
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

private enum AppGroupState {
    static let suiteName = "group.com.focuscage.app"

    struct ActiveState {
        let name: String
        let icon: String
        let colorHex: String
        let strictness: Strictness
        let endDate: Date
    }

    struct NextState {
        let name: String
        let icon: String
        let colorHex: String
        let strictness: Strictness
        let startDate: Date
        let endDate: Date
    }

    struct Strictness {
        let rawValue: String
        var isLocked: Bool { rawValue == "locked" }
        var label: String {
            switch rawValue {
            case "locked": return "Locked"
            case "strict": return "Strict"
            case "standard": return "Standard"
            default: return rawValue
            }
        }
        var icon: String {
            switch rawValue {
            case "locked": return "lock.fill"
            case "strict": return "shield.fill"
            case "standard": return "lock.open.fill"
            default: return "lock.shield.fill"
            }
        }
    }

    static func defaults() -> UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func loadActiveState(now: Date = Date()) -> ActiveState? {
        guard let defaults = defaults(),
              let name = defaults.string(forKey: "shared_active_profile_name"),
              let icon = defaults.string(forKey: "shared_active_profile_icon"),
              let colorHex = defaults.string(forKey: "shared_active_profile_color"),
              let strictnessRaw = defaults.string(forKey: "shared_active_strictness") else {
            return nil
        }

        let endTs = defaults.double(forKey: "shared_active_end_time")
        guard endTs > 0 else { return nil }
        let endDate = Date(timeIntervalSince1970: endTs)
        guard endDate > now else { return nil }

        return ActiveState(
            name: name,
            icon: icon,
            colorHex: colorHex,
            strictness: Strictness(rawValue: strictnessRaw),
            endDate: endDate
        )
    }

    static func loadNextState(now: Date = Date()) -> NextState? {
        guard let defaults = defaults(),
              let name = defaults.string(forKey: "shared_next_profile_name"),
              let icon = defaults.string(forKey: "shared_next_profile_icon"),
              let colorHex = defaults.string(forKey: "shared_next_profile_color"),
              let strictnessRaw = defaults.string(forKey: "shared_next_profile_strictness") else {
            return nil
        }

        let startTs = defaults.double(forKey: "shared_next_profile_start_time")
        let endTs = defaults.double(forKey: "shared_next_profile_end_time")
        guard startTs > 0, endTs > 0 else { return nil }
        let startDate = Date(timeIntervalSince1970: startTs)
        let endDate = Date(timeIntervalSince1970: endTs)
        guard endDate > now else { return nil }

        return NextState(
            name: name,
            icon: icon,
            colorHex: colorHex,
            strictness: Strictness(rawValue: strictnessRaw),
            startDate: startDate,
            endDate: endDate
        )
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
