// Platr iOS — VerificationView
// [iOSSwiftAgent]
// 6-digit OTP email verification screen shown after manual registration.

import SwiftUI

struct VerificationView: View {
    @Bindable var authVM: AuthViewModel
    let email: String

    // 6 individual digit slots
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?

    private var code: String { digits.joined() }
    private var isComplete: Bool { digits.allSatisfy { $0.count == 1 } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {

                // ── Header ─────────────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("📬")
                        .font(.system(size: 56))

                    Text("Check your email")
                        .font(.title2.bold())

                    Text("We sent a 6-digit code to")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)

                    Text(email)
                        .fontWeight(.semibold)
                        .font(.subheadline)
                }
                .padding(.top, 40)

                // ── OTP input ──────────────────────────────────────────────
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPDigitField(
                            digit: $digits[index],
                            isFocused: focusedIndex == index,
                            onInput: { handleInput(at: index) },
                            onDelete: { handleDelete(at: index) }
                        )
                        .focused($focusedIndex, equals: index)
                    }
                }

                // ── Error ──────────────────────────────────────────────────
                if let err = authVM.errorMessage {
                    Text(err)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // ── Verify button ──────────────────────────────────────────
                Button {
                    Task { await authVM.verifyEmail(code: code) }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verify Email").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isComplete || authVM.isLoading)
                .padding(.horizontal, 24)

                // ── Resend ─────────────────────────────────────────────────
                Button {
                    Task {
                        authVM.errorMessage = nil
                        await authVM.resendVerificationCode()
                        if authVM.errorMessage == nil {
                            digits = Array(repeating: "", count: 6)
                            focusedIndex = 0
                        }
                    }
                } label: {
                    Text("Resend code")
                        .font(.subheadline)
                        .foregroundStyle(.accentColor)
                }
                .disabled(authVM.isLoading)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { focusedIndex = 0 }
        }
    }

    // MARK: - Input handling

    private func handleInput(at index: Int) {
        // Keep only the last character entered (handles paste of multiple chars)
        if digits[index].count > 1 {
            digits[index] = String(digits[index].last!)
        }
        // Advance to next field
        if !digits[index].isEmpty && index < 5 {
            focusedIndex = index + 1
        }
        // Auto-submit when all digits are filled
        if isComplete {
            focusedIndex = nil
            Task { await authVM.verifyEmail(code: code) }
        }
    }

    private func handleDelete(at index: Int) {
        if digits[index].isEmpty && index > 0 {
            focusedIndex = index - 1
            digits[index - 1] = ""
        }
    }
}

// MARK: - Single digit field

private struct OTPDigitField: View {
    @Binding var digit: String
    let isFocused: Bool
    let onInput: () -> Void
    let onDelete: () -> Void

    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.title.bold())
            .frame(width: 46, height: 56)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .onChange(of: digit) { _, _ in onInput() }
    }
}
