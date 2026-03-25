// Platr iOS — Plate model (Swift 6 / Sendable)

import Foundation
import SwiftUI

// MARK: - Enums

enum PlateStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    // ── Active styles ──────────────────────────────────────────────────────────
    case vicStandard       = "VIC_STANDARD"
    case vicSlimlineBlack  = "VIC_SLIMLINE_BLACK"
    case vicCustom         = "VIC_CUSTOM"

    // ── Legacy (kept for decoding existing plates; NOT offered in picker) ──────
    case vicCustomBlack    = "VIC_CUSTOM_BLACK"
    case vicCustomWhite    = "VIC_CUSTOM_WHITE"
    case vicDeluxe         = "VIC_DELUXE"
    case vicPrestige       = "VIC_PRESTIGE"
    case vicEuro           = "VIC_EURO"
    case vicHeritage       = "VIC_HERITAGE"
    case vicEnvironment    = "VIC_ENVIRONMENT"
    case vicGardenState    = "VIC_GARDEN_STATE"
    case vicOnTheMove      = "VIC_ON_THE_MOVE"
    case nswStandard       = "NSW_STANDARD"
    case qldStandard       = "QLD_STANDARD"

    var id: String { rawValue }

    /// Only these 3 styles are available for new plates
    static let vicStyles: [PlateStyle] = [
        .vicStandard, .vicSlimlineBlack, .vicCustom,
    ]

    var displayName: String {
        switch self {
        case .vicStandard:       return "Standard"
        case .vicSlimlineBlack:  return "Slimline Black"
        case .vicCustom:         return "Custom"
        default:                 return "Standard"
        }
    }

    var subtitle: String {
        switch self {
        case .vicStandard:       return "The Education State"
        case .vicSlimlineBlack:  return "Most popular custom plate"
        case .vicCustom:         return "Pick your own color"
        default:                 return ""
        }
    }

    var sloganText: String {
        switch self {
        case .vicStandard:       return "VICTORIA - THE EDUCATION STATE"
        case .vicSlimlineBlack:  return ""
        case .vicCustom:         return ""
        default:                 return ""
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .vicSlimlineBlack:  return 3.72
        default:                 return 2.78
        }
    }

    var maxCharacters: Int { 8 }

    var numericOnly: Bool { false }

    /// Whether this style uses a dot separator between character groups
    var hasDotSeparator: Bool {
        self == .vicSlimlineBlack
    }
}

// MARK: - Plate Icon

enum PlateIcon: String, CaseIterable, Identifiable, Codable, Sendable {
    case heart
    case star
    case bat
    case shield
    case lightning
    case crown
    case flame
    case diamond

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heart:     return "Heart"
        case .star:      return "Star"
        case .bat:       return "Bat"
        case .shield:    return "Shield"
        case .lightning: return "Lightning"
        case .crown:     return "Crown"
        case .flame:     return "Flame"
        case .diamond:   return "Diamond"
        }
    }

    /// SF Symbol name. Empty for custom-drawn icons.
    var sfSymbol: String {
        switch self {
        case .heart:     return "heart.fill"
        case .star:      return "star.fill"
        case .bat:       return "" // custom Path
        case .shield:    return "shield.fill"
        case .lightning: return "bolt.fill"
        case .crown:     return "crown.fill"
        case .flame:     return "flame.fill"
        case .diamond:   return "diamond.fill"
        }
    }

    var isCustomDrawn: Bool { self == .bat }
}

/// Unicode marker character used in plate text to indicate icon positions.
let plateIconMarker: Character = "\u{2605}" // ★

enum RegoStatus: String, Codable, Sendable {
    case current   = "CURRENT"
    case expired   = "EXPIRED"
    case cancelled = "CANCELLED"
    case unknown   = "UNKNOWN"
    case pending   = "PENDING"

    var displayText: String {
        switch self {
        case .current:   return "Current"
        case .expired:   return "Expired"
        case .cancelled: return "Cancelled"
        case .unknown:   return "Unknown"
        case .pending:   return "Checking..."
        }
    }
}

// MARK: - Vehicle Details

struct VehicleDetails: Codable, Equatable, Sendable {
    let vehicleYear: Int?
    let vehicleMake: String?
    let vehicleModel: String?
    let vehicleColor: String?
    let regoStatus: RegoStatus
    let regoExpiryDate: Date?
    let regoCheckedAt: Date?

    var summaryText: String {
        let parts: [String?] = [
            vehicleYear.map(String.init),
            vehicleMake,
            vehicleModel,
            vehicleColor.map { "(\($0))" }
        ]
        return parts.compactMap { $0 }.joined(separator: " ")
    }
}

