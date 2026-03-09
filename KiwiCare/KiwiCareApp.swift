//
//  KiwiCareApp.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import SwiftUI

@main
struct KiwiCareApp: App {

    // MARK: - State

    /// Shared auth state injected into the view hierarchy as an environment object.
    @StateObject private var authVM = AuthViewModel()

    /// `true` once the splash screen has finished displaying.
    @State private var splashFinished = false

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            if !splashFinished {
                SplashView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        splashFinished = true
                    }
                }
            } else if authVM.isAuthenticated {
                // Placeholder — replace with MainTabView once built
                ContentView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
    }
}
