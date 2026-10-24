import SwiftUI
@preconcurrency import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Palette Officielle Livria Marketplace (Thème Clair / Blanc Dominant comme Livria Store)

public enum MarketplacePalette {
    // Blanc dominant & surfaces très claires ("plus blanc que violet dcp")
    public static let background = Color(red: 0.985, green: 0.985, blue: 0.995) // #FBFBFD
    public static let card = Color.white                                        // #FFFFFF
    public static let cardElevated = Color(red: 0.992, green: 0.992, blue: 1.0)
    public static let border = Color(red: 0.90, green: 0.89, blue: 0.94)        // #E6E3F0

    // Accents identitaires Livria (Violet librairie & Corail/Rose signature)
    public static let primary = Color(red: 0.48, green: 0.25, blue: 0.92)       // #7B40EB
    public static let primaryDark = Color(red: 0.36, green: 0.16, blue: 0.76)   // #5C29C2
    public static let primarySoft = Color(red: 0.95, green: 0.92, blue: 0.99)   // #F2EBFC
    public static let coral = Color(red: 0.93, green: 0.36, blue: 0.65)         // #ED5CA6
    public static let gold = Color(red: 0.95, green: 0.68, blue: 0.12)          // #F2AD1F
    public static let goldSoft = Color(red: 1.00, green: 0.96, blue: 0.86)
    public static let green = Color(red: 0.09, green: 0.64, blue: 0.36)
    public static let upsGold = Color(red: 1.00, green: 0.71, blue: 0.00)
    public static let upsBrown = Color(red: 0.21, green: 0.11, blue: 0.08)

    // Typographie contrastée sur fond blanc
    public static let ink = Color(red: 0.11, green: 0.09, blue: 0.18)           // #1C172E
    public static let inkMuted = Color(red: 0.42, green: 0.40, blue: 0.52)      // #6B6685

    public static let heroGradient = LinearGradient(
        colors: [primary, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let whiteSurfaceGradient = LinearGradient(
        colors: [Color.white, Color(red: 0.98, green: 0.97, blue: 1.0)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Modificateur de Carte Blanche Livria Marketplace

public struct MarketplaceWhiteCardModifier: ViewModifier {
    public var padding: CGFloat = 16
    public var cornerRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(MarketplacePalette.card)
                    .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MarketplacePalette.border, lineWidth: 1)
            )
    }
}

extension View {
    public func marketplaceCard(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(MarketplaceWhiteCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Affichage Image Universel (URL HTTP/HTTPS + Base64 Data URL Locale)

public struct MarketplaceSmartImage: View {
    public let urlString: String?
    public var contentMode: ContentMode = .fill

    public init(urlString: String?, contentMode: ContentMode = .fill) {
        self.urlString = urlString
        self.contentMode = contentMode
    }

    public var body: some View {
        if let raw = urlString, !raw.isEmpty {
            if raw.hasPrefix("data:image"),
               let commaIndex = raw.firstIndex(of: ","),
               let data = Data(base64Encoded: String(raw[raw.index(after: commaIndex)...])) {
                #if canImport(UIKit)
                if let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    placeholderView
                }
                #else
                placeholderView
                #endif
            } else if let resolved = MarketplaceURLResolver.resolveMediaURL(raw),
                      let url = URL(string: resolved) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        placeholderView
                    default:
                        ZStack {
                            MarketplacePalette.primarySoft.opacity(0.55)
                            ProgressView()
                                .tint(MarketplacePalette.primary)
                        }
                    }
                }
            } else {
                placeholderView
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [MarketplacePalette.primarySoft, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MarketplacePalette.primary.opacity(0.6))
                Text("Livria Marketplace")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketplacePalette.inkMuted)
            }
        }
    }
}

// MARK: - Avatar Utilisateur avec Anneau de Niveau Viple Live ID

public struct MarketplaceAvatarRing: View {
    public let avatarUrl: String?
    public let displayName: String
    public let level: Int
    public var size: CGFloat = 44

    public init(avatarUrl: String?, displayName: String, level: Int, size: CGFloat = 44) {
        self.avatarUrl = avatarUrl
        self.displayName = displayName
        self.level = level
        self.size = size
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [MarketplacePalette.primary, MarketplacePalette.coral, MarketplacePalette.gold, MarketplacePalette.primary],
                            center: .center
                        ),
                        lineWidth: max(2.2, size * 0.06)
                    )
                    .frame(width: size, height: size)

                if let avatarUrl, !avatarUrl.isEmpty {
                    MarketplaceSmartImage(urlString: avatarUrl, contentMode: .fill)
                        .frame(width: size - 6, height: size - 6)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(MarketplacePalette.primarySoft)
                        .frame(width: size - 6, height: size - 6)
                        .overlay(
                            Text(String(displayName.prefix(1)).uppercased())
                                .font(.system(size: size * 0.4, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.primary)
                        )
                }
            }

            Text("Niv.\(level)")
                .font(.system(size: max(8, size * 0.19), weight: .black, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(Capsule().fill(MarketplacePalette.primary))
                .foregroundStyle(.white)
                .offset(x: 3, y: 3)
        }
    }
}

// MARK: - Studio Interactif de Recadrage Photo (Profil Viple Live ID & Photos d'Annonces)

#if canImport(UIKit)
public struct MarketplaceImageCropperSheet: View {
    public let image: UIImage
    public var title: String = "Recadrer votre photo"
    public var isCircularMask: Bool = true
    public let onCropped: (Data) -> Void
    public let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 290

