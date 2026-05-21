//
//  ChatInputField.swift
//  ChatModule
//
//  Bottom input bar: multiline text field on the left, gradient send button
//  on the right. Disabled when text is empty or while the LLM is responding.
//

import SwiftUI

struct ChatInputField: View {
    @Binding var text: String
    let provider: LLMProvider
    let isResponding: Bool
    let canSend: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Text field container
            HStack(alignment: .bottom, spacing: 8) {
                if #available(iOS 16.0, *) {
                    TextField("Message \(provider.displayName)...",
                              text: $text,
                              axis: .vertical)
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .font(.body)
                        .submitLabel(.send)
                } else {
                    TextField("Message \(provider.displayName)...", text: $text)
                        .focused($isFocused)
                        .font(.body)
                }

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                isFocused ? provider.accentColor.opacity(0.5) : Color.primary.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.18), value: isFocused)
            .animation(.spring(response: 0.3), value: text.isEmpty)

            // Send button
            Button {
                onSend()
                isFocused = true   // keep keyboard open for the next message
            } label: {
                ZStack {
                    Circle()
                        .fill(canSend ? AnyShapeStyle(provider.accentGradient)
                                     : AnyShapeStyle(Color(.tertiarySystemFill)))
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: canSend ? provider.accentColor.opacity(0.45) : .clear,
                            radius: 10,
                            x: 0,
                            y: 5
                        )

                    if isResponding {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(canSend ? Color.white : Color.secondary)
                    }
                }
                .scaleEffect(canSend ? 1 : 0.92)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            // Translucent material so message bubbles peek through when scrolling.
            // ignoresSafeArea(edges: .bottom) fills the home-indicator area when
            // no keyboard is up; when the keyboard appears, .safeAreaInset on
            // the parent pushes us above it and the keyboard covers the rest.
            Color(.systemBackground)
                .opacity(0.95)
                .background(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            // Hairline top divider
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
