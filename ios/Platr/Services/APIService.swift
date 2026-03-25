// Platr iOS — API Service
// [iOSSwiftAgent | iOS-001]
// Async/await URLSession + Codable. Handles HTTP 409 duplicate redirect.

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case duplicatePlate(DuplicatePlateResponse)
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .duplicatePlate(let resp):
            return "Plate \(resp.stateCode)·\(resp.plateText) already exists."
        case .httpError(let code, let msg):
            return "HTTP \(code): \(msg)"
        case .decodingError(let e):
            return "Decoding error: \(e.localizedDescription)"
        case .networkError(let e):
            return e.localizedDescription
        }
    }
}

final class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String = "http://localhost:8001/api/v1") {
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Generic request

    /// Public convenience wrappers used by AuthService and other services
    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request("GET", path: path)
    }

    func post<T: Decodable>(_ path: String, body: Encodable?) async throws -> T {
        try await request("POST", path: path, body: body)
    }

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Inject Bearer token if available
        if let token = KeychainService.shared.read(.accessToken) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        // Handle 409 Conflict (duplicate plate) — iOS redirects to existing plate
        if http.statusCode == 409 {
            let dup = try decoder.decode(DuplicatePlateErrorWrapper.self, from: data)
            throw APIError.duplicatePlate(dup.detail)
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(http.statusCode, message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
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

    func listMySubmittedPlates() async throws -> [Plate] {
        try await request("GET", path: "/plates/submitted-by-me")
    }

    func searchPlates(query: String, stateCode: String? = nil) async throws -> [Plate] {
        var path = "/plates/search?q=\(query.uppercased())"
        if let sc = stateCode { path += "&state_code=\(sc)" }
        return try await request("GET", path: path)
    }

    func spotPlate(id: UUID) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("POST", path: "/plates/\(id.uuidString.lowercased())/spot")
    }

    func recheckRego(plateId: UUID) async throws {
        struct RecheckResponse: Decodable { let detail: String }
        let _: RecheckResponse = try await request("POST", path: "/plates/\(plateId.uuidString.lowercased())/recheck", body: Optional<String>.none)
    }

    // MARK: - Comments

    func listComments(plateId: UUID, limit: Int = 50) async throws -> [Comment] {
        try await request("GET", path: "/plates/\(plateId.uuidString.lowercased())/comments?limit=\(limit)")
    }

    func createComment(plateId: UUID, body: String) async throws -> Comment {
        let payload = CommentCreateRequest(body: body)
        return try await request("POST", path: "/plates/\(plateId.uuidString.lowercased())/comments", body: payload)
    }

    /// App Store UGC Rule 1.2 — Report
    func reportComment(commentId: UUID, reason: String) async throws {
        struct Empty: Decodable {}
        let payload = ReportRequest(reason: reason)
        let _: Empty = try await request("POST", path: "/comments/\(commentId.uuidString.lowercased())/report", body: payload)
    }

    /// App Store UGC Rule 1.2 — Block author
    func blockCommentAuthor(commentId: UUID) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request("POST", path: "/comments/\(commentId.uuidString.lowercased())/block", body: Optional<String>.none)
    }
}

// Wrapper to decode the 409 `detail` field which contains a DuplicatePlateResponse JSON
private struct DuplicatePlateErrorWrapper: Decodable {
    let detail: DuplicatePlateResponse
}
