import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var documentStore: DocumentStore
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.isPro {
                        Label("DocLens Pro — Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.teal)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free Plan")
                                .font(.subheadline.bold())
                            Text("\(StoreManager.freeScansPerMonth) scans / month · Basic OCR only")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Upgrade to Pro") { showPaywall = true }
                            .foregroundStyle(.teal)
                    }
                } header: { Text("Subscription") }

                Section("Storage") {
                    LabeledContent("Saved Documents", value: "\(documentStore.documents.count)")
                    Button("Delete All Documents", role: .destructive) { showDeleteConfirm = true }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    Link("Privacy Policy", destination: URL(string: "https://koki-coder-crypto.github.io/DocLens/privacy.html")!)
                    Link("Terms of Service", destination: URL(string: "https://koki-coder-crypto.github.io/DocLens/terms.html")!)
                    Link("Support", destination: URL(string: "https://koki-coder-crypto.github.io/DocLens/support.html")!)
                }

                Section {
                    Button("Restore Purchases") {
                        Task { await store.restorePurchases() }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Delete All Documents?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    documentStore.documents.indices.reversed().forEach { idx in
                        documentStore.delete(at: IndexSet(integer: idx))
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all documents and their scanned images.")
            }
        }
    }
}
