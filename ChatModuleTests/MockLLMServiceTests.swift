//
//  MockLLMServiceTests.swift
//  ChatModuleTests
//

import XCTest
@testable import ChatModule

final class MockLLMServiceTests: XCTestCase {

    func test_sendMessage_returnsNonEmptyString() async throws {
        let service = MockLLMService(provider: .openAI)
        let reply = try await service.sendMessage("Hello", history: [])
        XCTAssertFalse(reply.isEmpty)
    }

    func test_sendMessage_echoesPrompt() async throws {
        let service = MockLLMService(provider: .google)
        let reply = try await service.sendMessage("ping", history: [])
        XCTAssertTrue(reply.contains("ping"),
                      "Expected mock reply to echo the prompt; got: \(reply)")
    }

    func test_sendMessage_includesProviderName() async throws {
        let service = MockLLMService(provider: .openAI)
        let reply = try await service.sendMessage("hi", history: [])
        XCTAssertTrue(reply.contains("OpenAI"),
                      "Expected mock reply to mention provider; got: \(reply)")
    }
}
