//
//  ChatMessage.swift
//  ChatModule
//
//  Plain value type representing a single message in the conversation.
//

import Foundation

/// Who sent the message.
nonisolated enum ChatRole: String, Hashable, Codable {
    case user
    case assistant
    /// Reserved for system / status messages (e.g. "Provider switched to OpenAI").
    case system
}

// `nonisolated` so message values can be passed freely between actors (e.g.
// from the LLMService running off-main back to the main-actor ViewModel).
nonisolated struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let role: ChatRole
    var content: String
    let timestamp: Date
    /// The provider that generated the message (for assistant messages). `nil`
    /// for user/system messages.
    let provider: LLMProvider?

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        timestamp: Date = Date(),
        provider: LLMProvider? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.provider = provider
    }

    // MARK: - Convenience

    var isUser: Bool { role == .user }
    var isAssistant: Bool { role == .assistant }
    var isSystem: Bool { role == .system }

    /// Short timestamp like "14:32" used under each bubble.
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}