    public init(
        image: UIImage,
        title: String = "Recadrer votre photo",
        isCircularMask: Bool = true,
        onCropped: @escaping (Data) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.isCircularMask = isCircularMask
        self.onCropped = onCropped
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text("Pincez pour zoomer et glissez votre doigt pour ajuster le cadrage")
                        .font(.system(size: 12.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 10)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.92))
                        .frame(height: 350)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cropSize, height: cropSize)
                        .scaleEffect(scale)
                        .offset(offset)
                        .clipShape(
                            isCircularMask
                                ? AnyShape(Circle())
                                : AnyShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        )
                        .overlay(
                            Group {
                                if isCircularMask {
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [MarketplacePalette.primary, MarketplacePalette.coral],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3.5
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [MarketplacePalette.primary, MarketplacePalette.coral],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3.5
                                        )
                                }
                            }
                        )
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { val in
                                        scale = min(max(1.0, lastScale * val), 4.5)
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    },
                                DragGesture()
                                    .onChanged { val in
                                        offset = CGSize(
                                            width: lastOffset.width + val.translation.width,
                                            height: lastOffset.height + val.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                }
                .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "minus.magnifyingglass")
                            .foregroundStyle(MarketplacePalette.inkMuted)
                        Slider(value: $scale, in: 1.0...4.5, step: 0.05)
                            .tint(MarketplacePalette.primary)
                            .onChange(of: scale) { _, newValue in
                                lastScale = newValue
                            }
                        Image(systemName: "plus.magnifyingglass")
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    } label: {
                        Label("Réinitialiser le cadrage", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onCancel()
                    } label: {
                        Text("Annuler")
                            .font(.system(size: 14.5, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(MarketplacePalette.border, lineWidth: 1))
                            .foregroundStyle(MarketplacePalette.ink)
                    }

                    Button {
                        if let data = renderCroppedJPEG() {
                            onCropped(data)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crop")
                            Text("Valider le recadrage")
                                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MarketplacePalette.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func renderCroppedJPEG() -> Data? {
        let outputSize = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let cropped = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: outputSize)
            UIColor.white.setFill()
            ctx.fill(rect)

            let imgSize = image.size
            let aspect = max(outputSize.width / max(imgSize.width, 1), outputSize.height / max(imgSize.height, 1))
            let drawW = imgSize.width * aspect * scale
            let drawH = imgSize.height * aspect * scale
            let ratio = outputSize.width / cropSize
            let originX = (outputSize.width - drawW) / 2.0 + (offset.width * ratio)
            let originY = (outputSize.height - drawH) / 2.0 + (offset.height * ratio)
            image.draw(in: CGRect(x: originX, y: originY, width: drawW, height: drawH))
        }
        return cropped.jpegData(compressionQuality: 0.86)
    }
}

// MARK: - Scanner Code-Barres ISBN / Colis Looby Taker (Swift 6 Concurrency Safe)

public struct MarketplaceBarcodeScannerSheet: View {
    public var title: String = "Scanner le code-barres ISBN"
    public var subtitle: String = "Placez le code-barres ISBN-13 au dos de votre livre dans le cadre"
    public let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var manualCode: String = ""

    public init(
        title: String = "Scanner le code-barres ISBN",
        subtitle: String = "Placez le code-barres ISBN-13 au dos de votre livre dans le cadre",
        onScanned: @escaping (String) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onScanned = onScanned
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                ZStack {
                    MarketplaceCameraScannerRepresentable { code in
                        onScanned(code)
                        dismiss()
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(MarketplacePalette.primary, lineWidth: 2.5)
                    )

                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        .frame(width: 220, height: 110)
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ou saisir / simuler un code ISBN :")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(MarketplacePalette.ink)

                    HStack(spacing: 10) {
                        TextField("Ex : 9782070368228", text: $manualCode)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarketplacePalette.border, lineWidth: 1))

                        Button {
                            let code = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
                            onScanned(code.isEmpty ? "9782070368228" : code)
                            dismiss()
                        } label: {
                            Text("Valider")
                                .font(.system(size: 13.5, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primary))
                                .foregroundStyle(.white)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([
                                ("1984 (Orwell)", "9782070368228"),
                                ("L'Étranger (Camus)", "9782253004226"),
                                ("Dune T.1 (Herbert)", "9782266286268")
                            ], id: \.1) { label, isbn in
                                Button {
                                    onScanned(isbn)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "barcode.viewfinder")
                                        Text(label)
                                    }
                                    .font(.system(size: 11.5, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(MarketplacePalette.primarySoft))
                                    .foregroundStyle(MarketplacePalette.primary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

public struct MarketplaceCameraScannerRepresentable: UIViewControllerRepresentable {
    public var onCodeDetected: (String) -> Void

    public func makeUIViewController(context: Context) -> MarketplaceScannerVC {
        let vc = MarketplaceScannerVC()
        vc.onCodeDetected = onCodeDetected
        return vc
    }

    public func updateUIViewController(_ uiViewController: MarketplaceScannerVC, context: Context) {}
}

public final class MarketplaceScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    public var onCodeDetected: ((String) -> Void)?
    private let captureSession = AVCaptureSession()
    private var hasDetected = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            return
        }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .code128, .qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    nonisolated public func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        Task { @MainActor [weak self] in
            guard let self, !self.hasDetected else { return }
            self.hasDetected = true
            self.captureSession.stopRunning()
            self.onCodeDetected?(stringValue)
        }
    }
}
#endif
