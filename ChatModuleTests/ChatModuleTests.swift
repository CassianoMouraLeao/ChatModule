//
//  ChatModuleTests.swift
//  ChatModuleTests
//
//  Aggregator file. The actual tests live in:
//   • LLMProviderTests.swift
//   • ChatMessageTests.swift
//   • MockLLMServiceTests.swift
//   • ChatViewModelTests.swift
//   • OpenAIModelsTests.swift
//   • OpenAIServiceTests.swift
//
//  Run all of them with ⌘U or:
//      xcodebuild test -project ChatModule.xcodeproj \
//                      -scheme ChatModule \
//                      -destination 'platform=iOS Simulator,name=iPhone 17'
//

import XCTest

/// Smoke test that asserts the test target itself is wired up.
final class ChatModuleTestsSmoke: XCTestCase {
    func test_target_loads() {
        XCTAssertTrue(true)
    }
}
