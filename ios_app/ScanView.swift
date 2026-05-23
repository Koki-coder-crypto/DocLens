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
    @State private var orbScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ambientGlow

                VStack(spacing: 0) {
                    topBar.padding(.top, 60)
                    Spacer()

                    if isProcessing {
                        processingOrb
                    } else {
                        heroOrb
                            .onTapGesture { checkLimitAndRun { showScanner = true } }
                    }

                    Spacer()

                    if !isProcessing {
                        actionButtons.padding(.horizontal, 24).padding(.bottom, 28)
                    }

                    if !store.isPro {
                        freeFooter.padding(.bottom, 100)
                    } else {
                        Spacer().frame(height: 100)
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
            .navigationDestination(item: $navigateToDocument) { DocumentDetailView(document: $0) }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { orbScale = 1.06 }
        }
    }

    // MARK: - Components

    private var ambientGlow: some View {
        ZStack {
            Ellipse().fill(Color.appAccent.opacity(0.1)).frame(width: 300, height: 250)
                .blur(radius: 70).offset(y: -80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            Text("DocLens")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Color.appAccent, Color(hex: "60A5FA")],
                                                startPoint: .leading, endPoint: .trailing))
            Spacer()
            if !store.isPro {
                Button { showPaywall = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "crown.fill").font(.system(size: 10))
                            .foregroundStyle(Color(hex: "F59E0B"))
                        Text("Pro").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private var heroOrb: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.06)).frame(width: 200, height: 200)
                    .scaleEffect(orbScale)
                Circle().fill(Color.appAccent.opacity(0.1)).frame(width: 160, height: 160)
                Circle().fill(RadialGradient(
                    colors: [Color.appAccent.opacity(0.2), Color.appAccent.opacity(0.04)],
                    center: .center, startRadius: 0, endRadius: 65
                )).frame(width: 120, height: 120)
                Image(systemName: "doc.viewfinder.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(LinearGradient(colors: [Color.appAccent, Color(hex: "60A5FA")],
                                                    startPoint: .top, endPoint: .bottom))
            }

            VStack(spacing: 8) {
                Text("Scan Any Document")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Text("Point at a document — AI extracts text\nand creates an instant summary")
                    .font(.system(size: 15)).foregroundStyle(Color.appMuted)
                    .multilineTextAlignment(.center).lineSpacing(3)
            }
        }
    }

    private var processingOrb: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.1)).frame(width: 140, height: 140)
                Circle().stroke(Color.appAccent.opacity(0.2), lineWidth: 2).frame(width: 120, height: 120)
                Circle().trim(from: 0, to: 0.65)
                    .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(isProcessing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isProcessing)
                Image(systemName: "waveform").font(.system(size: 32)).foregroundStyle(Color.appAccent)
                    .symbolEffect(.pulse, isActive: true)
            }
            Text(processingStatus)
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Color.appMuted)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { checkLimitAndRun { showScanner = true } } label: {
                Label("Scan with Camera", systemImage: "camera.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(GradientButtonStyle())

            Button { checkLimitAndRun { showPhotoPicker = true } } label: {
                Label("Import from Photos", systemImage: "photo.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(GradientButtonStyle(
                colors: [Color(hex: "A78BFA"), Color(hex: "7C3AED")]
            ))
        }
    }

    private var freeFooter: some View {
        let remaining = max(0, StoreManager.freeScansPerMonth - monthlyCount)
        return HStack(spacing: 8) {
            Image(systemName: "sparkles").font(.system(size: 12)).foregroundStyle(Color(hex: "F39C12"))
            Text("\(remaining) free scans left this month")
                .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.appMuted)
            Spacer()
            Button("Upgrade") { showPaywall = true }
                .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.appAccent)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Logic

    private func checkLimitAndRun(_ action: () -> Void) {
        if !store.isPro && monthlyCount >= StoreManager.freeScansPerMonth { showPaywall = true }
        else { action() }
    }

    private func processImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        isProcessing = true; processingStatus = "Extracting text…"

        Task {
            do {
                var allText = ""; var imageFileNames: [String] = []
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
                let doc = ScannedDocument(title: analysis.title, pages: images.count, rawText: allText,
                                          summary: analysis.summary, keyPoints: analysis.keyPoints,
                                          category: category, imageFileNames: imageFileNames, language: analysis.language)
                await MainActor.run {
                    documentStore.save(doc); monthlyCount += 1
                    isProcessing = false; processingStatus = ""; navigateToDocument = doc
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isProcessing = false; processingStatus = "" }
            }
        }
    }
}

// MARK: - VisionKit Scanner (unchanged)

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: ([UIImage]) -> Void
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController(); vc.delegate = context.coordinator; return vc
    }
    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([UIImage]) -> Void
        init(onScan: @escaping ([UIImage]) -> Void) { self.onScan = onScan }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            onScan((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }
        func documentCameraViewControllerDidCancel(_ c: VNDocumentCameraViewController) { onScan([]) }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFailWithError e: Error) { onScan([]) }
    }
}
