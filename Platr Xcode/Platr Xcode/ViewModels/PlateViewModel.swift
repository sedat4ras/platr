// Platr iOS — PlateViewModel
// MVVM: @Observable macro (iOS 17+), handles duplicate-redirect flow
// + similar plate detection for AddPlateView.

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class PlateViewModel {

    // ── State ─────────────────────────────────────────────────────────────
    var plates: [Plate] = []
    var selectedPlate: Plate?
    var isLoading = false
    var errorMessage: String?

    // Duplicate redirect
    var duplicateRedirectPlateId: UUID?
    var showDuplicateAlert = false

    // Add plate form
    var newPlateText: String = ""
    var newPlateStyle: PlateStyle = .vicStandard
    var selectedIcon1: PlateIcon? = nil
    var selectedIcon2: PlateIcon? = nil
    var selectedStateCode: String = "VIC"
    var hasSpaceSeparator: Bool = true
    var customBgColor: String = "#000000"

    // Similar plate detection
    var similarPlates: [Plate] = []
    var isCheckingSimilar = false
    private var similarCheckTask: Task<Void, Never>?

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
            iconLeft: selectedIcon1?.rawValue ?? "",
            iconRight: selectedIcon2?.rawValue ?? "",
            hasSpaceSeparator: hasSpaceSeparator,
            customBgColor: newPlateStyle == .vicCustom ? customBgColor : nil
        )

        do {
            let plate = try await api.createPlate(req)
            plates.insert(plate, at: 0)
            resetForm()
            return plate
        } catch APIError.duplicatePlate(let dup) {
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

    // MARK: - Similar Plate Check

    /// Debounced check for similar plates. Called as the user types.
    func checkForSimilarPlates() {
        similarCheckTask?.cancel()

        let text = normalizedPlateText
        guard text.count >= 2 else {
            similarPlates = []
            return
        }

        similarCheckTask = Task {
            // Debounce 400ms
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            isCheckingSimilar = true
            defer { isCheckingSimilar = false }

            do {
                let results = try await api.searchPlates(
                    query: text,
                    stateCode: selectedStateCode,
                    limit: 5
                )
                guard !Task.isCancelled else { return }
                similarPlates = results
            } catch {
                guard !Task.isCancelled else { return }
                similarPlates = []
            }
        }
    }

    // MARK: - Helpers

    func resetForm() {
        newPlateText  = ""
        newPlateStyle = .vicStandard
        selectedIcon1 = nil
        selectedIcon2 = nil
        hasSpaceSeparator = true
        customBgColor = "#000000"
        similarPlates = []
    }

    /// Number of ★ markers currently in plate text
    var iconMarkerCount: Int {
        newPlateText.filter { $0 == plateIconMarker }.count
    }

    var isFormValid: Bool {
        let text = newPlateText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, text.count <= newPlateStyle.maxCharacters else { return false }
        // Each ★ must have a corresponding icon selected
        let markerCount = text.filter { $0 == plateIconMarker }.count
        if markerCount >= 1 && selectedIcon1 == nil { return false }
        if markerCount >= 2 && selectedIcon2 == nil { return false }
        return true
    }

    /// Plate text stripped of formatting and ★ markers for comparison
    var normalizedPlateText: String {
        newPlateText
            .uppercased()
            .trimmingCharacters(in: .whitespaces)
            .filter { $0.isLetter || $0.isNumber }
    }

    /// Whether the typed plate text exactly matches an existing plate
    var hasExactMatch: Bool {
        let normalized = normalizedPlateText
        return similarPlates.contains { $0.plateText.uppercased() == normalized }
    }

    /// Similar but not exact matches
    var similarButNotExact: [Plate] {
        let normalized = normalizedPlateText
        return similarPlates.filter { $0.plateText.uppercased() != normalized }
    }
}
