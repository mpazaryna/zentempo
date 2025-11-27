# Changelog

All notable changes to Zentempo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For detailed change information, see [docs/changelog/](docs/changelog/).

## [Unreleased]

### Added
- Persistent notifications with action buttons (Start Next, Snooze, Dismiss)
- Notification sound customization with system sounds
- Motivational quotes from JSON file on session completion
- Project structure with `plans/` and `docs/` folders for better organization

### Changed
- Notifications now use time-sensitive interruption level for better visibility
- Improved notification grouping with thread identifiers

### Fixed
- Notification sound playback issues
- Notifications disappearing too quickly
- Menu bar icon disappearing after notification interaction

## [0.1.0] - 2024-08-24

### Added
- Initial release of Zentempo menu bar pomodoro timer
- Core pomodoro timer functionality (25min work, 5min short break, 15min long break)
- Menu bar interface with real-time countdown display
- Session tracking (daily and lifetime pomodoro count)
- Settings for customizing timer durations
- Auto-start next session option
- Sound notifications for session completion
- macOS native notifications
- Launch at login support
- Keyboard shortcuts for timer control
- Light/dark mode support
- SwiftUI-based interface for macOS 15.5+

[Unreleased]: https://github.com/mpaz/zentempo/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mpaz/zentempo/releases/tag/v0.1.0