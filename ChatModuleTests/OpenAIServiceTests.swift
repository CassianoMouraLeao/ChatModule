//
//  OpenAIServiceTests.swift
//  ChatModuleTests
//
//  Exercises OpenAIService end-to-end by intercepting URLSession with
//  MockURLProtocol — no real network calls.
//

import XCTest
@testable import ChatModule

final class OpenAIServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Missing key

    func test_sendMessage_withEmptyKey_throwsMissingAPIKey() async {
        let service = OpenAIService(
            apiKey: "",
            urlSession: MockURLProtocol.makeURLSession()
        )

        do {
            _ = try await service.sendMessage("Hi", history: [])
            XCTFail("Expected missingAPIKey to be thrown")
        } catch let error as LLMServiceError {
            switch error {
            case .missingAPIKey: break // ✅
            default:
                XCTFail("Expected .missingAPIKey, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }

    // MARK: - Happy path

    func test_sendMessage_returnsFirstChoiceContent() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = """
            { "choices": [{ "message": { "role": "assistant", "content": "Hello world" } }] }
            """
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService()
        let reply = try await service.sendMessage("Hi", history: [])
        XCTAssertEqual(reply, "Hello world")
    }

    func test_sendMessage_sendsCorrectURL() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = #"{ "choices": [{ "message": { "role": "assistant", "content": "ok" } }] }"#
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService()
        _ = try await service.sendMessage("Hi", history: [])

        let url = try XCTUnwrap(MockURLProtocol.lastRequest?.url)
        XCTAssertEqual(url.absoluteString,
                       "https://models.github.ai/inference/chat/completions")
    }

    func test_sendMessage_sendsBearerAuthorizationHeader() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = #"{ "choices": [{ "message": { "role": "assistant", "content": "ok" } }] }"#
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService(apiKey: "my-token-xyz")
        _ = try await service.sendMessage("Hi", history: [])

        let auth = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(auth, "Bearer my-token-xyz")
    }

    func test_sendMessage_sendsPostWithJSONContentType() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = #"{ "choices": [{ "message": { "role": "assistant", "content": "ok" } }] }"#
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService()
        _ = try await service.sendMessage("Hi", history: [])

        XCTAssertEqual(MockURLProtocol.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type"),
                       "application/json")
    }

    func test_sendMessage_bodyIncludesSystemPromptAndUserHistory() async throws {
        var seenBody: [String: Any] = [:]

        MockURLProtocol.requestHandler = { request in
            // URLProtocol on iOS reads the body from httpBodyStream, not httpBody.
            if let stream = request.httpBodyStream {
                let data = Self.readAll(from: stream)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    seenBody = json
                }
            }
            let body = #"{ "choices": [{ "message": { "role": "assistant", "content": "ok" } }] }"#
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService()
        let history: [ChatMessage] = [
            ChatMessage(role: .user, content: "first user msg"),
            ChatMessage(role: .assistant, content: "first reply"),
            ChatMessage(role: .user, content: "Hi")
        ]
        _ = try await service.sendMessage("Hi", history: history)

        XCTAssertEqual(seenBody["model"] as? String, "openai/gpt-4o-mini")

        let messages = try XCTUnwrap(seenBody["messages"] as? [[String: String]])
        // [system, user, assistant, user] — system role prepended; UI .system msgs would be filtered
        XCTAssertEqual(messages.first?["role"], "system")
        let userMessages = messages.filter { $0["role"] == "user" }
        XCTAssertEqual(userMessages.count, 2)
        XCTAssertTrue(messages.contains(where: { $0["content"] == "first reply" && $0["role"] == "assistant" }))
    }

    func test_sendMessage_filtersOutUISystemMessages() async throws {
        var seenBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { request in
            if let stream = request.httpBodyStream {
                let data = Self.readAll(from: stream)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    seenBody = json
                }
            }
            let body = #"{ "choices": [{ "message": { "role": "assistant", "content": "ok" } }] }"#
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService()
        let history: [ChatMessage] = [
            ChatMessage(role: .system, content: "Now chatting with OpenAI"),
            ChatMessage(role: .user, content: "Hi")
        ]
        _ = try await service.sendMessage("Hi", history: history)

        let messages = try XCTUnwrap(seenBody["messages"] as? [[String: String]])
        // System prompt of OUR own + 1 user (the UI .system msg should be filtered out)
        let systemCount = messages.filter { $0["role"] == "system" }.count
        XCTAssertEqual(systemCount, 1, "Only the service's own system prompt should remain")
        XCTAssertFalse(messages.contains(where: { $0["content"] == "Now chatting with OpenAI" }),
                       "UI-level system message must be filtered out")
    }

    // MARK: - HTTP error handling

    func test_sendMessage_on401_throwsHttpError() async {
        MockURLProtocol.requestHandler = { request in
            let body = #"{ "error": { "message": "Bad credentials", "type": "auth", "code": "401" } }"#
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil
            )!
            return (response, Data(body.utf8))
        }

        let service = makeService()
        do {
            _ = try await service.sendMessage("Hi", history: [])
            XCTFail("Expected HTTP error")
        } catch let error as LLMServiceError {
            switch error {
            case .httpError(let status, let message):
                XCTAssertEqual(status, 401)
                XCTAssertEqual(message, "Bad credentials")
            default:
                XCTFail("Expected .httpError, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }

    func test_sendMessage_on500_withNonJsonBody_throwsHttpErrorWithRawText() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil
            )!
            return (response, Data("Internal Server Error".utf8))
        }

        let service = makeService()
        do {
            _ = try await service.sendMessage("Hi", history: [])
            XCTFail("Expected HTTP error")
        } catch let error as LLMServiceError {
            switch error {
            case .httpError(let status, let message):
                XCTAssertEqual(status, 500)
                XCTAssertEqual(message, "Internal Server Error")
            default:
                XCTFail("Expected .httpError, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }

    func test_sendMessage_on200_withEmptyChoices_throwsNoChoices() async {
        MockURLProtocol.requestHandler = { request in
            let body = #"{ "choices": [] }"#
            return (Self.okResponse(for: request), Data(body.utf8))
        }

        let service = makeService()
        do {
            _ = try await service.sendMessage("Hi", history: [])
            XCTFail("Expected noChoices error")
        } catch let error as LLMServiceError {
            switch error {
            case .noChoices: break // ✅
            default:
                XCTFail("Expected .noChoices, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }

    func test_sendMessage_on200_withMalformedJSON_throwsDecodingFailed() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, Data("not json".utf8))
        }

        let service = makeService()
        do {
            _ = try await service.sendMessage("Hi", history: [])
            XCTFail("Expected decoding error")
        } catch let error as LLMServiceError {
            switch error {
            case .decodingFailed: break // ✅
            default:
                XCTFail("Expected .decodingFailed, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }

    // MARK: - LLMServiceError descriptions

    func test_llmServiceError_descriptions_areUserFriendly() {
        XCTAssertNotNil(LLMServiceError.missingAPIKey(provider: "x").errorDescription)
        XCTAssertNotNil(LLMServiceError.invalidResponse.errorDescription)
        XCTAssertNotNil(LLMServiceError.httpError(status: 401, message: "bad").errorDescription)
        XCTAssertNotNil(LLMServiceError.noChoices.errorDescription)
        XCTAssertTrue(LLMServiceError.httpError(status: 401, message: "bad")
                        .errorDescription?.contains("401") ?? false)
    }

    // MARK: - Helpers

    private func makeService(apiKey: String = "test-key") -> OpenAIService {
        OpenAIService(apiKey: apiKey, urlSession: MockURLProtocol.makeURLSession())
    }

    private static func okResponse(for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200, httpVersion: nil, headerFields: nil
        )!
    }

    private static func readAll(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 { data.append(buffer, count: read) }
            else { break }
        }
        return data
    }
}
