// Platr iOS — Push Notification Service

import Foundation
import UserNotifications
import UIKit

@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    var isAuthorized = false
    var deviceToken: String?

    private init() {}

    // MARK: - Request Permission

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Check Current Status

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Register for remote notifications

    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Device Token

    func didRegisterForRemoteNotifications(deviceToken data: Data) {
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        // Send token to backend
        Task {
            try? await APIService.shared.registerDeviceToken(token)
        }
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        // Push notifications not available (simulator, etc.)
    }
}
