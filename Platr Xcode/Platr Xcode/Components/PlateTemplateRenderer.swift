// Platr iOS — PlateTemplateRenderer
//
// Realistic SwiftUI plate renderer for Victorian number plates.
// Three styles: VIC Standard (white/blue), VIC Slimline Black (chrome), VIC Custom (user color).
// Supports inline icons via ★ marker characters in plate text.

import SwiftUI

// MARK: - Main Renderer

struct PlateTemplateRenderer: View {
    let plateText: String
    let style: PlateStyle
    var icon1: PlateIcon? = nil
    var icon2: PlateIcon? = nil
    var hasSpaceSeparator: Bool = true
    var customBgColor: Color? = nil

    var body: some View {
        Group {
            switch style {
            case .vicSlimlineBlack:
                slimlinePlateBody
            case .vicCustom:
                customPlateBody
            default:
                standardPlateBody
            }
        }
        .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 5)
    }

    // MARK: - Text parsing

    /// Whether this plate text has inline icon markers
    private var hasIcons: Bool { plateText.contains(plateIconMarker) }

    /// Splits plate text on ★ markers into text segments
    private var textSegments: [String] {
        plateText.uppercased().split(
            separator: plateIconMarker,
            omittingEmptySubsequences: false
        ).map(String.init)
    }

    /// Ordered icons for each ★ marker
    private var icons: [PlateIcon?] {
        let count = plateText.filter { $0 == plateIconMarker }.count
        var result: [PlateIcon?] = []
        if count >= 1 { result.append(icon1) }
        if count >= 2 { result.append(icon2) }
        return result
    }

    /// Splits plate text into two groups for spacing/dot display (no-icon mode)
    private func splitText(_ text: String) -> (String, String) {
        let clean = text.uppercased()
        guard clean.count >= 4 else { return (clean, "") }
        let splitAt = min(3, clean.count - 1)
        let idx = clean.index(clean.startIndex, offsetBy: splitAt)
        return (String(clean[..<idx]), String(clean[idx...]))
    }

    // MARK: - VIC Standard Layout

    @ViewBuilder
    private var standardPlateBody: some View {
        let borderBlue = Color(red: 0.00, green: 0.12, blue: 0.40)
        let textBlue = Color(red: 0.00, green: 0.10, blue: 0.36)

        GeometryReader { geo in
            let w = geo.size.width
            let h = w / style.aspectRatio
            let borderW: CGFloat = max(3, w * 0.018)
            let cornerR: CGFloat = max(4, w * 0.022)
            let fontSize: CGFloat = max(16, h * 0.40)
            let footerSize: CGFloat = max(5, h * 0.060)
            let boltSize: CGFloat = max(5, w * 0.024)
            let emblemSize: CGFloat = max(8, h * 0.12)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: cornerR)
                    .fill(.white)

                // Blue border
                RoundedRectangle(cornerRadius: cornerR)
                    .stroke(
                        LinearGradient(
                            colors: [borderBlue, Color(red: 0.00, green: 0.18, blue: 0.52)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: borderW
                    )

                // Inner shadow for depth
                RoundedRectangle(cornerRadius: cornerR)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    .padding(borderW)

                // 4-corner bolt holes
                VStack {
                    HStack {
                        BoltHole(size: boltSize, style: .standard)
                        Spacer()
                        BoltHole(size: boltSize, style: .standard)
                    }
                    Spacer()
                    HStack {
                        BoltHole(size: boltSize, style: .standard)
                        Spacer()
                        BoltHole(size: boltSize, style: .standard)
                    }
                }
                .padding(borderW + boltSize * 0.5)

                // VIC emblem at top center
                VStack {
                    VicEmblem(color: borderBlue, size: emblemSize)
                        .padding(.top, borderW + 2)
                    Spacer()
                }

                // Main content
                VStack(spacing: 0) {
                    Spacer()

                    // Plate text (with or without inline icons)
                    standardPlateText(
                        textColor: textBlue,
                        fontSize: fontSize,
                        width: w,
                        borderW: borderW,
                        boltSize: boltSize
                    )

                    Spacer()

                    // Footer
                    Text("VICTORIA - THE EDUCATION STATE")
                        .font(.system(size: footerSize, weight: .bold))
                        .foregroundStyle(borderBlue)
                        .tracking(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, borderW + 8)
                        .padding(.bottom, max(3, h * 0.04))
                }
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(style.aspectRatio, contentMode: .fit)
    }

    @ViewBuilder
    private func standardPlateText(
        textColor: Color,
        fontSize: CGFloat,
        width: CGFloat,
        borderW: CGFloat,
        boltSize: CGFloat
    ) -> some View {
        if hasIcons {
            // Inline icons mode
            HStack(alignment: .center, spacing: max(2, width * 0.012)) {
                let segs = textSegments
                let icns = icons
                ForEach(Array(segs.enumerated()), id: \.offset) { idx, segment in
                    if !segment.isEmpty {
                        Text(segment)
                            .font(.system(size: fontSize, weight: .black, design: .default))
                            .foregroundStyle(textColor)
                    }
                    if idx < segs.count - 1 {
                        let icon = idx < icns.count ? icns[idx] : nil
                        PlateIconView(icon: icon, color: textColor, size: fontSize * 0.55)
                    }
                }
            }
            .tracking(1)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .padding(.horizontal, borderW + boltSize * 2.5)
        } else if hasSpaceSeparator && plateText.count >= 4 {
            // Space separator mode
            let (g1, g2) = splitText(plateText)
            HStack(spacing: max(4, width * 0.03)) {
                Text(g1)
                    .font(.system(size: fontSize, weight: .black, design: .default))
                    .foregroundStyle(textColor)
                Text(g2)
                    .font(.system(size: fontSize, weight: .black, design: .default))
                    .foregroundStyle(textColor)
            }
            .tracking(1)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .padding(.horizontal, borderW + boltSize * 2.5)
        } else {
            // Plain text mode
            Text(plateText.uppercased())
                .font(.system(size: fontSize, weight: .black, design: .default))
                .foregroundStyle(textColor)
                .tracking(2)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .padding(.horizontal, borderW + boltSize * 2.5)
        }
    }

    // MARK: - VIC Slimline Black Layout

    @ViewBuilder
    private var slimlinePlateBody: some View {
        let bgColor = Color(red: 0.05, green: 0.05, blue: 0.05)
        let chromeGradient = LinearGradient(
            colors: [
                Color(white: 0.78),
                Color(white: 0.92),
                Color(white: 0.55),
                Color(white: 0.75),
            ],
            startPoint: .top, endPoint: .bottom
        )

        GeometryReader { geo in
            let w = geo.size.width
            let h = w / style.aspectRatio
            let borderW: CGFloat = max(2, w * 0.008)
            let cornerR: CGFloat = max(3, w * 0.016)
            let fontSize: CGFloat = max(14, h * 0.52)
            let sidebarW: CGFloat = max(16, w * 0.07)
            let boltSize: CGFloat = max(5, w * 0.020)
            let vicFontSize: CGFloat = max(7, h * 0.16)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: cornerR)
                    .fill(bgColor)

                // Subtle border
                RoundedRectangle(cornerRadius: cornerR)
                    .stroke(
                        LinearGradient(
                            colors: [Color(white: 0.22), Color(white: 0.32), Color(white: 0.20)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: borderW
                    )

                // Content
                HStack(spacing: 0) {
                    // VIC sidebar
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: sidebarW)

                        VStack(spacing: max(0.5, h * 0.01)) {
                            Text("V").font(.system(size: vicFontSize, weight: .black, design: .default))
                            Text("I").font(.system(size: vicFontSize, weight: .black, design: .default))
                            Text("C").font(.system(size: vicFontSize, weight: .black, design: .default))
                        }
                        .foregroundStyle(.white.opacity(0.80))
                    }

                    // Separator
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1)
                        .padding(.vertical, max(4, h * 0.12))

                    // Main text area
                    Spacer()

                    slimlinePlateText(
                        chromeGradient: chromeGradient,
                        fontSize: fontSize,
                        width: w
                    )

                    Spacer()
                }

                // Metallic bolt holes
                HStack {
                    Spacer().frame(width: sidebarW + 4)
                    BoltHole(size: boltSize, style: .metallic)
                    Spacer()
                    BoltHole(size: boltSize, style: .metallic)
                }
                .padding(.trailing, max(6, w * 0.025))
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(style.aspectRatio, contentMode: .fit)
    }

    @ViewBuilder
    private func slimlinePlateText(
        chromeGradient: LinearGradient,
        fontSize: CGFloat,
        width: CGFloat
    ) -> some View {
        if hasIcons {
            // Inline icons mode
            HStack(alignment: .center, spacing: max(2, width * 0.008)) {
                let segs = textSegments
                let icns = icons
                ForEach(Array(segs.enumerated()), id: \.offset) { idx, segment in
                    if !segment.isEmpty {
                        Text(segment)
                            .font(.system(size: fontSize, weight: .black, design: .default))
                            .foregroundStyle(chromeGradient)
                    }
                    if idx < segs.count - 1 {
                        let icon = idx < icns.count ? icns[idx] : nil
                        PlateIconView(icon: icon, color: .white, size: fontSize * 0.50)
                    }
                }
            }
            .tracking(1.5)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 2)
        } else if plateText.count >= 4 {
            // Dot separator mode
            let (g1, g2) = splitText(plateText)
            HStack(spacing: max(2, width * 0.012)) {
                Text(g1)
                    .font(.system(size: fontSize, weight: .black, design: .default))
                    .foregroundStyle(chromeGradient)
                // Chrome dot separator
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.80), Color(white: 0.45)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: fontSize * 0.06
                        )
                    )
                    .frame(width: max(3, fontSize * 0.10), height: max(3, fontSize * 0.10))
                    .shadow(color: .white.opacity(0.3), radius: 0.5, y: -0.5)
                Text(g2)
                    .font(.system(size: fontSize, weight: .black, design: .default))
                    .foregroundStyle(chromeGradient)
            }
            .tracking(1.5)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 2)
        } else {
            Text(plateText.uppercased())
                .font(.system(size: fontSize, weight: .black, design: .default))
                .foregroundStyle(chromeGradient)
                .tracking(3)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 2)
        }
    }

    // MARK: - VIC Custom Layout

    @ViewBuilder
    private var customPlateBody: some View {
        let bgColor = customBgColor ?? Color.black
        let textColor = bgColor.contrastingTextColor
        let borderColor = textColor.opacity(0.18)

        GeometryReader { geo in
            let w = geo.size.width
            let h = w / PlateStyle.vicStandard.aspectRatio  // same ratio as standard
            let borderW: CGFloat = max(3, w * 0.018)
            let cornerR: CGFloat = max(4, w * 0.022)
            let fontSize: CGFloat = max(16, h * 0.42)
            let boltSize: CGFloat = max(5, w * 0.024)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: cornerR)
                    .fill(bgColor)

                // Border
                RoundedRectangle(cornerRadius: cornerR)
                    .stroke(borderColor, lineWidth: borderW)

                // 4-corner bolt holes
                VStack {
                    HStack {
                        BoltHole(size: boltSize, style: bgColor.luminance > 0.5 ? .standard : .metallic)
                        Spacer()
                        BoltHole(size: boltSize, style: bgColor.luminance > 0.5 ? .standard : .metallic)
                    }
                    Spacer()
                    HStack {
                        BoltHole(size: boltSize, style: bgColor.luminance > 0.5 ? .standard : .metallic)
                        Spacer()
                        BoltHole(size: boltSize, style: bgColor.luminance > 0.5 ? .standard : .metallic)
                    }
                }
                .padding(borderW + boltSize * 0.5)

                // Plate text — centered, no emblem, no footer
                customPlateText(
                    textColor: textColor,
                    fontSize: fontSize,
                    width: w,
                    borderW: borderW,
                    boltSize: boltSize
                )
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(PlateStyle.vicStandard.aspectRatio, contentMode: .fit)
    }

    @ViewBuilder
    private func customPlateText(
        textColor: Color,
        fontSize: CGFloat,
        width: CGFloat,
        borderW: CGFloat,
        boltSize: CGFloat
    ) -> some View {
        if hasIcons {
            HStack(alignment: .center, spacing: max(2, width * 0.012)) {
                let segs = textSegments
                let icns = icons
                ForEach(Array(segs.enumerated()), id: \.offset) { idx, segment in
                    if !segment.isEmpty {
                        Text(segment)
                            .font(.system(size: fontSize, weight: .black, design: .default))
                            .foregroundStyle(textColor)
                    }
                    if idx < segs.count - 1 {
                        let icon = idx < icns.count ? icns[idx] : nil
                        PlateIconView(icon: icon, color: textColor, size: fontSize * 0.55)
                    }
                }
            }
            .tracking(1)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .padding(.horizontal, borderW + boltSize * 2.5)
        } else if hasSpaceSeparator && plateText.count >= 4 {
            let (g1, g2) = splitText(plateText)
            HStack(spacing: max(4, width * 0.03)) {
                Text(g1)
                    .font(.system(size: fontSize, weight: .black, design: .default))
                    .foregroundStyle(textColor)
                Text(g2)
                    .font(.system(size: fontSize, weight: .black, design: .default))
                    .foregroundStyle(textColor)
            }
            .tracking(1)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .padding(.horizontal, borderW + boltSize * 2.5)
        } else {
            Text(plateText.uppercased())
                .font(.system(size: fontSize, weight: .black, design: .default))
                .foregroundStyle(textColor)
                .tracking(2)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .padding(.horizontal, borderW + boltSize * 2.5)
        }
    }
}

