// Platr iOS — ThemeManager
// 3 app-wide themes: Light, Dark, Blue

import SwiftUI

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark  = "dark"
    case blue  = "blue"

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark:  "Dark"
        case .blue:  "Blue"
        }
    }

    var icon: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark:  "moon.fill"
        case .blue:  "drop.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark:  .dark
        case .blue:  .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .light: .blue
        case .dark:  .blue
        case .blue:  Color(red: 0.29, green: 0.56, blue: 1.0)
        }
    }

    /// Hero gradient used in ProfileView
    var heroGradient: [Color] {
        switch self {
        case .light:
            return [Color(red: 0.12, green: 0.12, blue: 0.15),
                    Color(red: 0.20, green: 0.20, blue: 0.26)]
        case .dark:
            return [Color(red: 0.06, green: 0.06, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.16)]
        case .blue:
            return [Color(red: 0.04, green: 0.13, blue: 0.40),
                    Color(red: 0.10, green: 0.26, blue: 0.64)]
        }
    }

    /// Preview swatch colors for the theme picker
    var swatchColors: [Color] {
        switch self {
        case .light: [.white, Color(white: 0.93)]
        case .dark:  [Color(white: 0.12), Color(white: 0.18)]
        case .blue:  [Color(red: 0.05, green: 0.15, blue: 0.42),
                      Color(red: 0.12, green: 0.28, blue: 0.68)]
        }
    }
}

@Observable
final class ThemeManager {
    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? ""
        theme = AppTheme(rawValue: saved) ?? .light
    }
}
