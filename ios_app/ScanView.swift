import SwiftUI
import PhotosUI
import VisionKit

struct ScanView: View {
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var documentStore: DocumentStore
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var processingStatus = ""
    @State private var showPaywall = false
    @State private var monthlyCount = 0
    @State private var errorMessage: String?
    @State private var navigateToDocument: ScannedDocument?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                heroSection
                Spacer()
                if isProcessing {
                    processingView
                } else {
                    actionButtons
                }
                Spacer()
                if !store.isPro {
                    freeUsageFooter
                }
            }
            .padding()
            .navigationTitle("DocLens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pro") { showPaywall = true }
                            .font(.footnote.bold())
                            .foregroundStyle(.teal)
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                if VNDocumentCameraViewController.isSupported {
                    DocumentScannerView { images in
                        showScanner = false
                        processImages(images)
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        processImages([image])
                    }
                    selectedPhoto = nil
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .navigationDestination(item: $navigateToDocument) { doc in
                DocumentDetailView(document: doc)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "doc.viewfinder.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.teal)
            }

            Text("Scan Any Document")
                .font(.title2.bold())

            Text("Point your camera at any document and AI will extract the text and create an instant summary.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.teal)

            Text(processingStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 120)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                checkLimitAndRun { showScanner = true }
            } label: {
                Label("Scan with Camera", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.teal)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }

            Button {
                checkLimitAndRun { showPhotoPicker = true }
            } label: {
                Label("Import from Photos", systemImage: "photo.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
                    .cornerRadius(14)
            }
        }
    }

    private var freeUsageFooter: some View {
        let remaining = max(0, StoreManager.freeScansPerMonth - monthlyCount)
        return HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text("\(remaining) free scans left this month")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Upgrade") { showPaywall = true }
                .font(.caption.bold())
                .foregroundStyle(.teal)
        }
    }

    private func checkLimitAndRun(_ action: () -> Void) {
        if !store.isPro && monthlyCount >= StoreManager.freeScansPerMonth {
            showPaywall = true
        } else {
            action()
        }
    }

    private func processImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        isProcessing = true
        processingStatus = "Extracting text…"

        Task {
            do {
                var allText = ""
                var imageFileNames: [String] = []

                for (i, image) in images.enumerated() {
                    let fileName = "\(UUID().uuidString).jpg"
                    await MainActor.run {
                        documentStore.saveImage(image, named: fileName)
                        imageFileNames.append(fileName)
                        processingStatus = "Reading page \(i + 1) of \(images.count)…"
                    }
                    let text = try await DocLensAI.shared.extractText(from: image)
                    allText += (allText.isEmpty ? "" : "\n\n") + text
                }

                await MainActor.run { processingStatus = "Analyzing with AI…" }
                let analysis = try await DocLensAI.shared.analyze(text: allText)
                let category = ScannedDocument.DocumentCategory(rawValue: analysis.category) ?? .general

                var doc = ScannedDocument(
                    title: analysis.title,
                    pages: images.count,
                    rawText: allText,
                    summary: analysis.summary,
                    keyPoints: analysis.keyPoints,
                    category: category,
                    imageFileNames: imageFileNames,
                    language: analysis.language
                )

                await MainActor.run {
                    documentStore.save(doc)
                    monthlyCount += 1
                    isProcessing = false
                    processingStatus = ""
                    navigateToDocument = doc
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                    processingStatus = ""
                }
            }
        }
    }
}

// MARK: - VisionKit Scanner Wrapper

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([UIImage]) -> Void
        init(onScan: @escaping ([UIImage]) -> Void) { self.onScan = onScan }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            onScan(images)
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onScan([])
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onScan([])
        }
    }
}