// MARK: - VIC Emblem (Triangle/Chevron)

private struct VicEmblem: View {
    let color: Color
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            // Triangle pointing down (VIC chevron)
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.75))
                path.closeSubpath()
            }
            .fill(color)
            .frame(width: size, height: size * 0.75)

            // "VIC" text inside
            Text("VIC")
                .font(.system(size: size * 0.22, weight: .black))
                .foregroundStyle(.white)
                .offset(y: -size * 0.06)
        }
        .frame(width: size, height: size * 0.75)
    }
}

// MARK: - Bolt Hole

private enum BoltHoleAppearance {
    case standard
    case metallic
}

private struct BoltHole: View {
    var size: CGFloat = 9
    var style: BoltHoleAppearance = .standard

    var body: some View {
        switch style {
        case .standard:
            ZStack {
                Circle()
                    .fill(Color(white: 0.72).opacity(0.4))
                Circle()
                    .stroke(Color(white: 0.60).opacity(0.5), lineWidth: 0.8)
            }
            .frame(width: size, height: size)

        case .metallic:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.45), Color(white: 0.25), Color(white: 0.15)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.50), Color(white: 0.25)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.4
                        )
                    )
                    .frame(width: size * 0.5, height: size * 0.5)
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Plate Icon View

struct PlateIconView: View {
    let icon: PlateIcon?
    let color: Color
    var size: CGFloat = 22

