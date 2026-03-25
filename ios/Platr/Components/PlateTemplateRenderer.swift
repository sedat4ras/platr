// Platr iOS — PlateTemplateRenderer
// [iOSSwiftAgent | iOS-001]
//
// Pure SwiftUI ZStack-based vectorial plate renderer.
// NO UIKit, NO photo upload, NO external images.
// All VIC templates rendered from SwiftUI primitives (Shape, Text, SF Symbols).
//
// Usage:
//   PlateTemplateRenderer(plateText: "ABC123", style: .vicStandard)
//       .frame(width: 320, height: 160)

import SwiftUI

// MARK: - Template Configuration

struct PlateTemplateConfig {
    let aspectRatio: CGFloat
    let backgroundColor: Color
    let borderColor: LinearGradient
    let borderWidth: CGFloat
    let borderCornerRadius: CGFloat
    let textColor: Color
    let textFont: Font
    let stateFooterText: String
    let stateFooterColor: Color
    let stateFooterFont: Font
    let showStateBar: Bool
    let stateBarColor: Color
}

extension PlateTemplateConfig {

    static let vicStandard = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: .white,
        borderColor: LinearGradient(
            colors: [Color(red: 0.0, green: 0.18, blue: 0.56),
                     Color(red: 0.0, green: 0.35, blue: 0.80)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 6,
        borderCornerRadius: 10,
        textColor: .black,
        textFont: .system(size: 54, weight: .heavy, design: .default),
        stateFooterText: "Victoria",
        stateFooterColor: Color(red: 0.0, green: 0.18, blue: 0.56),
        stateFooterFont: .system(size: 13, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicCustomBlack = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: Color(red: 0.10, green: 0.10, blue: 0.10),
        borderColor: LinearGradient(
            colors: [Color(red: 0.85, green: 0.70, blue: 0.30),
                     Color(red: 1.00, green: 0.90, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 5,
        borderCornerRadius: 10,
        textColor: .white,
        textFont: .system(size: 54, weight: .heavy, design: .default),
        stateFooterText: "Victoria",
        stateFooterColor: Color(red: 0.85, green: 0.70, blue: 0.30),
        stateFooterFont: .system(size: 13, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicCustomWhite = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: .white,
        borderColor: LinearGradient(
            colors: [Color(white: 0.65), Color(white: 0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 5,
        borderCornerRadius: 10,
        textColor: Color(white: 0.10),
        textFont: .system(size: 54, weight: .heavy, design: .default),
        stateFooterText: "Victoria",
        stateFooterColor: Color(white: 0.40),
        stateFooterFont: .system(size: 13, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicHeritage = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: Color(red: 0.96, green: 0.93, blue: 0.82),
        borderColor: LinearGradient(
            colors: [Color(red: 0.50, green: 0.30, blue: 0.10),
                     Color(red: 0.70, green: 0.45, blue: 0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 5,
        borderCornerRadius: 8,
        textColor: Color(red: 0.25, green: 0.12, blue: 0.02),
        textFont: .system(size: 50, weight: .bold, design: .serif),
        stateFooterText: "Victoria",
        stateFooterColor: Color(red: 0.50, green: 0.30, blue: 0.10),
        stateFooterFont: .system(size: 13, weight: .regular, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicEnvironment = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: Color(red: 0.95, green: 0.98, blue: 0.94),
        borderColor: LinearGradient(
            colors: [Color(red: 0.13, green: 0.55, blue: 0.13),
                     Color(red: 0.20, green: 0.70, blue: 0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 5,
        borderCornerRadius: 10,
        textColor: Color(red: 0.05, green: 0.30, blue: 0.05),
        textFont: .system(size: 54, weight: .heavy, design: .default),
        stateFooterText: "Victoria",
        stateFooterColor: Color(red: 0.13, green: 0.55, blue: 0.13),
        stateFooterFont: .system(size: 13, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let nswStandard = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: .white,
        borderColor: LinearGradient(
            colors: [Color(red: 0.00, green: 0.39, blue: 0.20),
                     Color(red: 0.00, green: 0.52, blue: 0.27)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 6,
        borderCornerRadius: 10,
        textColor: Color(red: 0.08, green: 0.08, blue: 0.08),
        textFont: .system(size: 54, weight: .heavy, design: .default),
        stateFooterText: "New South Wales",
        stateFooterColor: Color(red: 0.00, green: 0.39, blue: 0.20),
        stateFooterFont: .system(size: 11, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let qldStandard = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: .white,
        borderColor: LinearGradient(
            colors: [Color(red: 0.50, green: 0.05, blue: 0.12),
                     Color(red: 0.65, green: 0.10, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 6,
        borderCornerRadius: 10,
        textColor: Color(red: 0.10, green: 0.05, blue: 0.05),
        textFont: .system(size: 54, weight: .heavy, design: .default),
        stateFooterText: "Queensland",
        stateFooterColor: Color(red: 0.50, green: 0.05, blue: 0.12),
        stateFooterFont: .system(size: 13, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    // MARK: - VPlates New Styles

    static let vicSlimlineBlack = PlateTemplateConfig(
        aspectRatio: 4.48,
        backgroundColor: Color(red: 0.07, green: 0.07, blue: 0.07),
        borderColor: LinearGradient(
            colors: [Color(white: 0.22), Color(white: 0.14)],
            startPoint: .top,
            endPoint: .bottom
        ),
        borderWidth: 2,
        borderCornerRadius: 6,
        textColor: .white,
        textFont: .system(size: 44, weight: .heavy),
        stateFooterText: "Victoria",
        stateFooterColor: Color(white: 0.55),
        stateFooterFont: .system(size: 9, weight: .medium),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicDeluxe = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: Color(red: 0.07, green: 0.07, blue: 0.09),
        borderColor: LinearGradient(
            colors: [Color(white: 0.30), Color(white: 0.12)],
            startPoint: .top,
            endPoint: .bottom
        ),
        borderWidth: 1,
        borderCornerRadius: 10,
        textColor: .white,
        textFont: .system(size: 54, weight: .heavy),
        stateFooterText: "Victoria",
        stateFooterColor: Color(white: 0.45),
        stateFooterFont: .system(size: 13, weight: .medium),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicPrestige = PlateTemplateConfig(
        aspectRatio: 2.776,
        backgroundColor: Color(red: 0.05, green: 0.08, blue: 0.18),
        borderColor: LinearGradient(
            colors: [Color(red: 0.90, green: 0.76, blue: 0.38),
                     Color(red: 0.68, green: 0.52, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        borderWidth: 8,
        borderCornerRadius: 12,
        textColor: Color(red: 0.92, green: 0.80, blue: 0.45),
        textFont: .system(size: 52, weight: .heavy),
        stateFooterText: "Victoria",
        stateFooterColor: Color(red: 0.85, green: 0.70, blue: 0.32),
        stateFooterFont: .system(size: 13, weight: .semibold, design: .serif),
        showStateBar: false,
        stateBarColor: .clear
    )

    static let vicEuro = PlateTemplateConfig(
        aspectRatio: 4.73,
        backgroundColor: Color(red: 0.08, green: 0.08, blue: 0.08),
        borderColor: LinearGradient(
            colors: [Color(white: 0.20), Color(white: 0.12)],
            startPoint: .top,
            endPoint: .bottom
        ),
        borderWidth: 2,
        borderCornerRadius: 5,
        textColor: .white,
        textFont: .system(size: 38, weight: .heavy),
        stateFooterText: "Victoria",
        stateFooterColor: Color(white: 0.42),
        stateFooterFont: .system(size: 9, weight: .medium),
        showStateBar: false,
        stateBarColor: .clear
    )

    static func config(for style: PlateStyle) -> PlateTemplateConfig {
        switch style {
        case .vicStandard:       return .vicStandard
        case .vicCustomBlack:    return .vicCustomBlack
        case .vicCustomWhite:    return .vicCustomWhite
        case .vicHeritage:       return .vicHeritage
        case .vicEnvironment:    return .vicEnvironment
        case .vicSlimlineBlack:  return .vicSlimlineBlack
        case .vicDeluxe:         return .vicDeluxe
        case .vicPrestige:       return .vicPrestige
        case .vicEuro:           return .vicEuro
        case .nswStandard:       return .nswStandard
        case .qldStandard:       return .qldStandard
        }
    }
}

// MARK: - Icon Renderer

/// Renders icon placeholder strings like [HEART], [STAR] as SF Symbols.
struct PlateIconView: View {
    let placeholder: String
    let color: Color
    var size: CGFloat = 22

    private var symbolName: String {
        switch placeholder.uppercased() {
        case "[HEART]":  return "heart.fill"
        case "[STAR]":   return "star.fill"
        case "[PAWS]":   return "pawprint.fill"
        case "[WAVE]":   return "waveform"
        case "[LEAF]":   return "leaf.fill"
        case "[FLAME]":  return "flame.fill"
        case "[BOLT]":   return "bolt.fill"
        case "[CROWN]":  return "crown.fill"
        default:         return ""
        }
    }

    var body: some View {
        if symbolName.isEmpty || placeholder.isEmpty {
            EmptyView()
        } else {
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Main Renderer

struct PlateTemplateRenderer: View {
    let plateText: String
    let style: PlateStyle
    var iconLeft: String  = ""
    var iconRight: String = ""

    private var config: PlateTemplateConfig {
        PlateTemplateConfig.config(for: style)
    }

    var body: some View {
        ZStack {
            // ── Layer 1: Background ────────────────────────────────────────
            RoundedRectangle(cornerRadius: config.borderCornerRadius)
                .fill(config.backgroundColor)

            // ── Layer 2: Border ────────────────────────────────────────────
            RoundedRectangle(cornerRadius: config.borderCornerRadius)
                .stroke(config.borderColor, lineWidth: config.borderWidth)

            // ── Layer 3: Bolt holes (decorative) ──────────────────────────
            HStack {
                BoltHole()
                Spacer()
                BoltHole()
            }
            .padding(.horizontal, 14)

            // ── Layer 4: Content stack ────────────────────────────────────
            VStack(spacing: 0) {

                Spacer()

                // Icon row + Plate text row
                HStack(alignment: .center, spacing: 8) {

                    PlateIconView(placeholder: iconLeft, color: config.textColor)
                        .padding(.leading, 4)

                    Spacer()

                    Text(plateText.uppercased())
                        .font(config.textFont)
                        .foregroundStyle(config.textColor)
                        .tracking(2)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Spacer()

                    PlateIconView(placeholder: iconRight, color: config.textColor)
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 20)

                Spacer()

                // ── Layer 5: State footer text ─────────────────────────────
                Text(config.stateFooterText)
                    .font(config.stateFooterFont)
                    .foregroundStyle(config.stateFooterColor)
                    .padding(.bottom, 8)
            }
        }
        .aspectRatio(config.aspectRatio, contentMode: .fit)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Bolt Hole Shape

private struct BoltHole: View {
    var body: some View {
        Circle()
            .fill(Color(white: 0.75).opacity(0.4))
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(Color(white: 0.5).opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview("VIC Standard") {
    VStack(spacing: 20) {
        PlateTemplateRenderer(plateText: "ABC123", style: .vicStandard)
            .frame(width: 320)

        PlateTemplateRenderer(
            plateText: "1LOVE",
            style: .vicCustomBlack,
            iconLeft: "[HEART]",
            iconRight: "[HEART]"
        )
        .frame(width: 320)

        PlateTemplateRenderer(plateText: "HERITAGE", style: .vicHeritage)
            .frame(width: 320)

        PlateTemplateRenderer(
            plateText: "ECO01",
            style: .vicEnvironment,
            iconLeft: "[LEAF]"
        )
        .frame(width: 320)
        PlateTemplateRenderer(plateText: "SLIM01", style: .vicSlimlineBlack)
            .frame(width: 320)

        PlateTemplateRenderer(plateText: "DLX999", style: .vicDeluxe)
            .frame(width: 320)

        PlateTemplateRenderer(plateText: "1VIP", style: .vicPrestige)
            .frame(width: 320)

        PlateTemplateRenderer(plateText: "EUR042", style: .vicEuro)
            .frame(width: 320)
    }
    .padding()
    .background(Color(white: 0.15))
}
