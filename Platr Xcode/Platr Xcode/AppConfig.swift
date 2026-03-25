// Platr iOS — App Configuration (Dev / Production)

import Foundation

enum AppEnvironment: String {
    case development
    case production
}

struct AppConfig: Sendable {
    static let current: AppConfig = {
        #if DEBUG
        return AppConfig(environment: .development)
        #else
        return AppConfig(environment: .production)
        #endif
    }()

    let environment: AppEnvironment
    let apiBaseURL: String

    init(environment: AppEnvironment) {
        self.environment = environment
        switch environment {
        case .development:
            self.apiBaseURL = "http://localhost:8001/api/v1"
        case .production:
            // TODO: Replace with your production API URL before App Store submission
            self.apiBaseURL = "https://api.platr.app/api/v1"
        }
    }
}
