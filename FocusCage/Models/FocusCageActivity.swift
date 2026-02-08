import ActivityKit
import Foundation

// Must match the definition in FocusCageWidget/FocusCageWidgetLiveActivity.swift
// ActivityKit uses the type name string to match activities across targets
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
