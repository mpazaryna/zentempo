//
//  PomodoroTimer.swift
//  zentempo
//
//  Created by MATTHEW PAZARYNA on 8/24/25.
//

import SwiftUI
import Combine
import UserNotifications
import AVFoundation
import AppKit
import UniformTypeIdentifiers

enum TimerState {
    case idle
    case work
    case shortBreak
    case longBreak
}

struct MotivationalQuotes: Codable {
    let workComplete: [String]
    let breakComplete: [String]
    let longBreakComplete: [String]
    
    private enum CodingKeys: String, CodingKey {
        case workComplete = "work_complete"
        case breakComplete = "break_complete"
        case longBreakComplete = "long_break_complete"
    }
}

enum SystemSound: String, CaseIterable {
    case `default` = "default"
    case glass = "Glass"
    case hero = "Hero"
    case morse = "Morse"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case tink = "Tink"
    
    var displayName: String {
        switch self {
        case .default:
            return "Default"
        default:
            return rawValue
        }
    }
    
    var notificationSound: UNNotificationSound {
        switch self {
        case .default:
            return .default
        default:
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(rawValue).aiff"))
        }
    }
}

class PomodoroTimer: ObservableObject {
    @Published var currentState: TimerState = .idle
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentTaskLabel: String = ""
    @Published var sessionsCompleted: Int = 0
    @Published var sessionsCompletedToday: Int = 0
    @Published var sessionsCompletedThisWeek: Int = 0
    @AppStorage("lifetimePomodoroCount") var lifetimePomodoroCount: Int = 0
    @AppStorage("notificationSound") var notificationSound: String = "default"
    @AppStorage("persistentNotifications") var persistentNotifications: Bool = true
    
    // Settings with defaults
    @AppStorage("workDuration") var workDuration: Int = 25 * 60 // 25 minutes
    @AppStorage("shortBreakDuration") var shortBreakDuration: Int = 5 * 60 // 5 minutes
    @AppStorage("longBreakDuration") var longBreakDuration: Int = 15 * 60 // 15 minutes
    @AppStorage("autoStartNextSession") var autoStartNextSession: Bool = false
    @AppStorage("sessionsUntilLongBreak") var sessionsUntilLongBreak: Int = 4
    
    private var timer: Timer?
    private var endDate: Date?
    private var pausedTimeRemaining: Int?
    private var workSessionsCount: Int = 0
    private var quotes: MotivationalQuotes?
    private var persistentReminderTimer: Timer?
    
    init() {
        loadTodaysSessions()
        loadWeekSessions()
        loadQuotes()
    }
    
    func start() {
        stopPersistentReminder()
        if currentState == .idle {
            currentState = .work
            timeRemaining = workDuration
        }

        isRunning = true
        isPaused = false
        endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        pausedTimeRemaining = nil
        startTimer()
    }

