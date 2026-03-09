//
//  LoginView.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import SwiftUI
import AuthenticationServices

// MARK: - LoginView

/// Entry screen for user authentication.
/// Supports email / password login and Sign in with Apple.
struct LoginView: View {

    // MARK: - Environment & State

    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var email    = ""
    @State private var password = ""
    @State private var navigateToRegister = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 28) {
                        logoSection
                        inputSection
                        loginButton
                        divider
                        appleSignInButton
                        registerLink
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                    .padding(.vertical, 32)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
            .alert("Error", isPresented: .constant(authVM.errorMessage != nil)) {
                Button("OK") { authVM.clearError() }
            } message: {
                Text(authVM.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Subviews

private extension LoginView {

    // MARK: Logo

    var logoSection: some View {
        VStack(spacing: 8) {
            // Use the dark/light variant based on current color scheme
            Image(colorScheme == .dark ? "kiwicare-white" : "kiwicare-black")
                .resizable()
                .scaledToFit()
                .frame(height: 150)

            Text("Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Input Fields

    var inputSection: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .clearButton(text: $email)

            // SecureField prevents the password appearing in autocomplete
            // suggestions, logs, or the clipboard history
            SecureField("Password", text: $password)
                .textContentType(.password)
                .clearButton(text: $password)
        }
    }

    // MARK: Login Button

    var loginButton: some View {
        Button {
            Task { await authVM.login(email: email, password: password) }
        } label: {
            Group {
                if authVM.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Sign In").fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .disabled(authVM.isLoading)
    }

    // MARK: Divider

    var divider: some View {
        HStack(spacing: 8) {
            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            Text("or").font(.caption).foregroundStyle(.secondary)
            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
        }
    }

    // MARK: Apple Sign In

    /// Apple Sign In button styled to Apple's Human Interface Guidelines.
    var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                Task { await authVM.loginWithApple(credential: credential) }
            case .failure(let error):
                // Ignore user-initiated cancellations (code 1001)
                guard (error as? ASAuthorizationError)?.code != .canceled else { return }
                authVM.errorMessage = error.localizedDescription
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
    }

    // MARK: Register Link

    var registerLink: some View {
        Button {
            navigateToRegister = true
        } label: {
            HStack(spacing: 2) {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)
                Text("Sign Up")
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.accentColor)
                    .fontWeight(.semibold)
            }
            .font(.footnote)
        }
        // Prevent Button from tinting the entire label with accentColor
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LoginView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
}
#endif
