// Platr iOS — AuthViewModel (@MainActor, Swift 6)

import Foundation
import SwiftUI
import Observation

@MainActor
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
            _ = try await auth.register(
                username: username.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            await fetchMe()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple(identityToken: String, fullName: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await auth.appleSignIn(identityToken: identityToken, fullName: fullName)
            await fetchMe()
            isAuthenticated = true
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
                loginField: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
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
        } catch APIError.httpError(401, _) {
            // Token is invalid or expired — force re-login
            logout()
        } catch {
            // Network error — don't log out, keep session
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
    }
}
