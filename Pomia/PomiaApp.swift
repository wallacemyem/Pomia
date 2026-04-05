//
//  PomiaApp.swift
//  Pomia
//
//  Created by Wallace Aboiyar on 04/04/2026.
//

import SwiftUI

@main
struct PomiaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Pomia") {
                Button("Send Message") {
                    NotificationCenter.default.post(name: .pomiaSendMessage, object: nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Button("Focus Message Input") {
                    NotificationCenter.default.post(name: .pomiaFocusInput, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Divider()

                Button("Start Apfel Server") {
                    NotificationCenter.default.post(name: .pomiaStartServer, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
    }
}
