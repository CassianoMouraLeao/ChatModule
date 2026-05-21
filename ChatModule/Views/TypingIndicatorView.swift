//
//  TypingIndicatorView.swift
//  ChatModule
//
//  Three pulsing dots shown while the LLM is "thinking". Uses the active
//  provider's accent color so it feels connected to the upcoming reply.
//

import SwiftUI
import Combine

struct TypingIndicatorView: View {
    let provider: LLMProvider
    @State private var phase: Int = 0

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .fill(provider.accentGradient)
                    .frame(width: 34, height: 34)
                Image(systemName: provider.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: provider.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)

            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(provider.accentColor)
                        .frame(width: 7, height: 7)
                        .opacity(phase == index ? 1 : 0.3)
                        .scaleEffect(phase == index ? 1.3 : 1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                BubbleShape(isFromCurrentUser: false)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

            Spacer(minLength: 40)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.35)) {
                phase = (phase + 1) % 3
            }
        }
        .accessibilityLabel("\(provider.displayName) is typing")
    }
}
