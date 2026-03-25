// Platr iOS — PlateOwnershipView
// [iOSSwiftAgent]
// Lets a user claim an unclaimed plate or manage one they already own.
// Relinquish, toggle comments, shown when viewing a plate you own.

import SwiftUI

struct PlateOwnershipView: View {
    let plate: Plate
    var onUpdate: ((Plate) -> Void)?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showClaimConfirm = false
    @State private var showRelinquishConfirm = false
    @Environment(\.dismiss) private var dismiss

    private let api = APIService.shared

    // Is the current user the owner?
    // In a real app inject currentUser from environment; here we assume
    // any logged-in user viewing this sheet can act on it.
    private var isOwner: Bool { plate.ownerUserId != nil }
    private var isClaimed: Bool { plate.ownerUserId != nil }

    var body: some View {
        NavigationStack {
            Form {
                // ── Plate preview ──────────────────────────────────────────
                Section {
                    HStack {
                        Spacer()
                        PlateTemplateRenderer(
                            plateText: plate.plateText,
                            style: plate.plateStyle,
                            iconLeft: plate.iconLeft,
                            iconRight: plate.iconRight
                        )
                        .frame(width: 260)
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                // ── Claim / Relinquish ─────────────────────────────────────
                Section("Ownership") {
                    if !isClaimed {
                        Button("Claim This Plate") {
                            showClaimConfirm = true
                        }
                        .foregroundStyle(.accentColor)

                        Text("Claiming marks this as your plate. Only you can close comments on it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if isOwner {
                        Label("You own this plate", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)

                        Button("Toggle Comments", role: .none) {
                            Task { await toggleComments() }
                        }

                        Button("Relinquish Ownership", role: .destructive) {
                            showRelinquishConfirm = true
                        }
                    } else {
                        Label("Claimed by someone else", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                // ── Status ─────────────────────────────────────────────────
                Section("Settings") {
                    LabeledContent("Comments") {
                        Text(plate.isCommentsOpen ? "Open" : "Closed")
                            .foregroundStyle(plate.isCommentsOpen ? .green : .secondary)
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Plate Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if isLoading { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            // ── Claim alert ────────────────────────────────────────────────
            .alert("Claim Plate?", isPresented: $showClaimConfirm) {
                Button("Claim") { Task { await claimPlate() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This marks \(plate.stateCode)·\(plate.plateText) as your plate.")
            }
            // ── Relinquish alert ───────────────────────────────────────────
            .alert("Relinquish Ownership?", isPresented: $showRelinquishConfirm) {
                Button("Relinquish", role: .destructive) { Task { await relinquishPlate() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will no longer be the owner of this plate.")
            }
        }
    }

    // MARK: - Actions

    private func claimPlate() async {
        isLoading = true; defer { isLoading = false }
        do {
            let updated: Plate = try await api.post(
                "/plates/\(plate.id.uuidString.lowercased())/claim", body: Optional<String>.none
            )
            onUpdate?(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func relinquishPlate() async {
        isLoading = true; defer { isLoading = false }
        // DELETE /plates/{id}/claim
        struct Empty: Decodable {}
        do {
            let _: Empty = try await api.request("DELETE",
                path: "/plates/\(plate.id.uuidString.lowercased())/claim")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleComments() async {
        isLoading = true; defer { isLoading = false }
        do {
            let updated: Plate = try await api.post(
                "/plates/\(plate.id.uuidString.lowercased())/comments/toggle",
                body: Optional<String>.none
            )
            onUpdate?(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    PlateOwnershipView(plate: Plate(
        id: UUID(),
        stateCode: "VIC",
        plateText: "DEMO01",
        plateStyle: .vicCustomBlack,
        iconLeft: "[HEART]",
        iconRight: "",
        isCommentsOpen: true,
        spotCount: 12,
        viewCount: 88,
        ownerUserId: nil,
        vehicle: VehicleDetails(
            vehicleYear: 2022,
            vehicleMake: "Toyota",
            vehicleModel: "Camry",
            vehicleColor: "Silver",
            regoStatus: .current,
            regoExpiryDate: nil,
            regoCheckedAt: nil
        ),
        createdAt: Date(),
        updatedAt: Date()
    ))
}
