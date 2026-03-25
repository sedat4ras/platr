// Platr iOS — AuthService
// @MainActor: token state, UI-driven flows

import Foundation

// MARK: - Response types

struct TokenPair: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

struct AuthUser: Codable, Sendable {
    let id: String
    let username: String
    let displayName: String?
    let isVerified: Bool
    let createdAt: Date
}

// MARK: - Service

@MainActor
final class AuthService {
    static let shared = AuthService()
    private let keychain = KeychainService.shared
    private let api      = APIService.shared

    // MARK: - Token management

    var accessToken: String? {
        get { keychain.read(.accessToken) }
        set {
            if let v = newValue { keychain.save(v, for: .accessToken) }
            else { keychain.delete(.accessToken) }
        }
    }

    var refreshToken: String? {
        get { keychain.read(.refreshToken) }
        set {
            if let v = newValue { keychain.save(v, for: .refreshToken) }
            else { keychain.delete(.refreshToken) }
        }
    }

    var isLoggedIn: Bool { accessToken != nil }

    // MARK: - Register

    func register(username: String, email: String, password: String, displayName: String?) async throws -> TokenPair {
        struct RegisterRequest: Encodable {
            let username, email, password: String
            let displayName: String?
        }
        let pair: TokenPair = try await api.post(
            "/auth/register",
            body: RegisterRequest(username: username, email: email, password: password, displayName: displayName)
        )
        persist(pair)
        return pair
    }

    // MARK: - Login

    func login(loginField: String, password: String) async throws -> TokenPair {
        struct LoginRequest: Encodable { let login, password: String }
        let pair: TokenPair = try await api.post(
            "/auth/login",
            body: LoginRequest(login: loginField, password: password)
        )
        persist(pair)
        return pair
    }

    // MARK: - Apple Sign-In

    func appleSignIn(identityToken: String, fullName: String?) async throws -> TokenPair {
        let pair = try await api.appleSignIn(identityToken: identityToken, fullName: fullName)
        persist(pair)
        return pair
    }

    // MARK: - Refresh

    func refreshAccessToken() async throws {
        guard let rt = refreshToken else { return }
        struct RefreshRequest: Encodable { let refreshToken: String }
        struct AccessResponse: Codable { let accessToken: String }
        let resp: AccessResponse = try await api.post("/auth/refresh", body: RefreshRequest(refreshToken: rt))
        accessToken = resp.accessToken
    }

    // MARK: - Me

    func fetchCurrentUser() async throws -> AuthUser {
        try await api.get("/auth/me")
    }

    // MARK: - Logout

    func logout() {
        keychain.clearAll()
    }

    // MARK: - Private

    private func persist(_ pair: TokenPair) {
        keychain.save(pair.accessToken,  for: .accessToken)
        keychain.save(pair.refreshToken, for: .refreshToken)
    }
}
