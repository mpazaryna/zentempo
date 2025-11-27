# Unreleased Features

## Persistent Notifications with Actions
*Added: 2024-08-25*

### Overview
Implemented persistent notifications that require user interaction to dismiss, helping users who tend to ignore break notifications when in flow state.

### Implementation Details
- Added `UNUserNotificationCenterDelegate` to handle notification interactions
- Configured notifications with `.timeSensitive` interruption level
- Added `relevanceScore` of 1.0 for maximum priority
- Implemented thread grouping with identifier "zentempo-timer"

### Action Buttons
1. **Start Next Session** - Immediately starts the next timer session
2. **Remind in 5 min** - Schedules a snooze notification
3. **OK** - Dismisses the notification

### Technical Notes
- Critical alerts were considered but require special Apple entitlements
- Time-sensitive notifications provide good persistence without special permissions
- Action handlers can trigger app UI through `showPopover()` method

### Configuration Required
Users should enable "Time Sensitive" notifications in System Settings > Notifications > Zentempo

---

## Custom Notification Sounds
*Added: 2024-08-24*

### Overview
Added ability to select from 14 system sounds for timer completion notifications.

### Available Sounds
- Default, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Blow, Bottle, Frog, Funk, Tink

### Implementation
- Sounds are referenced using `UNNotificationSound(named:)` with system sound files
- User preference stored in UserDefaults as "notificationSound"
- Settings UI provides picker with all available options