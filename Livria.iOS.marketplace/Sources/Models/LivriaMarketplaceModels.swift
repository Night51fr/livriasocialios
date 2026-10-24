import Foundation

// MARK: - Rubriques Officielles Livria Marketplace (Ordre de Priorité Strict : Livres > CD/DVD > Accessoires > Vêtements)

public enum MarketplaceCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case all = "all"
    case books = "books"
    case cddvd = "cddvd"
    case accessories = "accessories"
    case clothing = "clothing"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "Tout Livria"
        case .books: return "Livres"
        case .cddvd: return "CD & DVD / Blu-Ray"
        case .accessories: return "Accessoires & Goodies"
        case .clothing: return "Vêtements"
        }
    }

    public var shortTitle: String {
        switch self {
        case .all: return "Tout"
        case .books: return "1. Livres"
        case .cddvd: return "2. CD / DVD"
        case .accessories: return "3. Accessoires"
        case .clothing: return "4. Vêtements"
        }
    }

    public var subtitle: String {
        switch self {
        case .all:
            return "L'univers culturel & littéraire édité par la librairie en ligne Livria"
        case .books:
            return "Priorité N°1 Livria : Romans, Mangas, BD, SF, Polars, Essais & Éditions Collector"
        case .cddvd:
            return "Albums CD, Vinyles, Films DVD, Blu-Ray 4K UHD & Coffrets Séries"
        case .accessories:
            return "Tasses & Mugs littéraires, Goodies, Affiches, Marque-pages & Tote-bags"
        case .clothing:
            return "Sweats littéraires, T-shirts, Hoodies & Mode seconde main certifiée"
        }
    }

    public var icon: String {
        switch self {
        case .all: return "sparkles.rectangle.stack.fill"
        case .books: return "book.closed.fill"
        case .cddvd: return "opticaldisc.fill"
        case .accessories: return "cup.and.saucer.fill"
        case .clothing: return "tshirt.fill"
        }
    }

    public var priorityBadge: String? {
        switch self {
        case .all: return nil
        case .books: return "Cœur Livria • N°1"
        case .cddvd: return "Culture • N°2"
        case .accessories: return "Univers • N°3"
        case .clothing: return "Lifestyle • N°4"
        }
    }

    public var subcategories: [String] {
        switch self {
        case .all:
            return ["Tous"]
        case .books:
            return [
                "Tous",
                "Romans & Littérature",
                "Science-Fiction & Fantasy",
                "Manga & Bande Dessinée",
                "Polar & Thriller",
                "Essais & Philosophie",
                "Jeunesse & Young Adult",
                "Scolaire & Universitaire",
                "Beaux-Livres & Collector"
            ]
        case .cddvd:
            return [
                "Tous",
                "Albums CD",
                "Vinyles & Collectors",
                "Films DVD",
                "Blu-Ray & 4K UHD",
                "Coffrets Séries TV",
                "Bandes Originales (OST)"
            ]
        case .accessories:
            return [
                "Tous",
                "Tasses & Mugs",
                "Affiches & Posters",
                "Goodies & Figurines",
                "Marque-pages & Papeterie",
                "Tote-bags & Sacs de lecture",
                "Lampes & Confort de lecture"
            ]
        case .clothing:
            return [
                "Tous",
                "Sweats & Hoodies littéraires",
                "T-shirts Culture & Pop",
                "Vestes & Manteaux",
                "Mode Seconde Main",
                "Casquettes, Bonnets & Écharpes"
            ]
        }
    }

    /// Les 4 rubriques principales dans l'ordre exact demandé par Livria
    public static var orderedCreationCategories: [MarketplaceCategory] {
        [.books, .cddvd, .accessories, .clothing]
    }
}

public enum MarketplaceItemCondition: String, CaseIterable, Codable, Identifiable, Sendable {
    case newSealed = "Neuf avec étiquette / sous blister"
    case likeNew = "Comme neuf"
    case veryGood = "Très bon état"
    case good = "Bon état"
    case fair = "État satisfaisant"

    public var id: String { rawValue }
}

