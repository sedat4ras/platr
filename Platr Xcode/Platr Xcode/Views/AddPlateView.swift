// Platr iOS — AddPlateView (Redesigned)
// Visual style picker, inline icon insertion, similar plate warning.

import SwiftUI

struct AddPlateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PlateViewModel()
    @FocusState private var isPlateTextFocused: Bool

    var onDuplicateFound: ((UUID) -> Void)?
    var onPlateCreated: ((Plate) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Live plate preview ────────────────────────────────────
                    platePreview
                        .padding(.top, 8)

                    // ── Plate text input ──────────────────────────────────────
                    plateTextInput

                    // ── Icon pickers (shown when icon markers exist) ──────────
                    if viewModel.iconMarkerCount > 0 {
                        iconPickers
                    }

                    // ── Similar plate warning ────────────────────────────────
                    if !viewModel.similarPlates.isEmpty {
                        similarPlateWarning
                    }

                    // ── Style picker ─────────────────────────────────────────
                    stylePicker

                    // ── Color palette (Custom only) ────────────────────────
                    if viewModel.newPlateStyle == .vicCustom {
                        colorPalette
                    }

                    // ── Submit button ────────────────────────────────────────
                    submitButton
                        .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Spot a Plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
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
                    "VIC \(viewModel.newPlateText.uppercased()) has already been added. " +
                    "Would you like to view it?"
                )
            }
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

    // MARK: - Live Preview

    @ViewBuilder
    private var platePreview: some View {
        VStack(spacing: 8) {
            PlateTemplateRenderer(
                plateText: viewModel.newPlateText.isEmpty ? "PLATR" : viewModel.newPlateText,
                style: viewModel.newPlateStyle,
                icon1: viewModel.selectedIcon1,
                icon2: viewModel.selectedIcon2,
                hasSpaceSeparator: viewModel.hasSpaceSeparator,
                customBgColor: viewModel.newPlateStyle == .vicCustom
                    ? Color(hex: viewModel.customBgColor)
                    : nil
            )
            .frame(width: 300)
            .animation(.smooth(duration: 0.3), value: viewModel.newPlateStyle)
            .animation(.smooth(duration: 0.2), value: viewModel.newPlateText)
            .animation(.smooth(duration: 0.2), value: viewModel.hasSpaceSeparator)
            .animation(.smooth(duration: 0.2), value: viewModel.customBgColor)

            Text(viewModel.newPlateStyle.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Plate Text Input

    @ViewBuilder
    private var plateTextInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plate Number")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // State badge
                Text("VIC")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Text input with custom icon badge display
                ZStack(alignment: .leading) {
                    // Hidden TextField for keyboard input
                    TextField("", text: $viewModel.newPlateText)
                        .font(.system(.title2, design: .monospaced).bold())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isPlateTextFocused)
                        .foregroundStyle(.clear)
                        .tint(.clear)
                        .onChange(of: viewModel.newPlateText) { _, new in
                            let max = 8
                            let cleaned = String(
                                new.uppercased()
                                    .filter { $0.isLetter || $0.isNumber || $0 == plateIconMarker }
                                    .prefix(max)
                            )
                            var result = ""
                            var starCount = 0
                            for ch in cleaned {
                                if ch == plateIconMarker {
                                    if starCount < 2 {
                                        result.append(ch)
                                        starCount += 1
                                    }
                                } else {
                                    result.append(ch)
                                }
                            }
                            viewModel.newPlateText = result
                            let markers = result.filter { $0 == plateIconMarker }.count
                            if markers < 2 { viewModel.selectedIcon2 = nil }
                            if markers < 1 { viewModel.selectedIcon1 = nil }
                            viewModel.checkForSimilarPlates()
                        }

                    // Visual display: text chars + "icon" badges
                    if viewModel.newPlateText.isEmpty {
                        Text("e.g. ABC123")
                            .font(.system(.title2, design: .monospaced).bold())
                            .foregroundStyle(.tertiary)
                            .allowsHitTesting(false)
                    } else {
                        HStack(spacing: 2) {
                            ForEach(Array(viewModel.newPlateText.enumerated()), id: \.offset) { _, char in
                                if char == plateIconMarker {
                                    iconBadge
                                } else {
                                    Text(String(char))
                                        .font(.system(.title2, design: .monospaced).bold())
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { isPlateTextFocused = true }

                // Insert icon marker button
                Button {
                    if viewModel.newPlateText.count < 8 && viewModel.iconMarkerCount < 2 {
                        viewModel.newPlateText.append(plateIconMarker)
                    }
                } label: {
                    iconBadge
                        .opacity(
                            viewModel.iconMarkerCount >= 2 || viewModel.newPlateText.count >= 8
                            ? 0.4 : 1.0
                        )
                }
                .disabled(viewModel.iconMarkerCount >= 2 || viewModel.newPlateText.count >= 8)

                // Character counter
                Text("\(viewModel.newPlateText.count)/8")
                    .font(.caption)
                    .foregroundStyle(
                        viewModel.newPlateText.count >= 3 ? .green : .secondary
                    )
                    .monospacedDigit()
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Space separator toggle (hidden when icons are present)
            if viewModel.iconMarkerCount == 0 {
                Toggle(isOn: $viewModel.hasSpaceSeparator) {
                    Label("Space between groups", systemImage: "textformat.abc")
                        .font(.subheadline)
                }
                .tint(Color.accentColor)
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Icon Pickers

    @ViewBuilder
    private var iconPickers: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Icons")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            // Icon 1
            if viewModel.iconMarkerCount >= 1 {
                iconPickerRow(
                    label: "Icon 1",
                    selection: $viewModel.selectedIcon1
                )
            }

            // Icon 2
            if viewModel.iconMarkerCount >= 2 {
                iconPickerRow(
                    label: "Icon 2",
                    selection: $viewModel.selectedIcon2
                )
            }
        }
    }

    @ViewBuilder
    private func iconPickerRow(
        label: String,
        selection: Binding<PlateIcon?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.tertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PlateIcon.allCases) { icon in
                        let isSelected = selection.wrappedValue == icon

                        Button {
                            withAnimation(.smooth(duration: 0.15)) {
                                selection.wrappedValue = icon
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Group {
                                    if icon.isCustomDrawn {
                                        BatSilhouetteView(
                                            color: isSelected ? Color.accentColor : Color.primary,
                                            size: 24
                                        )
                                        .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: icon.sfSymbol)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isSelected
                                              ? Color.accentColor.opacity(0.12)
                                              : Color(.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                                )

                                Text(icon.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Similar Plate Warning

    @ViewBuilder
    private var similarPlateWarning: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.hasExactMatch ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundStyle(viewModel.hasExactMatch ? .orange : .blue)
                Text(viewModel.hasExactMatch ? "This plate already exists" : "Similar plates found")
                    .font(.subheadline.bold())
                    .foregroundStyle(viewModel.hasExactMatch ? .orange : .blue)
            }

            ForEach(viewModel.similarPlates.prefix(3)) { plate in
                HStack(spacing: 10) {
                    PlateTemplateRenderer(
                        plateText: plate.plateText,
                        style: plate.plateStyle,
                        icon1: plate.icon1,
                        icon2: plate.icon2,
                        hasSpaceSeparator: plate.hasSpaceSeparator,
                        customBgColor: plate.customBgColor.map { Color(hex: $0) }
                    )
                    .frame(width: 100)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(plate.stateCode) \(plate.plateText)")
                            .font(.caption.bold())
                    }

                    Spacer()

                    Button {
                        dismiss()
                        onDuplicateFound?(plate.id)
                    } label: {
                        Text("View")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }

            if viewModel.hasExactMatch {
                Text("Are you sure you want to add a duplicate?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(viewModel.hasExactMatch
                      ? Color.orange.opacity(0.08)
                      : Color.blue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(viewModel.hasExactMatch
                        ? Color.orange.opacity(0.2)
                        : Color.blue.opacity(0.15), lineWidth: 1)
        )
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
                        styleCard(style)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func styleCard(_ style: PlateStyle) -> some View {
        let isSelected = viewModel.newPlateStyle == style

        Button {
            withAnimation(.smooth(duration: 0.25)) {
                viewModel.newPlateStyle = style
            }
        } label: {
            VStack(spacing: 8) {
                PlateTemplateRenderer(
                    plateText: "ABC",
                    style: style,
                    customBgColor: style == .vicCustom
                        ? Color(hex: viewModel.customBgColor)
                        : nil
                )
                .frame(width: 100)
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

    // MARK: - Color Palette

    private let plateColors: [(name: String, hex: String)] = [
        ("Black",         "#000000"),
        ("White",         "#FFFFFF"),
        ("Navy",          "#1B2A4A"),
        ("Red",           "#C0392B"),
        ("Dark Green",    "#1E5631"),
        ("Gold",          "#D4A017"),
        ("Orange",        "#E67E22"),
        ("Maroon",        "#6B1D1D"),
        ("Silver",        "#A0A0A0"),
        ("Purple",        "#6C3483"),
        ("Sky Blue",      "#2E86C1"),
        ("Racing Green",  "#004225"),
    ]

    @ViewBuilder
    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plate Color")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(plateColors, id: \.hex) { item in
                    let isSelected = viewModel.customBgColor == item.hex

                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            viewModel.customBgColor = item.hex
                        }
                    } label: {
                        Circle()
                            .fill(Color(hex: item.hex))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(item.hex == "#FFFFFF" ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                                    .padding(-3)
                            )
                            .overlay(
                                isSelected
                                ? Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(hex: item.hex).contrastingTextColor)
                                : nil
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Icon Badge

    @ViewBuilder
    private var iconBadge: some View {
        Text("icon")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Submit

    @ViewBuilder
    private var submitButton: some View {
        Button(action: submitPlate) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Plate")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                viewModel.isFormValid && !viewModel.isLoading
                ? Color.accentColor
                : Color(.secondarySystemBackground)
            )
            .foregroundStyle(
                viewModel.isFormValid && !viewModel.isLoading
                ? .white
                : .secondary
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
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
