//
//  ChatMessageBubble.swift
//  ChatModule
//
//  One conversation bubble. User messages sit on the right with a gradient
//  fill; assistant messages sit on the left with a provider-colored avatar.
//  System messages are rendered as a small centered chip.
//

import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:      userBubble
        case .assistant: assistantBubble
        case .system:    systemChip
        }
    }

    // MARK: - User

    private var userBubble: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Spacer(minLength: 50)

            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        BubbleShape(isFromCurrentUser: true)
                            .fill(ChatTheme.userBubbleGradient)
                    )
                    .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)

                Text(message.formattedTimestamp)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 8)
            }
        }
    }

    // MARK: - Assistant

    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            // Provider avatar
            ZStack {
                Circle()
                    .fill(message.provider?.accentGradient ?? LLMProvider.openAI.accentGradient)
                    .frame(width: 34, height: 34)
                Image(systemName: message.provider?.iconName ?? "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: (message.provider?.accentColor ?? .gray).opacity(0.4), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                // Provider name pill
                if let provider = message.provider {
                    Text(provider.displayName)
                        .font(.system(size: 10, weight: .heavy))
                        .kerning(0.5)
                        .foregroundStyle(provider.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(provider.accentColor.opacity(0.13))
                        )
                }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        BubbleShape(isFromCurrentUser: false)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    .textSelection(.enabled)

                Text(message.formattedTimestamp)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 8)
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - System

    private var systemChip: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                if let provider = message.provider {
                    Image(systemName: provider.iconName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(provider.accentColor)
                }
                Text(message.content)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(.tertiarySystemFill))
            )
            Spacer()
        }
    }
}

// MARK: - Bubble Shape (asymmetric tail)

/// Native SwiftUI shape (iOS 16+). Replaces UIBezierPath bridge to avoid
/// EXC_BAD_ACCESS crashes on Xcode 26+ when SwiftUI lays out the bubble with
/// a zero-sized rect on first render.
struct BubbleShape: Shape {
    let isFromCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let big: CGFloat = 20
        let small: CGFloat = 4
        let radii = isFromCurrentUser
            ? RectangleCornerRadii(topLeading: big,   bottomLeading: big, bottomTrailing: small, topTrailing: big)
            : RectangleCornerRadii(topLeading: big,   bottomLeading: small, bottomTrailing: big,   topTrailing: big)
        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous).path(in: rect)
    }
}
