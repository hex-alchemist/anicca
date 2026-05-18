import SwiftUI

enum MainTab: Hashable {
    case home
    case log
    case insights
    case settings
}

struct MainTabView: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(MainTab.home)

            NavigationStack {
                LogView()
            }
            .tabItem {
                Label("Log", systemImage: "plus.circle.fill")
            }
            .tag(MainTab.log)

            NavigationStack {
                InsightsView()
            }
            .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            .tag(MainTab.insights)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(MainTab.settings)
        }
        .tint(AniccaTheme.brandPrimary)
    }
}
