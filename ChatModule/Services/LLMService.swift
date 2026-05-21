//
//  LLMService.swift
//  ChatModule
//
//  Abstraction the UI talks to. Implement one concrete service per provider
//  (OpenAIService, GeminiFirebaseService) and inject the right one
//  into ChatViewModel based on the user's selection.
//
//  IMPORTANT: marked `nonisolated` because the project uses
//  SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor — without nonisolated this
//  protocol would be implicitly MainActor-bound, which:
//   • forces every LLM API call onto the main thread (bad for performance)
//   • interacts badly with @StateObject's autoclosure and can crash SwiftUI.
//

import Foundation

nonisolated protocol LLMService {
    /// Sends the user's prompt to the LLM and returns the assistant reply.
    /// Throwing errors propagate to the UI as an inline error bubble.
    func sendMessage(_ prompt: String, history: [ChatMessage]) async throws -> String
}

// MARK: - Mock service (so the UI is fully usable right now)

/// Default placeholder that echoes a friendly reply so the UI can be tested
/// end-to-end before real provider integrations land. Swap for the real
/// service when ready.
nonisolated struct MockLLMService: LLMService {
    let provider: LLMProvider

    func sendMessage(_ prompt: String, history: [ChatMessage]) async throws -> String {
        // Simulate network latency so the typing indicator is visible.
        try await Task.sleep(nanoseconds: 1_200_000_000)
        return "👋 Hey! I'm a mock \(provider.displayName) reply. " +
               "Plug in the real \(provider.displayName) API and I'll be replaced. " +
               "Your prompt was: \"\(prompt)\""
    }
}
