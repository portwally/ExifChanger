//
//  ExifChangerApp.swift
//  ExifChanger
//
//  Created by Walter Tengler on 14/02/2026.
//

import SwiftUI

@main
struct ExifChangerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 950, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "Open Photos...")) {
                    NotificationCenter.default.post(name: .openPhotos, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .help) {
                Button(String(localized: "ExifChanger Help")) {
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
}

extension Notification.Name {
    static let openPhotos = Notification.Name("openPhotos")
    static let showHelp = Notification.Name("showHelp")
}
