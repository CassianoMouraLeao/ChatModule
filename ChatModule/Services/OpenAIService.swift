//
//  OpenAIService.swift
//  ChatModule
//
//  LLMService implementation that talks to ANY OpenAI-compatible
//  /chat/completions endpoint via URLSession + JSONEncoder/JSONDecoder.
//
//  Default config points at GitHub Models — a free tier that exposes models
//  like openai/gpt-4o-mini behind the OpenAI API contract, authenticated with
//  a GitHub Personal Access Token (PAT) carrying the `models:read` scope.
//
//  To swap to OpenAI proper / Groq / OpenRouter, change baseURL + model when
//  instantiating — no other code changes needed.
//

import Foundation

// MARK: - Errors

nonisolated enum LLMServiceError: LocalizedError {
    case missingAPIKey(provider: String)
    case invalidResponse
    case httpError(status: Int, message: String?)
    case decodingFailed(underlying: Error)
    case noChoices

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "Missing API key for \(provider). Set GITHUB_MODELS_TOKEN in Secrets.xcconfig (see README)."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let status, let message):
            return "HTTP \(status): \(message ?? "no message from server")"
        case .decodingFailed(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .noChoices:
            return "The model returned no choices."
        }
    }
}

// MARK: - Service

nonisolated struct OpenAIService: LLMService {

    // Default endpoint = GitHub Models. Override in init for other providers.
    static let defaultBaseURL = URL(string: "https://models.github.ai/inference")!

    let apiKey: String
    let baseURL: URL
    let model: String
    let systemPrompt: String
    let temperature: Double
    let maxTokens: Int
    let urlSession: URLSession

    init(
        apiKey: String,
        baseURL: URL = OpenAIService.defaultBaseURL,
        model: String = "openai/gpt-4o-mini",
        systemPrompt: String = "You are a helpful AI assistant. Be concise and friendly. Reply in the language the user wrote.",
        temperature: Double = 0.7,
        maxTokens: Int = 1024,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.urlSession = urlSession
    }

    // MARK: - LLMService

    func sendMessage(_ prompt: String, history: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMServiceError.missingAPIKey(provider: "GitHub Models / OpenAI")
        }

        // Build the request
        let request = try makeRequest(prompt: prompt, history: history)

        // Fire it
        let (data, response) = try await urlSession.data(for: request)

        // Validate HTTP status
        guard let http = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = decodeErrorMessage(from: data)
                ?? String(data: data, encoding: .utf8)
            throw LLMServiceError.httpError(status: http.statusCode, message: message)
        }

        // Decode success
        do {
            let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content,
                  !content.isEmpty
            else { throw LLMServiceError.noChoices }
            return content
        } catch let error as LLMServiceError {
            throw error
        } catch {
            throw LLMServiceError.decodingFailed(underlying: error)
        }
    }

    // MARK: - Private

    private func makeRequest(prompt: String, history: [ChatMessage]) throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.setValue("application/json",  forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let messages = buildMessages(from: history, newPrompt: prompt)
        let body = OpenAIChatRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    /// Maps ChatModule's `[ChatMessage]` to OpenAI's `[OpenAIMessage]`.
    ///
    /// Rules:
    ///   • Always prepend our own system prompt.
    ///   • Skip UI-level system messages ("Now chatting with X") — they're
    ///     informational for the user, not instructions for the model.
    ///   • Trust that `history` already contains the just-appended user prompt
    ///     (matches what ChatViewModel.sendMessage does).
    private func buildMessages(from history: [ChatMessage], newPrompt: String) -> [OpenAIMessage] {
        var messages: [OpenAIMessage] = [
            OpenAIMessage(role: "system", content: systemPrompt)
        ]

        for msg in history {
            switch msg.role {
            case .system:
                continue   // skip UI system messages
            case .user:
                messages.append(OpenAIMessage(role: "user", content: msg.content))
            case .assistant:
                messages.append(OpenAIMessage(role: "assistant", content: msg.content))
            }
        }

        // Safety net: if history was empty for some reason, ensure the prompt
        // is the last user message.
        if messages.last?.role != "user" {
            messages.append(OpenAIMessage(role: "user", content: newPrompt))
        }

        return messages
    }

    /// Tries to pull a readable `message` field out of a 4xx/5xx JSON body.
    private func decodeErrorMessage(from data: Data) -> String? {
        if let parsed = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
            return parsed.error.message
        }
        return nil
    }
}