    var body: some View {
        if let icon {
            if icon.isCustomDrawn {
                // Bat silhouette (custom Path)
                BatSilhouetteView(color: color, size: size)
            } else {
                Image(systemName: icon.sfSymbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(color)
            }
        } else {
            // Placeholder: "icon" badge for unselected marker positions
            Text("icon")
                .font(.system(size: max(6, size * 0.45), weight: .bold, design: .rounded))
                .foregroundStyle(color.opacity(0.5))
        }
    }
}

// MARK: - Bat Silhouette (Custom Path)

struct BatSilhouetteView: View {
    let color: Color
    var size: CGFloat = 22

    var body: some View {
        Path { p in
            let w = size
            let h = size * 0.55
            let cx = w / 2
            let cy = h / 2

            // Body center
            p.move(to: CGPoint(x: cx, y: cy - h * 0.15))

            // Right wing (upper arc)
            p.addQuadCurve(
                to: CGPoint(x: w, y: cy - h * 0.35),
                control: CGPoint(x: cx + w * 0.25, y: cy - h * 0.55)
            )
            // Right wing tip
            p.addQuadCurve(
                to: CGPoint(x: w * 0.82, y: cy + h * 0.10),
                control: CGPoint(x: w * 1.02, y: cy - h * 0.05)
            )
            // Right wing (lower scallop 1)
            p.addQuadCurve(
                to: CGPoint(x: w * 0.68, y: cy + h * 0.15),
                control: CGPoint(x: w * 0.76, y: cy + h * 0.30)
            )
            // Right wing (lower scallop 2)
            p.addQuadCurve(
                to: CGPoint(x: cx + w * 0.05, y: cy + h * 0.20),
                control: CGPoint(x: w * 0.62, y: cy + h * 0.35)
            )

            // Bottom center (tail)
            p.addQuadCurve(
                to: CGPoint(x: cx, y: cy + h * 0.50),
                control: CGPoint(x: cx + w * 0.02, y: cy + h * 0.35)
            )
            p.addQuadCurve(
                to: CGPoint(x: cx - w * 0.05, y: cy + h * 0.20),
                control: CGPoint(x: cx - w * 0.02, y: cy + h * 0.35)
            )

            // Left wing (lower scallop 2)
            p.addQuadCurve(
                to: CGPoint(x: w * 0.32, y: cy + h * 0.15),
                control: CGPoint(x: w * 0.38, y: cy + h * 0.35)
            )
            // Left wing (lower scallop 1)
            p.addQuadCurve(
                to: CGPoint(x: w * 0.18, y: cy + h * 0.10),
                control: CGPoint(x: w * 0.24, y: cy + h * 0.30)
            )
            // Left wing tip
            p.addQuadCurve(
                to: CGPoint(x: 0, y: cy - h * 0.35),
                control: CGPoint(x: w * -0.02, y: cy - h * 0.05)
            )
            // Left wing (upper arc back to top)
            p.addQuadCurve(
                to: CGPoint(x: cx, y: cy - h * 0.15),
                control: CGPoint(x: cx - w * 0.25, y: cy - h * 0.55)
            )

            p.closeSubpath()
        }
        .fill(color)
        .frame(width: size, height: size * 0.55)
    }
}

// MARK: - Preview

#Preview("VIC Plates") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Standard — No Icons").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "ABC123",
                style: .vicStandard,
                hasSpaceSeparator: true
            )
            .frame(width: 300)

            Text("Standard — Heart Icon").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "SED\(String(plateIconMarker))ARS",
                style: .vicStandard,
                icon1: .heart,
                hasSpaceSeparator: true
            )
            .frame(width: 300)

            Text("Slimline — Bat Icon").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "AB\(String(plateIconMarker))CD",
                style: .vicSlimlineBlack,
                icon1: .bat
            )
            .frame(width: 300)

            Text("Standard — Two Icons").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "\(String(plateIconMarker))PLATR\(String(plateIconMarker))",
                style: .vicStandard,
                icon1: .star,
                icon2: .crown
            )
            .frame(width: 300)

            Text("Slimline — No Icons").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "DRJ890",
                style: .vicSlimlineBlack,
                hasSpaceSeparator: true
            )
            .frame(width: 300)

            Text("Custom — Red").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "TURBO",
                style: .vicCustom,
                customBgColor: Color(hex: "#C0392B")
            )
            .frame(width: 300)

            Text("Custom — Navy").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "GTR35",
                style: .vicCustom,
                customBgColor: Color(hex: "#1B2A4A")
            )
            .frame(width: 300)

            Text("Custom — Gold").font(.caption.bold()).foregroundStyle(.white)
            PlateTemplateRenderer(
                plateText: "V8KING",
                style: .vicCustom,
                customBgColor: Color(hex: "#D4A017")
            )
            .frame(width: 300)
        }
        .padding()
    }
    .background(Color(white: 0.12))
}
