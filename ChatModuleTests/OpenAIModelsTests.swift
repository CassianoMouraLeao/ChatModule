//
//  OpenAIModelsTests.swift
//  ChatModuleTests
//

import XCTest
@testable import ChatModule

final class OpenAIModelsTests: XCTestCase {

    // MARK: - OpenAIMessage

    func test_openAIMessage_roundtrip() throws {
        let original = OpenAIMessage(role: "user", content: "Hello")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OpenAIMessage.self, from: data)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
    }

    // MARK: - OpenAIChatRequest encoding

    func test_chatRequest_usesSnakeCaseForMaxTokens() throws {
        let req = OpenAIChatRequest(
            model: "openai/gpt-4o-mini",
            messages: [OpenAIMessage(role: "user", content: "hi")],
            temperature: 0.7,
            maxTokens: 256,
            stream: false
        )
        let data = try JSONEncoder().encode(req)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"max_tokens\""),
                      "Expected max_tokens key in JSON; got: \(json)")
        XCTAssertFalse(json.contains("\"maxTokens\""),
                       "Should not emit maxTokens (Swift name) in JSON")
    }

    func test_chatRequest_encodesAllRequiredFields() throws {
        let req = OpenAIChatRequest(
            model: "openai/gpt-4o-mini",
            messages: [OpenAIMessage(role: "user", content: "hi")],
            temperature: 0.5,
            maxTokens: 100,
            stream: false
        )
        let data = try JSONEncoder().encode(req)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(dict?["model"] as? String, "openai/gpt-4o-mini")
        XCTAssertEqual(dict?["temperature"] as? Double, 0.5)
        XCTAssertEqual(dict?["max_tokens"] as? Int, 100)
        XCTAssertEqual(dict?["stream"] as? Bool, false)
        XCTAssertNotNil(dict?["messages"])
    }

    // MARK: - OpenAIChatResponse decoding

    func test_chatResponse_decodesStandardOpenAIPayload() throws {
        let json = """
        {
          "id": "chatcmpl-123",
          "model": "openai/gpt-4o-mini",
          "choices": [
            {
              "index": 0,
              "message": { "role": "assistant", "content": "Hello back!" },
              "finish_reason": "stop"
            }
          ],
          "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 5,
            "total_tokens": 15
          }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        XCTAssertEqual(decoded.id, "chatcmpl-123")
        XCTAssertEqual(decoded.model, "openai/gpt-4o-mini")
        XCTAssertEqual(decoded.choices.count, 1)
        XCTAssertEqual(decoded.choices.first?.message.content, "Hello back!")
        XCTAssertEqual(decoded.choices.first?.finishReason, "stop")
        XCTAssertEqual(decoded.usage?.promptTokens, 10)
        XCTAssertEqual(decoded.usage?.completionTokens, 5)
        XCTAssertEqual(decoded.usage?.totalTokens, 15)
    }

    func test_chatResponse_handlesMissingOptionalFields() throws {
        // Some providers omit `id`, `usage`, `finish_reason` etc.
        let json = """
        {
          "choices": [
            { "message": { "role": "assistant", "content": "Hi" } }
          ]
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        XCTAssertNil(decoded.id)
        XCTAssertNil(decoded.usage)
        XCTAssertNil(decoded.choices.first?.finishReason)
        XCTAssertEqual(decoded.choices.first?.message.content, "Hi")
    }

    // MARK: - OpenAIErrorResponse decoding

    func test_errorResponse_decodesAPIErrorPayload() throws {
        let json = """
        {
          "error": {
            "message": "Invalid API key",
            "type": "invalid_request_error",
            "code": "401"
          }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
        XCTAssertEqual(decoded.error.message, "Invalid API key")
        XCTAssertEqual(decoded.error.type, "invalid_request_error")
        XCTAssertEqual(decoded.error.code, "401")
    }
}
