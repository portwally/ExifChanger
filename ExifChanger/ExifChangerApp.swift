//
//  ExifChangerApp.swift
//  ExifChanger
//
//  Created by Walter Tengler on 14/02/2026.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep app running when window is closed (standard macOS behavior)
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // Reopen main window when user clicks Dock icon
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // No visible windows, create/show the main window
            for window in sender.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(self)
                    return true
                }
            }
            // If no existing window, post notification to create one
            NotificationCenter.default.post(name: .showMainWindow, object: nil)
        }
        return true
    }
}

@main
struct ExifChangerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            MainView()
                .onReceive(NotificationCenter.default.publisher(for: .showMainWindow)) { _ in
                    NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
                }
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 950, height: 650)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "New Window")) {
                    openWindow(id: "main")
                }
                .keyboardShortcut("n", modifiers: .command)

                Button(String(localized: "Open Photos...")) {
                    NotificationCenter.default.post(name: .openPhotos, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            // Window menu item to show main window
            CommandGroup(after: .windowList) {
                Divider()
                Button(String(localized: "Show ExifEasy")) {
                    showMainWindow()
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandGroup(replacing: .help) {
                Button(String(localized: "ExifEasy Help")) {
                    NotificationCenter.default.post(name: .showHelp, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        // Help Window
        Window(String(localized: "Help"), id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)
    }

    private func showMainWindow() {
        // Try to show existing window first
        for window in NSApplication.shared.windows {
            if window.identifier?.rawValue.contains("main") == true ||
               window.title == "ExifEasy" ||
               (window.canBecomeMain && window.contentView != nil) {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }
        }
        // If no window exists, the WindowGroup will create one automatically
        // when we activate the app
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let openPhotos = Notification.Name("openPhotos")
    static let showHelp = Notification.Name("showHelp")
    static let showMainWindow = Notification.Name("showMainWindow")
}