// MARK: - Annonce Livria Marketplace (Multi-photos swipeables directement depuis la Card)

public struct MarketplaceListing: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var description: String
    public var category: String
    public var subcategory: String
    public var condition: String
    public var price: Double
    public var originalRetailPrice: Double?
    public var livriaCommission: Double // Toujours 1,00 € ("Garantie et Maintien du service")
    public var shippingFee: Double      // Toujours 0,00 € ("Livraison 0 € UPS & Viple Taker")
    public var photos: [String]
    public var isbn: String?
    public var authorOrArtist: String?
    public var publisherOrBrand: String?
    public var releaseYear: String?
    public var clothingSize: String?
    public var sellerUsername: String
    public var sellerDisplayName: String
    public var sellerAvatarUrl: String?
    public var sellerLevel: Int
    public var sellerRating: Double
    public var sellerSalesCount: Int
    public var sellerCity: String
    public var isVipleVerified: Bool
    public var favoritesCount: Int
    public var isFavorited: Bool
    public var isSold: Bool
    public var allowsOffers: Bool
    public var createdAtDisplay: String

    public var totalBuyerPrice: Double {
        price + livriaCommission
    }

    public var parsedCategory: MarketplaceCategory {
        MarketplaceCategory(rawValue: category) ?? .books
    }

    public init(
        id: String,
        title: String,
        subtitle: String,
        description: String,
        category: String,
        subcategory: String,
        condition: String,
        price: Double,
        originalRetailPrice: Double? = nil,
        livriaCommission: Double = 1.00,
        shippingFee: Double = 0.00,
        photos: [String],
        isbn: String? = nil,
        authorOrArtist: String? = nil,
        publisherOrBrand: String? = nil,
        releaseYear: String? = nil,
        clothingSize: String? = nil,
        sellerUsername: String,
        sellerDisplayName: String,
        sellerAvatarUrl: String? = nil,
        sellerLevel: Int = 5,
        sellerRating: Double = 4.9,
        sellerSalesCount: Int = 12,
        sellerCity: String = "Nancy (54000)",
        isVipleVerified: Bool = true,
        favoritesCount: Int = 0,
        isFavorited: Bool = false,
        isSold: Bool = false,
        allowsOffers: Bool = true,
        createdAtDisplay: String = "À l'instant"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.category = category
        self.subcategory = subcategory
        self.condition = condition
        self.price = price
        self.originalRetailPrice = originalRetailPrice
        self.livriaCommission = livriaCommission
        self.shippingFee = shippingFee
        self.photos = photos
        self.isbn = isbn
        self.authorOrArtist = authorOrArtist
        self.publisherOrBrand = publisherOrBrand
        self.releaseYear = releaseYear
        self.clothingSize = clothingSize
        self.sellerUsername = sellerUsername
        self.sellerDisplayName = sellerDisplayName
        self.sellerAvatarUrl = sellerAvatarUrl
        self.sellerLevel = sellerLevel
        self.sellerRating = sellerRating
        self.sellerSalesCount = sellerSalesCount
        self.sellerCity = sellerCity
        self.isVipleVerified = isVipleVerified
        self.favoritesCount = favoritesCount
        self.isFavorited = isFavorited
        self.isSold = isSold
        self.allowsOffers = allowsOffers
        self.createdAtDisplay = createdAtDisplay
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, subtitle, subtitleOrCreator, description, category, subcategory, condition
        case price, sellerPrice, originalRetailPrice, livriaCommission, shippingFee
        case photos, photoUrls, isbn, isbnOrBarcode, authorOrArtist, publisherOrBrand, publisherOrLabel
        case releaseYear, publicationYear, clothingSize
        case sellerUsername, sellerHandle, sellerDisplayName, sellerAvatarUrl, sellerLevel
        case sellerRating, sellerSalesCount, sellerCity, isVipleVerified
        case favoritesCount, likesCount, isFavorited, isSold, allowsOffers, createdAtDisplay
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = UUID().uuidString
        }
        self.title = (try? c.decode(String.self, forKey: .title)) ?? "Annonce Livria"
        self.subtitle = (try? c.decode(String.self, forKey: .subtitle))
            ?? (try? c.decode(String.self, forKey: .subtitleOrCreator))
            ?? ""
        self.description = (try? c.decode(String.self, forKey: .description)) ?? ""
        self.category = (try? c.decode(String.self, forKey: .category)) ?? "books"
        self.subcategory = (try? c.decode(String.self, forKey: .subcategory)) ?? "Livres"
        self.condition = (try? c.decode(String.self, forKey: .condition)) ?? "Comme neuf"
        self.price = (try? c.decode(Double.self, forKey: .price))
            ?? (try? c.decode(Double.self, forKey: .sellerPrice))
            ?? 9.00
        self.originalRetailPrice = try? c.decode(Double.self, forKey: .originalRetailPrice)
        self.livriaCommission = (try? c.decode(Double.self, forKey: .livriaCommission)) ?? 1.00
        self.shippingFee = (try? c.decode(Double.self, forKey: .shippingFee)) ?? 0.00
        self.photos = (try? c.decode([String].self, forKey: .photos))
            ?? (try? c.decode([String].self, forKey: .photoUrls))
            ?? ["https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800&q=80"]
        self.isbn = (try? c.decode(String.self, forKey: .isbn)) ?? (try? c.decode(String.self, forKey: .isbnOrBarcode))
        self.authorOrArtist = (try? c.decode(String.self, forKey: .authorOrArtist))
            ?? (try? c.decode(String.self, forKey: .subtitleOrCreator))
        self.publisherOrBrand = (try? c.decode(String.self, forKey: .publisherOrBrand))
            ?? (try? c.decode(String.self, forKey: .publisherOrLabel))
        if let yrStr = try? c.decode(String.self, forKey: .releaseYear) {
            self.releaseYear = yrStr
        } else if let yrInt = try? c.decode(Int.self, forKey: .publicationYear) {
            self.releaseYear = String(yrInt)
        } else {
            self.releaseYear = nil
        }
        self.clothingSize = try? c.decode(String.self, forKey: .clothingSize)
        let rawHandle = (try? c.decode(String.self, forKey: .sellerUsername))
            ?? (try? c.decode(String.self, forKey: .sellerHandle))
            ?? "membre.livria"
        self.sellerUsername = rawHandle.hasPrefix("@") ? String(rawHandle.dropFirst()) : rawHandle
        self.sellerDisplayName = (try? c.decode(String.self, forKey: .sellerDisplayName)) ?? "Membre Livria"
        self.sellerAvatarUrl = try? c.decode(String.self, forKey: .sellerAvatarUrl)
        self.sellerLevel = (try? c.decode(Int.self, forKey: .sellerLevel)) ?? 8
        self.sellerRating = (try? c.decode(Double.self, forKey: .sellerRating)) ?? 4.95
        self.sellerSalesCount = (try? c.decode(Int.self, forKey: .sellerSalesCount)) ?? 15
        self.sellerCity = (try? c.decode(String.self, forKey: .sellerCity)) ?? "France"
        self.isVipleVerified = (try? c.decode(Bool.self, forKey: .isVipleVerified)) ?? true
        self.favoritesCount = (try? c.decode(Int.self, forKey: .favoritesCount))
            ?? (try? c.decode(Int.self, forKey: .likesCount))
            ?? 12
        self.isFavorited = (try? c.decode(Bool.self, forKey: .isFavorited)) ?? false
        self.isSold = (try? c.decode(Bool.self, forKey: .isSold)) ?? false
        self.allowsOffers = (try? c.decode(Bool.self, forKey: .allowsOffers)) ?? true
        self.createdAtDisplay = (try? c.decode(String.self, forKey: .createdAtDisplay)) ?? "Aujourd'hui"
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(subtitle, forKey: .subtitle)
        try c.encode(subtitle, forKey: .subtitleOrCreator)
        try c.encode(description, forKey: .description)
        try c.encode(category, forKey: .category)
        try c.encode(subcategory, forKey: .subcategory)
        try c.encode(condition, forKey: .condition)
        try c.encode(price, forKey: .price)
        try c.encode(price, forKey: .sellerPrice)
        try c.encodeIfPresent(originalRetailPrice, forKey: .originalRetailPrice)
        try c.encode(livriaCommission, forKey: .livriaCommission)
        try c.encode(shippingFee, forKey: .shippingFee)
        try c.encode(photos, forKey: .photos)
        try c.encode(photos, forKey: .photoUrls)
        try c.encodeIfPresent(isbn, forKey: .isbn)
        try c.encodeIfPresent(isbn, forKey: .isbnOrBarcode)
        try c.encodeIfPresent(authorOrArtist, forKey: .authorOrArtist)
        try c.encodeIfPresent(publisherOrBrand, forKey: .publisherOrBrand)
        try c.encodeIfPresent(publisherOrBrand, forKey: .publisherOrLabel)
        try c.encodeIfPresent(releaseYear, forKey: .releaseYear)
        try c.encodeIfPresent(clothingSize, forKey: .clothingSize)
        try c.encode(sellerUsername, forKey: .sellerUsername)
        try c.encode(sellerDisplayName, forKey: .sellerDisplayName)
        try c.encodeIfPresent(sellerAvatarUrl, forKey: .sellerAvatarUrl)
        try c.encode(sellerLevel, forKey: .sellerLevel)
        try c.encode(sellerRating, forKey: .sellerRating)
        try c.encode(sellerSalesCount, forKey: .sellerSalesCount)
        try c.encode(sellerCity, forKey: .sellerCity)
        try c.encode(isVipleVerified, forKey: .isVipleVerified)
        try c.encode(favoritesCount, forKey: .favoritesCount)
        try c.encode(isFavorited, forKey: .isFavorited)
        try c.encode(isSold, forKey: .isSold)
        try c.encode(allowsOffers, forKey: .allowsOffers)
        try c.encode(createdAtDisplay, forKey: .createdAtDisplay)
    }
}

