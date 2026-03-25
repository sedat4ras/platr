// Platr iOS — API Service
// Swift 6 / Xcode 26 uyumlu (@MainActor, nonisolated)

import Foundation

// MARK: - Errors

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case duplicatePlate(DuplicatePlateResponse)
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:                  return "Invalid URL"
        case .duplicatePlate(let r):       return "Plate \(r.stateCode)·\(r.plateText) already exists."
        case .httpError(let c, let m):     return "HTTP \(c): \(m)"
        case .decodingError(let m):        return "Decode error: \(m)"
        case .networkError(let m):         return m
        }
    }
}

// MARK: - Service

@MainActor
final class APIService: Sendable {
    static let shared = APIService()

    private let baseURL: String

    // Decoder / encoder are value-type-like and Sendable
    private nonisolated let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy  = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private nonisolated let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg)
    }()

    init(baseURL: String? = nil) {
        self.baseURL = baseURL ?? AppConfig.current.apiBaseURL
    }

    // MARK: - Convenience wrappers

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request("GET", path: path)
    }

    func post<T: Decodable>(_ path: String, body: (some Encodable)?) async throws -> T {
        try await request("POST", path: path, body: body)
    }

    // MARK: - Core request

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (some Encodable)? = Optional<String>.none
    ) async throws -> T {

        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var urlRequest        = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainService.shared.read(.accessToken) {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError("Bad response")
        }

        if http.statusCode == 409 {
            let wrapper = try decoder.decode(DuplicatePlateErrorWrapper.self, from: data)
            throw APIError.duplicatePlate(wrapper.detail)
        }

        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw APIError.httpError(http.statusCode, msg)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Plates

    func createPlate(_ req: PlateCreateRequest) async throws -> Plate {
        try await request("POST", path: "/plates", body: req)
    }

    func getPlate(id: UUID) async throws -> Plate {
        try await request("GET", path: "/plates/\(id.uuidString.lowercased())")
    }

    func listPlates(stateCode: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> [Plate] {
        var path = "/plates?limit=\(limit)&offset=\(offset)"
        if let sc = stateCode { path += "&state_code=\(sc)" }
        return try await request("GET", path: path)
    }

    func spotPlate(id: UUID) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("POST", path: "/plates/\(id.uuidString.lowercased())/spot")
    }

    func getMyPlates(limit: Int = 100) async throws -> [Plate] {
        try await request("GET", path: "/plates/submitted-by-me?limit=\(limit)")
    }

    func getOwnedPlates(limit: Int = 100) async throws -> [Plate] {
        try await request("GET", path: "/plates/owned-by-me?limit=\(limit)")
    }

    // MARK: - Ownership

    func uploadOwnershipPhoto(plateId: UUID, imageData: Data) async throws -> OwnershipStatusResponse {
        guard let url = URL(string: baseURL + "/plates/\(plateId.uuidString.lowercased())/claim/photo") else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = KeychainService.shared.read(.accessToken) {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"ownership.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.httpBody = body

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Upload failed"
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }
        return try decoder.decode(OwnershipStatusResponse.self, from: data)
    }

    func getOwnershipStatus(plateId: UUID) async throws -> OwnershipStatusResponse {
        try await request("GET", path: "/plates/\(plateId.uuidString.lowercased())/claim/status")
    }

    func relinquishOwnership(plateId: UUID) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("DELETE", path: "/plates/\(plateId.uuidString.lowercased())/claim")
    }

    func updatePlateVisibility(plateId: UUID, isHidden: Bool? = nil, isBlockedReadd: Bool? = nil) async throws -> Plate {
        struct Req: Encodable { let isHidden: Bool?; let isBlockedReadd: Bool? }
        return try await request(
            "PATCH",
            path: "/plates/\(plateId.uuidString.lowercased())/visibility",
            body: Req(isHidden: isHidden, isBlockedReadd: isBlockedReadd)
        )
    }

    func searchPlates(query: String, stateCode: String = "VIC", limit: Int = 30) async throws -> [Plate] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await request("GET", path: "/plates/search?q=\(q)&state_code=\(stateCode)&limit=\(limit)")
    }

    // MARK: - Feed

    func getFeed(limit: Int = 30, offset: Int = 0) async throws -> [FeedItem] {
        try await request("GET", path: "/feed?limit=\(limit)&offset=\(offset)")
    }

    // MARK: - Comments

    func listComments(plateId: UUID, limit: Int = 50) async throws -> [Comment] {
        try await request("GET", path: "/plates/\(plateId.uuidString.lowercased())/comments?limit=\(limit)")
    }

    func createComment(plateId: UUID, body: String) async throws -> Comment {
        try await request("POST", path: "/plates/\(plateId.uuidString.lowercased())/comments", body: CommentCreateRequest(body: body))
    }

    func reportComment(commentId: UUID, reason: String) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("POST", path: "/comments/\(commentId.uuidString.lowercased())/report", body: ReportRequest(reason: reason))
    }

    func blockCommentAuthor(commentId: UUID) async throws {
        struct Empty: Decodable {}
        struct EmptyBody: Encodable {}
        let _: Empty = try await request("POST", path: "/comments/\(commentId.uuidString.lowercased())/block", body: EmptyBody())
    }
    // MARK: - Apple Sign-In

    func appleSignIn(identityToken: String, fullName: String?) async throws -> TokenPair {
        struct Req: Encodable { let identityToken: String; let fullName: String? }
        return try await post("/auth/apple", body: Req(identityToken: identityToken, fullName: fullName))
    }

    // MARK: - Password Reset

    func forgotPassword(email: String) async throws {
        struct Req: Encodable { let email: String }
        struct Resp: Decodable { let sent: Bool }
        let _: Resp = try await post("/auth/forgot-password", body: Req(email: email))
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        struct Req: Encodable { let email: String; let code: String; let newPassword: String }
        struct Resp: Decodable { let reset: Bool }
        let _: Resp = try await post("/auth/reset-password", body: Req(email: email, code: code, newPassword: newPassword))
    }

    // MARK: - Avatar Upload

    func uploadAvatar(imageData: Data, filename: String = "avatar.jpg") async throws -> AuthUser {
        guard let url = URL(string: baseURL + "/auth/me/avatar") else { throw APIError.invalidURL }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = KeychainService.shared.read(.accessToken) {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.httpBody = body

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Upload failed"
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }
        return try decoder.decode(AuthUser.self, from: data)
    }

    // MARK: - Device Token (Push Notifications)

    func registerDeviceToken(_ token: String) async throws {
        struct Req: Encodable { let deviceToken: String; let platform: String }
        struct Resp: Decodable { let registered: Bool }
        let _: Resp = try await post("/auth/me/device-token", body: Req(deviceToken: token, platform: "ios"))
    }

    // MARK: - Account Deletion

    func deleteAccount() async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("DELETE", path: "/auth/me")
    }
}

// MARK: - Private helpers

private struct DuplicatePlateErrorWrapper: Decodable {
    let detail: DuplicatePlateResponse
}
