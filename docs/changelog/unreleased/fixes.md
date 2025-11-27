# Unreleased Fixes

## Notification Sound Not Playing
*Fixed: 2024-08-25*

### Problem
After implementing persistent notifications, the notification sound stopped playing.

### Root Cause
The sound configuration was correctly set but notifications were not being properly delivered due to permission and configuration issues.

### Solution
- Removed `criticalAlert` permission request (requires special entitlements)
- Ensured sound is set before all other notification properties
- Added error handling to notification delivery

---

## Notifications Disappearing Too Quickly
*Fixed: 2024-08-25*

### Problem
Notifications would appear briefly then auto-dismiss, defeating the purpose of persistent break reminders.

### Root Cause
Notifications were using default interruption level which allows automatic dismissal.

### Solution
- Set `.timeSensitive` interruption level
- Added maximum `relevanceScore` (1.0)
- Configured notification category with action buttons
- Added thread identifier for proper grouping

### User Action Required
Users should set notification style to "Alerts" (not "Banners") in System Settings for maximum persistence.

---

## Menu Bar Icon Disappearing
*Fixed: 2024-08-25*

### Problem
After completing a pomodoro session, the menu bar icon would sometimes disappear completely.

### Investigation
The app process was still running but the NSStatusItem was no longer visible in the menu bar.

### Solution
- Added defensive code in timer update loop
- Improved error handling in notification callbacks
- Ensured menu bar manager reference is properly maintained

### Notes
This appears to be related to macOS menu bar management when the app interacts with notifications. The fix ensures the status item remains registered even during notification interactions.