// MARK: - Offre de Prix sur une Annonce

public struct MarketplaceOffer: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var listingId: String
    public var listingTitle: String
    public var listingPhoto: String
    public var listingOriginalPrice: Double
    public var buyerUsername: String
    public var buyerDisplayName: String
    public var buyerAvatarUrl: String?
    public var sellerUsername: String
    public var offeredPrice: Double
    public var livriaCommission: Double
    public var shippingFee: Double
    public var message: String
    public var status: String // "En attente", "Acceptée", "Refusée"
    public var createdAtDisplay: String

    public var totalWithCommission: Double {
        offeredPrice + livriaCommission
    }
}

// MARK: - Messagerie Livria Marketplace (En 1er l'Annonce, et juste en dessous en plus petit le Pseudo !)

public struct MarketplaceConversationPreview: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var listingId: String
    public var listingTitle: String
    public var listingPhoto: String
    public var listingPrice: Double
    public var listingCategory: String
    public var listingIsSold: Bool
    public var otherUsername: String
    public var otherDisplayName: String
    public var otherAvatarUrl: String?
    public var otherLevel: Int
    public var lastMessagePreview: String
    public var lastMessageAt: String
    public var unreadCount: Int
    public var latestOfferPrice: Double?
    public var latestOfferStatus: String?

    public init(
        id: String,
        listingId: String,
        listingTitle: String,
        listingPhoto: String,
        listingPrice: Double,
        listingCategory: String,
        listingIsSold: Bool,
        otherUsername: String,
        otherDisplayName: String,
        otherAvatarUrl: String?,
        otherLevel: Int,
        lastMessagePreview: String,
        lastMessageAt: String,
        unreadCount: Int,
        latestOfferPrice: Double?,
        latestOfferStatus: String?
    ) {
        self.id = id
        self.listingId = listingId
        self.listingTitle = listingTitle
        self.listingPhoto = listingPhoto
        self.listingPrice = listingPrice
        self.listingCategory = listingCategory
        self.listingIsSold = listingIsSold
        self.otherUsername = otherUsername
        self.otherDisplayName = otherDisplayName
        self.otherAvatarUrl = otherAvatarUrl
        self.otherLevel = otherLevel
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.latestOfferPrice = latestOfferPrice
        self.latestOfferStatus = latestOfferStatus
    }

    private enum CodingKeys: String, CodingKey {
        case id, listingId, listingTitle, listingPhoto, listingFirstPhotoUrl
        case listingPrice, listingSellerPrice, listingCategory, listingIsSold
        case otherUsername, otherHandle, otherDisplayName, otherAvatarUrl, otherLevel
        case lastMessagePreview, lastMessageAt, updatedAt, unreadCount
        case latestOfferPrice, latestOfferAmount, latestOfferStatus
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .id) {
            self.id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            self.id = String(i)
        } else {
            self.id = UUID().uuidString
        }
        if let s = try? c.decode(String.self, forKey: .listingId) {
            self.listingId = s
        } else if let i = try? c.decode(Int.self, forKey: .listingId) {
            self.listingId = String(i)
        } else {
            self.listingId = "1001"
        }
        self.listingTitle = (try? c.decode(String.self, forKey: .listingTitle)) ?? "Annonce Livria"
        self.listingPhoto = (try? c.decode(String.self, forKey: .listingPhoto))
            ?? (try? c.decode(String.self, forKey: .listingFirstPhotoUrl))
            ?? ""
        self.listingPrice = (try? c.decode(Double.self, forKey: .listingPrice))
            ?? (try? c.decode(Double.self, forKey: .listingSellerPrice))
            ?? 10.00
        self.listingCategory = (try? c.decode(String.self, forKey: .listingCategory)) ?? "books"
        self.listingIsSold = (try? c.decode(Bool.self, forKey: .listingIsSold)) ?? false
        let rawHandle = (try? c.decode(String.self, forKey: .otherUsername))
            ?? (try? c.decode(String.self, forKey: .otherHandle))
            ?? "membre.livria"
        self.otherUsername = rawHandle.hasPrefix("@") ? String(rawHandle.dropFirst()) : rawHandle
        self.otherDisplayName = (try? c.decode(String.self, forKey: .otherDisplayName)) ?? "Membre Livria"
        self.otherAvatarUrl = try? c.decode(String.self, forKey: .otherAvatarUrl)
        self.otherLevel = (try? c.decode(Int.self, forKey: .otherLevel)) ?? 9
        self.lastMessagePreview = (try? c.decode(String.self, forKey: .lastMessagePreview)) ?? ""
        self.lastMessageAt = (try? c.decode(String.self, forKey: .lastMessageAt))
            ?? (try? c.decode(String.self, forKey: .updatedAt))
            ?? "Aujourd'hui"
        self.unreadCount = (try? c.decode(Int.self, forKey: .unreadCount)) ?? 0
        self.latestOfferPrice = (try? c.decode(Double.self, forKey: .latestOfferPrice))
            ?? (try? c.decode(Double.self, forKey: .latestOfferAmount))
        self.latestOfferStatus = try? c.decode(String.self, forKey: .latestOfferStatus)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(listingId, forKey: .listingId)
        try c.encode(listingTitle, forKey: .listingTitle)
        try c.encode(listingPhoto, forKey: .listingPhoto)
        try c.encode(listingPrice, forKey: .listingPrice)
        try c.encode(listingCategory, forKey: .listingCategory)
        try c.encode(listingIsSold, forKey: .listingIsSold)
        try c.encode(otherUsername, forKey: .otherUsername)
        try c.encode(otherDisplayName, forKey: .otherDisplayName)
        try c.encodeIfPresent(otherAvatarUrl, forKey: .otherAvatarUrl)
        try c.encode(otherLevel, forKey: .otherLevel)
        try c.encode(lastMessagePreview, forKey: .lastMessagePreview)
        try c.encode(lastMessageAt, forKey: .lastMessageAt)
        try c.encode(unreadCount, forKey: .unreadCount)
        try c.encodeIfPresent(latestOfferPrice, forKey: .latestOfferPrice)
        try c.encodeIfPresent(latestOfferStatus, forKey: .latestOfferStatus)
    }
}

