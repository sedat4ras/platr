// Platr iOS — PlateStyle Unit Tests
// QA Engineer | XCTest suite for PlateStyle computed properties

import XCTest
@testable import Platr

final class PlateStyleTests: XCTestCase {

    // MARK: - maxCharacters

    func testMaxCharacters_standardStyles_returns6() {
        XCTAssertEqual(PlateStyle.vicStandard.maxCharacters, 6)
        XCTAssertEqual(PlateStyle.nswStandard.maxCharacters, 6)
        XCTAssertEqual(PlateStyle.qldStandard.maxCharacters, 6)
    }

    func testMaxCharacters_customStyles_returns7() {
        XCTAssertEqual(PlateStyle.vicCustomBlack.maxCharacters, 7)
        XCTAssertEqual(PlateStyle.vicCustomWhite.maxCharacters, 7)
        XCTAssertEqual(PlateStyle.vicHeritage.maxCharacters, 7)
        XCTAssertEqual(PlateStyle.vicEnvironment.maxCharacters, 7)
    }

    // MARK: - allowedCharacters

    func testAllowedCharacters_containsUppercaseLetters() {
        let allowed = PlateStyle.vicStandard.allowedCharacters
        for scalar in "ABCDEFGHIJKLMNOPQRSTUVWXYZ".unicodeScalars {
            XCTAssertTrue(allowed.contains(scalar), "Expected '\(scalar)' to be allowed")
        }
    }

    func testAllowedCharacters_containsDigits() {
        let allowed = PlateStyle.vicStandard.allowedCharacters
        for scalar in "0123456789".unicodeScalars {
            XCTAssertTrue(allowed.contains(scalar), "Expected '\(scalar)' to be allowed")
        }
    }

    func testAllowedCharacters_rejectsLowercase() {
        let allowed = PlateStyle.vicStandard.allowedCharacters
        for scalar in "abcdefghijklmnopqrstuvwxyz".unicodeScalars {
            XCTAssertFalse(allowed.contains(scalar), "Expected '\(scalar)' to be rejected")
        }
    }

    func testAllowedCharacters_rejectsSymbols() {
        let allowed = PlateStyle.vicStandard.allowedCharacters
        for scalar in "!@#$%^&*()-_ .,:;".unicodeScalars {
            XCTAssertFalse(allowed.contains(scalar), "Expected '\(scalar)' to be rejected")
        }
    }

    func testAllowedCharacters_rejectsSpacesAndHyphens() {
        let allowed = PlateStyle.vicCustomBlack.allowedCharacters
        XCTAssertFalse(allowed.contains(" " as Unicode.Scalar), "Spaces should be rejected")
        XCTAssertFalse(allowed.contains("-" as Unicode.Scalar), "Hyphens should be rejected")
    }

    // MARK: - formatHint

    func testFormatHint_vicStandard() {
        XCTAssertEqual(PlateStyle.vicStandard.formatHint, "e.g. ABC123")
    }

    func testFormatHint_customStyles_show1LOVE() {
        XCTAssertEqual(PlateStyle.vicCustomBlack.formatHint, "e.g. 1LOVE")
        XCTAssertEqual(PlateStyle.vicCustomWhite.formatHint, "e.g. 1LOVE")
        XCTAssertEqual(PlateStyle.vicHeritage.formatHint, "e.g. 1LOVE")
        XCTAssertEqual(PlateStyle.vicEnvironment.formatHint, "e.g. 1LOVE")
    }

    func testFormatHint_nswAndQld() {
        XCTAssertEqual(PlateStyle.nswStandard.formatHint, "e.g. ABC123")
        XCTAssertEqual(PlateStyle.qldStandard.formatHint, "e.g. ABC123")
    }

    // MARK: - stateCode

    func testStateCode_vicStyles() {
        let vicStyles: [PlateStyle] = [.vicStandard, .vicCustomBlack, .vicCustomWhite, .vicHeritage, .vicEnvironment]
        for style in vicStyles {
            XCTAssertEqual(style.stateCode, "VIC", "\(style) should have stateCode VIC")
        }
    }

    func testStateCode_nswAndQld() {
        XCTAssertEqual(PlateStyle.nswStandard.stateCode, "NSW")
        XCTAssertEqual(PlateStyle.qldStandard.stateCode, "QLD")
    }

    // MARK: - isAvailable

    func testIsAvailable_vicStylesAreAvailable() {
        XCTAssertTrue(PlateStyle.vicStandard.isAvailable)
        XCTAssertTrue(PlateStyle.vicCustomBlack.isAvailable)
        XCTAssertTrue(PlateStyle.vicCustomWhite.isAvailable)
        XCTAssertTrue(PlateStyle.vicHeritage.isAvailable)
        XCTAssertTrue(PlateStyle.vicEnvironment.isAvailable)
    }

    func testIsAvailable_nonVicStylesAreUnavailable() {
        XCTAssertFalse(PlateStyle.nswStandard.isAvailable)
        XCTAssertFalse(PlateStyle.qldStandard.isAvailable)
    }

    // MARK: - styles(for:)

    func testStylesForState_VIC_returns5Styles() {
        let vic = PlateStyle.styles(for: "VIC")
        XCTAssertEqual(vic.count, 5)
        XCTAssertTrue(vic.contains(.vicStandard))
        XCTAssertTrue(vic.contains(.vicCustomBlack))
        XCTAssertTrue(vic.contains(.vicCustomWhite))
        XCTAssertTrue(vic.contains(.vicHeritage))
        XCTAssertTrue(vic.contains(.vicEnvironment))
    }

    func testStylesForState_NSW_returns1Style() {
        let nsw = PlateStyle.styles(for: "NSW")
        XCTAssertEqual(nsw.count, 1)
        XCTAssertTrue(nsw.contains(.nswStandard))
    }

    func testStylesForState_QLD_returns1Style() {
        let qld = PlateStyle.styles(for: "QLD")
        XCTAssertEqual(qld.count, 1)
        XCTAssertTrue(qld.contains(.qldStandard))
    }

    func testStylesForState_unknownState_returnsEmpty() {
        let unknown = PlateStyle.styles(for: "SA")
        XCTAssertTrue(unknown.isEmpty)
    }

    func testStylesForState_emptyString_returnsEmpty() {
        let empty = PlateStyle.styles(for: "")
        XCTAssertTrue(empty.isEmpty)
    }

    // MARK: - styles(for:) does NOT filter by isAvailable (latent issue)

    func testStylesForState_includesUnavailableStyles() {
        // styles(for:) returns ALL styles for a state, including unavailable ones.
        // The UI must filter by .isAvailable separately.
        let nsw = PlateStyle.styles(for: "NSW")
        XCTAssertEqual(nsw.count, 1)
        XCTAssertFalse(nsw[0].isAvailable, "NSW styles are currently unavailable — UI must filter")
    }
}
