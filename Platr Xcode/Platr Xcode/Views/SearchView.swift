// Platr iOS — SearchView
// [iOSSwiftAgent]

import SwiftUI

struct SearchView: View {
    @Environment(AuthViewModel.self) private var authVM

    @State private var query            = ""
    @State private var results: [Plate] = []
    @State private var recentPlates: [Plate] = []
    @State private var isSearching      = false
    @State private var isLoadingRecent  = false
    @State private var errorMessage: String?
    @State private var navigationPath   = NavigationPath()
    @State private var showAddPlate     = false

    private var recentSearches: [String] {
        let key = "recentPlateSearches_\(authVM.currentUser?.id ?? "guest")"
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Array(list.prefix(3))
    }

    private let api = APIService.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if isSearching {
                        HStack {
                            Spacer()
                            ProgressView("Searching…")
                            Spacer()
                        }
                        .padding(.top, 40)

                    } else if !query.isEmpty {
                        // ── Search results ─────────────────────────────────
                        if results.isEmpty {
                            emptyState
                        } else {
                            ForEach(results) { plate in
                                Button {
                                    navigationPath.append(plate.id)
                                } label: {
                                    searchResultRow(plate)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                    } else {
                        // ── Idle: recent searches + recently added ──────────
                        if !recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("Recent Searches")
                                ForEach(recentSearches, id: \.self) { term in
                                    Button {
                                        query = term
                                        Task { await performSearch(term) }
                                    } label: {
                                        HStack {
                                            Image(systemName: "clock")
                                                .foregroundStyle(.secondary)
                                            Text(term)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color(.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Recently Added")
                            // Show spinner only on very first load (empty list)
                            if isLoadingRecent && recentPlates.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if recentPlates.isEmpty {
                                Text("No plates yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 4)
                            } else {
                                ForEach(recentPlates) { plate in
                                    Button {
                                        navigationPath.append(plate.id)
                                    } label: {
                                        searchResultRow(plate)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search Plates")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Plate number, e.g. 2BN6AY")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .onChange(of: query) { _, newValue in
                if newValue.count >= 2 {
                    Task { await performSearch(newValue) }
                } else if newValue.isEmpty {
                    results = []
                }
            }
            .navigationDestination(for: UUID.self) { plateId in
                PlateView(plateId: plateId)
            }
            .sheet(isPresented: $showAddPlate) {
                AddPlateView(
                    onDuplicateFound: { id in
                        showAddPlate = false
                        navigationPath.append(id)
                    },
                    onPlateCreated: { plate in
                        showAddPlate = false
                        navigationPath.append(plate.id)
                    }
                )
            }
            .onAppear { Task { await loadRecentPlates() } }
            // Refresh list after AddPlate sheet dismisses so the new plate
            // immediately appears (and the 11th pushes the 1st off)
            .onChange(of: showAddPlate) { _, isShowing in
                if !isShowing { Task { await loadRecentPlates() } }
            }
        }
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    // MARK: - Empty state (no results for query)

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)

            Text("No plates found for \"\(query)\"")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Want to add it to Platr?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showAddPlate = true
            } label: {
                Label("Add \"\(query.uppercased())\"", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding()
    }

    // MARK: - Result row

    @ViewBuilder
    private func searchResultRow(_ plate: Plate) -> some View {
        HStack(spacing: 14) {
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                icon1: plate.icon1,
                icon2: plate.icon2,
                hasSpaceSeparator: plate.hasSpaceSeparator,
                customBgColor: plate.customBgColor.map { Color(hex: $0) }
            )
            .frame(width: 150)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(plate.stateCode) · \(plate.plateText)")
                    .font(.subheadline.bold())
                if plate.ownerUserId != nil {
                    Text("Owned")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green, in: Capsule())
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - API

    private func performSearch(_ term: String) async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await api.searchPlates(query: trimmed)
            saveRecentSearch(trimmed.uppercased())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRecentPlates() async {
        // Only show spinner when the list is empty (first load).
        // On tab revisits, update silently so the list never disappears.
        let firstLoad = recentPlates.isEmpty
        if firstLoad { isLoadingRecent = true }
        defer { isLoadingRecent = false }
        if let plates = try? await api.listPlates(stateCode: "VIC", limit: 10, offset: 0) {
            recentPlates = plates
        }
    }

    // MARK: - Persistence

    private func saveRecentSearch(_ term: String) {
        let key = "recentPlateSearches_\(authVM.currentUser?.id ?? "guest")"
        var current = recentSearches
        current.removeAll { $0 == term }
        current.insert(term, at: 0)
        current = Array(current.prefix(3))
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

#Preview {
    SearchView()
}
