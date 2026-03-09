//
//  ContentView.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            Text("Hello, world!")
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                .confirmationDialog("Logout", isPresented: $showLogoutConfirm) {
                    Button("Logout", role: .destructive) {
                        authVM.logout()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to log out?")
                }
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
}
#endif
