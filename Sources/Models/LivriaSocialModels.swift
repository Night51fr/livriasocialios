import Foundation

// MARK: - Configuration Officielle de l'Application « Livria Social » (Bundle ID : store.livria.social • iOS 18+ / iOS 26+)

public enum LivriaSocialAppConfig: Sendable {
    public static let appName = "Livria Social"
    public static let bundleIdentifier = "store.livria.social"
    public static let signingOrganization = "Viple"
    public static let minimumIOSVersion = "18.0"
    public static let enhancedIOSVersion = "26.0"

    public static let socialWebBaseURL = "https://livriasocial.viplenetwork.com"
    public static let storeWebBaseURL = "https://livria.store"
    public static let myLivriaWebBaseURL = "https://my.livria.store"
}

// MARK: - Modèles de Données Codable & Sendable 100% Concurrency-Safe (Swift 6)

public struct SocialBootstrapResponse: Codable, Sendable {
    public var ok: Bool
    public var user: SocialUserProfile
    public var posts: [SocialFeedPost]
    public var lists: [SocialBookListModel]
    public var myLists: [SocialBookListModel]
    public var conversations: [SocialConversationSummary]
    public var topMembers: [SocialMemberSummary]
    public var booksCatalog: [SocialBookItem]
    public var backgroundPresets: [SocialBackgroundPreset]
    public var games: SocialGamesState
}

public struct SocialAuthResponse: Codable, Sendable {
    public var ok: Bool
    public var error: String?
    public var token: String?
    public var user: SocialUserProfile?
}

public struct SocialUserProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var email: String
    public var displayName: String
    public var bio: String
    public var motto: String
    public var accentColor: String
    public var favoriteGenres: String
    public var avatarUrl: String
    public var profileBorder: String
    public var xp: Int
    public var level: Int
    public var xpInLevel: Int
    public var isLivriaPlus: Bool
    public var loyaltyPoints: Int
    public var cashbackBalance: Double
    public var affiliateEarnings: Double
    public var pageBackgroundType: String
    public var pageBackgroundValue: String
    public var cardStyle: String
    public var cardOpacity: Int
    public var bannerUrl: String
    public var customTitleBadge: String

    // Propriétés calculées de compatibilité pour les vues
    public var xpPoints: Int { xp }
    public var affiliateBalanceEur: Double { affiliateEarnings + cashbackBalance }
    public var handle: String {
        let base = email.split(separator: "@").first.map(String.init)
            ?? displayName.lowercased().replacingOccurrences(of: " ", with: "")
        return "@\(base.isEmpty ? "lecteur" : base)"
    }
}

public struct SocialMemberSummary: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: Int
    public var displayName: String
    public var email: String?
    public var bio: String
    public var motto: String
    public var favoriteGenres: String
    public var accentColor: String
    public var avatarUrl: String
    public var xp: Int
    public var level: Int
    public var isLivriaPlus: Bool
    public var profileUrl: String

    public var handle: String {
        let base = email?.split(separator: "@").first.map(String.init)
            ?? displayName.lowercased().replacingOccurrences(of: " ", with: "")
        return "@\(base.isEmpty ? "lecteur" : base)"
    }
}

public struct SocialBookItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: Int
    public var isbn: String
    public var title: String
    public var author: String
    public var genre: String
    public var description: String
    public var coverUrl: String
    public var price: Double
    public var newPrice: Double
    public var usedPrice: Double?
    public var availabilityBadge: String
    public var storeUrl: String

    public var priceTtc: Double { price }
}

public struct SocialSharedListSummary: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var description: String
    public var themeEmoji: String
    public var themeGradient: String
    public var salesCount: Int
    public var totalEarned: Double
}

public struct SocialPostCommentItem: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var postId: Int
    public var userId: Int
    public var authorName: String
    public var authorAvatar: String
    public var authorAccent: String
    public var content: String
    public var createdAt: String
}

public struct SocialFeedPost: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var userId: Int
    public var postType: String
    public var content: String
    public var mediaUrl: String
    public var mediaType: String
    public var bookId: Int?
    public var bookListId: Int?
    public var moodBadge: String
    public var likesCount: Int
    public var fireCount: Int
    public var bookLoveCount: Int
    public var clapCount: Int
    public var commentsCount: Int
    public var createdAt: String
    public var author: SocialMemberSummary
    public var recommendedBook: SocialBookItem?
    public var sharedList: SocialSharedListSummary?
    public var comments: [SocialPostCommentItem]
}

public struct SocialBookListEntry: Codable, Identifiable, Equatable, Sendable {
    public var itemId: Int
    public var curatorNote: String
    public var book: SocialBookItem

    public var id: Int { itemId }
    public var bookTitle: String { book.title }
    public var coverUrl: String { book.coverUrl }
    public var priceTtc: Double { book.price }
    public var storeUrl: String { book.storeUrl }
}

