//
//  View+ClearButton.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import SwiftUI

// MARK: - ClearButtonModifier

/// Wraps any text input in a styled container with an inline ✕ clear button.
///
/// The border + background replace `textFieldStyle(.roundedBorder)`, so do NOT
/// apply both at the same time.
///
/// Usage:
/// ```swift
/// TextField("Email", text: $email)
///     .clearButton(text: $email)
///
/// SecureField("Password", text: $password)
///     .clearButton(text: $password)
/// ```
private struct ClearButtonModifier: ViewModifier {

    @Binding var text: String

    func body(content: Content) -> some View {
        HStack(spacing: 4) {
            content

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                // .plain prevents the button tap from propagating to the scroll view
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        // Mimic the system rounded-border appearance
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
}

// MARK: - View Extension

extension View {
    /// Adds an inline clear (✕) button and applies consistent text-field border styling.
    /// Replace `textFieldStyle(.roundedBorder)` with this modifier.
    func clearButton(text: Binding<String>) -> some View {
        modifier(ClearButtonModifier(text: text))
    }
}
