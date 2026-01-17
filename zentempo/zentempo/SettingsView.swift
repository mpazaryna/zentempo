//
//  SettingsView.swift
//  zentempo
//
//  Created by MATTHEW PAZARYNA on 8/24/25.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var timer: PomodoroTimer
    @Environment(\.dismiss) var dismiss
    @State private var launchAtLogin = false
    @State private var showingResetConfirmation = false
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "Unknown"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                Section("Timer Durations") {
                    HStack {
                        Text("Work Session")
                        Spacer()
                        Stepper("\(timer.workDuration / 60) min", 
                               value: Binding(
                                   get: { timer.workDuration / 60 },
                                   set: { timer.workDuration = $0 * 60 }
                               ),
                               in: 1...60)
                    }
                    
                    HStack {
                        Text("Short Break")
                        Spacer()
                        Stepper("\(timer.shortBreakDuration / 60) min",
                               value: Binding(
                                   get: { timer.shortBreakDuration / 60 },
                                   set: { timer.shortBreakDuration = $0 * 60 }
                               ),
                               in: 1...30)
                    }
                    
                    HStack {
                        Text("Long Break")
                        Spacer()
                        Stepper("\(timer.longBreakDuration / 60) min",
                               value: Binding(
                                   get: { timer.longBreakDuration / 60 },
                                   set: { timer.longBreakDuration = $0 * 60 }
                               ),
                               in: 1...60)
                    }
                    
                    HStack {
                        Text("Sessions until long break")
                        Spacer()
                        Stepper("\(timer.sessionsUntilLongBreak)",
                               value: $timer.sessionsUntilLongBreak,
                               in: 2...10)
                    }
                }
                
                Section("Behavior") {
                    Toggle("Auto-start next session", isOn: $timer.autoStartNextSession)
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            setLaunchAtLogin(newValue)
                        }
                }
                
                Section("Notifications") {
                    HStack {
                        Text("Notification Sound")
                        Spacer()
                        Picker("Sound", selection: $timer.notificationSound) {
                            ForEach(PomodoroTimer.getAvailableSounds(), id: \.rawValue) { sound in
                                Text(sound.displayName).tag(sound.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    Toggle("Persistent notifications", isOn: $timer.persistentNotifications)
                        .help("Makes notifications more attention-grabbing and harder to dismiss")
                }
                
                Section("Statistics") {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Lifetime Pomodoros: \(timer.lifetimePomodoroCount)")
                        Spacer()
                        Button("Reset") {
                            showingResetConfirmation = true
                        }
                        .buttonStyle(.link)
                        .foregroundColor(.red)
                    }

                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Version: \(appVersion)")
                        Spacer()
                    }
                }

                Section("Data Export") {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.green)
                        Text("Export session history")
                        Spacer()
                        Button("JSON") {
                            timer.saveExport(format: "json")
                        }
                        .buttonStyle(.bordered)
                        Button("CSV") {
                            timer.saveExport(format: "csv")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 540)
        .onAppear {
            checkLaunchAtLogin()
        }
        .alert("Reset Lifetime Counter?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                timer.resetLifetimeCounter()
            }
        } message: {
            Text("This will reset your lifetime pomodoro count to zero. This action cannot be undone.")
        }
    }
    
    private func resetToDefaults() {
        timer.workDuration = 25 * 60
        timer.shortBreakDuration = 5 * 60
        timer.longBreakDuration = 15 * 60
        timer.sessionsUntilLongBreak = 4
        timer.autoStartNextSession = false
        timer.notificationSound = "default"
        timer.persistentNotifications = true
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
    
    private func checkLaunchAtLogin() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}