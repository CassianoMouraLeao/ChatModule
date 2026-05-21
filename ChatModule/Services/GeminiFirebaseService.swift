//
//  GeminiFirebaseService.swift
//  ChatModule
//
//  Concrete LLMService that talks to Gemini through Firebase AI Logic.
//
//  • No API key in this file. Authentication is handled server-side by
//    Firebase using the bundle ID + GoogleService-Info.plist.
//  • Free tier is available on Firebase's Spark plan (no credit card).
//  • Requires:
//      1. A Firebase project with this app's bundle ID registered.
//      2. GoogleService-Info.plist added to the ChatModule target.
//      3. Firebase AI Logic enabled in the Firebase Console.
//      4. The `FirebaseAI` SPM product added to the target.
//      5. `FirebaseApp.configure()` called at app start.
//

import Foundation
import FirebaseAI

nonisolated struct GeminiFirebaseService: LLMService {

    /// The Gemini model used for generation.
    /// `gemini-2.5-flash` is the recommended default — fast, multimodal,
    /// generous free quota. Switch to `gemini-2.5-pro` for higher-quality
    /// answers (slower, smaller quota) or `gemini-2.5-flash-lite` for the
    /// cheapest / fastest path.
    private let model: GenerativeModel

    init(modelName: String = "gemini-2.5-flash") {
        // `.googleAI()` uses the Gemini Developer API backend (the simpler,
        // free-tier-friendly path). `.vertexAI()` is the alternative for
        // Google Cloud / Vertex AI billing.
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        self.model = ai.generativeModel(modelName: modelName)
    }

    // MARK: - LLMService

    func sendMessage(_ prompt: String, history: [ChatMessage]) async throws -> String {
        // ChatViewModel appends the user's message to `messages` BEFORE
        // calling this. So `history.last` is the current prompt — drop it,
        // since we'll send it as the new turn via `chat.sendMessage(prompt)`.
        let priorHistory = history.dropLast()

        // Convert our ChatMessage history into Firebase's ModelContent.
        // Gemini's chat history accepts user/model roles in strict
        // alternation; we skip our `.system` chips.
        let chatHistory: [ModelContent] = priorHistory.compactMap { msg in
            switch msg.role {
            case .user:      return ModelContent(role: "user",  parts: msg.content)
            case .assistant: return ModelContent(role: "model", parts: msg.content)
            case .system:    return nil
            }
        }

        let chat = model.startChat(history: chatHistory)
        let response = try await chat.sendMessage(prompt)

        guard let text = response.text, !text.isEmpty else {
            // Safety filters or the model can return an empty payload —
            // surface a friendly error so the UI shows the inline error bubble.
            throw GeminiError.emptyResponse
        }
        return text
    }
}

// MARK: - Errors

nonisolated enum GeminiError: LocalizedError {
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Gemini returned an empty response. Try rephrasing your question."
        }
    }
}
