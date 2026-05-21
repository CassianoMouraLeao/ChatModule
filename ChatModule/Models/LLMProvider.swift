//
//  LLMProvider.swift
//  ChatModule
//
//  The LLM backends the user can pick from. Visual identity (colors/icons)
//  lives here so views stay declarative.
//

import SwiftUI

// `nonisolated` because the project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor.
// Without this, the enum's properties would be MainActor-isolated, blocking the
// LLMService (which runs off the main actor) from reading displayName/iconName.
nonisolated enum LLMProvider: String, CaseIterable, Identifiable, Hashable {
    case openAI
    case google

    var id: String { rawValue }

    /// Display name shown on chips and the header subtitle.
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .google: return "Google"
        }
    }

    /// SF Symbol used as the provider avatar / chip icon.
    var iconName: String {
        switch self {
        case .openAI: return "sparkles"
        case .google: return "g.circle.fill"
        }
    }

    /// Brand accent color for chip selection and assistant bubble accents.
    var accentColor: Color {
        switch self {
        case .openAI: return Color(red: 0.06, green: 0.65, blue: 0.50)   // OpenAI green
        case .google: return Color(red: 0.26, green: 0.52, blue: 0.96)   // Google blue
        }
    }

    /// Two-stop gradient derived from the accent color — used on the provider
    /// chip when selected, and on the assistant avatar circle.
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, accentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
