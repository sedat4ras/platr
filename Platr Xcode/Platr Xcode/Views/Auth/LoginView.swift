// Platr iOS — LoginView
// [iOSSwiftAgent]

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var authVM: AuthViewModel
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @FocusState private var focused: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // ── Logo / Header ──────────────────────────────────────
                    VStack(spacing: 8) {
                        Text("🚘")
                            .font(.system(size: 64))

                        Text("Platr")
                            .font(.system(size: 40, weight: .black, design: .rounded))

                        Text("Spot & share number plates")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .padding(.top, 40)

                    // ── Form ──────────────────────────────────────────────
                    VStack(spacing: 16) {
                        PlatrTextField(
                            icon: "person",
                            placeholder: "Email or username",
                            text: $authVM.email
                        )
                        .textInputAutocapitalization(.never)
                        .focused($focused, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }

                        PlatrSecureField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $authVM.password
                        )
                        .focused($focused, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { loginAction() }
                    }

                    // ── Error ──────────────────────────────────────────────
                    if let err = authVM.errorMessage {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    // ── Login button ───────────────────────────────────────
                    Button(action: loginAction) {
                        Group {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!authVM.isLoginFormValid || authVM.isLoading)

                    // ── Forgot Password ──────────────────────────────────
                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // ── Divider ──────────────────────────────────────────
                    HStack {
                        Rectangle().frame(height: 0.5).foregroundStyle(.secondary.opacity(0.4))
                        Text("or").font(.caption).foregroundStyle(.secondary)
                        Rectangle().frame(height: 0.5).foregroundStyle(.secondary.opacity(0.4))
                    }

                    // ── Sign in with Apple ───────────────────────────────
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // ── Register link ──────────────────────────────────────
                    Button {
                        authVM.clearFields()
                        showRegister = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(authVM: authVM)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private func loginAction() {
        Task { await authVM.login() }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                authVM.errorMessage = "Failed to get Apple ID token."
                return
            }
            var fullName: String?
            if let name = credential.fullName {
                let parts = [name.givenName, name.familyName].compactMap { $0 }
                if !parts.isEmpty { fullName = parts.joined(separator: " ") }
            }
            Task { await authVM.signInWithApple(identityToken: identityToken, fullName: fullName) }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authVM.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Reusable text field components

struct PlatrTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PlatrSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isVisible {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                SecureField(placeholder, text: $text)
            }

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LoginView(authVM: AuthViewModel())
}
