//
//  OpenAIModels.swift
//  ChatModule
//
//  Codable types mirroring the OpenAI Chat Completions API
//  (https://platform.openai.com/docs/api-reference/chat).
//
//  Works as-is with any OpenAI-compatible backend:
//      • OpenAI itself  → https://api.openai.com/v1
//      • GitHub Models  → https://models.github.ai/inference
//      • Groq           → https://api.groq.com/openai/v1
//      • OpenRouter     → https://openrouter.ai/api/v1
//
//  All types are `nonisolated` because the project default isolation is
//  MainActor — values need to cross the actor boundary when the OpenAIService
//  decodes them on a background URLSession task and returns to the main actor.
//

import Foundation

// MARK: - Request

/// POST body for /chat/completions.
nonisolated struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double?
    let maxTokens: Int?
    let stream: Bool?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

/// A single conversational turn. `role` is "system" | "user" | "assistant".
nonisolated struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Response

/// /chat/completions response body (non-streaming).
nonisolated struct OpenAIChatResponse: Decodable {
    let id: String?
    let model: String?
    let choices: [Choice]
    let usage: Usage?

    nonisolated struct Choice: Decodable {
        let index: Int?
        let message: OpenAIMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    nonisolated struct Usage: Decodable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens     = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens      = "total_tokens"
        }
    }
}

// MARK: - Error response (when the API returns a non-2xx with a JSON body)

nonisolated struct OpenAIErrorResponse: Decodable {
    let error: APIError

    nonisolated struct APIError: Decodable {
        let message: String?
        let type: String?
        let code: String?
    }
}