public struct SocialBookListModel: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var userId: Int
    public var title: String
    public var description: String
    public var themeEmoji: String
    public var themeGradient: String
    public var viewsCount: Int
    public var salesCount: Int
    public var totalEarned: Double
    public var createdAt: String
    public var myLivriaUrl: String
    public var creator: SocialMemberSummary
    public var books: [SocialBookListEntry]

    public var items: [SocialBookListEntry] { books }
    public var booksCount: Int { books.count }
    public var isMonetized: Bool { true }
    public var creatorName: String { creator.displayName }
    public var creatorHandle: String { creator.handle }
    public var estimatedEarningsEur: Double { totalEarned }
    public var shareUrl: String {
        myLivriaUrl.isEmpty ? "https://my.livria.store/listes/\(id)" : myLivriaUrl
    }
}

public struct SocialConversationSummary: Codable, Identifiable, Equatable, Sendable {
    public var id: Int { otherUser.id }
    public var otherUser: SocialMemberSummary
    public var lastPreview: String
    public var lastSentAt: String
    public var unreadCount: Int

    public var userId: Int { otherUser.id }
    public var displayName: String { otherUser.displayName }
    public var handle: String { otherUser.handle }
    public var avatarUrl: String { otherUser.avatarUrl }
    public var accentColor: String { otherUser.accentColor }
    public var lastMessagePreview: String { lastPreview }
}

public struct SocialRichMessageItem: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var senderId: Int
    public var recipientId: Int
    public var isFromMe: Bool
    public var body: String
    public var attachmentType: String
    public var attachmentUrl: String
    public var attachmentTitle: String
    public var attachmentMeta: String
    public var bookId: Int?
    public var voiceDurationSec: Int
    public var isRead: Bool
    public var sentAt: String

    public var isMine: Bool { isFromMe }

    enum CodingKeys: String, CodingKey {
        case id, senderId, recipientId, isFromMe, body, attachmentType
        case attachmentUrl, attachmentTitle, attachmentMeta
        case bookId, voiceDurationSec, isRead, sentAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        senderId = try c.decode(Int.self, forKey: .senderId)
        recipientId = try c.decode(Int.self, forKey: .recipientId)
        isFromMe = (try? c.decode(Bool.self, forKey: .isFromMe)) ?? false
        body = (try? c.decode(String.self, forKey: .body)) ?? ""
        attachmentType = (try? c.decode(String.self, forKey: .attachmentType)) ?? "none"
        attachmentUrl = (try? c.decodeIfPresent(String.self, forKey: .attachmentUrl)) ?? ""
        attachmentTitle = (try? c.decodeIfPresent(String.self, forKey: .attachmentTitle)) ?? ""
        attachmentMeta = (try? c.decodeIfPresent(String.self, forKey: .attachmentMeta)) ?? ""
        bookId = try? c.decodeIfPresent(Int.self, forKey: .bookId)
        voiceDurationSec = (try? c.decode(Int.self, forKey: .voiceDurationSec)) ?? 0
        isRead = (try? c.decode(Bool.self, forKey: .isRead)) ?? true
        sentAt = (try? c.decode(String.self, forKey: .sentAt)) ?? ""
    }
}

public struct SocialThreadResponse: Codable, Sendable {
    public var ok: Bool
    public var otherUser: SocialMemberSummary
    public var messages: [SocialRichMessageItem]
}

public struct SocialMemberPublicProfileResponse: Codable, Sendable {
    public var ok: Bool
    public var user: SocialUserProfile
    public var booksReadCount: Int
    public var postsCount: Int
    public var listsCount: Int
    public var posts: [SocialFeedPost]
    public var lists: [SocialBookListModel]
    public var readBooks: [SocialBookItem]

    public var member: SocialUserProfile { user }
}

public struct SocialMemberSearchResponse: Codable, Sendable {
    public var ok: Bool
    public var members: [SocialMemberSummary]
}

public struct SocialBackgroundPreset: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var emoji: String
    public var cssValue: String

    public var key: String { id }
    public var label: String { "\(emoji) \(name)" }
}

public struct SocialGamesState: Codable, Equatable, Sendable {
    public var streakDays: Int
    public var canClaimDaily: Bool
    public var canSpinWheel: Bool
    public var xp: Int
    public var level: Int
    public var xpInLevel: Int
    public var loyaltyPoints: Int
    public var cashbackBalance: Double
    public var affiliateEarnings: Double

    public var xpPoints: Int { xp }
    public var dailyStreak: Int { streakDays }
    public var affiliateBalanceEur: Double { affiliateEarnings + cashbackBalance }

    enum CodingKeys: String, CodingKey {
        case streakDays, canClaimDaily, canSpinWheel, xp, level, xpInLevel, loyaltyPoints, cashbackBalance, affiliateEarnings
    }