public struct MarketplaceDirectMessage: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var conversationId: String
    public var listingId: String
    public var senderUsername: String
    public var senderDisplayName: String
    public var senderAvatarUrl: String?
    public var text: String
    public var imageUrl: String?
    public var gifUrl: String?
    public var audioUrl: String?
    public var audioDurationSeconds: Int?
    public var offerId: String?
    public var offerAmount: Double?
    public var offerStatus: String?
    public var sentAtDisplay: String
    public var isFromMe: Bool
}

public struct MarketplaceThreadResponse: Codable, Hashable, Sendable {
    public var ok: Bool?
    public var conversationId: String
    public var listing: MarketplaceListing?
    public var messages: [MarketplaceDirectMessage]
}

// MARK: - Commandes & Achats Marketplace (PayPal, Apple Pay, UPS & Viple Taker)

public struct MarketplaceOrder: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var orderNumber: String
    public var listingId: String
    public var listingTitle: String
    public var listingPhoto: String
    public var category: String
    public var buyerUsername: String
    public var sellerUsername: String
    public var itemPrice: Double
    public var livriaCommission: Double // 1,00 € ("Garantie et Maintien du service")
    public var shippingFee: Double      // 0,00 €
    public var totalPaid: Double
    public var paymentMethod: String    // "Apple Pay" ou "PayPal"
    public var deliveryMode: String     // "Point Relais Viple Taker", "Point Relais UPS Access Point", "Domicile UPS Standard"
    public var relayId: String?
    public var relayName: String?
    public var relayAddress: String?
    public var isVipleTakerRelay: Bool
    public var upsTrackingNumber: String
    public var vipleDeliveryBarcode: String
    public var status: String
    public var createdAtDisplay: String
}

