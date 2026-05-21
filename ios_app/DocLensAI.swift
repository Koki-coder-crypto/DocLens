import Foundation
import Vision
import UIKit

// MARK: - OCR + AI Analysis Engine

actor DocLensAI {
    static let shared = DocLensAI()

    private let claudeURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
    }()

    // MARK: - OCR (Apple Vision, on-device)

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw DocLensError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error { continuation.resume(throwing: error); return }
                let text = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "ja-JP"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }

    // MARK: - AI Analysis (Claude)

    struct AnalysisResult {
        let title: String
        let summary: String
        let keyPoints: [String]
        let category: String
        let language: String
    }

    func analyze(text: String) async throws -> AnalysisResult {
        guard !apiKey.isEmpty else { throw DocLensError.missingAPIKey }

        let wordCount = text.split(separator: " ").count
        guard wordCount > 3 else {
            return AnalysisResult(
                title: "Scanned Document",
                summary: text,
                keyPoints: [],
                category: "general",
                language: "en"
            )
        }

        let prompt = """
        Analyze this document text and respond with ONLY valid JSON, no other text.

        Document text:
        \(text.prefix(6000))

        Respond with exactly this JSON structure:
        {
          "title": "Short descriptive title (max 40 chars)",
          "summary": "2-3 sentence summary of the document",
          "key_points": ["point 1", "point 2", "point 3"],
          "category": "general" | "receipt" | "contract" | "note" | "article" | "id" | "other",
          "language": "en" | "ja" | "zh" | "ko" | "fr" | "de" | "es"
        }

        Rules:
        - title: concise and descriptive
        - summary: clear overview for quick understanding
        - key_points: up to 5 most important facts or figures (empty array if short)
        - category: best matching document type
        - language: primary language of the document (2-letter ISO code)
        """

        var request = URLRequest(url: claudeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 600,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DocLensError.apiError
        }

        let apiResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        let responseText = apiResponse.content.first?.text ?? "{}"

        if let jsonData = responseText.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return AnalysisResult(
                title: parsed["title"] as? String ?? "Document",
                summary: parsed["summary"] as? String ?? "",
                keyPoints: parsed["key_points"] as? [String] ?? [],
                category: parsed["category"] as? String ?? "general",
                language: parsed["language"] as? String ?? "en"
            )
        }

        return AnalysisResult(title: "Document", summary: text, keyPoints: [], category: "general", language: "en")
    }
}

// MARK: - Supporting types

enum DocLensError: LocalizedError {
    case invalidImage, missingAPIKey, apiError, cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:      return "Could not process the image. Please try again."
        case .missingAPIKey:     return "API key not configured. Please check settings."
        case .apiError:          return "AI analysis failed. Please try again."
        case .cameraUnavailable: return "Camera is not available on this device."
        }
    }
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable { let text: String }
    let content: [Content]
}
