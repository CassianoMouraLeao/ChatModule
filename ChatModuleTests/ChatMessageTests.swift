//
//  ChatMessageTests.swift
//  ChatModuleTests
//

import XCTest
@testable import ChatModule

final class ChatMessageTests: XCTestCase {

    // MARK: - ChatRole

    func test_chatRole_hasAllExpectedCases() {
        let roles: [ChatRole] = [.user, .assistant, .system]
        XCTAssertEqual(roles.count, 3)
    }

    func test_chatRole_rawValuesAreLowercaseStrings() {
        XCTAssertEqual(ChatRole.user.rawValue, "user")
        XCTAssertEqual(ChatRole.assistant.rawValue, "assistant")
        XCTAssertEqual(ChatRole.system.rawValue, "system")
    }

    func test_chatRole_isCodable() throws {
        let encoded = try JSONEncoder().encode(ChatRole.assistant)
        let decoded = try JSONDecoder().decode(ChatRole.self, from: encoded)
        XCTAssertEqual(decoded, .assistant)
    }

    // MARK: - ChatMessage init

    func test_init_withDefaults_generatesIdAndTimestamp() {
        let msg = ChatMessage(role: .user, content: "Hello")
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "Hello")
        XCTAssertNil(msg.provider)
        XCTAssertNotNil(msg.id)
        XCTAssertLessThan(abs(msg.timestamp.timeIntervalSinceNow), 1.0,
                          "Default timestamp should be ~now")
    }

    func test_init_withExplicitProvider_isStored() {
        let msg = ChatMessage(role: .assistant, content: "Hi!", provider: .openAI)
        XCTAssertEqual(msg.provider, .openAI)
    }

    func test_init_eachMessageHasUniqueId() {
        let a = ChatMessage(role: .user, content: "A")
        let b = ChatMessage(role: .user, content: "A")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - Role helpers

    func test_isUser_trueOnlyForUserRole() {
        XCTAssertTrue(ChatMessage(role: .user, content: "").isUser)
        XCTAssertFalse(ChatMessage(role: .assistant, content: "").isUser)
        XCTAssertFalse(ChatMessage(role: .system, content: "").isUser)
    }

    func test_isAssistant_trueOnlyForAssistantRole() {
        XCTAssertFalse(ChatMessage(role: .user, content: "").isAssistant)
        XCTAssertTrue(ChatMessage(role: .assistant, content: "").isAssistant)
        XCTAssertFalse(ChatMessage(role: .system, content: "").isAssistant)
    }

    func test_isSystem_trueOnlyForSystemRole() {
        XCTAssertFalse(ChatMessage(role: .user, content: "").isSystem)
        XCTAssertFalse(ChatMessage(role: .assistant, content: "").isSystem)
        XCTAssertTrue(ChatMessage(role: .system, content: "").isSystem)
    }

    // MARK: - Timestamp formatting

    func test_formattedTimestamp_returnsHourMinuteFormat() {
        // 14:32 in any timezone — we build a precise Date.
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 21
        components.hour = 14
        components.minute = 32
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(from: components)!

        let msg = ChatMessage(role: .user, content: "x", timestamp: date)
        // Format depends on locale, but should always be "HH:mm" — 5 chars.
        XCTAssertEqual(msg.formattedTimestamp.count, 5)
        XCTAssertTrue(msg.formattedTimestamp.contains(":"))
    }

    // MARK: - Hashable / Equatable

    func test_messagesWithSameContentButDifferentIds_areNotEqual() {
        let a = ChatMessage(role: .user, content: "Hi")
        let b = ChatMessage(role: .user, content: "Hi")
        XCTAssertNotEqual(a, b)
    }

    func test_sameMessageEqualsItself() {
        let msg = ChatMessage(role: .user, content: "Hi")
        XCTAssertEqual(msg, msg)
    }
}
