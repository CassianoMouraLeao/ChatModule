//
//  ChatHeroHeader.swift
//  ChatModule
//
//  Top hero: brand gradient + decorative circles + the three
//  provider chips. Mirrors the Portfolio/Cart/Profile header pattern from
//  BTW-ios for visual consistency.
//

import SwiftUI

struct ChatHeroHeader: View {
    @Binding var selectedProvider: LLMProvider
    let onClear: () -> Void
    let hasMessages: Bool

    @State private var visible = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient (matches BTW-ios)
            ChatTheme.brandGradient

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 180, height: 180)
                .offset(x: 220, y: -70)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 80, height: 80)
                .offset(x: -20, y: 130)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 50, height: 50)
                .offset(x: 300, y: 130)

            // Content — tight spacing so the header stays compact.
            VStack(alignment: .leading, spacing: 16) {
                // Kicker + Clear button on the same row
                HStack {
                    Text("ASSISTANT")
                        .font(.system(size: 12, weight: .heavy))
                        .kerning(2.5)
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    if hasMessages {
                        Button(action: {
                            withAnimation(.spring(response: 0.4)) { onClear() }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Clear")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.white.opacity(0.20)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .offset(y: visible ? 0 : 10)
                .opacity(visible ? 1 : 0)

                // Provider chips (no Spacer above — keeps the header compact)
                LLMProviderPicker(
                    providers: LLMProvider.allCases,
                    selected: selectedProvider
                ) { selectedProvider = $0 }
                .offset(y: visible ? 0 : 22)
                .opacity(visible ? 1 : 0)
            }
            .padding(.horizontal, ChatTheme.horizontalMargin)
            // ~status-bar height + 12pt margin on top
            .padding(.top, 62)
            .padding(.bottom, 18)
        }
        .frame(height: ChatTheme.heroHeaderHeight)
        .clipShape(BottomRoundedShape(radius: 28))
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
                visible = true
            }
        }
    }
}

// MARK: - Helper shape

/// Uses SwiftUI's native UnevenRoundedRectangle (iOS 16+) instead of bridging
/// UIBezierPath to Path — the bridge is fragile when the rect is .zero during
/// the first layout pass and can crash with EXC_BAD_ACCESS on Xcode 26+.
struct BottomRoundedShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: radius,
                bottomTrailing: radius,
                topTrailing: 0
            ),
            style: .continuous
        ).path(in: rect)
    }
}
