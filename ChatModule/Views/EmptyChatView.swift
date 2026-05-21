//
//  EmptyChatView.swift
//  ChatModule
//
//  Welcoming empty state shown when the conversation is fresh. Includes
//  three "suggested prompt" cards that tap-fill the input field.
//

import SwiftUI

struct EmptyChatView: View {
    let provider: LLMProvider
    let onSuggestionTap: (String) -> Void

    @State private var pulse = false

    private let suggestions: [(String, String)] = [
        ("📱", "Help me design an iOS feature"),
        ("🐛", "Debug a SwiftUI layout issue"),
        ("✨", "Suggest UX improvements for my app")
    ]

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)

            // Glowing avatar
            ZStack {
                Circle()
                    .fill(provider.accentColor.opacity(0.18))
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulse ? 1.08 : 1)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .fill(provider.accentGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: provider.accentColor.opacity(0.45), radius: 16, x: 0, y: 8)

                Image(systemName: provider.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("Start a conversation")
                    .font(.title3.weight(.bold))

                Text("Ask anything — \(provider.displayName)\nis ready when you are.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Suggestion cards
            VStack(spacing: 10) {
                ForEach(suggestions, id: \.1) { emoji, suggestion in
                    Button {
                        onSuggestionTap(suggestion)
                    } label: {
                        HStack(spacing: 12) {
                            Text(emoji)
                                .font(.system(size: 22))
                            Text(suggestion)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(provider.accentColor)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
        .onAppear { pulse = true }
    }
}
