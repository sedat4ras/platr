// Platr iOS — LoginView
// [iOSSwiftAgent]

import SwiftUI

struct LoginView: View {
    @Bindable var authVM: AuthViewModel
    @State private var showRegister = false
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
                            icon: "envelope",
                            placeholder: "Email",
                            text: $authVM.email
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
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
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!authVM.isLoginFormValid || authVM.isLoading)

                    // ── Divider ────────────────────────────────────────────
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                        Text("or").font(.footnote).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    }

                    // ── Google Sign-In button ──────────────────────────────
                    Button {
                        Task { await authVM.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            // Google "G" logo colours via attributed text workaround
                            Text("G")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .red, .yellow, .green],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Continue with Google")
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(authVM.isLoading)

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
        }
    }

    private func loginAction() {
        Task { await authVM.login() }
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
