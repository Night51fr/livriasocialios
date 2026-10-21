import SwiftUI

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

// MARK: - Logo Officiel « Livria Social » (Identique à l'icône de l'application)

public struct LivriaSocialBrandLogoView: View {
    public var compact: Bool = false

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                    .fill(LivriaSocialPalette.socialHeroGradient)
                    .frame(width: compact ? 32 : 38, height: compact ? 32 : 38)
                    .shadow(color: LivriaSocialPalette.coral.opacity(0.45), radius: 6, x: 0, y: 3)

                Image(systemName: "book.pages.fill")
                    .font(.system(size: compact ? 15 : 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .trailing, spacing: -3) {
                Text("Livria")
                    .font(.system(size: compact ? 20 : 23, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                Text("Social")
                    .font(.system(size: compact ? 10 : 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.gold)
            }
        }
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
