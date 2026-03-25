// Platr iOS — AuthService
// [iOSSwiftAgent]
// Handles register, login, token refresh, and logout.
// Persists tokens securely in Keychain.

import Foundation

struct TokenPair: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

struct AuthUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let isVerified: Bool
    let createdAt: Date
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case accountDisabled
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:  return "Invalid email or password."
        case .accountDisabled:     return "Your account is disabled."
        case .networkError(let e): return e.localizedDescription
        case .serverError(let m):  return m
        }
    }
}

final class AuthService {
    static let shared = AuthService()
    private let keychain = KeychainService.shared
    private let api = APIService.shared

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

    func register(
        username: String,
        email: String,
        password: String,
        displayName: String?
    ) async throws -> TokenPair {
        struct RegisterRequest: Encodable {
            let username, email, password: String
            let displayName: String?
        }

        let payload = RegisterRequest(
            username: username,
            email: email,
            password: password,
            displayName: displayName
        )
        let pair: TokenPair = try await api.post("/auth/register", body: payload)
        _persist(pair)
        return pair
    }

    // MARK: - Login

    func login(email: String, password: String) async throws -> TokenPair {
        struct LoginRequest: Encodable {
            let email, password: String
        }

        let pair: TokenPair = try await api.post(
            "/auth/login",
            body: LoginRequest(email: email, password: password)
        )
        _persist(pair)
        return pair
    }

    // MARK: - Refresh

    func refreshAccessToken() async throws {
        guard let rt = refreshToken else { throw AuthError.invalidCredentials }

        struct RefreshRequest: Encodable { let refreshToken: String }
        struct AccessTokenResponse: Codable { let accessToken: String }

        let resp: AccessTokenResponse = try await api.post(
            "/auth/refresh",
            body: RefreshRequest(refreshToken: rt)
        )
        accessToken = resp.accessToken
    }

    // MARK: - Email verification

    func verifyEmail(email: String, code: String) async throws {
        struct VerifyRequest: Encodable { let email: String; let code: String }
        struct VerifyResponse: Decodable { let verified: Bool }
        let _: VerifyResponse = try await api.post("/auth/verify-email", body: VerifyRequest(email: email, code: code))
    }

    func resendVerification(email: String) async throws {
        struct ResendRequest: Encodable { let email: String }
        struct SentResponse: Decodable { let sent: Bool }
        let _: SentResponse = try await api.post("/auth/resend-verification", body: ResendRequest(email: email))
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(idToken: String) async throws -> TokenPair {
        struct GoogleRequest: Encodable { let idToken: String }
        let pair: TokenPair = try await api.post("/auth/google", body: GoogleRequest(idToken: idToken))
        _persist(pair)
        return pair
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

    private func _persist(_ pair: TokenPair) {
        accessToken  = pair.accessToken
        refreshToken = pair.refreshToken
    }
}