// MARK: - Points Relais UPS & Viple Taker (Particuliers & Commerces — 1,00 € / colis)

public struct MarketplaceRelayPoint: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var address: String
    public var postalCode: String
    public var city: String
    public var distanceKm: Double
    public var openingHours: String
    public var latitude: Double
    public var longitude: Double
    public var isAvailable: Bool
    public var isVipleTaker: Bool?
    public var takerDisplayName: String?
    public var remunerationPerParcel: Double?

    public var isParticulierTaker: Bool {
        if isVipleTaker == true { return true }
        return id.hasPrefix("TAKER-") || name.localizedCaseInsensitiveContains("Viple Taker")
    }
}

// MARK: - Candidature & Suivi « Devenir Viple Taker » (Point Relais Particulier — 1,00 € / colis)

public struct MarketplaceVipleTakerApplication: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var userId: String
    public var username: String
    public var fullName: String
    public var email: String
    public var phone: String
    public var streetAddress: String
    public var postalCode: String
    public var city: String
    public var availabilityHours: String
    public var storageCapacityParcels: Int
    public var housingType: String
    public var motivation: String
    public var acceptsCharter: Bool
    public var status: String // "Envoyée", "Vu par Viple, en cours de traitement", "Validé", "Refusé", "En attente d'éléments supplémentaires", "Annulée"
    public var requestedAdditionalInfo: String?
    public var applicantAdditionalReply: String?
    public var adminComment: String?
    public var relayPointId: String?
    public var loobyTakerCode: String
    public var remunerationPerParcel: Double
    public var parcelsDeliveredCount: Int
    public var totalEarnedEuros: Double
    public var createdAt: String
    public var updatedAt: String
}

