//
//  ChatViewModel.swift
//  ChatModule
//
//  MVVM: holds the conversation, the current LLM selection, the draft text
//  and the "is responding" flag.
//
//  Uses the modern @Observable macro (iOS 17+) instead of ObservableObject +
//  @Published. Combined with @State (not @StateObject) in the View, this
//  completely avoids the autoclosure / actor isolation crash that
//  @StateObject was triggering under Xcode 26 Approachable Concurrency.
//

import Foundation
import SwiftUI
import Observation

@Observable
final class ChatViewModel {

    // MARK: - State

    private(set) var messages: [ChatMessage] = []
    var draftText: String = ""
    // Defaults to Google (Gemini via Firebase AI Logic). OpenAI also works
    // when a GitHub Models token is configured in Firebase Remote Config.
    var selectedProvider: LLMProvider = .google
    private(set) var isResponding: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    /// Plug in a real implementation per provider. Defaults to a mock so the
    /// UI is fully functional without any backend.
    /// `@ObservationIgnored` — closures are not observable values; we don't
    /// want SwiftUI to re-render when this is reassigned.
    @ObservationIgnored
    var serviceFactory: (LLMProvider) -> LLMService

    // MARK: - Init

    // Note: uses the concrete class name `ChatViewModel.defaultServiceFactory`
    // instead of `Self.defaultServiceFactory` — Swift does not allow covariant
    // `Self` in default argument expressions.
    init(serviceFactory: @escaping (LLMProvider) -> LLMService = ChatViewModel.defaultServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    /// Default routing per provider. Each provider returns its real service
    /// implementation — no more placeholders.
    ///
    /// `nonisolated(unsafe)` — the closure type `(LLMProvider) -> LLMService`
    /// isn't `Sendable`, which trips strict concurrency on a `static let`.
    /// It's safe here: the property is an immutable `let`, the closure
    /// captures nothing, and it only constructs fresh value-type services on
    /// each call — there is no shared mutable state.
    nonisolated(unsafe) private static let defaultServiceFactory: (LLMProvider) -> LLMService = { provider in
        switch provider {
        case .google:
            return GeminiFirebaseService()
        case .openAI:
            return OpenAIService(apiKey: Secrets.githubModelsToken ?? "")
        }
    }

    // MARK: - Computed

    var isEmpty: Bool { messages.isEmpty }

    var trimmedDraft: String {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSend: Bool {
        !trimmedDraft.isEmpty && !isResponding
    }

    // MARK: - Intents

    func sendMessage() {
        let prompt = trimmedDraft
        guard !prompt.isEmpty, !isResponding else { return }

        // Append user message immediately.
        let userMessage = ChatMessage(role: .user, content: prompt)
        messages.append(userMessage)
        draftText = ""
        errorMessage = nil

        // Kick off the assistant reply.
        let provider = selectedProvider
        let service = serviceFactory(provider)
        let history = messages
        isResponding = true

        Task { [weak self] in
            do {
                let reply = try await service.sendMessage(prompt, history: history)
                self?.appendAssistantReply(reply, provider: provider)
            } catch {
                self?.handleSendError(error)
            }
        }
    }

    func clearChat() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            messages.removeAll()
            errorMessage = nil
        }
    }

    /// Switches the active provider and emits an inline system message so the
    /// user has visual feedback of the switch.
    func selectProvider(_ provider: LLMProvider) {
        guard provider != selectedProvider else { return }
        selectedProvider = provider
        let system = ChatMessage(
            role: .system,
            content: "Now chatting with \(provider.displayName)",
            provider: provider
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            messages.append(system)
        }
    }

    // MARK: - Private

    private func appendAssistantReply(_ content: String, provider: LLMProvider) {
        let reply = ChatMessage(role: .assistant, content: content, provider: provider)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            messages.append(reply)
            isResponding = false
        }
    }

    private func handleSendError(_ error: Error) {
        withAnimation(.spring(response: 0.4)) {
            isResponding = false
            errorMessage = error.localizedDescription
        }
    }
}
