import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Focus Timer Tab
            FocusTimerView()
                .tabItem {
                    Label("Focus", systemImage: selectedTab == 0 ? "circle.fill" : "circle")
                }
                .tag(0)

            // Analytics Tab
            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(1)

            // Insights Tab
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: selectedTab == 2 ? "brain.head.profile.fill" : "brain.head.profile")
                }
                .tag(2)

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .tint(Color(red: 0.5, green: 0.6, blue: 1.0))
    }
}

#Preview {
    ContentView()
}
