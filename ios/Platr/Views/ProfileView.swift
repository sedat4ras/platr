// Platr iOS — ProfileView
// Modern "Driver's License" aesthetic:
// Gradient hero with avatar + stats → card-based plate list → account section.

import SwiftUI

struct ProfileView: View {
    @Bindable var authVM: AuthViewModel
    @State private var myPlates: [Plate] = []
    @State private var isLoading = false
    @State private var navigationPath = NavigationPath()
    @State private var showLogoutConfirm = false

    private let api = APIService.shared

    // MARK: - Derived stats

    private var totalSpots: Int { myPlates.reduce(0) { $0 + $1.spotCount } }
    private var totalViews: Int { myPlates.reduce(0) { $0 + $1.viewCount } }

    private var displayName: String {
        authVM.currentUser?.displayName
            ?? authVM.currentUser?.username
            ?? "Platr User"
    }

    private var username: String { authVM.currentUser?.username ?? "" }
    private var isVerified: Bool { authVM.currentUser?.isVerified ?? false }

    private var initials: String {
        let name = authVM.currentUser?.displayName ?? authVM.currentUser?.username ?? "P"
        return String(name.prefix(1)).uppercased()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    profileHero
                    statsRow
                    myPlatesSection
                    accountSection
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { plateId in
                PlateView(plateId: plateId)
            }
            .task {
                await loadMyPlates()
                await authVM.fetchMe()
            }
            .refreshable {
                await loadMyPlates()
                await authVM.fetchMe()
            }
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) { authVM.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Hero

    private var profileHero: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.accentColor,
                    Color.accentColor.opacity(0.6),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)

            VStack(spacing: 10) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.35), lineWidth: 2)
                        )

                    Text(initials)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)

                // Name + verified badge
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.headline)
                    }
                }

                // @username
                if !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(.bottom, 28)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: myPlates.count, label: "Plates")
            statDivider
            statCell(value: totalSpots, label: "Spots")
            statDivider
            statCell(value: totalViews, label: "Views")
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.title3.bold())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 1, height: 28)
    }

    // MARK: - My Plates

    private var myPlatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "My Plates", count: myPlates.isEmpty ? nil : myPlates.count)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else if myPlates.isEmpty {
                emptyPlatesState
            } else {
                ForEach(myPlates) { plate in
                    Button {
                        navigationPath.append(plate.id)
                    } label: {
                        plateCard(plate)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }

    @ViewBuilder
    private func plateCard(_ plate: Plate) -> some View {
        HStack(spacing: 14) {
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                iconLeft: plate.iconLeft,
                iconRight: plate.iconRight
            )
            .frame(width: 130)
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 7) {
                Text(plate.plateText)
                    .font(.headline)
                    .foregroundStyle(.primary)

                regoBadge(plate.vehicle.regoStatus)

                Label(
                    plate.isCommentsOpen ? "Comments open" : "Closed",
                    systemImage: plate.isCommentsOpen ? "bubble.left.fill" : "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(plate.isCommentsOpen ? .green : .secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func regoBadge(_ status: RegoStatus) -> some View {
        let color = regoColor(status)
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(status.displayText)
                .font(.caption2.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func regoColor(_ status: RegoStatus) -> Color {
        switch status {
        case .current:              return .green
        case .expired, .cancelled:  return .red
        case .pending:              return .orange
        default:                    return .gray
        }
    }

    private var emptyPlatesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.rear.road.lane.dashed")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No plates yet")
                .font(.headline)
            Text("Plates you spot will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Account", count: nil)

            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .frame(width: 20)
                    Text("Sign Out")
                    Spacer()
                }
                .font(.body)
                .foregroundStyle(.red)
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Section header

    private func sectionHeader(title: String, count: Int?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(0.8)

            if let count {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Load

    private func loadMyPlates() async {
        isLoading = true
        defer { isLoading = false }
        if let plates = try? await api.listMySubmittedPlates() {
            myPlates = plates
        }
    }
}

#Preview {
    ProfileView(authVM: AuthViewModel())
}