    public init(
        streakDays: Int = 1,
        canClaimDaily: Bool = true,
        canSpinWheel: Bool = true,
        xp: Int = 100,
        level: Int = 1,
        xpInLevel: Int = 0,
        loyaltyPoints: Int = 0,
        cashbackBalance: Double = 0,
        affiliateEarnings: Double = 0
    ) {
        self.streakDays = streakDays
        self.canClaimDaily = canClaimDaily
        self.canSpinWheel = canSpinWheel
        self.xp = xp
        self.level = level
        self.xpInLevel = xpInLevel
        self.loyaltyPoints = loyaltyPoints
        self.cashbackBalance = cashbackBalance
        self.affiliateEarnings = affiliateEarnings
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        streakDays = (try? c.decode(Int.self, forKey: .streakDays)) ?? 1
        canClaimDaily = (try? c.decode(Bool.self, forKey: .canClaimDaily)) ?? true
        canSpinWheel = (try? c.decode(Bool.self, forKey: .canSpinWheel)) ?? true
        xp = (try? c.decode(Int.self, forKey: .xp)) ?? 100
        level = (try? c.decode(Int.self, forKey: .level)) ?? 1
        xpInLevel = (try? c.decode(Int.self, forKey: .xpInLevel)) ?? 0
        loyaltyPoints = (try? c.decode(Int.self, forKey: .loyaltyPoints)) ?? 0
        cashbackBalance = (try? c.decode(Double.self, forKey: .cashbackBalance)) ?? 0
        affiliateEarnings = (try? c.decode(Double.self, forKey: .affiliateEarnings)) ?? 0
    }
}

// MARK: - Jeux Littéraires de Livria (Quiz Culturel & Mot Mystère — 100% Sendable)

public struct SocialQuizQuestionItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let question: String
    public let options: [String]
    public let correctIndex: Int
    public let explanation: String
    public let xpReward: Int

    public var aneckdote: String { explanation }

    public init(id: UUID = UUID(), question: String, options: [String], correctIndex: Int, explanation: String, xpReward: Int) {
        self.id = id
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.xpReward = xpReward
    }

    public static let sampleQuestions: [SocialQuizQuestionItem] = [
        SocialQuizQuestionItem(
            question: "Qui a écrit « Les Misérables » et « Notre-Dame de Paris » ?",
            options: ["Honoré de Balzac", "Victor Hugo", "Émile Zola", "Gustave Flaubert"],
            correctIndex: 1,
            explanation: "Victor Hugo a publié Notre-Dame de Paris en 1831 et Les Misérables en 1862.",
            xpReward: 25
        ),
        SocialQuizQuestionItem(
            question: "Dans quelle œuvre d'Antoine de Saint-Exupéry rencontre-t-on un renard qui demande à être apprivoisé ?",
            options: ["Vol de nuit", "Terre des hommes", "Le Petit Prince", "Pilote de guerre"],
            correctIndex: 2,
            explanation: "« On ne voit bien qu'avec le cœur. L'essentiel est invisible pour les yeux. » — Le Petit Prince (1943).",
            xpReward: 25
        ),
        SocialQuizQuestionItem(
            question: "Quel détective belge créé par Agatha Christie résout l'affaire du « Crime de l'Orient-Express » ?",
            options: ["Sherlock Holmes", "Hercule Poirot", "Jules Maigret", "Arsène Lupin"],
            correctIndex: 1,
            explanation: "Hercule Poirot mène l'enquête à bord du célèbre train bloqué par la neige.",
            xpReward: 30
        ),
        SocialQuizQuestionItem(
            question: "Sur quelle planète désertique se déroule l'intrigue principale du roman « Dune » de Frank Herbert ?",
            options: ["Caladan", "Arrakis", "Tatooine", "Trantor"],
            correctIndex: 1,
            explanation: "Arrakis, surnommée Dune, est l'unique source de l'Épice de longue vie.",
            xpReward: 30
        ),
        SocialQuizQuestionItem(
            question: "Quel écrivain français est l'auteur du « Comte de Monte-Cristo » et des « Trois Mousquetaires » ?",
            options: ["Alexandre Dumas", "Jules Verne", "Stendhal", "Guy de Maupassant"],
            correctIndex: 0,
            explanation: "Alexandre Dumas a publié ces deux chefs-d'œuvre en 1844.",
            xpReward: 25
        )
    ]
}

public struct SocialWordScrambleItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let scrambled: String
    public let answer: String
    public let hint: String
    public let xpReward: Int

    public init(id: UUID = UUID(), scrambled: String, answer: String, hint: String, xpReward: Int = 30) {
        self.id = id
        self.scrambled = scrambled
        self.answer = answer
        self.hint = hint
        self.xpReward = xpReward
    }

    public static let all: [SocialWordScrambleItem] = [
        SocialWordScrambleItem(scrambled: "M A N R O", answer: "ROMAN", hint: "Genre littéraire narratif en prose"),
        SocialWordScrambleItem(scrambled: "P O E S I E", answer: "POESIE", hint: "Art du langage en vers ou en prose rythmée"),
        SocialWordScrambleItem(scrambled: "A U T E U R", answer: "AUTEUR", hint: "Créateur d'une œuvre littéraire"),
        SocialWordScrambleItem(scrambled: "C H A P I T R E", answer: "CHAPITRE", hint: "Grande division d'un livre"),
        SocialWordScrambleItem(scrambled: "I N T R I G U E", answer: "INTRIGUE", hint: "Enchaînement des événements d'un récit"),
        SocialWordScrambleItem(scrambled: "L E C T U R E", answer: "LECTURE", hint: "Activité favorite de la communauté Livria")
    ]
}
