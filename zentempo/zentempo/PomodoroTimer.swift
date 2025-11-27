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
    @Published var sessionsCompleted: Int = 0
    @Published var sessionsCompletedToday: Int = 0
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
    private var workSessionsCount: Int = 0
    private var quotes: MotivationalQuotes?
    
    init() {
        loadTodaysSessions()
        loadQuotes()
    }
    
    func start() {
        if currentState == .idle {
            currentState = .work
            timeRemaining = workDuration
        }
        
        isRunning = true
        isPaused = false
        startTimer()
    }
    
    func pause() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        if isPaused {
            isRunning = true
            isPaused = false
            startTimer()
        }
    }
    
    func reset() {
        timer?.invalidate()
        timer = nil
        currentState = .idle
        timeRemaining = 0
        isRunning = false
        isPaused = false
    }
    
    func skip() {
        completeCurrentSession()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.tick()
        }
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeCurrentSession()
        }
    }
    
    private func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        
        // Send notification
        sendNotification()
        
        // Update session counts
        if currentState == .work {
            sessionsCompleted += 1
            sessionsCompletedToday += 1
            lifetimePomodoroCount += 1
            saveTodaysSessions()
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
            startTimer()
        } else {
            isRunning = false
            isPaused = false
        }
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
    
    private func loadTodaysSessions() {
        let dateKey = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        sessionsCompletedToday = UserDefaults.standard.integer(forKey: "sessions_\(dateKey)")
    }
    
    private func saveTodaysSessions() {
        let dateKey = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        UserDefaults.standard.set(sessionsCompletedToday, forKey: "sessions_\(dateKey)")
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
}