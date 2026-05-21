import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: StoreManager
    @State private var selectedTab: Tab = .scan

    enum Tab { case scan, documents, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView()
                .tabItem { Label("Scan", systemImage: "viewfinder.circle.fill") }
                .tag(Tab.scan)

            DocumentListView()
                .tabItem { Label("Documents", systemImage: "doc.fill") }
                .tag(Tab.documents)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .accentColor(.teal)
    }
}