    func pause() {
        isRunning = false
        isPaused = true
        pausedTimeRemaining = timeRemaining
        endDate = nil
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        if isPaused {
            isRunning = true
            isPaused = false
            let remaining = pausedTimeRemaining ?? timeRemaining
            endDate = Date().addingTimeInterval(TimeInterval(remaining))
            pausedTimeRemaining = nil
            startTimer()
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        pausedTimeRemaining = nil
        stopPersistentReminder()
        currentState = .idle
        timeRemaining = 0
        isRunning = false
        isPaused = false
        currentTaskLabel = ""
    }
    
    func skip() {
        completeCurrentSession()
    }
    
    private func startTimer() {
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.tick()
        }
        // Fire during UI interactions (menu tracking, popover) too
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func tick() {
        guard let endDate = endDate else { return }
        let remaining = Int(ceil(endDate.timeIntervalSinceNow))
        if remaining > 0 {
            if timeRemaining != remaining {
                timeRemaining = remaining
            }
        } else {
            timeRemaining = 0
            completeCurrentSession()
        }
    }
    
    private func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        pausedTimeRemaining = nil
        
        // Send notification
        sendNotification()
        
        // Update session counts
        if currentState == .work {
            sessionsCompleted += 1
            sessionsCompletedToday += 1
            lifetimePomodoroCount += 1
            saveTodaysSessions()
            saveSessionLog()
            workSessionsCount += 1
        }
        
        // Determine next state
        let nextState: TimerState
        switch currentState {
        case .idle:
            nextState = .work
        case .work:
            if workSessionsCount >= sessionsUntilLongBreak {
                nextState = .longBreak
                workSessionsCount = 0
            } else {
                nextState = .shortBreak
            }
        case .shortBreak, .longBreak:
            nextState = .work
        }
        
        // Set up next session
        currentState = nextState
        switch nextState {
        case .idle:
            timeRemaining = 0
        case .work:
            timeRemaining = workDuration
        case .shortBreak:
            timeRemaining = shortBreakDuration
        case .longBreak:
            timeRemaining = longBreakDuration
        }
        
        // Auto-start if enabled
        if autoStartNextSession {
            isRunning = true
            endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
            startTimer()
        } else {
            isRunning = false
            isPaused = false
            // Re-fire notification periodically until user acts
            if persistentNotifications {
                startPersistentReminder()
            }
        }
    }
    
