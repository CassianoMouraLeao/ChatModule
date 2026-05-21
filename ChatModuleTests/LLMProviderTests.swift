//
//  LLMProviderTests.swift
//  ChatModuleTests
//

import XCTest
@testable import ChatModule

final class LLMProviderTests: XCTestCase {

    // MARK: - Cases

    func test_allCases_containsExactlyOpenAIAndGoogle() {
        let cases = LLMProvider.allCases
        XCTAssertEqual(cases.count, 2)
        XCTAssertTrue(cases.contains(.openAI))
        XCTAssertTrue(cases.contains(.google))
    }

    func test_id_equalsRawValue() {
        XCTAssertEqual(LLMProvider.openAI.id, LLMProvider.openAI.rawValue)
        XCTAssertEqual(LLMProvider.google.id, LLMProvider.google.rawValue)
    }

    // MARK: - Display

    func test_displayName_openAI() {
        XCTAssertEqual(LLMProvider.openAI.displayName, "OpenAI")
    }

    func test_displayName_google() {
        XCTAssertEqual(LLMProvider.google.displayName, "Google")
    }

    func test_displayName_neverEmpty() {
        for provider in LLMProvider.allCases {
            XCTAssertFalse(provider.displayName.isEmpty,
                           "displayName empty for \(provider)")
        }
    }

    // MARK: - Icons

    func test_iconName_openAI() {
        XCTAssertEqual(LLMProvider.openAI.iconName, "sparkles")
    }

    func test_iconName_google() {
        XCTAssertEqual(LLMProvider.google.iconName, "g.circle.fill")
    }

    func test_iconName_neverEmpty() {
        for provider in LLMProvider.allCases {
            XCTAssertFalse(provider.iconName.isEmpty,
                           "iconName empty for \(provider)")
        }
    }

    // MARK: - Accent

    func test_accentColor_isDistinctPerProvider() {
        // Each provider should have a visually distinct accent. We sample
        // the SwiftUI Color via its description — that's stable per RGB.
        let descriptions = LLMProvider.allCases.map { String(describing: $0.accentColor) }
        XCTAssertEqual(Set(descriptions).count, descriptions.count,
                       "Providers should not share the same accent color")
    }

    func test_accentGradient_isNotNil() {
        // Sanity — calling the property shouldn't crash and should produce a value.
        for provider in LLMProvider.allCases {
            _ = provider.accentGradient
        }
    }

    // MARK: - Hashable / Equatable

    func test_equality() {
        XCTAssertEqual(LLMProvider.openAI, LLMProvider.openAI)
        XCTAssertNotEqual(LLMProvider.openAI, LLMProvider.google)
    }

    func test_isHashable_canBeUsedInSet() {
        let set: Set<LLMProvider> = [.openAI, .openAI, .google]
        XCTAssertEqual(set.count, 2)
    }
}
