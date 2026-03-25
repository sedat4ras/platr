// Platr iOS — RegisterView
// [iOSSwiftAgent]

import SwiftUI

struct RegisterView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Field?
    @State private var showVerification = false

    enum Field { case username, email, displayName, password, confirmPassword }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    Text("Create Account")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    // ── Fields ─────────────────────────────────────────────
                    Group {
                        PlatrTextField(
                            icon: "person",
                            placeholder: "Username (letters, numbers, _)",
                            text: $authVM.username
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focused = .displayName }

                        PlatrTextField(
                            icon: "person.text.rectangle",
                            placeholder: "Display name (optional)",
                            text: $authVM.displayName
                        )
                        .focused($focused, equals: .displayName)
                        .submitLabel(.next)
                        .onSubmit { focused = .email }

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
                            placeholder: "Password (8+ characters)",
                            text: $authVM.password
                        )
                        .focused($focused, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focused = .confirmPassword }

                        PlatrSecureField(
                            icon: "lock.badge.checkmark",
                            placeholder: "Confirm password",
                            text: $authVM.confirmPassword
                        )
                        .focused($focused, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit { registerAction() }
                    }

                    // Password match indicator
                    if !authVM.confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: authVM.password == authVM.confirmPassword
                                  ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(authVM.password == authVM.confirmPassword
                                 ? "Passwords match" : "Passwords don't match")
                        }
                        .font(.caption)
                        .foregroundStyle(
                            authVM.password == authVM.confirmPassword ? .green : .red
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Error
                    if let err = authVM.errorMessage {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    // Submit
                    Button(action: registerAction) {
                        Group {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!authVM.isRegisterFormValid || authVM.isLoading)

                    // Terms notice
                    Text("By creating an account you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        authVM.clearFields()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showVerification) {
                if let email = authVM.pendingVerificationEmail {
                    VerificationView(authVM: authVM, email: email)
                        .interactiveDismissDisabled()
                }
            }
        }
    }

    private func registerAction() {
        Task {
            await authVM.register()
            if authVM.pendingVerificationEmail != nil {
                showVerification = true
            }
        }
    }
}

#Preview {
    RegisterView(authVM: AuthViewModel())
}