    private func startPersistentReminder() {
        persistentReminderTimer?.invalidate()
        let reminderTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPersistentReminder()
        }
        RunLoop.current.add(reminderTimer, forMode: .common)
        persistentReminderTimer = reminderTimer
    }

    func stopPersistentReminder() {
        persistentReminderTimer?.invalidate()
        persistentReminderTimer = nil
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["zentempo-persistent-reminder"])
    }

    private func sendPersistentReminder() {
        let content = UNMutableNotificationContent()

        switch currentState {
        case .work:
            content.title = "Ready to focus? ⚡"
            content.body = "Your break ended. Start your next work session!"
        case .shortBreak, .longBreak:
            content.title = "Time for a break! 🎉"
            content.body = "Work session complete. Take your well-earned break!"
        case .idle:
            stopPersistentReminder()
            return
        }

        if let selectedSound = SystemSound(rawValue: notificationSound) {
            content.sound = selectedSound.notificationSound
        } else {
            content.sound = .default
        }

        content.categoryIdentifier = "TIMER_COMPLETE"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.threadIdentifier = "zentempo-timer"

        // Use a fixed identifier so it replaces the previous reminder
        let request = UNNotificationRequest(identifier: "zentempo-persistent-reminder", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        
        switch currentState {
        case .idle:
            return
        case .work:
            content.title = "Work Session Complete! 🎉"
            if let randomQuote = getRandomQuote(for: .work) {
                content.body = randomQuote
            } else {
                content.body = workSessionsCount >= sessionsUntilLongBreak - 1 ? 
                    "Time for a long break!" : "Time for a short break!"
            }
        case .shortBreak:
            content.title = "Break Complete! ⚡"
            if let randomQuote = getRandomQuote(for: .shortBreak) {
                content.body = randomQuote
            } else {
                content.body = "Ready to focus again?"
            }
        case .longBreak:
            content.title = "Long Break Complete! 🚀"
            if let randomQuote = getRandomQuote(for: .longBreak) {
                content.body = randomQuote
            } else {
                content.body = "Great job! Ready for another round?"
            }
        }
        
        // Set the sound based on user preference
        if let selectedSound = SystemSound(rawValue: notificationSound) {
            content.sound = selectedSound.notificationSound
        } else {
            content.sound = .default
        }

        // Configure notification for persistence
        content.categoryIdentifier = "TIMER_COMPLETE"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        // Add thread identifier to group notifications
        content.threadIdentifier = "zentempo-timer"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            }
        }
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "sessions_\(formatter.string(from: date))"
    }

    private func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }

    private func loadTodaysSessions() {
        sessionsCompletedToday = UserDefaults.standard.integer(forKey: dateKey(for: Date()))
    }

    private func saveTodaysSessions() {
        UserDefaults.standard.set(sessionsCompletedToday, forKey: dateKey(for: Date()))
        loadWeekSessions()
    }

    private func loadWeekSessions() {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        let weekStart = startOfWeek(for: Date())

        var total = 0
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                total += UserDefaults.standard.integer(forKey: dateKey(for: day))
            }
        }
        sessionsCompletedThisWeek = total
    }
    
    func formattedTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func sessionDescription() -> String {
        switch currentState {
        case .idle:
            return "Ready to focus?"
        case .work:
            return "Focus Time"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    func resetLifetimeCounter() {
        lifetimePomodoroCount = 0
    }
    
    private func loadQuotes() {
        guard let path = Bundle.main.path(forResource: "motivational_quotes", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let quotes = try? JSONDecoder().decode(MotivationalQuotes.self, from: data) else {
            print("Could not load motivational quotes")
            return
        }
        self.quotes = quotes
    }
    
    private func getRandomQuote(for state: TimerState) -> String? {
        guard let quotes = quotes else { return nil }
        
        let quoteArray: [String]
        switch state {
        case .work:
            quoteArray = quotes.workComplete
        case .shortBreak:
            quoteArray = quotes.breakComplete
        case .longBreak:
            quoteArray = quotes.longBreakComplete
        case .idle:
            return nil
        }
        
        return quoteArray.randomElement()
    }
    
    static func getAvailableSounds() -> [SystemSound] {
        return SystemSound.allCases
    }

    // MARK: - Session Log

    struct SessionLogEntry: Codable {
        let date: String
        let task: String
        let durationMinutes: Int
    }

    private func saveSessionLog() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let entry = SessionLogEntry(
            date: formatter.string(from: Date()),
            task: currentTaskLabel.isEmpty ? "" : currentTaskLabel,
            durationMinutes: workDuration / 60
        )
        var logs = loadSessionLogs()
        logs.append(entry)
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "sessionLogs")
        }
    }

    private func loadSessionLogs() -> [SessionLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: "sessionLogs"),
              let logs = try? JSONDecoder().decode([SessionLogEntry].self, from: data) else {
            return []
        }
        return logs
    }

    // MARK: - Data Export

    struct SessionData: Codable {
        let date: String
        let sessions: Int
    }

    struct ExportData: Codable {
        let exportDate: String
        let lifetimeSessions: Int
        let dailySessions: [SessionData]
        let sessionLog: [SessionLogEntry]
    }

    func getAllSessionData() -> [SessionData] {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        var sessions: [SessionData] = []
        for key in allKeys where key.hasPrefix("sessions_") {
            let dateString = String(key.dropFirst("sessions_".count))
            let count = defaults.integer(forKey: key)
            if count > 0 {
                sessions.append(SessionData(date: dateString, sessions: count))
            }
        }

        return sessions.sorted { $0.date < $1.date }
    }

    func exportToJSON() -> Data? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let exportData = ExportData(
            exportDate: formatter.string(from: Date()),
            lifetimeSessions: lifetimePomodoroCount,
            dailySessions: getAllSessionData(),
            sessionLog: loadSessionLogs()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportData)
    }

    func exportToCSV() -> String {
        var csv = "date,task,duration_minutes\n"
        for entry in loadSessionLogs() {
            let escapedTask = entry.task.contains(",") ? "\"\(entry.task)\"" : entry.task
            csv += "\(entry.date),\(escapedTask),\(entry.durationMinutes)\n"
        }
        return csv
    }

    func saveExport(format: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false

        if format == "json" {
            panel.nameFieldStringValue = "zentempo_sessions.json"
            panel.allowedContentTypes = [.json]
        } else {
            panel.nameFieldStringValue = "zentempo_sessions.csv"
            panel.allowedContentTypes = [.commaSeparatedText]
        }

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            do {
                if format == "json" {
                    if let data = self.exportToJSON() {
                        try data.write(to: url)
                    }
                } else {
                    try self.exportToCSV().write(to: url, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}