// Platr iOS — App Entry Point
// iOS 17+ SwiftUI lifecycle.
// Auth gate: shows LoginView until isAuthenticated = true.
// 3 tabs: Home (feed+search) | Map | Profile

import GoogleSignIn
import SwiftUI

@main
struct PlatrApp: App {
    @State private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authVM.isAuthenticated {
                MainTabView(authVM: authVM)
                    .transition(.opacity)
            } else {
                LoginView(authVM: authVM)
                    .transition(.opacity)
            }
        }
        .handlesExternalEvents(matching: ["*"])
    }
}

extension PlatrApp {
    static func handleURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        TabView {
            // ── Tab 1: Home (birleşik feed + arama) ───────────────────────
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // ── Tab 2: Map ─────────────────────────────────────────────────
            PlateMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            // ── Tab 3: Profile ─────────────────────────────────────────────
            ProfileView(authVM: authVM)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .task {
            await authVM.fetchMe()
        }
    }
}
