// Platr iOS — FeedItem model (unified activity feed)

import Foundation

struct FeedItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let type: FeedItemType
    let createdAt: Date
    let actorUserId: String?
    let actorUsername: String?
    let plateId: String
    let plateText: String
    let stateCode: String
    let commentBody: String?

    var plateUUID: UUID? { UUID(uuidString: plateId) }
}

enum FeedItemType: String, Codable, Sendable {
    case plateAdded = "plate_added"
    case comment    = "comment"
}
