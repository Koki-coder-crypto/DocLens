import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var documentStore: DocumentStore
    @State private var searchText = ""
    @State private var selectedCategory: ScannedDocument.DocumentCategory?
    @State private var selectedDoc: ScannedDocument?

    var filtered: [ScannedDocument] {
        var docs = documentStore.documents
        if let cat = selectedCategory { docs = docs.filter { $0.category == cat } }
        if !searchText.isEmpty {
            docs = docs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.rawText.localizedCaseInsensitiveContains(searchText)
            }
        }
        return docs
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { doc in
                            DocCard(document: doc)
                                .contentShape(Rectangle())
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        if let i = documentStore.documents.firstIndex(where: { $0.id == doc.id }) {
                                            documentStore.delete(at: IndexSet(integer: i))
                                        }
                                    } label: { Label("Delete", systemImage: "trash.fill") }
                                }
                                .background(
                                    NavigationLink("", destination: DocumentDetailView(document: doc))
                                        .opacity(0)
                                )
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.appBG)
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBG, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { selectedCategory = nil }
                        Divider()
                        ForEach(ScannedDocument.DocumentCategory.allCases, id: \.self) { cat in
                            Button { selectedCategory = cat } label: {
                                Label(cat.label, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: selectedCategory == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(selectedCategory == nil ? Color.appMuted : Color.appAccent)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "doc.slash").font(.system(size: 40)).foregroundStyle(Color.appMuted)
            }
            VStack(spacing: 8) {
                Text(searchText.isEmpty && selectedCategory == nil ? "No Documents Yet" : "No Results")
                    .font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                Text(searchText.isEmpty && selectedCategory == nil
                     ? "Scanned documents will appear here."
                     : "Try a different filter or search term.")
                .font(.system(size: 15)).foregroundStyle(Color.appMuted).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DocCard: View {
    let document: ScannedDocument

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: document.category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                if let summary = document.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 12)).foregroundStyle(Color.appMuted).lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(document.pages)p")
                    .font(.system(size: 12).monospacedDigit()).foregroundStyle(Color.appMuted)
                Text(document.createdAt, style: .relative)
                    .font(.system(size: 11)).foregroundStyle(Color.appMuted.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
        )
    }
}
