// Platr iOS — ContentView (Pure Activity Feed)
// Unified feed: plate additions + comment activity, chronologically ordered.

import SwiftUI

// MARK: - Navigation types

struct UserProfileNavigation: Hashable {
    let userId: String
    let username: String
}

struct ContentView: View {

    @State private var feedItems: [FeedItem] = []
    @State private var isLoadingFeed  = false
    @State private var feedError: String?
    @State private var navigationPath = NavigationPath()

    private let api = APIService.shared

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            feedContent
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .task { await loadFeed() }
            .refreshable { await loadFeed() }
            .navigationDestination(for: UUID.self) { PlateView(plateId: $0) }
            .navigationDestination(for: UserProfileNavigation.self) { nav in
                UserProfileView(userId: nav.userId, username: nav.username)
            }
        }
    }

    // MARK: - Feed content

    @ViewBuilder
    private var feedContent: some View {
        if isLoadingFeed && feedItems.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = feedError, feedItems.isEmpty {
            NetworkErrorView(message: error) { await loadFeed() }
        } else if feedItems.isEmpty {
            emptyFeedState
        } else {
            List {
                // ── Header bar ──────────────────────────────────────
                feedHeaderBar
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(feedItems) { item in
                    feedRow(item)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Header bar

    @ViewBuilder
    private var feedHeaderBar: some View {
        HStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Latest Activities")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    // MARK: - Feed row (unified)

    @ViewBuilder
    private func feedRow(_ item: FeedItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Bullet — blue for plates, orange for comments
            Circle()
                .fill(item.type == .plateAdded ? Color.accentColor : Color.orange)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 6) {
                activityText(item)
                Text(relativeTime(item.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func activityText(_ item: FeedItem) -> some View {
        switch item.type {
        case .plateAdded:
            // "@username added "ABC123""
            HStack(spacing: 0) {
                userLink(item)
                Text(" added ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                plateLink(item)
            }

        case .comment:
            // "@username commented on "ABC123""
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    userLink(item)
                    Text(" commented on ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    plateLink(item)
                }
                if let body = item.commentBody {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    @ViewBuilder
    private func userLink(_ item: FeedItem) -> some View {
        if let username = item.actorUsername {
            Button {
                if let userId = item.actorUserId {
                    navigationPath.append(
                        UserProfileNavigation(userId: userId, username: username)
                    )
                }
            } label: {
                Text("@\(username)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        } else {
            Text("Someone")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func plateLink(_ item: FeedItem) -> some View {
        Button {
            if let uuid = item.plateUUID {
                navigationPath.append(uuid)
            }
        } label: {
            Text("\"\(item.plateText)\"")
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyFeedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.rear.road.lane.dashed")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No activity yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Plates and comments will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - API

    private func loadFeed() async {
        isLoadingFeed = true
        feedError = nil
        defer { isLoadingFeed = false }
        do {
            feedItems = try await api.getFeed()
        } catch {
            if feedItems.isEmpty {
                feedError = error.localizedDescription
            }
        }
    }

    // MARK: - Helpers

    private func relativeTime(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60     { return "just now" }
        if s < 3600   { return "\(s / 60)m ago" }
        if s < 86400  { return "\(s / 3600)h ago" }
        if s < 604800 { return "\(s / 86400)d ago" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

#Preview {
    ContentView()
}
