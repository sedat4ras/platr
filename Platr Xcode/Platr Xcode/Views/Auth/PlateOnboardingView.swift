// Platr iOS — PlateOnboardingView
// Shown after registration: optionally add your own plate to get started.

import SwiftUI

struct PlateOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var plateText = ""
    @State private var selectedStyle: PlateStyle = .vicStandard
    @State private var isChecking = false
    @State private var plateExists = false
    @State private var existingPlateId: UUID?
    @State private var plateCreated = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool

    private let api = APIService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Header ────────────────────────────────────────────
                    headerSection

                    // ── Plate Preview ─────────────────────────────────────
                    PlateTemplateRenderer(
                        plateText: plateText.isEmpty ? "YOUR PLATE" : plateText.uppercased(),
                        style: selectedStyle
                    )
                    .frame(width: 260)
                    .animation(.smooth(duration: 0.25), value: plateText)
                    .animation(.smooth(duration: 0.25), value: selectedStyle)

                    // ── Plate Text Input ──────────────────────────────────
                    plateInput

                    // ── Style Picker ─────────────────────────────────────
                    stylePicker

                    // ── Result Messages ───────────────────────────────────
                    if plateExists {
                        plateExistsMessage
                    }

                    if plateCreated {
                        plateCreatedMessage
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // ── Action Buttons ────────────────────────────────────
                    actionButtons

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Welcome to Platr!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .interactiveDismissDisabled(false)
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 4)

            Text("Got a plate?")
                .font(.title2.bold())

            Text("If you have a personalised plate, add it now to get started. You can always do this later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Plate Text Input

    @ViewBuilder
    private var plateInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plate Number")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text("VIC")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                TextField("e.g. ABC123", text: $plateText)
                    .font(.system(.title3, design: .monospaced).bold())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($isTextFieldFocused)
                    .onChange(of: plateText) { _, newValue in
                        let cleaned = String(
                            newValue.uppercased()
                                .filter { $0.isLetter || $0.isNumber }
                                .prefix(8)
                        )
                        plateText = cleaned
                        // Reset states on new input
                        plateExists = false
                        existingPlateId = nil
                        plateCreated = false
                        errorMessage = nil
                    }

                Text("\(plateText.count)/8")
                    .font(.caption)
                    .foregroundStyle(plateText.count >= 3 ? .green : .secondary)
                    .monospacedDigit()
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Style Picker

    @ViewBuilder
    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plate Style")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PlateStyle.vicStyles) { style in
                        let isSelected = selectedStyle == style

                        Button {
                            withAnimation(.smooth(duration: 0.25)) {
                                selectedStyle = style
                            }
                        } label: {
                            VStack(spacing: 8) {
                                PlateTemplateRenderer(
                                    plateText: "ABC",
                                    style: style
                                )
                                .frame(width: 90)
                                .allowsHitTesting(false)

                                Text(style.displayName)
                                    .font(.caption2.bold())
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected
                                          ? Color.accentColor.opacity(0.08)
                                          : Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Plate Exists Message

    @ViewBuilder
    private var plateExistsMessage: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("This plate already exists")
                    .font(.subheadline.bold())
                Text("The plate you're trying to add already exists in our system. You can claim it from the plate detail page.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Plate Created Message

    @ViewBuilder
    private var plateCreatedMessage: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Plate added successfully!")
                    .font(.subheadline.bold())
                Text("Your plate has been added to Platr. You can claim ownership from the plate detail page.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Add Plate button
            Button(action: addPlate) {
                HStack(spacing: 8) {
                    if isChecking {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Add My Plate")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isFormValid && !isChecking && !plateCreated
                             ? Color.accentColor
                             : Color(.secondarySystemBackground))
                .foregroundStyle(isFormValid && !isChecking && !plateCreated
                                  ? .white
                                  : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isFormValid || isChecking || plateCreated)

            // Continue / Done button
            Button {
                dismiss()
            } label: {
                Text(plateCreated || plateExists ? "Continue" : "Skip for now")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    // MARK: - Logic

    private var isFormValid: Bool {
        let text = plateText.trimmingCharacters(in: .whitespaces)
        return text.count >= 2 && text.count <= 8
    }

    private func addPlate() {
        guard isFormValid else { return }

        isChecking = true
        errorMessage = nil
        plateExists = false
        plateCreated = false

        Task {
            defer { isChecking = false }

            let req = PlateCreateRequest(
                stateCode: "VIC",
                plateText: plateText.uppercased().trimmingCharacters(in: .whitespaces),
                plateStyle: selectedStyle,
                iconLeft: "",
                iconRight: "",
                hasSpaceSeparator: true,
                customBgColor: nil
            )

            do {
                let _: Plate = try await api.createPlate(req)
                plateCreated = true
            } catch APIError.duplicatePlate(let dup) {
                existingPlateId = dup.existingPlateId
                plateExists = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    PlateOnboardingView()
}
