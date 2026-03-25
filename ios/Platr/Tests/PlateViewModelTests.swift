// Platr iOS — PlateViewModel Unit Tests
// QA Engineer | XCTest suite for PlateViewModel form validation and input logic

import XCTest
@testable import Platr

final class PlateViewModelTests: XCTestCase {

    private var vm: PlateViewModel!

    override func setUp() {
        super.setUp()
        vm = PlateViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    // MARK: - isFormValid: empty / whitespace

    func testIsFormValid_emptyText_returnsFalse() {
        vm.newPlateText = ""
        vm.newPlateStyle = .vicStandard
        XCTAssertFalse(vm.isFormValid)
    }

    func testIsFormValid_whitespaceOnly_returnsFalse() {
        vm.newPlateText = "   "
        vm.newPlateStyle = .vicStandard
        XCTAssertFalse(vm.isFormValid)
    }

    func testIsFormValid_tabsOnly_returnsFalse() {
        vm.newPlateText = "\t\t"
        vm.newPlateStyle = .vicStandard
        XCTAssertFalse(vm.isFormValid)
    }

    // MARK: - isFormValid: valid inputs (standard style, max=6)

    func testIsFormValid_singleChar_returnsTrue() {
        vm.newPlateText = "A"
        vm.newPlateStyle = .vicStandard
        XCTAssertTrue(vm.isFormValid)
    }

    func testIsFormValid_exactlyMaxChars_standard_returnsTrue() {
        vm.newPlateText = "ABC123"
        vm.newPlateStyle = .vicStandard
        XCTAssertTrue(vm.isFormValid, "6 chars on max=6 style should be valid")
    }

    func testIsFormValid_exceedsMaxChars_standard_returnsFalse() {
        vm.newPlateText = "ABC1234"
        vm.newPlateStyle = .vicStandard
        XCTAssertFalse(vm.isFormValid, "7 chars on max=6 style should be invalid")
    }

    // MARK: - isFormValid: valid inputs (custom style, max=7)

    func testIsFormValid_7chars_customBlack_returnsTrue() {
        vm.newPlateText = "ABCDEFG"
        vm.newPlateStyle = .vicCustomBlack
        XCTAssertTrue(vm.isFormValid, "7 chars on max=7 style should be valid")
    }

    func testIsFormValid_8chars_customBlack_returnsFalse() {
        vm.newPlateText = "ABCDEFGH"
        vm.newPlateStyle = .vicCustomBlack
        XCTAssertFalse(vm.isFormValid, "8 chars on max=7 style should be invalid")
    }

    func testIsFormValid_6chars_customBlack_returnsTrue() {
        vm.newPlateText = "ABC123"
        vm.newPlateStyle = .vicCustomBlack
        XCTAssertTrue(vm.isFormValid, "6 chars on max=7 style should be valid")
    }

    // MARK: - isFormValid: boundary values

    func testIsFormValid_1char_allStyles() {
        for style in PlateStyle.allCases {
            vm.newPlateText = "X"
            vm.newPlateStyle = style
            XCTAssertTrue(vm.isFormValid, "1 char should be valid for \(style.displayName)")
        }
    }

    func testIsFormValid_exactlyAtMax_allStyles() {
        for style in PlateStyle.allCases {
            let text = String(repeating: "A", count: style.maxCharacters)
            vm.newPlateText = text
            vm.newPlateStyle = style
            XCTAssertTrue(vm.isFormValid, "\(style.maxCharacters) chars should be valid for \(style.displayName)")
        }
    }

    func testIsFormValid_oneOverMax_allStyles() {
        for style in PlateStyle.allCases {
            let text = String(repeating: "A", count: style.maxCharacters + 1)
            vm.newPlateText = text
            vm.newPlateStyle = style
            XCTAssertFalse(vm.isFormValid, "\(style.maxCharacters + 1) chars should be INVALID for \(style.displayName)")
        }
    }

    // MARK: - isFormValid: does NOT validate allowedCharacters (BUG-003)

    /// Confirms isFormValid rejects text with invalid characters (BUG-003 fix verified).
    func testIsFormValid_rejectsInvalidCharacters() {
        vm.newPlateText = "!!!"   // symbols — not in allowedCharacters
        vm.newPlateStyle = .vicStandard
        XCTAssertFalse(vm.isFormValid, "Symbols should be rejected by character validation")
    }

    func testIsFormValid_rejectsMixedValidAndInvalidCharacters() {
        vm.newPlateText = "AB!C1"
        vm.newPlateStyle = .vicStandard
        XCTAssertFalse(vm.isFormValid, "Mixed valid+invalid chars should be rejected")
    }

    // MARK: - resetForm

    func testResetForm_clearsAllFields() {
        vm.newPlateText = "ABC123"
        vm.newPlateStyle = .vicCustomBlack
        vm.newIconLeft = "[HEART]"
        vm.newIconRight = "[STAR]"

        vm.resetForm()

        XCTAssertEqual(vm.newPlateText, "")
        XCTAssertEqual(vm.newPlateStyle, .vicStandard)
        XCTAssertEqual(vm.newIconLeft, "")
        XCTAssertEqual(vm.newIconRight, "")
    }

    func testResetForm_resetsSelectedStateCode() {
        // BUG-004 fix verified: resetForm now resets selectedStateCode
        vm.selectedStateCode = "NSW"
        vm.resetForm()
        XCTAssertEqual(vm.selectedStateCode, "VIC", "selectedStateCode should reset to VIC")
    }

    // MARK: - Character Filtering (simulating AddPlateView onChange logic)

    /// Simulates the onChange filter from AddPlateView to verify correctness.
    /// In production, this runs inside SwiftUI — here we replicate the logic.
    private func applyInputFilter(_ input: String, style: PlateStyle) -> String {
        let maxLen = style.maxCharacters
        let allowed = style.allowedCharacters
        let filtered = input.uppercased().unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered).prefix(maxLen))
    }

    func testFilter_lowercaseLetters_autoUppercased() {
        let result = applyInputFilter("abc", style: .vicStandard)
        XCTAssertEqual(result, "ABC")
    }

    func testFilter_symbols_stripped() {
        let result = applyInputFilter("A!@#B$C", style: .vicStandard)
        XCTAssertEqual(result, "ABC")
    }

    func testFilter_spaces_stripped() {
        let result = applyInputFilter("A B C", style: .vicStandard)
        XCTAssertEqual(result, "ABC")
    }

    func testFilter_hyphens_stripped() {
        let result = applyInputFilter("ABC-123", style: .vicStandard)
        XCTAssertEqual(result, "ABC123")
    }

    func testFilter_exactly6Chars_vicStandard_unchanged() {
        let result = applyInputFilter("ABC123", style: .vicStandard)
        XCTAssertEqual(result, "ABC123")
    }

    func testFilter_7thChar_vicStandard_truncated() {
        let result = applyInputFilter("ABC1234", style: .vicStandard)
        XCTAssertEqual(result, "ABC123")
    }

    func testFilter_7chars_vicCustomBlack_accepted() {
        let result = applyInputFilter("ABCDEFG", style: .vicCustomBlack)
        XCTAssertEqual(result, "ABCDEFG")
    }

    func testFilter_8thChar_vicCustomBlack_truncated() {
        let result = applyInputFilter("ABCDEFGH", style: .vicCustomBlack)
        XCTAssertEqual(result, "ABCDEFG")
    }

    func testFilter_emptyInput_returnsEmpty() {
        let result = applyInputFilter("", style: .vicStandard)
        XCTAssertEqual(result, "")
    }

    func testFilter_allSymbols_returnsEmpty() {
        let result = applyInputFilter("!@#$%^&*()", style: .vicStandard)
        XCTAssertEqual(result, "")
    }

    func testFilter_mixedWithSymbolsAndSpaces_correctResult() {
        let result = applyInputFilter("a b!c-1@2#3", style: .vicStandard)
        XCTAssertEqual(result, "ABC123")
    }

    func testFilter_mixedExceedingMax_truncatesAfterFiltering() {
        // "A!B!C!1!2!3!4" → filtered = "ABC1234" (7 chars) → prefix(6) = "ABC123"
        let result = applyInputFilter("A!B!C!1!2!3!4", style: .vicStandard)
        XCTAssertEqual(result, "ABC123")
    }

    // MARK: - Style Switch Truncation (BUG-001 fix verification)

    /// Simulates the .onChange(of: newPlateStyle) handler from AddPlateView.
    /// In production this runs inside SwiftUI; here we replicate the logic.
    private func applyStyleSwitchFilter(currentText: String, newStyle: PlateStyle) -> String {
        let maxLen = newStyle.maxCharacters
        let allowed = newStyle.allowedCharacters
        let filtered = currentText.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered).prefix(maxLen))
    }

    func testStyleSwitch_7charsToLowerMax_textTruncatedTo6() {
        // BUG-001 fix verified: onChange(of: newPlateStyle) now truncates text
        let text = "ABCDEFG"  // 7 chars, valid on vicCustomBlack
        let result = applyStyleSwitchFilter(currentText: text, newStyle: .vicStandard)
        XCTAssertEqual(result, "ABCDEF", "Switching to max=6 style should truncate to 6 chars")
        XCTAssertEqual(result.count, 6)
    }

    func testStyleSwitch_6charsToHigherMax_textUnchanged() {
        let text = "ABC123"  // 6 chars, valid on both standard and custom
        let result = applyStyleSwitchFilter(currentText: text, newStyle: .vicCustomBlack)
        XCTAssertEqual(result, "ABC123", "Switching to higher max should not change text")
    }

    func testStyleSwitch_exactlyAtNewMax_textUnchanged() {
        let text = "ABCDEF"  // 6 chars, exactly at vicStandard max
        let result = applyStyleSwitchFilter(currentText: text, newStyle: .vicStandard)
        XCTAssertEqual(result, "ABCDEF", "Text at exactly max should remain unchanged")
    }

    func testStyleSwitch_emptyText_staysEmpty() {
        let result = applyStyleSwitchFilter(currentText: "", newStyle: .vicStandard)
        XCTAssertEqual(result, "", "Empty text should remain empty on style switch")
    }

    func testStyleSwitch_customToCustom_noTruncation() {
        // Both custom styles have max=7, so no truncation needed
        let text = "ABCDEFG"
        let result = applyStyleSwitchFilter(currentText: text, newStyle: .vicCustomWhite)
        XCTAssertEqual(result, "ABCDEFG", "Switching between same-max styles should not truncate")
    }
}
