//
//  zentempoTests.swift
//  zentempoTests
//
//  Created by MATTHEW PAZARYNA on 8/23/25.
//

import Testing
import Foundation
@testable import zentempo

struct PomodoroTimerTests {
    
    // MARK: - Initial State Tests
    
    @Test("Initial state is correct")
    func testInitialState() async throws {
        let timer = PomodoroTimer()
        
        #expect(timer.currentState == .idle)
        #expect(timer.timeRemaining == 0)
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
        #expect(timer.sessionsCompleted == 0)
        #expect(timer.sessionsCompletedToday == 0)
    }
    
    // MARK: - Timer Control Tests
    
    @Test("Pausing timer works correctly")
    func testPauseTimer() async throws {
        let timer = PomodoroTimer()
        
        timer.start()
        timer.pause()
        
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == true)
        #expect(timer.currentState == .work)
    }
    
    @Test("Resuming timer works correctly")
    func testResumeTimer() async throws {
        let timer = PomodoroTimer()
        
        timer.start()
        timer.pause()
        timer.resume()
        
        #expect(timer.isRunning == true)
        #expect(timer.isPaused == false)
        #expect(timer.currentState == .work)
    }
    
    @Test("Resetting timer works correctly")
    func testResetTimer() async throws {
        let timer = PomodoroTimer()
        
        timer.start()
        timer.reset()
        
        #expect(timer.currentState == .idle)
        #expect(timer.timeRemaining == 0)
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
    }
    
    // MARK: - Time Formatting Tests
    
    @Test("Time formatting works correctly")
    func testTimeFormatting() async throws {
        let timer = PomodoroTimer()
        
        timer.timeRemaining = 1500 // 25 minutes
        #expect(timer.formattedTime() == "25:00")
        
        timer.timeRemaining = 300 // 5 minutes
        #expect(timer.formattedTime() == "05:00")
        
        timer.timeRemaining = 61 // 1 minute 1 second
        #expect(timer.formattedTime() == "01:01")
        
        timer.timeRemaining = 30 // 30 seconds
        #expect(timer.formattedTime() == "00:30")
        
        timer.timeRemaining = 0
        #expect(timer.formattedTime() == "00:00")
    }
    
    // MARK: - Session Description Tests
    
    @Test("Session descriptions are correct")
    func testSessionDescriptions() async throws {
        let timer = PomodoroTimer()
        
        #expect(timer.sessionDescription() == "Ready to focus?")
        
        timer.currentState = .work
        #expect(timer.sessionDescription() == "Focus Time")
        
        timer.currentState = .shortBreak
        #expect(timer.sessionDescription() == "Short Break")
        
        timer.currentState = .longBreak
        #expect(timer.sessionDescription() == "Long Break")
    }
    
    // MARK: - Settings Tests
    
    @Test("Custom durations can be set")
    func testCustomDurations() async throws {
        let timer = PomodoroTimer()
        
        timer.workDuration = 30 * 60 // 30 minutes
        timer.shortBreakDuration = 10 * 60 // 10 minutes
        timer.longBreakDuration = 20 * 60 // 20 minutes
        
        #expect(timer.workDuration == 30 * 60)
        #expect(timer.shortBreakDuration == 10 * 60)
        #expect(timer.longBreakDuration == 20 * 60)
    }
    
    @Test("Auto-start setting works")
    func testAutoStartSetting() async throws {
        let timer = PomodoroTimer()
        
        timer.autoStartNextSession = true
        #expect(timer.autoStartNextSession == true)
        
        timer.autoStartNextSession = false
        #expect(timer.autoStartNextSession == false)
    }
    
    // MARK: - Lifetime Counter Tests
    
    @Test("Lifetime counter can be reset")
    func testLifetimeCounterReset() async throws {
        let timer = PomodoroTimer()
        
        timer.lifetimePomodoroCount = 10
        #expect(timer.lifetimePomodoroCount == 10)
        
        timer.resetLifetimeCounter()
        #expect(timer.lifetimePomodoroCount == 0)
    }
    
    // MARK: - Integration Tests
    
    @Test("Start from idle goes to work state")
    func testStateTransitionFromIdle() async throws {
        let timer = PomodoroTimer()
        
        #expect(timer.currentState == .idle)
        
        timer.start()
        
        #expect(timer.currentState == .work)
        #expect(timer.timeRemaining == timer.workDuration)
    }
    
    @Test("Timer can be started multiple times safely")
    func testMultipleStarts() async throws {
        let timer = PomodoroTimer()
        
        timer.start()
        let firstTimeRemaining = timer.timeRemaining
        let firstState = timer.currentState
        
        // Starting again should not change the state if already running
        timer.start()
        
        #expect(timer.currentState == firstState)
        #expect(timer.isRunning == true)
    }
}
