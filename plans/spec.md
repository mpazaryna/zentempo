# ZenTempo: macOS Menu Bar Pomodoro Timer Spec

## Project Overview
Create a macOS menu bar pomodoro timer application called "ZenTempo" that helps users maintain focus through timed work sessions. The app should be unobtrusive, living in the menu bar, and follow the pomodoro technique with customizable work/break intervals.

## Core Features
- Menu bar presence with icon indicating timer state
- Standard pomodoro functionality (25 min work, 5 min break, 15 min long break after 4 work sessions)
- Customizable work/break durations
- Desktop notifications for session transitions
- Ability to pause, resume, and reset timer
- Auto-start next session option
- Basic session tracking (completed today)
- Launch at login option

## Technical Requirements
- Swift & SwiftUI for macOS
- Target macOS 12.0+
- No external dependencies required
- Persistent settings using UserDefaults
- Notification support via NSUserNotification

## UI Components
- Menu bar icon with dropdown menu
- Settings panel
- Timer display in menu
- Visual indication of current state (work/break)

## Implementation Details
1. Create NSStatusBar item with custom icon
2. Implement timer logic with work/break alternation
3. Build dropdown menu with timer controls and settings
4. Add notification system for session transitions
5. Create preferences UI for customizing durations
6. Implement session tracking
7. Add launch at login functionality
8. Persist settings between app launches

## Application Flow
1. App launches to menu bar (no dock icon)
2. Initial state is idle with option to start
3. User initiates timer from dropdown menu
4. Timer runs in background, updating icon
5. Notifications appear at session transitions
6. User can control timer via dropdown menu
7. Settings persist between sessions

## Design Notes
- Clean, minimalist interface
- Color coding: work (blue), short break (green), long break (purple)
- Menu bar icon should indicate time remaining
- Zen/yoga/music influences in visual design

## Stretch Goals
- Sound cues for transitions
- Focus mode integration
- Dark/light mode support
- Basic productivity statistics
- Custom session names

This spec provides a complete blueprint for creating ZenTempo as a useful, focused productivity tool that reflects your background as a yoga teacher and musician.