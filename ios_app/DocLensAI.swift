import Foundation
import Vision
import UIKit

/// OCR and document organization that keeps the scanned text on the device.
actor DocLensAI {
    static let shared = DocLensAI()

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw DocLensError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "ja-JP"]

            do { try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }

    struct AnalysisResult {
        let title: String
        let summary: String
        let keyPoints: [String]
        let category: String
        let language: String
    }

    /// Produces a transparent local preview rather than sending document text to a third party.
    func analyze(text: String) async throws -> AnalysisResult {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let locale = text.range(of: "[ぁ-んァ-ン一-龥]", options: .regularExpression) == nil ? "en" : "ja"
        let fallbackTitle = locale == "ja" ? "スキャンした書類" : "Scanned document"
        let title = String((lines.first ?? fallbackTitle).prefix(40))
        let summary = String(lines.prefix(3).joined(separator: " ").prefix(280))
        let points = Array(lines.dropFirst().prefix(5)).map { String($0.prefix(120)) }
        let lower = text.lowercased()
        let category: String
        if lower.contains("invoice") || lower.contains("receipt") || text.contains("領収") { category = "receipt" }
        else if lower.contains("agreement") || lower.contains("contract") || text.contains("契約") { category = "contract" }
        else if lower.contains("note") || text.contains("メモ") { category = "note" }
        else { category = "general" }

        return AnalysisResult(title: title, summary: summary, keyPoints: points, category: category, language: locale)
    }
}

enum DocLensError: LocalizedError {
    case invalidImage, cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process the image. Please try again."
        case .cameraUnavailable: "Camera is not available on this device."
        }
    }
}
