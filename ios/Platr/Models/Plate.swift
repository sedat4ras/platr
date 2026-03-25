// Platr iOS — Plate data model
// [iOSSwiftAgent | iOS-001]

import Foundation

// MARK: - Enums

enum PlateStyle: String, Codable, CaseIterable, Identifiable {
    case vicStandard     = "VIC_STANDARD"
    case vicCustomBlack  = "VIC_CUSTOM_BLACK"
    case vicCustomWhite  = "VIC_CUSTOM_WHITE"
    case vicHeritage     = "VIC_HERITAGE"
    case vicEnvironment    = "VIC_ENVIRONMENT"
    case vicSlimlineBlack  = "VIC_SLIMLINE_BLACK"
    case vicDeluxe         = "VIC_DELUXE"
    case vicPrestige       = "VIC_PRESTIGE"
    case vicEuro           = "VIC_EURO"
    case nswStandard       = "NSW_STANDARD"
    case qldStandard       = "QLD_STANDARD"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vicStandard:       return "VIC Standard"
        case .vicCustomBlack:    return "VIC Custom Black"
        case .vicCustomWhite:    return "VIC Custom White"
        case .vicHeritage:       return "VIC Heritage"
        case .vicEnvironment:    return "VIC Environment"
        case .vicSlimlineBlack:  return "VIC Slimline Black"
        case .vicDeluxe:         return "VIC Deluxe"
        case .vicPrestige:       return "VIC Prestige"
        case .vicEuro:           return "VIC Euro"
        case .nswStandard:       return "NSW Standard"
        case .qldStandard:       return "QLD Standard"
        }
    }

    /// Maximum number of characters allowed for this plate style.
    var maxCharacters: Int {
        switch self {
        case .vicStandard, .nswStandard, .qldStandard:
            return 6
        case .vicCustomBlack, .vicCustomWhite, .vicHeritage, .vicEnvironment:
            return 7
        case .vicSlimlineBlack, .vicDeluxe, .vicPrestige, .vicEuro:
            return 6
        }
    }

    /// CharacterSet of characters allowed in plate text for this style.
    var allowedCharacters: CharacterSet {
        // ASCII A-Z and 0-9 only. Explicit set prevents Unicode homoglyph attacks
        // (e.g., Cyrillic А/В/С visually matching Latin A/B/C).
        var cs = CharacterSet()
        cs.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return cs
    }

    /// Placeholder hint shown in the text field for this style.
    var formatHint: String {
        switch self {
        case .vicStandard:    return "e.g. ABC123"
        case .vicCustomBlack, .vicCustomWhite,
             .vicHeritage, .vicEnvironment: return "e.g. 1LOVE"
        case .vicSlimlineBlack, .vicDeluxe, .vicEuro:
            return "e.g. ABC123"
        case .vicPrestige:    return "e.g. 1VIP"
        case .nswStandard:    return "e.g. ABC123"
        case .qldStandard:    return "e.g. ABC123"
        }
    }

    /// Whether this style is currently available for use in the app.
    /// Non-VIC styles are hidden until those states are officially supported.
    var isAvailable: Bool {
        switch self {
        case .vicStandard, .vicCustomBlack, .vicCustomWhite,
             .vicHeritage, .vicEnvironment,
             .vicSlimlineBlack, .vicDeluxe, .vicPrestige, .vicEuro:
            return true
        case .nswStandard, .qldStandard:
            return false
        }
    }

    /// The state code this style belongs to. Used to filter style options by selected state.
    var stateCode: String {
        switch self {
        case .vicStandard, .vicCustomBlack, .vicCustomWhite,
             .vicHeritage, .vicEnvironment,
             .vicSlimlineBlack, .vicDeluxe, .vicPrestige, .vicEuro:
            return "VIC"
        case .nswStandard: return "NSW"
        case .qldStandard: return "QLD"
        }
    }

    /// All styles available for a given state code.
    static func styles(for stateCode: String) -> [PlateStyle] {
        allCases.filter { $0.stateCode == stateCode }
    }
}

enum RegoStatus: String, Codable {
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

    var color: String {   // SwiftUI color asset name
        switch self {
        case .current:   return "regoGreen"
        case .expired:   return "regoRed"
        case .cancelled: return "regoRed"
        case .unknown:   return "regoGray"
        case .pending:   return "regoGray"
        }
    }
}

// MARK: - Vehicle Details

struct VehicleDetails: Codable {
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

struct Plate: Codable, Identifiable, Equatable {
    let id: UUID
    let stateCode: String
    let plateText: String
    let plateStyle: PlateStyle
    let iconLeft: String
    let iconRight: String
    let isCommentsOpen: Bool
    let latitude: Double?
    let longitude: Double?
    let spotCount: Int
    let viewCount: Int
    let ownerUserId: UUID?
    let submittedByUserId: UUID?
    let submittedByUsername: String?
    let vehicle: VehicleDetails
    let createdAt: Date
    let updatedAt: Date

    static func == (lhs: Plate, rhs: Plate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Request / Response models

struct PlateCreateRequest: Codable {
    let stateCode: String
    let plateText: String
    let plateStyle: PlateStyle
    let iconLeft: String
    let iconRight: String
    let latitude: Double?
    let longitude: Double?
}

struct DuplicatePlateResponse: Codable {
    let detail: String
    let existingPlateId: UUID
    let stateCode: String
    let plateText: String
}
