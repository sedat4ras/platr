// Platr iOS — Forgot Password Flow (2-step: send code → reset)

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step: Step = .enterEmail
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let api = APIService.shared

    enum Step { case enterEmail, enterCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)

                        Text("Reset Password")
                            .font(.title2.bold())

                        Text(step == .enterEmail
                             ? "Enter your email to receive a reset code."
                             : "Enter the 6-digit code and your new password.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 16) {
                        if step == .enterEmail {
                            PlatrTextField(icon: "envelope", placeholder: "Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        } else {
                            PlatrTextField(icon: "number", placeholder: "6-digit code", text: $code)
                                .keyboardType(.numberPad)

                            PlatrSecureField(icon: "lock", placeholder: "New password (min 8 chars)", text: $newPassword)

                            PlatrSecureField(icon: "lock.fill", placeholder: "Confirm new password", text: $confirmPassword)
                        }
                    }

                    // Error / Success
                    if let err = errorMessage {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    if let msg = successMessage {
                        Text(msg)
                            .foregroundStyle(.green)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    // Action button
                    Button(action: primaryAction) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(step == .enterEmail ? "Send Reset Code" : "Reset Password")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isFormValid || isLoading)

                    if step == .enterCode {
                        Button("Resend Code") {
                            Task { await sendCode() }
                        }
                        .font(.subheadline)
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Logic

    private var isFormValid: Bool {
        switch step {
        case .enterEmail:
            return !email.isEmpty && email.contains("@")
        case .enterCode:
            return code.count == 6 && newPassword.count >= 8 && newPassword == confirmPassword
        }
    }

    private func primaryAction() {
        Task {
            switch step {
            case .enterEmail: await sendCode()
            case .enterCode: await resetPassword()
            }
        }
    }

    private func sendCode() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.forgotPassword(email: email.trimmingCharacters(in: .whitespaces))
            successMessage = "Reset code sent! Check your email."
            step = .enterCode
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.resetPassword(
                email: email.trimmingCharacters(in: .whitespaces),
                code: code,
                newPassword: newPassword
            )
            successMessage = "Password reset successfully!"
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
