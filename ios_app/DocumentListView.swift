import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var documentStore: DocumentStore
    @State private var searchText = ""
    @State private var selectedCategory: ScannedDocument.DocumentCategory?

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
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty && selectedCategory == nil ? "No Documents Yet" : "No Results",
                        systemImage: "doc.slash",
                        description: Text(searchText.isEmpty && selectedCategory == nil
                            ? "Scanned documents will appear here."
                            : "Try a different filter or search term.")
                    )
                } else {
                    List {
                        ForEach(filtered) { doc in
                            NavigationLink(destination: DocumentDetailView(document: doc)) {
                                DocumentRow(document: doc)
                            }
                        }
                        .onDelete { documentStore.delete(at: $0) }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Documents")
            .searchable(text: $searchText, prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { selectedCategory = nil }
                        Divider()
                        ForEach(ScannedDocument.DocumentCategory.allCases, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Label(cat.label, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: selectedCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundStyle(.teal)
                    }
                }
            }
        }
    }
}

struct DocumentRow: View {
    let document: ScannedDocument

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: document.category.icon)
                    .foregroundStyle(.teal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                if let summary = document.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(document.pages)p")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(document.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
