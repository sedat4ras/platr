// Platr iOS — UserProfileView
// Public profile page for viewing other users from the feed.

import SwiftUI

struct UserProfileView: View {
    let userId: String
    let username: String

    @State private var userPlates: [Plate] = []
    @State private var isLoading = false

    private let api = APIService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // ── Hero section ────────────────────────────────────────
                VStack(spacing: 14) {
                    // Initials avatar
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Circle()
                            .stroke(Color.accentColor.opacity(0.25), lineWidth: 2)
                            .frame(width: 88, height: 88)
                        Text(String(username.prefix(1)).uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(spacing: 4) {
                        Text("@\(username)")
                            .font(.title3.bold())
                        Text("Platr Member")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 24)

                // ── Stats ───────────────────────────────────────────────
                if !userPlates.isEmpty {
                    HStack(spacing: 0) {
                        statItem(
                            value: userPlates.count,
                            label: "Plates",
                            icon: "car.fill"
                        )
                        Divider()
                            .frame(height: 32)
                            .background(Color(.separator))
                        statItem(
                            value: userPlates.reduce(0) { $0 + $1.spotCount },
                            label: "Spots",
                            icon: "location.fill"
                        )
                        Divider()
                            .frame(height: 32)
                            .background(Color(.separator))
                        statItem(
                            value: userPlates.reduce(0) { $0 + $1.viewCount },
                            label: "Views",
                            icon: "eye.fill"
                        )
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                    .padding(.horizontal)
                }

                // ── Plates section ──────────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plates by @\(username)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if userPlates.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "car.rear.road.lane.dashed")
                                .font(.system(size: 44))
                                .foregroundStyle(.tertiary)
                            Text("No plates yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("This user hasn't added any plates.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(userPlates) { plate in
                                NavigationLink(value: plate.id) {
                                    plateRow(plate)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadUserPlates() }
    }

    // MARK: - Components

    @ViewBuilder
    private func statItem(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                Text("\(value)")
                    .font(.title3.bold().monospacedDigit())
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func plateRow(_ plate: Plate) -> some View {
        HStack(spacing: 14) {
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                icon1: plate.icon1,
                icon2: plate.icon2,
                hasSpaceSeparator: plate.hasSpaceSeparator,
                customBgColor: plate.customBgColor.map { Color(hex: $0) }
            )
            .frame(width: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(plate.stateCode) \u{00B7} \(plate.plateText)")
                    .font(.subheadline.bold())

                HStack(spacing: 12) {
                    Label("\(plate.spotCount)", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(plate.viewCount)", systemImage: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - API

    private func loadUserPlates() async {
        isLoading = true
        defer { isLoading = false }
        // Search for plates by this user via the search endpoint
        // (limited approach — will show plates matching their username)
        if let plates = try? await api.listPlates(stateCode: nil, limit: 50, offset: 0) {
            userPlates = plates.filter { $0.submittedByUserId?.uuidString.lowercased() == userId.lowercased() }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: "test-uuid", username: "sedat4ras")
    }
}
