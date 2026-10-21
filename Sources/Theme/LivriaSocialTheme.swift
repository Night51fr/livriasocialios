import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Palette & Design System « Livria Social » (store.livria.social)

public enum LivriaSocialPalette: Sendable {
    public static let primary = Color(red: 0.525, green: 0.325, blue: 1.000)       // #8653FF
    public static let primaryDeep = Color(red: 0.345, green: 0.165, blue: 0.820)   // #582AD1
    public static let primarySoft = Color(red: 0.933, green: 0.906, blue: 1.000)   // #EEE7FF
    public static let coral = Color(red: 1.000, green: 0.365, blue: 0.620)         // #FF5D9E
    public static let secondary = Color(red: 1.000, green: 0.365, blue: 0.620)     // #FF5D9E
    public static let coralSoft = Color(red: 1.000, green: 0.910, blue: 0.953)     // #FFE8F3
    public static let accent = Color(red: 0.110, green: 0.780, blue: 0.920)        // #1CC7EB
    public static let gold = Color(red: 0.992, green: 0.725, blue: 0.157)          // #FDB928
    public static let goldSoft = Color(red: 1.000, green: 0.957, blue: 0.835)      // #FFF4D5
    public static let mint = Color(red: 0.090, green: 0.820, blue: 0.580)          // #17D194
    public static let emerald = Color(red: 0.090, green: 0.820, blue: 0.580)       // #17D194
    public static let background = Color(red: 0.098, green: 0.071, blue: 0.212)    // #191236
    public static let cardPaper = Color.white
    public static let cardSurface = Color(red: 0.165, green: 0.122, blue: 0.325)   // #2A1F53
    public static let ink = Color(red: 0.114, green: 0.082, blue: 0.200)           // #1D1533
    public static let inkMuted = Color(red: 0.435, green: 0.404, blue: 0.529)      // #6F6787
    public static let textMuted = Color(red: 0.780, green: 0.745, blue: 0.895)     // #C7BEE4
    public static let border = Color.white.opacity(0.18)

