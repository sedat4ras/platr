// Platr iOS — Comment data model
// [iOSSwiftAgent | iOS-002]
// UGC compliance: reportCount and block action built into model

import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: UUID
    let plateId: UUID
    let authorUserId: UUID
    let body: String
    let reportCount: Int
    let isHidden: Bool
    let createdAt: Date

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }

    var isDeleted: Bool {
        body == "[deleted]"
    }
}

struct CommentCreateRequest: Codable {
    let body: String
}

struct ReportRequest: Codable {
    let reason: String
}
