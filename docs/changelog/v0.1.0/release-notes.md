# Version 0.1.0 Release Notes
*Released: 2024-08-24*

## Initial Release

Zentempo v0.1.0 is the initial release of our macOS menu bar pomodoro timer, built with SwiftUI and targeting macOS 15.5+.

## Core Features

### Pomodoro Timer Functionality
- **Work Sessions**: 25-minute focused work periods
- **Short Breaks**: 5-minute breaks between work sessions
- **Long Breaks**: 15-minute breaks after completing 4 work sessions
- **Customizable Durations**: All timer periods can be adjusted in settings

### Menu Bar Interface
- **Real-time Countdown**: Shows remaining time directly in the menu bar
- **State Icons**: Different icons for work, short break, and long break states
- **Color-coded Display**: Blue for work, green for short breaks, purple for long breaks
- **Click to Access**: Click menu bar icon to open control interface

### Session Tracking
- **Daily Sessions**: Track pomodoros completed today
- **Lifetime Counter**: Total pomodoro sessions completed
- **Persistent Storage**: Session data saved using UserDefaults

### Notifications
- **Native macOS Notifications**: System notifications when sessions complete
- **Sound Alerts**: Audible notification when timer finishes
- **Completion Messages**: Contextual messages for different session types

### Settings & Customization
- **Timer Duration Settings**: Customize work, short break, and long break durations
- **Auto-start Option**: Automatically begin next session after break
- **Sessions Until Long Break**: Configure how many work sessions before long break
- **Launch at Login**: Option to start Zentempo when macOS starts

### System Integration
- **Menu Bar Only**: No dock icon - lives entirely in menu bar (LSUIElement=true)
- **Light/Dark Mode**: Automatically adapts to system appearance
- **macOS 15.5+ Optimized**: Takes advantage of latest SwiftUI features
- **App Sandbox**: Runs with minimal permissions for security

## Technical Highlights

### Architecture
- **SwiftUI Interface**: Modern, native macOS UI
- **ObservableObject Pattern**: Reactive UI updates with @Published properties
- **UserNotifications Framework**: Native notification support
- **NSStatusItem**: Menu bar integration
- **Bundle Identifier**: `paz.zentempo`

### Development Standards
- **No External Dependencies**: Pure Swift/SwiftUI implementation
- **Swift Testing**: Unit tests using modern Swift Testing framework
- **XCTest UI Tests**: Automated UI testing
- **Xcode Project**: Standard Xcode development workflow

### User Experience
- **Minimal Interface**: Focused, distraction-free design
- **Keyboard Shortcuts**: Quick access to timer functions
- **Immediate Feedback**: Visual and audio confirmation of actions
- **Persistent Settings**: Preferences saved between sessions

## Installation
Built as a standard macOS application bundle, installed by copying to /Applications folder.

## Future Roadmap
This initial release establishes the foundation for future enhancements including:
- Enhanced notification persistence
- Custom notification sounds
- Motivational quotes and messages
- Advanced session analytics
- Productivity insights