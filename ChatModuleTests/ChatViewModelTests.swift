//
//  ChatViewModelTests.swift
//  ChatModuleTests
//
//  Comprehensive ViewModel tests. Each test injects a deterministic stub
//  LLMService so the suite is fast and offline.
//

import XCTest
@testable import ChatModule

@MainActor
final class ChatViewModelTests: XCTestCase {

    // MARK: - Initial state

    func test_init_messagesAreEmpty() {
        let vm = ChatViewModel()
        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertTrue(vm.isEmpty)
    }

    func test_init_draftTextEmpty() {
        let vm = ChatViewModel()
        XCTAssertEqual(vm.draftText, "")
    }

    func test_init_defaultsToGoogle() {
        let vm = ChatViewModel()
        XCTAssertEqual(vm.selectedProvider, .google)
    }

    func test_init_isNotResponding() {
        let vm = ChatViewModel()
        XCTAssertFalse(vm.isResponding)
    }

    func test_init_noErrorMessage() {
        let vm = ChatViewModel()
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - canSend logic

    func test_canSend_falseWhenDraftEmpty() {
        let vm = ChatViewModel()
        vm.draftText = ""
        XCTAssertFalse(vm.canSend)
    }

    func test_canSend_falseWhenDraftWhitespaceOnly() {
        let vm = ChatViewModel()
        vm.draftText = "   \n\t  "
        XCTAssertFalse(vm.canSend)
    }

    func test_canSend_trueWhenDraftHasContent() {
        let vm = ChatViewModel()
        vm.draftText = "hi"
        XCTAssertTrue(vm.canSend)
    }

    // MARK: - trimmedDraft

    func test_trimmedDraft_stripsLeadingTrailingWhitespace() {
        let vm = ChatViewModel()
        vm.draftText = "  hello  \n"
        XCTAssertEqual(vm.trimmedDraft, "hello")
    }

    // MARK: - sendMessage flow

    func test_sendMessage_appendsUserMessageImmediately() async {
        let vm = makeViewModel(stub: .success("reply"))
        vm.draftText = "Hi there"
        vm.sendMessage()

        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.messages.first?.role, .user)
        XCTAssertEqual(vm.messages.first?.content, "Hi there")
    }

    func test_sendMessage_clearsDraftText() {
        let vm = makeViewModel(stub: .success("reply"))
        vm.draftText = "Hi"
        vm.sendMessage()
        XCTAssertEqual(vm.draftText, "")
    }

    func test_sendMessage_setsIsResponding() {
        let vm = makeViewModel(stub: .success("reply"), delayNanos: 1_000_000_000)
        vm.draftText = "Hi"
        vm.sendMessage()
        XCTAssertTrue(vm.isResponding,
                      "isResponding should be true synchronously after sending")
    }

    func test_sendMessage_doesNothingWhenDraftEmpty() {
        let vm = makeViewModel(stub: .success("reply"))
        vm.draftText = ""
        vm.sendMessage()
        XCTAssertEqual(vm.messages.count, 0)
        XCTAssertFalse(vm.isResponding)
    }

