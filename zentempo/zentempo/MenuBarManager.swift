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
    private var telosManager: TelosManager

    init(timer: PomodoroTimer, telosManager: TelosManager) {
        self.timer = timer
        self.telosManager = telosManager
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

        if timer.currentState == .idle {
            // Idle: show default SF Symbol
            if let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "ZenTempo") {
                image.isTemplate = true
                button.image = image
                button.contentTintColor = .labelColor
            }
            button.title = ""
            return
        }

        // Active session: draw progress ring
        let totalDuration: Int
        switch timer.currentState {
        case .work:
            totalDuration = timer.workDuration
        case .shortBreak:
            totalDuration = timer.shortBreakDuration
        case .longBreak:
            totalDuration = timer.longBreakDuration
        case .idle:
            totalDuration = 1
        }

        let progress = totalDuration > 0 ? Double(timeRemaining) / Double(totalDuration) : 0
        let color: NSColor
        switch timer.currentState {
        case .work:
            color = .systemBlue
        case .shortBreak:
            color = .systemGreen
        case .longBreak:
            color = .systemPurple
        case .idle:
            color = .labelColor
        }

        let image = drawProgressRing(progress: progress, color: color, paused: timer.isPaused)
        button.image = image
        button.contentTintColor = nil
        button.title = ""
    }

    private var timeRemaining: Int {
        timer.timeRemaining
    }

    private func drawProgressRing(progress: Double, color: NSColor, paused: Bool) -> NSImage {
        let size: CGFloat = 18
        let lineWidth: CGFloat = 2.0
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = (size - lineWidth) / 2

            // Background track
            let trackPath = NSBezierPath()
            trackPath.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            trackPath.lineWidth = lineWidth
            NSColor.tertiaryLabelColor.setStroke()
            trackPath.stroke()

            // Progress arc (clockwise from 12 o'clock)
            if progress > 0 {
                let startAngle: CGFloat = 90 // 12 o'clock
                let endAngle: CGFloat = startAngle - CGFloat(progress) * 360

                let arcPath = NSBezierPath()
                arcPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                arcPath.lineWidth = lineWidth
                arcPath.lineCapStyle = .round

                let drawColor = paused ? color.withAlphaComponent(0.5) : color
                drawColor.setStroke()
                arcPath.stroke()
            }

            return true
        }
        image.isTemplate = false
        return image
    }
    
    @objc private func togglePopover() {
        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 300, height: 450)
            popover?.behavior = .transient
            popover?.animates = true
            popover?.contentViewController = NSHostingController(rootView: MainPopoverView(timer: timer, telosManager: telosManager))
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
            popover?.contentSize = NSSize(width: 300, height: 450)
            popover?.behavior = .transient
            popover?.animates = true
            popover?.contentViewController = NSHostingController(rootView: MainPopoverView(timer: timer, telosManager: telosManager))
        }
        
        guard let button = statusItem?.button else { return }
        
        if let popover = popover, !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}