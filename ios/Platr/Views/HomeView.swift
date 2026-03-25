// Platr iOS — HomeView
// Combined Feed + Search.
// Idle: text-based activity feed (no plate renderer).
// Searching: compact text rows.
// Tappable: plate text → PlateView, @username → (TODO: PublicProfileView)

import SwiftUI

struct HomeView: View {

    // ── State ──────────────────────────────────────────────────────────────
    @State private var feedPlates:    [Plate] = []
    @State private var searchResults: [Plate] = []
    @State private var isLoadingFeed  = false
    @State private var isSearching    = false
    @State private var query          = ""
    @State private var navigationPath = NavigationPath()
    @State private var showAddPlate   = false

    private let selectedState = "VIC"
    private let api = APIService.shared

    // ── Body ───────────────────────────────────────────────────────────────
    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContent
            .navigationTitle("Platr")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search plates, e.g. ABC123")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .toolbar { addButton }
            .sheet(isPresented: $showAddPlate) {
                AddPlateView(
                    onDuplicateFound: { navigationPath.append($0) },
                    onPlateCreated:   { navigationPath.append($0.id) }
                )
            }
            .onChange(of: query) { _, new in
                if new.count >= 2 { Task { await performSearch() } }
                else { searchResults = [] }
            }
            .task { await loadFeed() }
            .refreshable {
                if query.count >= 2 { await performSearch() }
                else { await loadFeed() }
            }
            .navigationDestination(for: UUID.self) { PlateView(plateId: $0) }
        }
    }

    // ── Main content: feed or search ───────────────────────────────────────

    @ViewBuilder
    private var mainContent: some View {
        if query.count >= 2 {
            searchContent
        } else {
            feedContent
        }
    }

    // MARK: - Feed mode ─────────────────────────────────────────────────────

    @ViewBuilder
    private var feedContent: some View {
        if isLoadingFeed && feedPlates.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if feedPlates.isEmpty {
            emptyFeedState
        } else {
            List {
                ForEach(feedPlates) { plate in
                    feedRow(plate)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                }
            }
            .listStyle(.plain)
        }
    }

    // Feed row — tappable plate + username, no plate renderer
    @ViewBuilder
    private func feedRow(_ plate: Plate) -> some View {
        VStack(alignment: .leading, spacing: 5) {

            // Row 1: "ABC123 · spotted by @username"
            HStack(spacing: 0) {

                // Tappable: plate text → PlateView
                Button {
                    navigationPath.append(plate.id)
                } label: {
                    Text(plate.plateText)
                        .font(.body.bold())
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)

                Text("  ·  spotted by ")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let username = plate.submittedByUsername {
                    // Tappable: username → (TODO: PublicProfileView)
                    Button {
                        // TODO: navigate to PublicProfileView(username: username)
                    } label: {
                        Text("@\(username)")
                            .font(.body.bold())
                            .foregroundStyle(Color.orange)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("someone")
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }

            // Row 2: relative time
            Text(relativeTime(plate.createdAt))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    // MARK: - Search mode ───────────────────────────────────────────────────

    @ViewBuilder
    private var searchContent: some View {
        if isSearching {
            ProgressView("Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if searchResults.isEmpty {
            noResultsState
        } else {
            List {
                ForEach(searchResults) { plate in
                    searchRow(plate)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(.plain)
        }
    }

    // Search row — compact, no plate renderer
    @ViewBuilder
    private func searchRow(_ plate: Plate) -> some View {
        let (regoLabel, regoColor) = regoStyle(plate.vehicle.regoStatus)

        Button { navigationPath.append(plate.id) } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {

                    // State chip + plate text + rego
                    HStack(spacing: 8) {
                        Text(plate.stateCode)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(plate.plateText)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(.primary)

                        Spacer()

                        HStack(spacing: 4) {
                            Circle().fill(regoColor).frame(width: 7, height: 7)
                            Text(regoLabel)
                                .font(.caption.bold())
                                .foregroundStyle(regoColor)
                        }
                    }

                    // Vehicle detail
                    if !plate.vehicle.summaryText.isEmpty {
                        Text(plate.vehicle.summaryText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Meta row
                    HStack(spacing: 10) {
                        if let username = plate.submittedByUsername {
                            Label("@\(username)", systemImage: "person.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Label("\(plate.spotCount) spot", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.quaternary)
                    .font(.caption)
                    .padding(.top, 4)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty / no-results states ────────────────────────────────────

    private var emptyFeedState: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.rear.road.lane.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No plates yet")
                .font(.title3.bold())
            Text("Be the first to add one!")
                .foregroundStyle(.secondary)
            Button("Add Plate") { showAddPlate = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("No results for "\(query)"")
                .font(.title3.bold())
            Text("This plate isn't in the database yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar ───────────────────────────────────────────────────────

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showAddPlate = true } label: {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
            }
        }
    }

    // MARK: - API ───────────────────────────────────────────────────────────

    private func loadFeed() async {
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        if let result = try? await api.listPlates(stateCode: selectedState) {
            feedPlates = result
        }
    }

    private func performSearch() async {
        guard query.count >= 2 else { return }
        isSearching = true
        defer { isSearching = false }
        if let result = try? await api.searchPlates(query: query, stateCode: selectedState) {
            searchResults = result
        }
    }

    // MARK: - Helpers ───────────────────────────────────────────────────────

    private func regoStyle(_ status: RegoStatus) -> (String, Color) {
        switch status {
        case .current:             return ("Current", .green)
        case .expired, .cancelled: return ("Expired", .red)
        case .pending:             return ("Checking", .orange)
        default:                   return ("Unknown", .gray)
        }
    }

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
    HomeView()
}
