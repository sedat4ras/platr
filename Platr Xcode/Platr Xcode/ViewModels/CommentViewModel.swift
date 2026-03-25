// Platr iOS — CommentViewModel
// [iOSSwiftAgent | iOS-002]
// Handles loading, posting, AI-moderation feedback, reporting (UGC Rule 1.2) and blocking.

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class CommentViewModel {
    var comments: [Comment] = []
    var isLoading = false
    var isPosting = false
    var errorMessage: String?
    var newCommentBody: String = ""

    // AI moderation alert (shown when a posted comment is flagged)
    var showModerationWarning = false
    var moderationMessage     = ""

    // UGC action feedback
    var reportedCommentIds: Set<UUID> = []
    var blockedAuthorIds:   Set<UUID> = []

    private let api = APIService.shared

    // MARK: - Load

    func loadComments(plateId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await api.listComments(plateId: plateId)
            // Filter out content from blocked authors
            comments = all.filter { !blockedAuthorIds.contains($0.authorUserId) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Post

    func postComment(plateId: UUID) async {
        let body = newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        isPosting = true
        defer { isPosting = false }

        do {
            let comment = try await api.createComment(plateId: plateId, body: body)
            newCommentBody = ""

            if comment.wasModerated {
                // Comment was hidden by AI moderation — show a polite warning,
                // do NOT insert it into the visible list.
                moderationMessage = "Your comment was hidden as it may violate our community standards. Please keep the conversation respectful."
                showModerationWarning = true
            } else {
                // Normal comment — insert at top of list
                comments.insert(comment, at: 0)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - UGC: Report (App Store Guideline 1.2)

    func reportComment(_ comment: Comment, reason: String) async {
        do {
            try await api.reportComment(commentId: comment.id, reason: reason)
            reportedCommentIds.insert(comment.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - UGC: Block author (App Store Guideline 1.2)

    func blockAuthor(of comment: Comment) async {
        do {
            try await api.blockCommentAuthor(commentId: comment.id)
            blockedAuthorIds.insert(comment.authorUserId)
            // Remove all comments by this author from the local list
            comments.removeAll { $0.authorUserId == comment.authorUserId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
