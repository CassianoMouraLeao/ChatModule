//
//  ChatView.swift
//  ChatModule
//
//  Root view of the Chat module.
//
//  Layout strategy:
//  • ZStack(alignment: .top) — three layers:
//      1. background color
//      2. main content (feed + input via .safeAreaInset(.bottom))
//      3. hero header overlay, pinned at top
//  • The hero overlay gets .ignoresSafeArea(.keyboard, edges: .bottom) so
//    SwiftUI's automatic keyboard avoidance does NOT shift it up when the
//    user starts typing. The input field still floats above the keyboard
//    because it lives inside a .safeAreaInset(edge: .bottom).
//  • Tap anywhere on the screen dismisses the keyboard (simultaneousGesture
//    so it doesn't swallow chip / button taps). Swiping down on the message
//    list also dismisses it interactively.
//
//  Uses @State + @Observable (iOS 17+) — sidesteps the @StateObject
//  autoclosure crash under Xcode 26's Approachable Concurrency.
//

import SwiftUI

struct ChatView: View {

    @State private var viewModel = ChatViewModel()

    /// Tracks whether the bottom of the feed is currently on screen. Drives
    /// the floating "scroll to bottom" button.
    @State private var isAtBottom = true

    var body: some View {
        // Inline @Bindable shadow so child views can take Binding<...> for
        // selectedProvider / draftText, etc.
        @Bindable var viewModel = viewModel

        return ZStack(alignment: .top) {
            // 1. Background
            Color(.systemGroupedBackground).ignoresSafeArea()

            // 2. Main content: feed + bottom input. The hero overlay (layer 3)
            // covers the top, so we reserve space for it with a Color.clear.
            VStack(spacing: 0) {
                Color.clear.frame(height: ChatTheme.heroHeaderHeight)
                feed
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ChatInputField(
                    text: $viewModel.draftText,
                    provider: viewModel.selectedProvider,
                    isResponding: viewModel.isResponding,
                    canSend: viewModel.canSend,
                    onSend: { viewModel.sendMessage() }
                )
            }

            // 3. Hero overlay. Pinned to top of the ZStack.
            //   .ignoresSafeArea(.keyboard, edges: .bottom) is the key bit —
            //   it opts the hero out of SwiftUI's automatic keyboard avoidance
            //   so it stays anchored when the user focuses the text field.
            ChatHeroHeader(
                selectedProvider: $viewModel.selectedProvider,
                onClear: { viewModel.clearChat() },
                hasMessages: !viewModel.isEmpty
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(edges: .top)
        // Tap anywhere to dismiss keyboard. simultaneousGesture means it does
        // NOT swallow taps on chips / buttons.
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
        .onChange(of: viewModel.selectedProvider) { _, newValue in
            viewModel.selectProvider(newValue)
        }
    }

    // MARK: - Feed

    @ViewBuilder
    private var feed: some View {
        if viewModel.isEmpty && !viewModel.isResponding {
            EmptyChatView(provider: viewModel.selectedProvider) { suggestion in
                viewModel.draftText = suggestion
            }
            .transition(.opacity)
        } else {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            Color.clear.frame(height: 8)

                            ForEach(viewModel.messages) { message in
                                ChatMessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: message.isUser ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            if viewModel.isResponding {
                                TypingIndicatorView(provider: viewModel.selectedProvider)
                                    .id("typing")
                                    .transition(.opacity)
                            }

                            if let errorMessage = viewModel.errorMessage {
                                ErrorBubble(message: errorMessage)
                                    .transition(.opacity)
                            }

                            // Sentinel for "scroll to bottom" detection.
                            Color.clear
                                .frame(height: 1)
                                .id("bottomAnchor")
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isAtBottom = true
                                    }
                                }
                                .onDisappear {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isAtBottom = false
                                    }
                                }
                        }
                        .padding(.horizontal, ChatTheme.horizontalMargin)
                    }
                    // Drag the message list down to dismiss the keyboard.
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isResponding) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }

                    if !isAtBottom {
                        scrollToBottomButton(proxy: proxy)
                            .padding(.trailing, 18)
                            .padding(.bottom, 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
    }

    private func scrollToBottomButton(proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.35)) {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.selectedProvider.accentGradient)
                    .frame(width: 42, height: 42)
                    .shadow(
                        color: viewModel.selectedProvider.accentColor.opacity(0.45),
                        radius: 12,
                        x: 0,
                        y: 6
                    )

                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    .frame(width: 42, height: 42)

                Image(systemName: "arrow.down")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("Scroll to latest message")
    }
}

// MARK: - Error bubble

private struct ErrorBubble: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .padding(8)
                .background(Circle().fill(Color.red))

            VStack(alignment: .leading, spacing: 2) {
                Text("Something went wrong")
                    .font(.subheadline.weight(.bold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
