// Platr iOS — ContentView (Feed)
// Social discovery feed: full-width plate renders + submitter + time + spot count.

import SwiftUI

struct ContentView: View {
    @State private var plateVM = PlateViewModel()
    @State private var showAddPlate = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if plateVM.isLoading && plateVM.plates.isEmpty {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if plateVM.plates.isEmpty {
                    emptyState
                } else {
                    feedList
                }
            }
            .navigationTitle("Feed")
            .navigationDestination(for: UUID.self) { PlateView(plateId: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddPlate = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddPlate) {
                AddPlateView(
                    onDuplicateFound: { navigationPath.append($0) },
                    onPlateCreated:   { navigationPath.append($0.id) }
                )
            }
            .task { await plateVM.loadPlates(stateCode: nil) }
            .refreshable { await plateVM.loadPlates(stateCode: nil) }
        }
    }

    // MARK: - Feed list

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(plateVM.plates) { plate in
                    Button {
                        navigationPath.append(plate.id)
                    } label: {
                        feedCard(plate)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Feed card

    @ViewBuilder
    private func feedCard(_ plate: Plate) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Full-width plate render ────────────────────────────────────
            PlateTemplateRenderer(
                plateText: plate.plateText,
                style: plate.plateStyle,
                iconLeft: plate.iconLeft,
                iconRight: plate.iconRight
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 16)

            // ── Info section ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {

                // Plate ID + state chip + rego badge
                HStack(spacing: 8) {
                    Text(plate.plateText)
                        .font(.title3.bold())
                    Text(plate.stateCode)
                        .font(.caption.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    Spacer()
                    regoBadge(plate.vehicle.regoStatus)
                }

                // Vehicle summary
                if !plate.vehicle.summaryText.isEmpty {
                    Text(plate.vehicle.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Social row: submitter · time ago · spot count
                HStack(spacing: 6) {
                    if let username = plate.submittedByUsername {
                        Label("@\(username)", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.quaternary)

                    Text(relativeTime(plate.createdAt))
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Label("\(plate.spotCount)", systemImage: "eye")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
    }

    // MARK: - Helpers

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
        .background(color.opacity(0.10))
        .clipShape(Capsule())
    }

    private func regoColor(_ status: RegoStatus) -> Color {
        switch status {
        case .current:             return .green
        case .expired, .cancelled: return .red
        case .pending:             return .orange
        default:                   return .gray
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60     { return "just now" }
        if s < 3600   { return "\(s / 60)m ago" }
        if s < 86400  { return "\(s / 3600)h ago" }
        if s < 604800 { return "\(s / 86400)d ago" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: date)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.rear.road.lane.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No plates yet")
                .font(.title3.bold())
            Text("Be the first to add a plate!")
                .foregroundStyle(.secondary)
            Button("Add a Plate") { showAddPlate = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
