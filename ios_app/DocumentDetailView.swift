import SwiftUI

struct DocumentDetailView: View {
    let document: ScannedDocument
    @EnvironmentObject var documentStore: DocumentStore
    @State private var selectedTab: DetailTab = .summary
    @State private var selectedImageIndex = 0

    enum DetailTab: String, CaseIterable { case summary = "Summary", text = "Text", pages = "Pages" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                categoryBadge
                tabPicker

                switch selectedTab {
                case .summary: summarySection
                case .text:    textSection
                case .pages:   pagesSection
                }
            }
            .padding()
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: document.rawText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Category badge

    private var categoryBadge: some View {
        HStack {
            Label(document.category.label, systemImage: document.category.icon)
                .font(.caption.bold())
                .foregroundStyle(.teal)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.teal.opacity(0.1))
                .cornerRadius(20)

            Text("•")
                .foregroundStyle(.tertiary)

            Text("\(document.pages) page\(document.pages == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.tertiary)

            Text("\(document.wordCount) words")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary

    @ViewBuilder
    private var summarySection: some View {
        if let summary = document.summary, !summary.isEmpty {
            InfoCard(title: "AI Summary", icon: "sparkles", color: .teal) {
                Text(summary)
                    .font(.body)
            }
        }

        if !document.keyPoints.isEmpty {
            InfoCard(title: "Key Points", icon: "list.bullet", color: .blue) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(document.keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.blue)
                                .padding(.top, 6)
                            Text(point).font(.subheadline)
                        }
                    }
                }
            }
        }

        metaCard
    }

    private var metaCard: some View {
        InfoCard(title: "Details", icon: "info.circle", color: .secondary) {
            VStack(spacing: 8) {
                MetaRow(label: "Scanned", value: document.createdAt.formatted(date: .abbreviated, time: .shortened))
                MetaRow(label: "Pages", value: "\(document.pages)")
                MetaRow(label: "Words", value: "\(document.wordCount)")
                MetaRow(label: "Language", value: document.language.uppercased())
                MetaRow(label: "Category", value: document.category.label)
            }
        }
    }

    // MARK: - Text

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Extracted Text")
                    .font(.headline)
                Spacer()
                ShareLink(item: document.rawText) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.teal)
            }

            Text(document.rawText.isEmpty ? "No text was extracted from this document." : document.rawText)
                .font(.body)
                .textSelection(.enabled)
                .foregroundStyle(document.rawText.isEmpty ? .secondary : .primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Pages

    private var pagesSection: some View {
        VStack(spacing: 16) {
            if document.imageFileNames.isEmpty {
                ContentUnavailableView("No Page Images", systemImage: "photo.slash", description: Text("Original page images are not available."))
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(document.imageFileNames.enumerated()), id: \.offset) { idx, fileName in
                        if let img = documentStore.image(named: fileName) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)

                Text("Page \(selectedImageIndex + 1) of \(document.imageFileNames.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Shared components

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct MetaRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}
