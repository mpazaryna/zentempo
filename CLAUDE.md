# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Zentempo is a macOS menu bar pomodoro timer application built with SwiftUI, targeting macOS 15.5+. It's an Xcode-based project using Swift 5.0 that helps users maintain focus through timed work sessions.

## Key Commands

### Development Commands
All development is done through Xcode. From the command line:
```bash
# Open project in Xcode
open zentempo/zentempo.xcodeproj

# Build from command line
xcodebuild -project zentempo/zentempo.xcodeproj -scheme zentempo build

# Run tests
xcodebuild -project zentempo/zentempo.xcodeproj -scheme zentempo test

# Run a specific test
xcodebuild -project zentempo/zentempo.xcodeproj -scheme zentempo -only-testing:zentempoTests/TestClassName/testMethodName test
```

### Deployment Steps
To build and install the app to the Applications folder:
```bash
# 1. Build the app in Release configuration
xcodebuild -project zentempo/zentempo.xcodeproj -scheme zentempo -configuration Release build

# 2. Quit any running instance
pkill -x zentempo || true

# 3. Copy to Applications folder
cp -R ~/Library/Developer/Xcode/DerivedData/zentempo-*/Build/Products/Release/zentempo.app /Applications/

# 4. Launch the app
open /Applications/zentempo.app
```

Note: The app will request notification permissions on first launch. For persistent notifications, enable "Critical Alerts" in System Settings > Notifications > Zentempo.

## Architecture & Structure

### Project Layout
- `zentempo/zentempo/` - Main application source code
  - `zentempoApp.swift` - App entry point with NSApplicationDelegate for menu bar setup
  - `MenuBarManager.swift` - Manages NSStatusItem and menu bar interactions
  - `PomodoroTimer.swift` - Core timer logic and state management
  - `MenuBarView.swift` - SwiftUI popover content for menu bar
  - `SettingsView.swift` - Settings interface for customization
  - `ContentView.swift` - (Legacy from template, can be removed)
  - `Info.plist` - App configuration with LSUIElement for menu bar mode
  - `zentempo.entitlements` - App sandbox permissions
  - `Assets.xcassets/` - Images, colors, and app icon
- `zentempo/zentempoTests/` - Unit tests (uses Swift Testing framework)
- `zentempo/zentempoUITests/` - UI tests (uses XCTest framework)

### Key Architectural Decisions
1. **Menu Bar App**: Uses LSUIElement=true in Info.plist to hide dock icon
2. **NSApplicationDelegate**: Uses AppDelegate for menu bar initialization
3. **ObservableObject Pattern**: PomodoroTimer uses @Published for reactive UI
4. **UserDefaults Storage**: Settings persist using @AppStorage
5. **Notification Support**: Uses UserNotifications framework for session alerts
6. **SwiftUI Popover**: Menu dropdown uses NSPopover with SwiftUI content
7. **App Sandboxing**: Enabled with minimal permissions
8. **Testing Strategy**: 
   - Unit tests use Swift Testing (`@Test`, `#expect` syntax)
   - UI tests use XCTest framework
9. **No External Dependencies**: Pure Swift/SwiftUI project without package managers

### Core Components
- **PomodoroTimer**: Manages timer states (idle, work, shortBreak, longBreak), durations, and session tracking
- **MenuBarManager**: Handles NSStatusBar item, icon updates, and popover presentation
- **AppDelegate**: Initializes menu bar on app launch and manages timer updates

### Development Notes
- This is an Xcode project - use `.xcodeproj` file for all configuration changes
- Menu bar icon updates automatically with timer state and remaining time
- App targets macOS 15.5+ only
- Bundle identifier: `paz.zentempo`
- Supports launch at login via ServiceManagement framework