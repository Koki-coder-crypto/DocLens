import Foundation
import UIKit

struct ScannedDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    let createdAt: Date
    var pages: Int
    var rawText: String
    var summary: String?
    var keyPoints: [String]
    var category: DocumentCategory
    var imageFileNames: [String]
    var language: String

    enum DocumentCategory: String, Codable, CaseIterable, Hashable {
        case general, receipt, contract, note, article, id, other
        var icon: String {
            switch self {
            case .general:  return "doc.text.fill"
            case .receipt:  return "receipt.fill"
            case .contract: return "doc.badge.gearshape"
            case .note:     return "note.text"
            case .article:  return "newspaper.fill"
            case .id:       return "creditcard.fill"
            case .other:    return "doc.fill"
            }
        }
        var label: String { rawValue.capitalized }
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = Date(),
        pages: Int = 1,
        rawText: String = "",
        summary: String? = nil,
        keyPoints: [String] = [],
        category: DocumentCategory = .general,
        imageFileNames: [String] = [],
        language: String = "en"
    ) {
        self.id = id
        self.title = title.isEmpty ? "Document \(Self.formattedDate(createdAt))" : title
        self.createdAt = createdAt
        self.pages = pages
        self.rawText = rawText
        self.summary = summary
        self.keyPoints = keyPoints
        self.category = category
        self.imageFileNames = imageFileNames
        self.language = language
    }

    private static func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        return f.string(from: date)
    }

    var wordCount: Int { rawText.split(separator: " ").count }
}

@MainActor
class DocumentStore: ObservableObject {
    @Published private(set) var documents: [ScannedDocument] = []

    private let storageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("doclens_documents.json")
    }()

    var imageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("doclens_images", isDirectory: true)
    }

    init() {
        try? FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        load()
    }

    func save(_ document: ScannedDocument) {
        if let idx = documents.firstIndex(where: { $0.id == document.id }) {
            documents[idx] = document
        } else {
            documents.insert(document, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        offsets.forEach { idx in
            let doc = documents[idx]
            doc.imageFileNames.forEach { name in
                let url = imageDirectory.appendingPathComponent(name)
                try? FileManager.default.removeItem(at: url)
            }
        }
        documents.remove(atOffsets: offsets)
        persist()
    }

    func image(named fileName: String) -> UIImage? {
        let url = imageDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func saveImage(_ image: UIImage, named fileName: String) {
        let url = imageDirectory.appendingPathComponent(fileName)
        try? image.jpegData(compressionQuality: 0.85)?.write(to: url, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([ScannedDocument].self, from: data)
        else { return }
        documents = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(documents) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
