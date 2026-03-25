// Platr iOS — SearchView
// Plate lookup tool: compact text rows, no plate renderer, uses /plates/search endpoint.

import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [Plate] = []
    @State private var isSearching = false
    @State private var navigationPath = NavigationPath()

    private let selectedState = "VIC"
    private let api = APIService.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isSearching {
                    ProgressView("Searching…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if query.count < 2 {
                    promptState
                } else if results.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "e.g. ABC123")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .onChange(of: query) { _, new in
                if new.count >= 2 { Task { await performSearch() } }
                else { results = [] }
            }
            .navigationDestination(for: UUID.self) { PlateView(plateId: $0) }
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { plate in
                    Button {
                        navigationPath.append(plate.id)
                    } label: {
                        searchRow(plate)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Search row (compact — no plate renderer)

    @ViewBuilder
    private func searchRow(_ plate: Plate) -> some View {
        let (regoLabel, regoColor) = regoStyle(plate.vehicle.regoStatus)

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {

                // Top line: state chip + plate text + rego status
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

                    Spacer()

                    HStack(spacing: 4) {
                        Circle().fill(regoColor).frame(width: 7, height: 7)
                        Text(regoLabel)
                            .font(.caption.bold())
                            .foregroundStyle(regoColor)
                    }
                }

                // Vehicle details
                if !plate.vehicle.summaryText.isEmpty {
                    Text(plate.vehicle.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats row
                HStack(spacing: 12) {
                    if let username = plate.submittedByUsername {
                        Label("@\(username)", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Label("\(plate.spotCount) spots", systemImage: "location.fill")
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

    // MARK: - Prompt / empty states

    private var promptState: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("Look up a plate")
                .font(.title3.bold())
            Text("Type at least 2 characters to search Victoria plates")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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

    // MARK: - Search

    private func performSearch() async {
        guard query.count >= 2 else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await api.searchPlates(query: query, stateCode: selectedState)
        } catch {
            results = []
        }
    }

    // MARK: - Helpers

    private func regoStyle(_ status: RegoStatus) -> (String, Color) {
        switch status {
        case .current:             return ("Current", .green)
        case .expired, .cancelled: return ("Expired", .red)
        case .pending:             return ("Checking", .orange)
        default:                   return ("Unknown", .gray)
        }
    }
}

#Preview {
    SearchView()
}
