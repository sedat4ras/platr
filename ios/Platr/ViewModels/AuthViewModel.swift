// Platr iOS — AuthViewModel
// [iOSSwiftAgent]
// Manages login / register state. @Observable (iOS 17+).

import Foundation
import GoogleSignIn
import SwiftUI

@Observable
final class AuthViewModel {

    // ── Form fields ───────────────────────────────────────────────────────
    var email        = ""
    var password     = ""
    var username     = ""
    var displayName  = ""
    var confirmPassword = ""

    // ── State ─────────────────────────────────────────────────────────────
    var isLoading = false
    var errorMessage: String?
    var currentUser: AuthUser?

    // Drives root navigation: show main app or auth flow
    var isAuthenticated: Bool = AuthService.shared.isLoggedIn

    // Set after manual register → triggers VerificationView sheet in RegisterView
    var pendingVerificationEmail: String? = nil

    private let auth = AuthService.shared

    // MARK: - Register

    func register() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            _ = try await auth.register(
                username: username.trimmingCharacters(in: .whitespaces),
                email: trimmedEmail,
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            // Don't navigate to main app yet — show email verification first
            pendingVerificationEmail = trimmedEmail
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email Verification

    func verifyEmail(code: String) async {
        guard let email = pendingVerificationEmail else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.verifyEmail(email: email, code: code)
            await fetchMe()
            pendingVerificationEmail = nil
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resendVerificationCode() async {
        guard let email = pendingVerificationEmail else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.resendVerification(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Login

    func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await auth.login(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            await fetchMe()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        guard let rootVC = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController
        else {
            errorMessage = "Cannot present Google Sign-In."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google Sign-In failed: missing ID token."
                return
            }
            _ = try await auth.signInWithGoogle(idToken: idToken)
            await fetchMe()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Logout

    func logout() {
        auth.logout()
        currentUser = nil
        isAuthenticated = false
        clearFields()
    }

    // MARK: - Fetch current user

    func fetchMe() async {
        do {
            currentUser = try await auth.fetchCurrentUser()
        } catch {
            // Non-fatal — UI shows username from token if this fails
        }
    }

    // MARK: - Validation

    var isLoginFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isRegisterFormValid: Bool {
        !username.isEmpty && !email.isEmpty &&
        !password.isEmpty && password == confirmPassword &&
        password.count >= 8
    }

    // MARK: - Helpers

    func clearFields() {
        email = ""; password = ""; username = ""
        displayName = ""; confirmPassword = ""
        errorMessage = nil
        pendingVerificationEmail = nil
    }
}
