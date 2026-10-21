import SwiftUI

// MARK: - Palette & Thème Personnalisable « Livria Social » (store.livria.social • iOS 18+ / iOS 26+)

public enum LivriaSocialPalette: Sendable {
    public static let primary = Color(red: 0.486, green: 0.302, blue: 1.000)       // #7C4DFF
    public static let primaryDeep = Color(red: 0.329, green: 0.165, blue: 0.788)   // #542AC9
    public static let primarySoft = Color(red: 0.933, green: 0.906, blue: 1.000)   // #EEE7FF
    public static let coral = Color(red: 1.000, green: 0.373, blue: 0.635)         // #FF5FA2
    public static let secondary = Color(red: 1.000, green: 0.373, blue: 0.635)     // #FF5FA2
    public static let coralSoft = Color(red: 1.000, green: 0.910, blue: 0.953)     // #FFE8F3
    public static let accent = Color(red: 0.024, green: 0.714, blue: 0.831)        // #06B6D4
    public static let gold = Color(red: 0.976, green: 0.659, blue: 0.145)          // #F9A825
    public static let goldSoft = Color(red: 1.000, green: 0.957, blue: 0.835)      // #FFF4D5
    public static let mint = Color(red: 0.063, green: 0.725, blue: 0.506)          // #10B981
    public static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)       // #10B981
    public static let background = Color(red: 0.988, green: 0.973, blue: 1.000)    // #FCF8FF
    public static let cardPaper = Color.white
    public static let cardSurface = Color(red: 0.114, green: 0.082, blue: 0.200)   // #1D1533
    public static let ink = Color(red: 0.114, green: 0.082, blue: 0.200)           // #1D1533
    public static let inkMuted = Color(red: 0.435, green: 0.404, blue: 0.529)      // #6F6787
    public static let textMuted = Color(red: 0.680, green: 0.650, blue: 0.790)     // #AEA6C9
    public static let border = Color(red: 0.486, green: 0.302, blue: 1.000).opacity(0.24)

    public static var socialHeroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.486, green: 0.302, blue: 1.000),
                Color(red: 0.850, green: 0.275, blue: 0.650),
                Color(red: 1.000, green: 0.450, blue: 0.420)
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
                Color(red: 1.000, green: 0.820, blue: 0.280),
                Color(red: 0.960, green: 0.580, blue: 0.110)
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
            return LinearGradient(colors: [Color(red: 0.12, green: 0.11, blue: 0.29), Color(red: 0.19, green: 0.06, blue: 0.26), Color(red: 0.06, green: 0.09, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if low.contains("sunset") || low.contains("fff7ed") {
            return LinearGradient(colors: [Color(red: 0.28, green: 0.10, blue: 0.24), Color(red: 0.42, green: 0.14, blue: 0.22), Color(red: 0.14, green: 0.08, blue: 0.20)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if low.contains("emerald") || low.contains("ecfdf5") {
            return LinearGradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.18), Color(red: 0.08, green: 0.16, blue: 0.28), Color(red: 0.06, green: 0.09, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if low.contains("ocean") || low.contains("ecfeff") {
            return LinearGradient(colors: [Color(red: 0.06, green: 0.16, blue: 0.30), Color(red: 0.12, green: 0.10, blue: 0.32), Color(red: 0.05, green: 0.08, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if low.contains("sakura") || low.contains("fff1f2") {
            return LinearGradient(colors: [Color(red: 0.26, green: 0.09, blue: 0.24), Color(red: 0.18, green: 0.10, blue: 0.30), Color(red: 0.09, green: 0.07, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.08, blue: 0.24),
                Color(red: 0.16, green: 0.09, blue: 0.30),
                Color(red: 0.07, green: 0.09, blue: 0.18)
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

// MARK: - En-tête MeshGradient iOS 18+ & iOS 26 Liquid Glass

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
                Color(red: 0.650, green: 0.240, blue: 0.940),
                Color(red: 1.000, green: 0.373, blue: 0.635),
                Color(red: 0.380, green: 0.200, blue: 0.880),
                Color(red: 0.920, green: 0.310, blue: 0.660),
                Color(red: 1.000, green: 0.560, blue: 0.350),
                Color(red: 0.250, green: 0.140, blue: 0.620),
                Color(red: 0.560, green: 0.220, blue: 0.850),
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
                            colors: [LivriaSocialPalette.colorFromHex(accentHex), LivriaSocialPalette.coral, LivriaSocialPalette.gold, LivriaSocialPalette.colorFromHex(accentHex)],
                            center: .center
                        ),
                        lineWidth: 2.5
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
                    .frame(width: size - 6, height: size - 6)
                    .clipShape(Circle())
                } else {
                    fallbackCircle
                        .frame(width: size - 6, height: size - 6)
                }
            }

            Text("Niv.\(level)")
                .font(.system(size: max(8, size * 0.17), weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(Capsule().fill(LivriaSocialPalette.colorFromHex(accentHex)))
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
        .shadow(color: Color.black.opacity(0.14), radius: 5, x: 0, y: 3)
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

// MARK: - Modificateurs de Carte et d'Arrière-Plan Personnalisable

extension View {
    @ViewBuilder
    public func socialCard(cornerRadius: CGFloat = 20, padding: CGFloat = 15, opacity: Double = 0.94) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.14, green: 0.11, blue: 0.27).opacity(opacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LivriaSocialPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 4)
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
                                    .overlay(Color.black.opacity(0.55))
                            } else {
                                LivriaSocialPalette.gradientForPreset(bgValue)
                            }
                        }
                        .ignoresSafeArea()
                    } else {
                        LivriaSocialPalette.gradientForPreset(bgValue).ignoresSafeArea()
                    }
                } else {
                    LivriaSocialPalette.gradientForPreset(bgValue).ignoresSafeArea()
                }
            }
        )
    }
}
