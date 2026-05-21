//
//  ChatModuleApp.swift
//  ChatModule
//

import SwiftUI
import FirebaseCore

@main
struct ChatModuleApp: App {

    // Configure Firebase before any view renders. This reads
    // GoogleService-Info.plist from the bundle and wires up:
    //   • Firebase AI Logic   → Gemini via GeminiFirebaseService
    //   • Firebase Remote Config → secrets via Secrets.swift
    init() {
        FirebaseApp.configure()

        // Pull secrets (GitHub Models token, etc.) from Remote Config.
        // Runs in the background — first launch may use empty defaults until
        // the network fetch completes, after that values are cached on disk.
        Task {
            await Secrets.bootstrap()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