    func test_sendMessage_doesNothingWhileResponding() {
        let vm = makeViewModel(stub: .success("reply"), delayNanos: 1_000_000_000)
        vm.draftText = "First"
        vm.sendMessage()
        XCTAssertEqual(vm.messages.count, 1)

        // Try to send again while still responding — should be ignored.
        vm.draftText = "Second"
        vm.sendMessage()
        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.draftText, "Second",
                       "Draft should NOT be cleared when sendMessage is ignored")
    }

    func test_sendMessage_appendsAssistantReplyAfterAwait() async throws {
        let vm = makeViewModel(stub: .success("the reply"))
        vm.draftText = "Hi"
        vm.sendMessage()

        try await waitForReply(in: vm)

        XCTAssertEqual(vm.messages.count, 2)
        XCTAssertEqual(vm.messages.last?.role, .assistant)
        XCTAssertEqual(vm.messages.last?.content, "the reply")
        XCTAssertEqual(vm.messages.last?.provider, vm.selectedProvider)
        XCTAssertFalse(vm.isResponding)
    }

    func test_sendMessage_setsErrorOnFailure() async throws {
        struct Boom: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let vm = makeViewModel(stub: .failure(Boom()))
        vm.draftText = "Hi"
        vm.sendMessage()

        try await waitForResponseToSettle(in: vm)

        XCTAssertEqual(vm.errorMessage, "boom")
        XCTAssertFalse(vm.isResponding)
        // Failure should NOT append an assistant message.
        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.messages.last?.role, .user)
    }

    func test_sendMessage_clearsPreviousErrorMessage() async throws {
        struct Boom: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let recorder = RecordingLLMService()

        // First send → error
        recorder.response = .failure(Boom())
        let vm = ChatViewModel(serviceFactory: { _ in recorder })
        vm.draftText = "Hi"
        vm.sendMessage()
        try await waitForResponseToSettle(in: vm)
        XCTAssertEqual(vm.errorMessage, "boom")

        // Second send → success → errorMessage should be cleared
        recorder.response = .success("recovered")
        vm.draftText = "Try again"
        vm.sendMessage()
        XCTAssertNil(vm.errorMessage, "errorMessage should be cleared synchronously when a new send starts")
    }

    func test_sendMessage_passesFullHistoryToService() async throws {
        let recorder = RecordingLLMService()
        let vm = ChatViewModel(serviceFactory: { _ in recorder })

        vm.draftText = "first"
        vm.sendMessage()
        try await waitForReply(in: vm)

        vm.draftText = "second"
        vm.sendMessage()
        try await waitForReply(in: vm)

        XCTAssertEqual(recorder.capturedPrompts, ["first", "second"])
        // The second call should see both user + first reply in history.
        XCTAssertEqual(recorder.capturedHistories.last?.count, 3)
    }

    // MARK: - clearChat

    func test_clearChat_removesAllMessages() async throws {
        let vm = makeViewModel(stub: .success("reply"))
        vm.draftText = "Hi"
        vm.sendMessage()
        try await waitForReply(in: vm)

        XCTAssertEqual(vm.messages.count, 2)
        vm.clearChat()
        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertTrue(vm.isEmpty)
    }

    func test_clearChat_clearsErrorMessage() async throws {
        struct Boom: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let vm = makeViewModel(stub: .failure(Boom()))
        vm.draftText = "Hi"
        vm.sendMessage()
        try await waitForResponseToSettle(in: vm)
        XCTAssertEqual(vm.errorMessage, "boom")

        vm.clearChat()
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - selectProvider

    func test_selectProvider_changesSelectedProvider() {
        let vm = ChatViewModel()
        XCTAssertEqual(vm.selectedProvider, .google)
        vm.selectProvider(.openAI)
        XCTAssertEqual(vm.selectedProvider, .openAI)
    }

    func test_selectProvider_appendsSystemMessage() {
        let vm = ChatViewModel()
        vm.selectProvider(.openAI)
        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.messages.first?.role, .system)
        XCTAssertTrue(vm.messages.first?.content.contains("OpenAI") ?? false)
        XCTAssertEqual(vm.messages.first?.provider, .openAI)
    }

    func test_selectProvider_noOpWhenSameProvider() {
        let vm = ChatViewModel()
        XCTAssertEqual(vm.selectedProvider, .google)
        vm.selectProvider(.google)   // same — should do nothing
        XCTAssertTrue(vm.messages.isEmpty,
                      "Selecting the already-selected provider must NOT add a system message")
    }

    // MARK: - Helpers

    private func makeViewModel(
        stub result: Result<String, Error>,
        delayNanos: UInt64 = 0
    ) -> ChatViewModel {
        ChatViewModel(serviceFactory: { _ in StubLLMService(result, delayNanos: delayNanos) })
    }

    /// Spins until the assistant reply arrives (message count grows past the
    /// user message) or times out.
    private func waitForReply(
        in vm: ChatViewModel,
        timeout: TimeInterval = 2.0
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while vm.isResponding || vm.messages.last?.role != .assistant {
            if Date() > deadline {
                XCTFail("Timed out waiting for assistant reply")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    /// Spins until isResponding flips back to false (success or failure).
    private func waitForResponseToSettle(
        in vm: ChatViewModel,
        timeout: TimeInterval = 2.0
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while vm.isResponding {
            if Date() > deadline {
                XCTFail("Timed out waiting for isResponding == false")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