    public static var socialHeroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.440, green: 0.220, blue: 0.960),
                Color(red: 0.820, green: 0.240, blue: 0.680),
                Color(red: 0.980, green: 0.460, blue: 0.380)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var heroGradient: LinearGradient {
        socialHeroGradient
    }

    public static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [primary, coral],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.000, green: 0.855, blue: 0.320),
                Color(red: 0.975, green: 0.600, blue: 0.120)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static func presetGradient(for key: String) -> LinearGradient {
        gradientForPreset(key)
    }

    public static func colorFromHex(_ hex: String) -> Color {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let rgb = UInt64(cleaned, radix: 16) else {
            return primary
        }
        return Color(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }

    public static func gradientForPreset(_ presetOrValue: String) -> LinearGradient {
        let low = presetOrValue.lowercased()
        if low.contains("cosmic") || low.contains("1e1b4b") {
            return LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.13, blue: 0.44),
                    Color(red: 0.31, green: 0.11, blue: 0.42),
                    Color(red: 0.11, green: 0.12, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if low.contains("sunset") || low.contains("fff7ed") {
            return LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.14, blue: 0.36),
                    Color(red: 0.54, green: 0.18, blue: 0.32),
                    Color(red: 0.20, green: 0.11, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if low.contains("emerald") || low.contains("ecfdf5") {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.29, blue: 0.28),
                    Color(red: 0.14, green: 0.22, blue: 0.40),
                    Color(red: 0.09, green: 0.13, blue: 0.27)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if low.contains("ocean") || low.contains("ecfeff") {
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.24, blue: 0.46),
                    Color(red: 0.20, green: 0.15, blue: 0.46),
                    Color(red: 0.09, green: 0.13, blue: 0.29)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if low.contains("sakura") || low.contains("fff1f2") {
            return LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.14, blue: 0.36),
                    Color(red: 0.28, green: 0.15, blue: 0.45),
                    Color(red: 0.15, green: 0.10, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(red: 0.17, green: 0.11, blue: 0.38),
                Color(red: 0.26, green: 0.13, blue: 0.45),
                Color(red: 0.12, green: 0.11, blue: 0.29)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    public init(hex: String) {
        self = LivriaSocialPalette.colorFromHex(hex)
    }
}

// MARK: - Logo Officiel « Livria Social » (Typographie épurée sans icône bibliothèque)

public struct LivriaSocialBrandLogoView: View {
    public var compact: Bool = false

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: compact ? 5 : 6) {
            Text("Livria")
                .font(.system(size: compact ? 20 : 26, weight: .black, design: .serif))
                .foregroundStyle(.white)
            Text("Social")
                .font(.system(size: compact ? 12 : 14, weight: .heavy, design: .rounded))
                .foregroundStyle(LivriaSocialPalette.gold)
        }
    }
}

// MARK: - Logo Horizontal « Livria Social » (Barre de navigation Accueil — identique à Livria Store)

public struct LivriaSocialHorizontalLogoView: View {
    public var height: CGFloat = 24

    public init(height: CGFloat = 24) {
        self.height = height
    }

    public var body: some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(named: "LivriaSocialLogoHorizontal") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityLabel("Livria Social")
        } else {
            fallbackLogoText
        }
        #else
        fallbackLogoText
        #endif
    }

    private var fallbackLogoText: some View {
        Text("Livria Social")
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 124.0 / 255.0, green: 77.0 / 255.0, blue: 1.0),
                        Color(red: 1.0, green: 95.0 / 255.0, blue: 162.0 / 255.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

// MARK: - Redirection Intelligente d'un Livre vers l'App « Livria Store » (si installée) ou vers le Site Web

@MainActor
public enum LivriaSocialBookLinkOpener {
    public static func openBook(bookId: Int? = nil, storeUrl: String = "") {
        var resolvedId: Int = bookId ?? 0
        let trimmedUrl = storeUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        if resolvedId <= 0, !trimmedUrl.isEmpty, let parsedUrl = URL(string: trimmedUrl) {
            let parts = parsedUrl.pathComponents.filter { $0 != "/" }
            if let idx = parts.firstIndex(where: {
                let p = $0.lowercased()
                return p == "livre" || p == "book" || p == "books"
            }), parts.count > idx + 1, let id = Int(parts[idx + 1]) {
                resolvedId = id
            } else if let last = parts.last, let id = Int(last) {
                resolvedId = id
            }
        }

        let fallbackWebString: String
        if !trimmedUrl.isEmpty {
            if trimmedUrl.hasPrefix("http://") || trimmedUrl.hasPrefix("https://") {
                fallbackWebString = trimmedUrl
            } else {
                fallbackWebString = "https://livria.store\(trimmedUrl.hasPrefix("/") ? "" : "/")\(trimmedUrl)"
            }
        } else if resolvedId > 0 {
            fallbackWebString = "https://livria.store/livre/\(resolvedId)"
        } else {
            fallbackWebString = "https://livria.store"
        }

        #if canImport(UIKit)
        if resolvedId > 0 {
            var comps = URLComponents(string: "livriastore://book/\(resolvedId)")
            let defaults = UserDefaults.standard
            let savedUid = defaults.integer(forKey: "livria.social.ios.authUserId.v2")
            let savedEmail = defaults.string(forKey: "livria.social.ios.authEmail.v2") ?? ""
            let savedName = defaults.string(forKey: "livria.social.ios.authDisplayName.v2") ?? ""
            let savedAvatar = defaults.string(forKey: "livria.social.ios.authAvatarUrl.v2") ?? ""
            if savedUid > 0 && !savedEmail.isEmpty && !savedEmail.lowercased().hasSuffix("@guest.livria.store") {
                comps?.queryItems = [
                    URLQueryItem(name: "ssoUid", value: String(savedUid)),
                    URLQueryItem(name: "ssoEmail", value: savedEmail),
                    URLQueryItem(name: "ssoName", value: savedName.isEmpty ? "Lecteur Viple" : savedName),
                    URLQueryItem(name: "ssoAvatar", value: savedAvatar),
                    URLQueryItem(name: "ssoSource", value: "Livria Social")
                ]
            }
            if let appDeepLink = comps?.url ?? URL(string: "livriastore://book/\(resolvedId)") {
                UIApplication.shared.open(appDeepLink, options: [:]) { opened in
                    if !opened, let webUrl = URL(string: fallbackWebString) {
                        UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                    }
                }
            }
        } else if let webUrl = URL(string: fallbackWebString) {
            UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
        }
        #endif
    }
}

// MARK: - Sélecteur d'Onglets Animé en Pilules (Remplace les Pickers gris par un design coloré)

public struct SocialSegmentedPillBar: View {
    public let items: [(tag: Int, title: String, icon: String)]
    @Binding public var selection: Int

    public init(items: [(tag: Int, title: String, icon: String)], selection: Binding<Int>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.tag) { item in
                let isSelected = selection == item.tag
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        selection = item.tag
                    }
                } label: {
                    HStack(spacing: 5) {
                        if !item.icon.isEmpty {
                            Image(systemName: item.icon)
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                isSelected
                                    ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.06))
                            )
                    )
                    .foregroundStyle(isSelected ? .white : LivriaSocialPalette.textMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.24))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LivriaSocialPalette.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - En-tête MeshGradient Lumineux

