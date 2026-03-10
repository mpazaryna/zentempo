//
//  MenuBarView.swift
//  zentempo
//
//  Created by MATTHEW PAZARYNA on 8/24/25.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var timer: PomodoroTimer
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("ZenTempo")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Task Label Input
            TextField("What are you working on?", text: $timer.currentTaskLabel)
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
                .onSubmit {
                    if timer.currentState == .idle {
                        timer.start()
                    }
                }

            // Timer Display
            VStack(spacing: 8) {
                Text(timer.sessionDescription())
                    .font(.headline)
                    .foregroundColor(sessionColor())

                Text(timer.formattedTime())
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(sessionColor())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(sessionColor().opacity(0.1))
            )
            
            // Control Buttons
            HStack(spacing: 16) {
                if timer.isRunning {
                    Button(action: { timer.pause() }) {
                        Label("Pause", systemImage: "pause.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { timer.skip() }) {
                        Label("Skip", systemImage: "forward.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                } else if timer.isPaused {
                    Button(action: { timer.resume() }) {
                        Label("Resume", systemImage: "play.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { timer.start() }) {
                        Label("Start", systemImage: "play.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: { timer.reset() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Session Counters
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Today: \(timer.sessionsCompletedToday) sessions")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("This week: \(timer.sessionsCompletedThisWeek) sessions")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Lifetime: \(timer.lifetimePomodoroCount) pomodoros")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            
            Divider()
            
            // Bottom Actions
            HStack {
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .frame(width: 280)
        .sheet(isPresented: $showingSettings) {
            SettingsView(timer: timer)
        }
    }
    
    private func sessionColor() -> Color {
        switch timer.currentState {
        case .idle:
            return .primary
        case .work:
            return .blue
        case .shortBreak:
            return .green
        case .longBreak:
            return .purple
        }
    }
}