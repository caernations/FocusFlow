import SwiftUI

@main
struct FocusFlowApp: App {
    @StateObject private var authManager = AuthManager.shared
    @State private var showSplash = true

    init() {
        // Request notification permission on app launch
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("✅ Notifications authorized")
            } else {
                print("⚠️ Notifications denied")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(isActive: $showSplash)
                } else {
                    if authManager.isAuthenticated {
                        ContentView()
                    } else {
                        LoginView()
                    }
                }
            }
        }
    }
}
