//
//  MenuBarManager.swift
//  zentempo
//
//  Created by MATTHEW PAZARYNA on 8/24/25.
//

import SwiftUI
import AppKit

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var timer: PomodoroTimer
    
    init(timer: PomodoroTimer) {
        self.timer = timer
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        let iconName: String
        let tintColor: NSColor
        
        switch timer.currentState {
        case .idle:
            iconName = "timer"
            tintColor = .labelColor
        case .work:
            iconName = "timer.circle.fill"
            tintColor = .systemBlue
        case .shortBreak:
            iconName = "leaf.circle.fill"
            tintColor = .systemGreen
        case .longBreak:
            iconName = "sparkles.rectangle.stack.fill"
            tintColor = .systemPurple
        }
        
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "ZenTempo") {
            image.isTemplate = true
            button.image = image
            button.contentTintColor = tintColor
        }
        
        // Show time remaining in menu bar
        if timer.isRunning {
            let minutes = timer.timeRemaining / 60
            let seconds = timer.timeRemaining % 60
            button.title = String(format: " %02d:%02d", minutes, seconds)
        } else {
            button.title = ""
        }
    }
    
    @objc private func togglePopover() {
        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 300, height: 400)
            popover?.behavior = .transient
            popover?.animates = true
            popover?.contentViewController = NSHostingController(rootView: MenuBarView(timer: timer))
        }
        
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func showPopover() {
        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 300, height: 400)
            popover?.behavior = .transient
            popover?.animates = true
            popover?.contentViewController = NSHostingController(rootView: MenuBarView(timer: timer))
        }
        
        guard let button = statusItem?.button else { return }
        
        if let popover = popover, !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}