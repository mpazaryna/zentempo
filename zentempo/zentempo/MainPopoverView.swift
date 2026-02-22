//
//  MainPopoverView.swift
//  zentempo
//

import SwiftUI

struct MainPopoverView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var telosManager: TelosManager

    enum Tab: String, CaseIterable {
        case timer = "Timer"
        case skills = "Skills"
    }

    @State private var selectedTab: Tab = .timer

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            switch selectedTab {
            case .timer:
                MenuBarView(timer: timer)
            case .skills:
                TelosView(telosManager: telosManager)
                    .onAppear {
                        if telosManager.agents.isEmpty && telosManager.errorMessage == nil {
                            telosManager.refresh()
                        }
                    }
            }
        }
    }
}