public struct MarketplaceTakerStatusResponse: Codable, Hashable, Sendable {
    public var ok: Bool
    public var hasApplication: Bool
    public var application: MarketplaceVipleTakerApplication?
    public var message: String?
}

// MARK: - Profil Utilisateur Viple Live ID & Cross-App SSO

public struct MarketplaceUserProfile: Codable, Hashable, Sendable {
    public var id: String
    public var username: String
    public var displayName: String
    public var email: String
    public var avatarUrl: String?
    public var bio: String
    public var motto: String
    public var level: Int
    public var xp: Int
    public var isLivriaPlus: Bool
    public var firstName: String
    public var lastName: String
    public var phone: String
    public var address: String
    public var postalCode: String
    public var city: String
    public var walletBalance: Double
}

public struct MarketplaceCrossAppDiscoverResponse: Codable, Hashable, Sendable {
    public let hasSession: Bool
    public let sourceApp: String?
    public let token: String?
    public let user: MarketplaceUserProfile?
}

public struct MarketplaceAuthResponse: Codable, Hashable, Sendable {
    public var success: Bool
    public var message: String
    public var token: String?
    public var user: MarketplaceUserProfile?
}

public struct MarketplaceBootstrapResponse: Codable, Hashable, Sendable {
    public var maintenanceMode: Bool?
    public var maintenanceMessage: String?
    public var commissionFee: Double?
    public var commissionLabel: String?
    public var shippingFee: Double?
    public var listings: [MarketplaceListing]
    public var conversations: [MarketplaceConversationPreview]
    public var offers: [MarketplaceOffer]
    public var orders: [MarketplaceOrder]
    public var relayPoints: [MarketplaceRelayPoint]
    public var takerApplication: MarketplaceVipleTakerApplication?
    public var currentUser: MarketplaceUserProfile?

