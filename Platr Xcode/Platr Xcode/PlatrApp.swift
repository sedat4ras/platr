// Platr iOS — App Entry Point

import SwiftUI
import UIKit

// MARK: - AppDelegate (Push Notifications)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationService.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
}

@main
struct PlatrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authVM = AuthViewModel()
    @State private var themeManager = ThemeManager()
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if !hasCompletedOnboarding {
                        OnboardingView()
                    } else {
                        MainTabView(authVM: authVM)
                            .transition(.opacity)
                    }
                }
                .environment(themeManager)
                .environment(authVM)
                .preferredColorScheme(themeManager.theme.colorScheme)
                .tint(themeManager.theme.accentColor)

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}

// MARK: - MainTabView (3 tabs: Feed / Search / Profile)

struct MainTabView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        TabView {
            // ── Tab 1: Feed (browse-only OK) ─────────────────────────────────
            ContentView()
                .tabItem { Label("Feed", systemImage: "house.fill") }

            // ── Tab 2: Search (browse-only OK) ───────────────────────────────
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            // ── Tab 3: Profile (requires auth) ───────────────────────────────
            Group {
                if authVM.isAuthenticated {
                    ProfileView(authVM: authVM)
                } else {
                    LoginView(authVM: authVM)
                }
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .task {
            if authVM.isAuthenticated {
                await authVM.fetchMe()
                await NotificationService.shared.requestPermission()
            }
        }
    }
}