// MARK: - Plate

struct Plate: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let stateCode: String
    let plateText: String
    let plateStyle: PlateStyle
    let iconLeft: String
    let iconRight: String
    let isCommentsOpen: Bool
    let spotCount: Int
    let viewCount: Int
    let ownerUserId: UUID?
    let submittedByUserId: UUID?
    let submittedByUsername: String?
    let vehicle: VehicleDetails
    let createdAt: Date
    let updatedAt: Date

    // New fields (optional for backward compat with older API responses)
    let hasSpaceSeparator: Bool
    let customBgColor: String?
    let isHidden: Bool
    let isBlockedReadd: Bool
    let ownershipVerified: Bool
    let ownershipStatus: String

    enum CodingKeys: String, CodingKey {
        case id, stateCode, plateText, plateStyle, iconLeft, iconRight
        case isCommentsOpen, spotCount, viewCount, ownerUserId
        case submittedByUserId, submittedByUsername, vehicle
        case createdAt, updatedAt
        case hasSpaceSeparator, customBgColor, isHidden, isBlockedReadd
        case ownershipVerified, ownershipStatus
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        stateCode = try c.decode(String.self, forKey: .stateCode)
        plateText = try c.decode(String.self, forKey: .plateText)
        plateStyle = try c.decode(PlateStyle.self, forKey: .plateStyle)
        iconLeft = try c.decode(String.self, forKey: .iconLeft)
        iconRight = try c.decode(String.self, forKey: .iconRight)
        isCommentsOpen = try c.decode(Bool.self, forKey: .isCommentsOpen)
        spotCount = try c.decode(Int.self, forKey: .spotCount)
        viewCount = try c.decode(Int.self, forKey: .viewCount)
        ownerUserId = try c.decodeIfPresent(UUID.self, forKey: .ownerUserId)
        submittedByUserId = try c.decodeIfPresent(UUID.self, forKey: .submittedByUserId)
        submittedByUsername = try c.decodeIfPresent(String.self, forKey: .submittedByUsername)
        vehicle = try c.decode(VehicleDetails.self, forKey: .vehicle)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        // Defaults for backward compat
        hasSpaceSeparator = try c.decodeIfPresent(Bool.self, forKey: .hasSpaceSeparator) ?? true
        customBgColor = try c.decodeIfPresent(String.self, forKey: .customBgColor)
        isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        isBlockedReadd = try c.decodeIfPresent(Bool.self, forKey: .isBlockedReadd) ?? false
        ownershipVerified = try c.decodeIfPresent(Bool.self, forKey: .ownershipVerified) ?? false
        ownershipStatus = try c.decodeIfPresent(String.self, forKey: .ownershipStatus) ?? "none"
    }

    // MARK: - Icon helpers

    /// First inline icon (parsed from iconLeft field)
    var icon1: PlateIcon? { PlateIcon(rawValue: iconLeft) }
    /// Second inline icon (parsed from iconRight field)
    var icon2: PlateIcon? { PlateIcon(rawValue: iconRight) }
    /// Whether plate text contains inline icon markers (★)
    var hasInlineIcons: Bool { plateText.contains(plateIconMarker) }
    /// Number of icon markers in plate text
    var iconMarkerCount: Int { plateText.filter { $0 == plateIconMarker }.count }
}

// MARK: - Request / Response

struct PlateCreateRequest: Codable, Sendable {
    let stateCode: String
    let plateText: String
    let plateStyle: PlateStyle
    let iconLeft: String
    let iconRight: String
    let hasSpaceSeparator: Bool
    let customBgColor: String?
}

struct DuplicatePlateResponse: Codable, Sendable {
    let detail: String
    let existingPlateId: UUID
    let stateCode: String
    let plateText: String
}

// MARK: - Color Helpers

extension Color {
    /// Create a Color from a hex string like "#FF0000"
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else {
            self = .gray
            return
        }
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }

    /// Relative luminance (0 = black, 1 = white)
    var luminance: Double {
        // Approximate via sRGB → linear
        let comps = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = comps.count > 0 ? comps[0] : 0
        let g = comps.count > 1 ? comps[1] : 0
        let b = comps.count > 2 ? comps[2] : 0
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Returns white or black depending on background luminance
    var contrastingTextColor: Color {
        luminance > 0.5 ? .black : .white
    }
}

struct OwnershipStatusResponse: Codable, Sendable {
    let plateId: UUID
    let status: String
    let day1SubmittedAt: Date?
    let day2SubmittedAt: Date?
    let ownershipVerified: Bool
}
