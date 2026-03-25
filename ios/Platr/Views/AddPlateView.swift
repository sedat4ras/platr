// Platr iOS — AddPlateView
// [iOSSwiftAgent | iOS-002]
// Form to submit a new plate. Handles HTTP 409 duplicate with alert + redirect.

import SwiftUI

struct AddPlateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PlateViewModel()
    @State private var showStylePicker = false

    // Called by parent to navigate to an existing plate on duplicate
    var onDuplicateFound: ((UUID) -> Void)?
    var onPlateCreated: ((Plate) -> Void)?

    let stateCodes = ["VIC"]  // NSW, QLD, etc. unlocked in future updates

    var body: some View {
        NavigationStack {
            Form {
                // ── Plate preview ──────────────────────────────────────────
                Section {
                    HStack {
                        Spacer()
                        PlateTemplateRenderer(
                            plateText: viewModel.newPlateText.isEmpty
                                       ? "PLATR" : viewModel.newPlateText,
                            style: viewModel.newPlateStyle,
                            iconLeft: viewModel.newIconLeft,
                            iconRight: viewModel.newIconRight
                        )
                        .frame(width: 280)
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                // ── Plate text input ───────────────────────────────────────
                Section("Plate Details") {
                    Picker("State", selection: $viewModel.selectedStateCode) {
                        ForEach(stateCodes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }

                    HStack {
                        Text("Plate Number")
                        Spacer()
                        TextField(viewModel.newPlateStyle.formatHint, text: $viewModel.newPlateText)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            // Client-side character filter: strips non-ASCII-alphanumeric characters and
                            // enforces per-style length limits. IMPORTANT: This is a UX convenience only.
                            // The backend API must independently validate plateText (ASCII A-Z, 0-9,
                            // length ≤ maxCharacters) and must not trust client input as a security boundary.
                            .onChange(of: viewModel.newPlateText) { _, new in
                                let maxLen = viewModel.newPlateStyle.maxCharacters
                                let allowed = viewModel.newPlateStyle.allowedCharacters
                                let filtered = new.uppercased().unicodeScalars.filter { allowed.contains($0) }
                                viewModel.newPlateText = String(String.UnicodeScalarView(filtered).prefix(maxLen))
                            }
                            .onChange(of: viewModel.newPlateStyle) { _, newStyle in
                                // Re-apply filter when style changes in case maxCharacters decreased
                                let maxLen = newStyle.maxCharacters
                                let allowed = newStyle.allowedCharacters
                                let filtered = viewModel.newPlateText.unicodeScalars.filter { allowed.contains($0) }
                                viewModel.newPlateText = String(String.UnicodeScalarView(filtered).prefix(maxLen))
                            }
                    }
                }

                // ── Template style picker ──────────────────────────────────
                Section("Style") {
                    Picker("Template", selection: $viewModel.newPlateStyle) {
                        ForEach(PlateStyle.styles(for: viewModel.selectedStateCode).filter { $0.isAvailable }) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: viewModel.selectedStateCode) { _, newState in
                        // When state changes, reset to that state's first available style
                        if let defaultStyle = PlateStyle.styles(for: newState).first(where: { $0.isAvailable }) {
                            viewModel.newPlateStyle = defaultStyle
                        }
                    }
                }

                // ── Icon slots ─────────────────────────────────────────────
                Section("Icons (optional)") {
                    iconPicker(label: "Left Icon", binding: $viewModel.newIconLeft)
                    iconPicker(label: "Right Icon", binding: $viewModel.newIconRight)
                }

                // ── Submit ─────────────────────────────────────────────────
                Section {
                    Button(action: submitPlate) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Add Plate")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Add a Plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // ── Duplicate alert (HTTP 409 handler) ─────────────────────────
            .alert("Plate Already Exists", isPresented: $viewModel.showDuplicateAlert) {
                Button("View Plate") {
                    if let id = viewModel.duplicateRedirectPlateId {
                        dismiss()
                        onDuplicateFound?(id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "\(viewModel.selectedStateCode)·\(viewModel.newPlateText) " +
                    "has already been added. Would you like to view it?"
                )
            }
            // ── Generic error alert ────────────────────────────────────────
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func iconPicker(label: String, binding: Binding<String>) -> some View {
        let options = ["", "[HEART]", "[STAR]", "[PAWS]", "[LEAF]", "[FLAME]", "[BOLT]", "[CROWN]"]
        Picker(label, selection: binding) {
            ForEach(options, id: \.self) { opt in
                Text(opt.isEmpty ? "None" : opt).tag(opt)
            }
        }
    }

    private func submitPlate() {
        Task {
            if let plate = await viewModel.createPlate() {
                dismiss()
                onPlateCreated?(plate)
            }
        }
    }
}

#Preview {
    AddPlateView()
}