    private enum CodingKeys: String, CodingKey {
        case maintenanceMode, maintenanceEnabled, maintenanceMessage
        case commissionFee, commissionAmount, commissionLabel, shippingFee
        case listings, conversations, offers, orders, relayPoints
        case takerApplication, currentUser
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.maintenanceMode = (try? c.decode(Bool.self, forKey: .maintenanceMode))
            ?? (try? c.decode(Bool.self, forKey: .maintenanceEnabled))
        self.maintenanceMessage = try? c.decode(String.self, forKey: .maintenanceMessage)
        self.commissionFee = (try? c.decode(Double.self, forKey: .commissionFee))
            ?? (try? c.decode(Double.self, forKey: .commissionAmount))
            ?? 1.00
        self.commissionLabel = (try? c.decode(String.self, forKey: .commissionLabel))
            ?? "Garantie et Maintien du service"
        self.shippingFee = (try? c.decode(Double.self, forKey: .shippingFee)) ?? 0.00
        self.listings = (try? c.decode([MarketplaceListing].self, forKey: .listings)) ?? []
        self.conversations = (try? c.decode([MarketplaceConversationPreview].self, forKey: .conversations)) ?? []
        self.offers = (try? c.decode([MarketplaceOffer].self, forKey: .offers)) ?? []
        self.orders = (try? c.decode([MarketplaceOrder].self, forKey: .orders)) ?? []
        self.relayPoints = (try? c.decode([MarketplaceRelayPoint].self, forKey: .relayPoints)) ?? []
        self.takerApplication = try? c.decode(MarketplaceVipleTakerApplication.self, forKey: .takerApplication)
        self.currentUser = try? c.decode(MarketplaceUserProfile.self, forKey: .currentUser)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(maintenanceMode, forKey: .maintenanceMode)
        try c.encodeIfPresent(maintenanceMessage, forKey: .maintenanceMessage)
        try c.encodeIfPresent(commissionFee, forKey: .commissionFee)
        try c.encodeIfPresent(commissionLabel, forKey: .commissionLabel)
        try c.encodeIfPresent(shippingFee, forKey: .shippingFee)
        try c.encode(listings, forKey: .listings)
        try c.encode(conversations, forKey: .conversations)
        try c.encode(offers, forKey: .offers)
        try c.encode(orders, forKey: .orders)
        try c.encode(relayPoints, forKey: .relayPoints)
        try c.encodeIfPresent(takerApplication, forKey: .takerApplication)
        try c.encodeIfPresent(currentUser, forKey: .currentUser)
    }
}

public struct MarketplaceGifItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var url: String
}

public struct MarketplaceISBNLookupResult: Codable, Hashable, Sendable {
    public var isbn: String
    public var title: String
    public var author: String
    public var publisher: String
    public var releaseYear: String
    public var suggestedPrice: Double
    public var originalRetailPrice: Double
    public var subcategory: String
    public var coverUrl: String
    public var summary: String
}
