# FocusCage

A strict iOS focus app that blocks distracting apps with **zero bypass options**. Unlike other screen time apps that offer "just 5 more minutes" or "take a deep breath" loopholes, FocusCage enforces your focus profiles with no exceptions.

## Features

- **Timed Focus Profiles**: Create custom profiles for different parts of your day (e.g., "Work Focus" from 9am-5pm, "Study Time" from 7pm-10pm)
- **App & Category Blocking**: Select specific apps or entire categories to block during focus sessions
- **Schedule-Based Activation**: Profiles automatically activate based on your configured schedule and days
- **No Bypass Options**: Once a focus session starts, blocked apps remain blocked until the scheduled end time
- **Multiple Profiles**: Create different profiles for different needs with unique schedules and blocked apps

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
├── FocusCageApp.swift          # App entry point
├── ContentView.swift            # Main tab view
├── Models/
│   └── FocusProfile.swift       # Profile data model with schedule
├── Managers/
│   ├── ProfileManager.swift     # Profile CRUD and scheduling
│   └── ScreenTimeManager.swift  # Screen Time API integration
└── Views/
    ├── ProfileListView.swift    # List of all profiles
    ├── ProfileDetailView.swift  # Edit existing profile
    ├── CreateProfileView.swift  # Create new profile wizard
    ├── AppSelectionView.swift   # App picker wrapper
    ├── ScheduleView.swift       # Time and day selection
    ├── ActiveProfileView.swift  # Current session status
    └── SettingsView.swift       # App settings and about
```

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **FamilyControls**: Apple's framework for parental controls and screen time management
- **ManagedSettings**: Framework for applying app restrictions
- **DeviceActivity**: Framework for monitoring and responding to device usage

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

- [ ] Widget showing current focus status
- [ ] Focus session statistics and history
- [ ] iCloud sync for profiles across devices
- [ ] Notification reminders before sessions start
- [ ] Emergency contact allowlist
- [ ] Focus session streaks and achievements

## License

MIT License - See LICENSE file for details
