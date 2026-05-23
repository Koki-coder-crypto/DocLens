import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: StoreManager
    @State private var selectedTab: Tab = .scan

    enum Tab: Int, CaseIterable {
        case scan, documents, settings

        var icon: String {
            switch self {
            case .scan:      return "viewfinder.circle.fill"
            case .documents: return "doc.fill"
            case .settings:  return "gearshape.fill"
            }
        }
        var label: String {
            switch self {
            case .scan:      return "Scan"
            case .documents: return "Documents"
            case .settings:  return "Settings"
            }
        }
        var tint: Color {
            switch self {
            case .scan:      return Color.appAccent
            case .documents: return Color(hex: "A78BFA")
            case .settings:  return Color.appMuted
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBG.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .scan:
                    ScanView()
                case .documents:
                    DocumentListView()
                        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }
                case .settings:
                    SettingsView()
                        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    if selectedTab != tab {
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(tab.tint.opacity(selectedTab == tab ? 0.15 : 0))
                                .frame(width: 52, height: 34)
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? tab.tint : Color.appMuted)
                                .scaleEffect(selectedTab == tab ? 1.08 : 1.0)
                        }
                        .frame(width: 52, height: 34)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)

                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? tab.tint : Color.appMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(LinearGradient(colors: [Color.white.opacity(0.05), Color.clear],
                                                startPoint: .top, endPoint: .bottom))
                Rectangle().frame(height: 0.5).foregroundStyle(Color.white.opacity(0.1))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
