//
//  TestHelpers.swift
//  ChatModuleTests
//
//  Shared utilities for the unit test suite:
//   • StubLLMService — predictable, instant LLMService for ViewModel tests.
//   • MockURLProtocol — intercepts URLSession requests so we can test
//     OpenAIService end-to-end without hitting the network.
//

import Foundation
import XCTest
@testable import ChatModule

// MARK: - StubLLMService

/// A no-op LLMService that returns a canned result (success or failure).
/// Lets ChatViewModel tests run deterministically without network or delays.
/// `@unchecked Sendable` — LLMService requires Sendable; this holds a
/// `Result<String, Error>` whose `Error` existential isn't Sendable. Safe for
/// a test stub: all fields are immutable `let`s set once at init.
struct StubLLMService: LLMService, @unchecked Sendable {
    let result: Result<String, Error>
    let delayNanos: UInt64

    init(_ result: Result<String, Error>, delayNanos: UInt64 = 0) {
        self.result = result
        self.delayNanos = delayNanos
    }

    func sendMessage(_ prompt: String, history: [ChatMessage]) async throws -> String {
        if delayNanos > 0 {
            try await Task.sleep(nanoseconds: delayNanos)
        }
        switch result {
        case .success(let text): return text
        case .failure(let err):  throw err
        }
    }
}

/// Records every prompt/history it sees so tests can assert on what was sent.
final class RecordingLLMService: LLMService, @unchecked Sendable {
    private(set) var capturedPrompts: [String] = []
    private(set) var capturedHistories: [[ChatMessage]] = []
    var response: Result<String, Error> = .success("recorded reply")

    func sendMessage(_ prompt: String, history: [ChatMessage]) async throws -> String {
        capturedPrompts.append(prompt)
        capturedHistories.append(history)
        return try response.get()
    }
}

// MARK: - MockURLProtocol

/// Lets the test inject the exact (HTTPURLResponse, Data) returned for any
/// URLSession request. Install via:
///
///     let config = URLSessionConfiguration.ephemeral
///     config.protocolClasses = [MockURLProtocol.self]
///     let session = URLSession(configuration: config)
final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    /// Set this before each test to control what the mock returns.
    /// Receives the URLRequest so tests can also inspect what was sent.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Last request the mock saw — handy for assertions.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func reset() {
        requestHandler = nil
        lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        MockURLProtocol.lastRequest = request
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(
                domain: "MockURLProtocol", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No requestHandler set"]
            ))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

extension MockURLProtocol {
    /// Convenience to build a URLSession wired to MockURLProtocol.
    static func makeURLSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
