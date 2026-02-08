# FocusCage

A strict iOS focus app that blocks distracting apps with **zero bypass options**. Unlike other screen time apps that offer "just 5 more minutes" or "take a deep breath" loopholes, FocusCage enforces your focus profiles with no exceptions.

## Features

- **Timed Focus Profiles**: Create custom profiles for different parts of your day (e.g., "Work Focus" 9am-5pm, "Study Time" 7pm-10pm)
- **App & Category Blocking**: Select specific apps or entire categories to block during focus sessions
- **Schedule-Based Activation**: Profiles automatically activate based on your configured schedule and days
- **Three Strictness Levels**: Standard (freely disable), Strict (cooldown + limited unlocks), or Locked (zero bypass until session ends)
- **Statistics Dashboard**: Track focus hours, streaks, completion rate, and session history with weekly charts
- **Home Screen & Lock Screen Widgets**: See active session timer and upcoming sessions at a glance
- **Live Activities & Dynamic Island**: Real-time session countdown on your Lock Screen and Dynamic Island
- **Onboarding Flow**: Guided setup for first-time users with Screen Time permission explanation
- **5 Color Themes**: Indigo, Ocean, Emerald, Sunset, and Rose — with matching app icons
- **100% Private**: All data stays on your device. No accounts, no analytics, no tracking

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Apple Developer Account with Family Controls capability

## Setup

1. Open `FocusCage.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Request the **Family Controls** capability from Apple (required for Screen Time API access)
4. Build and run on a physical device (Screen Time API doesn't work in Simulator)

## Architecture

```
FocusCage/
├── FocusCageApp.swift              # App entry point with onboarding
├── ContentView.swift                # Main tab view (Profiles, Active, Stats, Settings)
├── Models/
│   ├── FocusProfile.swift           # Profile data model with schedule & strictness
│   ├── FocusSession.swift           # Session history data model
│   ├── FocusCageActivity.swift      # ActivityKit attributes for Live Activities
│   └── AppTheme.swift               # Color theme definitions
├── Managers/
│   ├── ProfileManager.swift         # Profile CRUD, scheduling, Live Activity lifecycle
│   ├── ScreenTimeManager.swift      # Screen Time API integration
│   ├── StatisticsManager.swift      # Session tracking and statistics
│   ├── SharedDefaults.swift         # App Group shared data for widget
│   └── ThemeManager.swift           # Theme persistence
└── Views/
    ├── ProfileListView.swift        # List of all profiles
    ├── ProfileDetailView.swift      # Edit existing profile
    ├── CreateProfileView.swift      # Create new profile wizard
    ├── AppSelectionView.swift       # App picker wrapper
    ├── ScheduleView.swift           # Time and day selection
    ├── ActiveProfileView.swift      # Current session status
    ├── StatisticsView.swift         # Focus stats with charts
    ├── OnboardingView.swift         # First-launch onboarding flow
    ├── SettingsView.swift           # Settings, themes, and about
    ├── SplashScreenView.swift       # Animated splash screen
    ├── CooldownSheet.swift          # Strict mode cooldown UI
    └── NuclearButtonSheet.swift     # Emergency unlock UI

FocusCageWidget/                     # Widget extension
├── FocusCageWidget.swift            # Home Screen & Lock Screen widgets
├── FocusCageWidgetLiveActivity.swift # Dynamic Island & Live Activity UI
└── FocusCageWidgetBundle.swift      # Widget bundle entry point

FocusCageMonitor/                    # Device Activity Monitor extension
└── DeviceActivityMonitorExtension.swift
```

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **FamilyControls**: Apple's framework for screen time management
- **ManagedSettings**: Framework for applying app restrictions
- **DeviceActivity**: Framework for monitoring and responding to device usage
- **WidgetKit**: Home Screen, Lock Screen, and Control Center widgets
- **ActivityKit**: Live Activities and Dynamic Island support
- **Swift Charts**: Statistics visualization

## How It Works

1. User creates a Focus Profile with:
   - Name and icon
   - Start and end time
   - Active days of the week
   - Apps/categories to block

2. The `ProfileManager` monitors the current time and checks if any profiles should be active

3. When a profile becomes active, `ScreenTimeManager` uses the ManagedSettings framework to shield (block) the selected apps

4. The shield remains in place until the scheduled end time - there are no buttons, gestures, or workarounds to remove it early

## Important Notes

- **Family Controls Entitlement**: You must request this capability from Apple. It's typically approved for legitimate screen time/parental control apps.
- **Physical Device Required**: The Screen Time API does not work in the iOS Simulator
- **User Authorization**: The app must request Screen Time authorization from the user before it can block apps

## Future Enhancements

- [ ] iCloud sync for profiles across devices
- [ ] Notification reminders before sessions start
- [ ] Emergency contact allowlist
- [ ] Focus session achievements and badges

## Privacy

FocusCage contains no ads, no analytics, no tracking, and no server-side components. All data is stored locally on your device. See our [Privacy Policy](https://dylandeschryver.github.io/FocusCage/privacy-policy).

## License

MIT License - See LICENSE file for details
