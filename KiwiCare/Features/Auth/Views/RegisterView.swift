//
//  RegisterView.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import SwiftUI

// MARK: - RegisterView

/// New user registration screen.
struct RegisterView: View {

    // MARK: - Environment & State

    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name            = ""
    @State private var email           = ""
    @State private var phone           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""

    // MARK: - Computed Properties

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.isEmpty
            && password.count >= 8
            && passwordsMatch
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                formSection
                submitButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        // Dismiss back to LoginView once registration succeeds
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated { dismiss() }
        }
        .alert("Error", isPresented: .constant(authVM.errorMessage != nil)) {
            Button("OK") { authVM.clearError() }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }
}

// MARK: - Subviews

private extension RegisterView {

    // MARK: Header

    var headerSection: some View {
        VStack(spacing: 4) {
            Text("Join KiwiCare")
                .font(.title2.bold())
            Text("Create your account to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Form Fields

    var formSection: some View {
        VStack(spacing: 14) {
            TextField("Full Name", text: $name)
                .textContentType(.name)
                .clearButton(text: $name)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .clearButton(text: $email)

            TextField("Phone (optional)", text: $phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .clearButton(text: $phone)

            // Raw password values are passed directly to the service and never stored
            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .clearButton(text: $password)

            SecureField("Confirm Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .clearButton(text: $confirmPassword)

            // Inline mismatch hint shown as soon as confirm field has input
            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Submit Button

    var submitButton: some View {
        Button {
            Task {
                await authVM.register(
                    name: name,
                    email: email,
                    password: password,
                    phone: phone.isEmpty ? nil : phone
                )
            }
        } label: {
            Group {
                if authVM.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Create Account").fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSubmit || authVM.isLoading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel(authService: MockAuthService()))
    }
}
#endif
