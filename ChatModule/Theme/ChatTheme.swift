//
//  ChatTheme.swift
//  ChatModule
//
//  Shared design tokens for the Chat UI. Mirrors BTW-ios so the Chat module
//  feels like part of the same product family (cyan → blue → indigo).
//

import SwiftUI

enum ChatTheme {

    // MARK: - Sizes

    /// Hero header height. Chat doesn't have title/tagline like the BTW-ios
    /// tabs so it can be much shorter — just enough to fit the status bar,
    /// the "ASSISTANT" kicker and the provider picker.
    static let heroHeaderHeight: CGFloat = 175

    /// Corner radius used on cards (provider chips, message bubbles).
    static let cardCornerRadius: CGFloat = 22

    /// Horizontal margin used throughout.
    static let horizontalMargin: CGFloat = 20

    // MARK: - Gradients

    /// Brand gradient used on the hero header and primary CTAs.
    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 0.30, green: 0.78, blue: 0.95),   // systemCyan
            Color(red: 0.13, green: 0.52, blue: 0.96),   // systemBlue
            Color(red: 0.31, green: 0.27, blue: 0.85).opacity(0.92) // systemIndigo
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle gradient used behind the user's message bubble.
    static let userBubbleGradient = LinearGradient(
        colors: [
            Color(red: 0.13, green: 0.52, blue: 0.96),
            Color(red: 0.31, green: 0.27, blue: 0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
