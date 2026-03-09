//
//  SplashView.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import SwiftUI

// MARK: - SplashView

/// Launch splash screen shown for a brief moment while the app initialises.
/// Transitions automatically to the main content after `displayDuration` seconds.
struct SplashView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    /// Controls the fade-in animation for the logo and title.
    @State private var opacity: Double = 0

    // MARK: - Configuration

    private let displayDuration: TimeInterval = 1.8

    // MARK: - Callback

    /// Called when the splash has finished so the parent can transition to main content.
    let onFinished: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Requires two image assets in the asset catalogue:
                //   "kiwicare-white" — used in Dark Mode
                //   "kiwicare-black" — used in Light Mode
                Image(colorScheme == .dark ? "kiwicare-white" : "kiwicare-black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Text("KiwiCare")
                    .font(.title)
                    .foregroundStyle(.primary)
            }
            .opacity(opacity)
        }
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1
            }
            // Transition out after display duration
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                onFinished()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(onFinished: {})
}
