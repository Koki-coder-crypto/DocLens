import SwiftUI

@main
struct DocLensApp: App {
    @StateObject private var store = StoreManager()
    @StateObject private var documentStore = DocumentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(documentStore)
                .preferredColorScheme(.none)
        }
    }
}