public struct SocialMeshHeaderBackground: View {
    public init() {}

    public var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0),
                .init(0.0, 0.5), .init(0.55, 0.45), .init(1.0, 0.5),
                .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)
            ],
            colors: [
                Color(red: 0.486, green: 0.302, blue: 1.000),
                Color(red: 0.680, green: 0.240, blue: 0.960),
                Color(red: 1.000, green: 0.373, blue: 0.635),
                Color(red: 0.380, green: 0.200, blue: 0.880),
                Color(red: 0.920, green: 0.310, blue: 0.660),
                Color(red: 1.000, green: 0.560, blue: 0.350),
                Color(red: 0.280, green: 0.160, blue: 0.680),
                Color(red: 0.600, green: 0.240, blue: 0.880),
                Color(red: 0.960, green: 0.380, blue: 0.580)
            ]
        )
    }
}

// MARK: - Avatar avec Anneau XP Coloré

public struct SocialAvatarRingView: View {
    public let avatarUrl: String?
    public let displayName: String
    public let level: Int
    public let accentHex: String
    public var size: CGFloat = 46

    public init(avatarUrl: String?, displayName: String, level: Int = 1, accentHex: String = "#7c4dff", size: CGFloat = 46) {
        self.avatarUrl = avatarUrl
        self.displayName = displayName
        self.level = level
        self.accentHex = accentHex
        self.size = size
    }

    public init(name: String, avatarUrl: String?, level: Int = 1, accentHex: String = "#7c4dff", size: CGFloat = 46) {
        self.avatarUrl = avatarUrl
        self.displayName = name
        self.level = level
        self.accentHex = accentHex
        self.size = size
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                LivriaSocialPalette.colorFromHex(accentHex),
                                LivriaSocialPalette.coral,
                                LivriaSocialPalette.gold,
                                LivriaSocialPalette.colorFromHex(accentHex)
                            ],
                            center: .center
                        ),
                        lineWidth: 2.8
                    )
                    .frame(width: size, height: size)

                if let raw = avatarUrl, !raw.isEmpty, let url = URL(string: raw.hasPrefix("http") ? raw : "https://livriasocial.viplenetwork.com\(raw)") {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            fallbackCircle
                        }
                    }
                    .frame(width: size - 7, height: size - 7)
                    .clipShape(Circle())
                } else {
                    fallbackCircle
                        .frame(width: size - 7, height: size - 7)
                }
            }

            Text("Niv.\(level)")
                .font(.system(size: max(8.5, size * 0.17), weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 1.5)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [LivriaSocialPalette.colorFromHex(accentHex), LivriaSocialPalette.coral], startPoint: .leading, endPoint: .trailing))
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .offset(x: 2, y: 3)
        }
    }

    private var fallbackCircle: some View {
        Circle()
            .fill(LivriaSocialPalette.socialHeroGradient)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            )
    }
}

