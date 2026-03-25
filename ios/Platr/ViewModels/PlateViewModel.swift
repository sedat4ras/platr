// Platr iOS — PlateViewModel
// [iOSSwiftAgent | iOS-001 / iOS-002]
// MVVM: @Observable macro (iOS 17+), handles duplicate-redirect flow.

import Foundation
import SwiftUI

@Observable
final class PlateViewModel {

    // ── State ─────────────────────────────────────────────────────────────
    var plates: [Plate] = []
    var selectedPlate: Plate?
    var isLoading = false
    var isRechecking = false
    var errorMessage: String?

    // Duplicate redirect
    var duplicateRedirectPlateId: UUID?
    var showDuplicateAlert = false

    // Add plate form
    var newPlateText: String = ""
    var newPlateStyle: PlateStyle = .vicStandard
    var newIconLeft: String = ""
    var newIconRight: String = ""
    var selectedStateCode: String = "VIC"

    // ── API ───────────────────────────────────────────────────────────────
    private let api = APIService.shared

    // MARK: - Load

    func loadPlates(stateCode: String? = "VIC") async {
        isLoading = true
        defer { isLoading = false }
        do {
            plates = try await api.listPlates(stateCode: stateCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadPlate(id: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            selectedPlate = try await api.getPlate(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create

    /// Returns the created plate, or nil on non-duplicate error.
    /// On HTTP 409 (duplicate), sets duplicateRedirectPlateId and returns nil.
    @discardableResult
    func createPlate() async -> Plate? {
        isLoading = true
        defer { isLoading = false }

        let req = PlateCreateRequest(
            stateCode: selectedStateCode,
            plateText: newPlateText.uppercased().trimmingCharacters(in: .whitespaces),
            plateStyle: newPlateStyle,
            iconLeft: newIconLeft,
            iconRight: newIconRight
        )

        do {
            let plate = try await api.createPlate(req)
            plates.insert(plate, at: 0)
            resetForm()
            return plate
        } catch APIError.duplicatePlate(let dup) {
            // ── Duplicate redirect logic ────────────────────────────────────
            // iOS navigates to the existing plate's detail view
            duplicateRedirectPlateId = dup.existingPlateId
            showDuplicateAlert = true
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Spot

    func spotPlate(_ plate: Plate) async {
        do {
            try await api.spotPlate(id: plate.id)
            // Refresh the individual plate data
            if let updated = try? await api.getPlate(id: plate.id) {
                if let idx = plates.firstIndex(where: { $0.id == plate.id }) {
                    plates[idx] = updated
                }
                if selectedPlate?.id == plate.id {
                    selectedPlate = updated
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Recheck

    func recheckRego() async {
        guard let plate = selectedPlate else { return }
        isRechecking = true
        defer { isRechecking = false }
        do {
            try await api.recheckRego(plateId: plate.id)
            // Poll every 3 seconds (up to 30s) while status is still PENDING
            for _ in 0..<10 {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                if let updated = try? await api.getPlate(id: plate.id) {
                    selectedPlate = updated
                    if updated.vehicle.regoStatus != .pending { break }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func resetForm() {
        newPlateText       = ""
        newPlateStyle      = .vicStandard
        newIconLeft        = ""
        newIconRight       = ""
        selectedStateCode  = "VIC"
    }

    var isFormValid: Bool {
        let trimmed = newPlateText.trimmingCharacters(in: .whitespaces)
        let allowed = newPlateStyle.allowedCharacters
        let allValid = trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
        return !trimmed.isEmpty && trimmed.count <= newPlateStyle.maxCharacters && allValid
    }
}
