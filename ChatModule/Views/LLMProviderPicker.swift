//
//  LLMProviderPicker.swift
//  ChatModule
//
//  Horizontal row of selectable provider badges. Tapping a badge sends an
//  intent up to the view model. The selected chip gets a gradient fill and
//  a soft shadow in the provider's brand color.
//

import SwiftUI

struct LLMProviderPicker: View {
    let providers: [LLMProvider]
    let selected: LLMProvider
    let onSelect: (LLMProvider) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(providers) { provider in
                ProviderChip(
                    provider: provider,
                    isSelected: provider == selected
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        onSelect(provider)
                    }
                }
            }
        }
    }
}

// MARK: - Chip

private struct ProviderChip: View {
    let provider: LLMProvider
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: provider.iconName)
                    .font(.system(size: 12, weight: .bold))
                Text(provider.displayName)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(chipBackground)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.35 : 0.25), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? provider.accentColor.opacity(0.55) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
            .scaleEffect(isSelected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(provider.displayName) provider")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            Capsule().fill(provider.accentGradient)
        } else {
            Capsule().fill(Color.white.opacity(0.18))
        }
    }
}
