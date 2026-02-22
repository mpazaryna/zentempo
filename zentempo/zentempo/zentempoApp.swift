//
//  zentempoApp.swift
//  zentempo
//
//  Created by MATTHEW PAZARYNA on 8/23/25.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var menuBarManager: MenuBarManager?
    var timer = PomodoroTimer()
    var telosManager = TelosManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        // Set up notification categories for better interaction
        setupNotificationCategories()
        
        // Set up menu bar
        menuBarManager = MenuBarManager(timer: timer, telosManager: telosManager)

        // Load telos agents
        telosManager.refresh()
        
        // Update icon when timer changes
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.menuBarManager?.updateIcon()
        }
    }
    
    private func setupNotificationCategories() {
        let startNextAction = UNNotificationAction(
            identifier: "START_NEXT",
            title: "Start Next Session",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "OK",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind in 5 min",
            options: []
        )
        
        let timerCompleteCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETE",
            actions: [startNextAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([timerCompleteCategory])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.sound, .badge, .list, .banner])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "START_NEXT":
            // Start the next session
            timer.start()
            menuBarManager?.showPopover()
        case "SNOOZE":
            // Schedule a reminder in 5 minutes
            scheduleSnoozeNotification()
        case "DISMISS", UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            break
        default:
            // User tapped on the notification itself
            menuBarManager?.showPopover()
        }
        completionHandler()
    }
    
    private func scheduleSnoozeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Reminder: Session Complete"
        content.body = "Your timer finished 5 minutes ago. Ready to continue?"
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "snooze-\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

@main
struct zentempoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