// MARK: - Couverture de Livre avec Lien Boutique

public struct SocialBookCoverView: View {
    public let coverUrl: String
    public let title: String
    public var width: CGFloat = 68
    public var height: CGFloat = 98
    public var cornerRadius: CGFloat = 10

    public init(coverUrl: String, title: String, width: CGFloat = 68, height: CGFloat = 98, cornerRadius: CGFloat = 10) {
        self.coverUrl = coverUrl
        self.title = title
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public init(title: String, imageUrl: String, width: CGFloat = 68, height: CGFloat = 98, cornerRadius: CGFloat = 10) {
        self.coverUrl = imageUrl
        self.title = title
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    private var resolvedURL: URL? {
        if coverUrl.isEmpty { return nil }
        if coverUrl.hasPrefix("http") { return URL(string: coverUrl) }
        return URL(string: "https://livria.store\(coverUrl.hasPrefix("/") ? "" : "/")\(coverUrl)")
    }

    public var body: some View {
        Group {
            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
    }

    private var placeholder: some View {
        ZStack {
            LivriaSocialPalette.socialHeroGradient
            VStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Modificateurs de Carte Verre Lumineuse & Arrière-Plan Dynamique

extension View {
    @ViewBuilder
    public func socialCard(cornerRadius: CGFloat = 22, padding: CGFloat = 16, opacity: Double = 0.92) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.21, green: 0.15, blue: 0.39).opacity(opacity),
                                    Color(red: 0.14, green: 0.10, blue: 0.28).opacity(opacity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    LivriaSocialPalette.primary.opacity(0.25),
                                    LivriaSocialPalette.coral.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.26), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    public func socialCustomBackground(type: String?, value: String?) -> some View {
        self.socialCustomBackground(bgType: type ?? "preset", bgValue: value ?? "")
    }

    @ViewBuilder
    public func socialCustomBackground(bgType: String = "preset", bgValue: String = "") -> some View {
        self.background(
            ZStack {
                if bgType == "image" || bgValue.lowercased().contains("url(") || bgValue.lowercased().hasPrefix("http") {
                    let cleanUrl = bgValue
                        .replacingOccurrences(of: "url('", with: "")
                        .replacingOccurrences(of: "')", with: "")
                        .replacingOccurrences(of: "url(\"", with: "")
                        .replacingOccurrences(of: "\")", with: "")
                        .replacingOccurrences(of: "url(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                    if let url = URL(string: cleanUrl) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                                    .overlay(Color.black.opacity(0.48))
                            } else {
                                LivriaSocialPalette.gradientForPreset(bgValue)
                            }
                        }
                        .ignoresSafeArea()
                    } else {
                        LivriaSocialPalette.gradientForPreset(bgValue).ignoresSafeArea()
                    }
                } else {
                    ZStack {
                        LivriaSocialPalette.gradientForPreset(bgValue)
                            .ignoresSafeArea()

                        // Halos lumineux décoratifs pour un rendu chaleureux et vivant
                        Circle()
                            .fill(LivriaSocialPalette.primary.opacity(0.22))
                            .frame(width: 280, height: 280)
                            .blur(radius: 65)
                            .offset(x: -110, y: -220)

                        Circle()
                            .fill(LivriaSocialPalette.coral.opacity(0.18))
                            .frame(width: 260, height: 260)
                            .blur(radius: 65)
                            .offset(x: 130, y: 180)
                    }
                    .ignoresSafeArea()
                }
            }
        )
    }
}

// MARK: - Menu de Recherche Visuel avec Couvertures pour Choisir un Livre Livria

public struct SocialBookPickerSheetView: View {
    @Environment(\.dismiss) private var dismiss

    public let books: [SocialBookItem]
    @Binding public var selectedBookId: Int
    public var title: String

    @State private var searchText: String = ""
    @State private var selectedGenre: String = "Tous"
    @State private var useGridMode: Bool = true

    public init(
        books: [SocialBookItem],
        selectedBookId: Binding<Int>,
        title: String = "Choisir un livre Livria"
    ) {
        self.books = books
        self._selectedBookId = selectedBookId
        self.title = title
    }

    private var availableGenres: [String] {
        var seen = Set<String>()
        var result: [String] = ["Tous"]
        for book in books {
            let g = book.genre.trimmingCharacters(in: .whitespacesAndNewlines)
            if !g.isEmpty && !seen.contains(g) {
                seen.insert(g)
                result.append(g)
            }
        }
        return result
    }

    private var filteredBooks: [SocialBookItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return books.filter { book in
            let matchesGenre = (selectedGenre == "Tous") || (book.genre.caseInsensitiveCompare(selectedGenre) == .orderedSame)
            guard matchesGenre else { return false }
            if q.isEmpty { return true }
            return book.title.localizedCaseInsensitiveContains(q)
                || book.author.localizedCaseInsensitiveContains(q)
                || book.genre.localizedCaseInsensitiveContains(q)
                || book.isbn.localizedCaseInsensitiveContains(q)
        }
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Barre de recherche + bascule Grille / Liste
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(LivriaSocialPalette.gold)
                        TextField("Rechercher un titre, un auteur, un genre...", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                            .font(.system(size: 14))

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(LivriaSocialPalette.border, lineWidth: 1)
                            )
                    )

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            useGridMode.toggle()
                        }
                    } label: {
                        Image(systemName: useGridMode ? "list.bullet" : "square.grid.2x2.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Filtres rapides par genre
                if availableGenres.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableGenres, id: \.self) { genre in
                                let active = selectedGenre == genre
                                Button {
                                    withAnimation {
                                        selectedGenre = genre
                                    }
                                } label: {
                                    Text(genre)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(active ? .white : LivriaSocialPalette.textMuted)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    active
                                                        ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                                        : AnyShapeStyle(Color.white.opacity(0.07))
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Résultats avec les couvertures des livres
                ScrollView {
                    if filteredBooks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(LivriaSocialPalette.gold)
                            Text("Aucun livre ne correspond à votre recherche")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Essayez un autre titre, nom d'auteur ou réinitialisez les filtres.")
                                .font(.system(size: 13))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .multilineTextAlignment(.center)
                            if !searchText.isEmpty || selectedGenre != "Tous" {
                                Button {
                                    searchText = ""
                                    selectedGenre = "Tous"
                                } label: {
                                    Text("Tout afficher")
                                        .font(.system(size: 13, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 9)
                                        .background(Capsule().fill(LivriaSocialPalette.primary))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                    } else if useGridMode {
                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            ForEach(filteredBooks) { book in
                                bookGridCard(book)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredBooks) { book in
                                bookListRow(book)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .socialCustomBackground(bgType: "preset", bgValue: "aurora")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                if selectedBookId > 0 {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Retirer") {
                            selectedBookId = 0
                            dismiss()
                        }
                        .foregroundStyle(LivriaSocialPalette.coral)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bookGridCard(_ book: SocialBookItem) -> some View {
        let isSelected = selectedBookId == book.id
        return Button {
            selectedBookId = book.id
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    HStack {
                        Spacer()
                        SocialBookCoverView(
                            coverUrl: book.coverUrl,
                            title: book.title,
                            width: 112,
                            height: 160,
                            cornerRadius: 12
                        )
                        Spacer()
                    }
                    .padding(.top, 6)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.mint)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .padding(6)
                    }
                }

                Text(book.title)
                    .font(.system(size: 13.5, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(book.author)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
                    .lineLimit(1)

                HStack {
                    Text(String(format: "%.2f €", book.price))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LivriaSocialPalette.gold)

                    Spacer()

                    Text(isSelected ? "Choisi ✓" : "Choisir")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                isSelected
                                    ? AnyShapeStyle(LivriaSocialPalette.mint)
                                    : AnyShapeStyle(LivriaSocialPalette.brandGradient)
                            )
                        )
                        .foregroundStyle(isSelected ? .black : .white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.14 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isSelected ? LivriaSocialPalette.mint : Color.white.opacity(0.16),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func bookListRow(_ book: SocialBookItem) -> some View {
        let isSelected = selectedBookId == book.id
        return Button {
            selectedBookId = book.id
            dismiss()
        } label: {
            HStack(spacing: 12) {
                SocialBookCoverView(
                    coverUrl: book.coverUrl,
                    title: book.title,
                    width: 62,
                    height: 90,
                    cornerRadius: 10
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 14.5, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("par \(book.author)")
                        .font(.system(size: 12))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(String(format: "%.2f €", book.price))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LivriaSocialPalette.gold)

                        if !book.genre.isEmpty {
                            Text(book.genre)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white.opacity(0.10)))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }

                Spacer()

                Text(isSelected ? "Choisi ✓" : "Choisir")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            isSelected
                                ? AnyShapeStyle(LivriaSocialPalette.mint)
                                : AnyShapeStyle(LivriaSocialPalette.brandGradient)
                        )
                    )
                    .foregroundStyle(isSelected ? .black : .white)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.14 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? LivriaSocialPalette.mint : Color.white.opacity(0.16),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Carte Bouton Réutilisable pour Ouvrir le Sélecteur de Livre avec Couverture

public struct SocialBookPickerButtonCard: View {
    public let books: [SocialBookItem]
    @Binding public var selectedBookId: Int
    public var placeholderTitle: String = "Choisir un livre Livria"
    public var placeholderSubtitle: String = "Recherche par titre ou auteur avec aperçu des couvertures"

    @State private var isShowingSheet: Bool = false

    public init(
        books: [SocialBookItem],
        selectedBookId: Binding<Int>,
        placeholderTitle: String = "Choisir un livre Livria",
        placeholderSubtitle: String = "Recherche par titre ou auteur avec aperçu des couvertures"
    ) {
        self.books = books
        self._selectedBookId = selectedBookId
        self.placeholderTitle = placeholderTitle
        self.placeholderSubtitle = placeholderSubtitle
    }

    private var selectedBook: SocialBookItem? {
        books.first(where: { $0.id == selectedBookId })
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let book = selectedBook {
                HStack(spacing: 12) {
                    SocialBookCoverView(
                        coverUrl: book.coverUrl,
                        title: book.title,
                        width: 64,
                        height: 94,
                        cornerRadius: 10
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIVRE SÉLECTIONNÉ")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LivriaSocialPalette.mint)

                        Text(book.title)
                            .font(.system(size: 14.5, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text("par \(book.author)")
                            .font(.system(size: 12))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                            .lineLimit(1)

                        Text(String(format: "%.2f € • %@", book.price, book.availabilityBadge))
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(LivriaSocialPalette.gold)
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Button {
                            isShowingSheet = true
                        } label: {
                            Label("Changer", systemImage: "magnifyingglass")
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(LivriaSocialPalette.primary))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            selectedBookId = 0
                        } label: {
                            Label("Retirer", systemImage: "xmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LivriaSocialPalette.coral)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(LivriaSocialPalette.mint.opacity(0.6), lineWidth: 1.5)
                        )
                )
            } else {
                Button {
                    isShowingSheet = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LivriaSocialPalette.brandGradient)
                                .frame(width: 52, height: 52)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(placeholderTitle)
                                .font(.system(size: 14.5, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text(placeholderSubtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .lineLimit(2)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("Parcourir")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                        .foregroundStyle(LivriaSocialPalette.ink)
                    }
                    .padding(13)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(LivriaSocialPalette.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            SocialBookPickerSheetView(
                books: books,
                selectedBookId: $selectedBookId,
                title: placeholderTitle
            )
        }
    }
}
