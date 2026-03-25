// Platr iOS — Comment model (Swift 6 / Sendable)
// UGC: reportCount ve block action built-in

import Foundation

struct Comment: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let plateId: UUID
    let authorUserId: UUID
    let authorUsername: String?  // denormalised from backend via selectinload
    let body: String
    let reportCount: Int
    let isHidden: Bool
    let createdAt: Date
    let wasModerated: Bool   // true when AI moderation hid this comment on creation

    var isDeleted: Bool { body == "[deleted]" }

    // Custom decode so optional fields default gracefully when absent
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,   forKey: .id)
        plateId        = try c.decode(UUID.self,   forKey: .plateId)
        authorUserId   = try c.decode(UUID.self,   forKey: .authorUserId)
        authorUsername = try c.decodeIfPresent(String.self, forKey: .authorUsername)
        body           = try c.decode(String.self, forKey: .body)
        reportCount    = try c.decode(Int.self,    forKey: .reportCount)
        isHidden       = try c.decode(Bool.self,   forKey: .isHidden)
        createdAt      = try c.decode(Date.self,   forKey: .createdAt)
        wasModerated   = try c.decodeIfPresent(Bool.self, forKey: .wasModerated) ?? false
    }
}

struct CommentCreateRequest: Codable, Sendable {
    let body: String
}

struct ReportRequest: Codable, Sendable {
    let reason: String
}
