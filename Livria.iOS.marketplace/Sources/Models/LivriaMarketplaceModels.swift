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
            ?? []
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

    public init(
        id: String,
        conversationId: String,
        listingId: String,
        senderUsername: String,
        senderDisplayName: String,
        senderAvatarUrl: String?,
        text: String,
        imageUrl: String?,
        gifUrl: String?,
        audioUrl: String?,
        audioDurationSeconds: Int?,
        offerId: String?,
        offerAmount: Double?,
        offerStatus: String?,
        sentAtDisplay: String,
        isFromMe: Bool
    ) {
        self.id = id
        self.conversationId = conversationId
        self.listingId = listingId
        self.senderUsername = senderUsername
        self.senderDisplayName = senderDisplayName
        self.senderAvatarUrl = senderAvatarUrl
        self.text = text
        self.imageUrl = imageUrl
        self.gifUrl = gifUrl
        self.audioUrl = audioUrl
        self.audioDurationSeconds = audioDurationSeconds
        self.offerId = offerId
        self.offerAmount = offerAmount
        self.offerStatus = offerStatus
        self.sentAtDisplay = sentAtDisplay
        self.isFromMe = isFromMe
    }

    private enum CodingKeys: String, CodingKey {
        case id, conversationId, listingId, senderId, senderUsername, senderDisplayName, senderAvatarUrl
        case text, body, attachmentType, attachmentUrl
        case imageUrl, gifUrl, audioUrl, audioDurationSeconds, voiceDurationSec
        case offerId, offerAmount, offerStatus, sentAtDisplay, sentAt, isFromMe
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
        if let s = try? c.decode(String.self, forKey: .conversationId) {
            self.conversationId = s
        } else if let i = try? c.decode(Int.self, forKey: .conversationId) {
            self.conversationId = String(i)
        } else {
            self.conversationId = "0"
        }
        if let s = try? c.decode(String.self, forKey: .listingId) {
            self.listingId = s
        } else if let i = try? c.decode(Int.self, forKey: .listingId) {
            self.listingId = String(i)
        } else {
            self.listingId = "0"
        }
        let disp = (try? c.decode(String.self, forKey: .senderDisplayName)) ?? "Membre Livria"
        self.senderDisplayName = disp
        self.senderUsername = (try? c.decode(String.self, forKey: .senderUsername)) ?? disp.lowercased().replacingOccurrences(of: " ", with: ".")
        self.senderAvatarUrl = try? c.decode(String.self, forKey: .senderAvatarUrl)
        self.text = (try? c.decode(String.self, forKey: .text))
            ?? (try? c.decode(String.self, forKey: .body))
            ?? ""
        let attType = (try? c.decode(String.self, forKey: .attachmentType))?.lowercased() ?? "none"
        let attUrl = try? c.decode(String.self, forKey: .attachmentUrl)
        self.imageUrl = (try? c.decode(String.self, forKey: .imageUrl)) ?? (attType == "image" ? attUrl : nil)
        self.gifUrl = (try? c.decode(String.self, forKey: .gifUrl)) ?? (attType == "gif" ? attUrl : nil)
        self.audioUrl = (try? c.decode(String.self, forKey: .audioUrl)) ?? (attType == "voice" ? attUrl : nil)
        self.audioDurationSeconds = (try? c.decode(Int.self, forKey: .audioDurationSeconds))
            ?? (try? c.decode(Int.self, forKey: .voiceDurationSec))
        if let oidStr = try? c.decode(String.self, forKey: .offerId) {
            self.offerId = oidStr
        } else if let oidInt = try? c.decode(Int.self, forKey: .offerId) {
            self.offerId = String(oidInt)
        } else {
            self.offerId = nil
        }
        self.offerAmount = try? c.decode(Double.self, forKey: .offerAmount)
        self.offerStatus = try? c.decode(String.self, forKey: .offerStatus)
        self.sentAtDisplay = (try? c.decode(String.self, forKey: .sentAtDisplay))
            ?? (try? c.decode(String.self, forKey: .sentAt))
            ?? "Aujourd'hui"
        self.isFromMe = (try? c.decode(Bool.self, forKey: .isFromMe)) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(conversationId, forKey: .conversationId)
        try c.encode(listingId, forKey: .listingId)
        try c.encode(senderUsername, forKey: .senderUsername)
        try c.encode(senderDisplayName, forKey: .senderDisplayName)
        try c.encodeIfPresent(senderAvatarUrl, forKey: .senderAvatarUrl)
        try c.encode(text, forKey: .text)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(gifUrl, forKey: .gifUrl)
        try c.encodeIfPresent(audioUrl, forKey: .audioUrl)
        try c.encodeIfPresent(audioDurationSeconds, forKey: .audioDurationSeconds)
        try c.encodeIfPresent(offerId, forKey: .offerId)
        try c.encodeIfPresent(offerAmount, forKey: .offerAmount)
        try c.encodeIfPresent(offerStatus, forKey: .offerStatus)
        try c.encode(sentAtDisplay, forKey: .sentAtDisplay)
        try c.encode(isFromMe, forKey: .isFromMe)
    }
}

public struct MarketplaceThreadResponse: Codable, Hashable, Sendable {
    public var ok: Bool?
    public var conversationId: String
    public var listing: MarketplaceListing?
    public var messages: [MarketplaceDirectMessage]

    private enum CodingKeys: String, CodingKey {
        case ok, conversationId, listing, messages
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.ok = try? c.decode(Bool.self, forKey: .ok)
        if let s = try? c.decode(String.self, forKey: .conversationId) {
            self.conversationId = s
        } else if let i = try? c.decode(Int.self, forKey: .conversationId) {
            self.conversationId = String(i)
        } else {
            self.conversationId = "0"
        }
        self.listing = try? c.decode(MarketplaceListing.self, forKey: .listing)
        self.messages = (try? c.decode([MarketplaceDirectMessage].self, forKey: .messages)) ?? []
    }
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

    public init(
        id: String,
        orderNumber: String,
        listingId: String,
        listingTitle: String,
        listingPhoto: String,
        category: String,
        buyerUsername: String,
        sellerUsername: String,
        itemPrice: Double,
        livriaCommission: Double,
        shippingFee: Double,
        totalPaid: Double,
        paymentMethod: String,
        deliveryMode: String,
        relayId: String?,
        relayName: String?,
        relayAddress: String?,
        isVipleTakerRelay: Bool,
        upsTrackingNumber: String,
        vipleDeliveryBarcode: String,
        status: String,
        createdAtDisplay: String
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.listingId = listingId
        self.listingTitle = listingTitle
        self.listingPhoto = listingPhoto
        self.category = category
        self.buyerUsername = buyerUsername
        self.sellerUsername = sellerUsername
        self.itemPrice = itemPrice
        self.livriaCommission = livriaCommission
        self.shippingFee = shippingFee
        self.totalPaid = totalPaid
        self.paymentMethod = paymentMethod
        self.deliveryMode = deliveryMode
        self.relayId = relayId
        self.relayName = relayName
        self.relayAddress = relayAddress
        self.isVipleTakerRelay = isVipleTakerRelay
        self.upsTrackingNumber = upsTrackingNumber
        self.vipleDeliveryBarcode = vipleDeliveryBarcode
        self.status = status
        self.createdAtDisplay = createdAtDisplay
    }

    private enum CodingKeys: String, CodingKey {
        case id, orderNumber, reference, listingId, listingTitle
        case listingPhoto, listingPhotoUrl, category, listingCategory
        case buyerUsername, buyerDisplayName, sellerUsername, sellerDisplayName
        case itemPrice, livriaCommission, shippingFee, totalPaid
        case paymentMethod, deliveryMode, carrier
        case relayId, relayName, relayAddress, relayOrAddressSummary, isVipleTakerRelay
        case upsTrackingNumber, trackingNumber, vipleDeliveryBarcode, status, createdAtDisplay
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
        self.orderNumber = (try? c.decode(String.self, forKey: .orderNumber))
            ?? (try? c.decode(String.self, forKey: .reference))
            ?? "#MKT-\(self.id)"
        if let s = try? c.decode(String.self, forKey: .listingId) {
            self.listingId = s
        } else if let i = try? c.decode(Int.self, forKey: .listingId) {
            self.listingId = String(i)
        } else {
            self.listingId = "0"
        }
        self.listingTitle = (try? c.decode(String.self, forKey: .listingTitle)) ?? "Commande Livria"
        self.listingPhoto = (try? c.decode(String.self, forKey: .listingPhoto))
            ?? (try? c.decode(String.self, forKey: .listingPhotoUrl))
            ?? ""
        self.category = (try? c.decode(String.self, forKey: .category))
            ?? (try? c.decode(String.self, forKey: .listingCategory))
            ?? "books"
        self.buyerUsername = (try? c.decode(String.self, forKey: .buyerUsername))
            ?? (try? c.decode(String.self, forKey: .buyerDisplayName))
            ?? ""
        self.sellerUsername = (try? c.decode(String.self, forKey: .sellerUsername))
            ?? (try? c.decode(String.self, forKey: .sellerDisplayName))
            ?? ""
        let price = (try? c.decode(Double.self, forKey: .itemPrice)) ?? 0.0
        self.itemPrice = price
        let comm = (try? c.decode(Double.self, forKey: .livriaCommission)) ?? 1.00
        self.livriaCommission = comm
        self.shippingFee = (try? c.decode(Double.self, forKey: .shippingFee)) ?? 0.00
        self.totalPaid = (try? c.decode(Double.self, forKey: .totalPaid)) ?? (price + comm)
        self.paymentMethod = (try? c.decode(String.self, forKey: .paymentMethod)) ?? "Apple Pay"
        let mode = (try? c.decode(String.self, forKey: .deliveryMode))
            ?? (try? c.decode(String.self, forKey: .carrier))
            ?? "Point Relais UPS / Viple Taker"
        self.deliveryMode = mode
        self.relayId = try? c.decode(String.self, forKey: .relayId)
        let rSummary = try? c.decode(String.self, forKey: .relayOrAddressSummary)
        self.relayName = (try? c.decode(String.self, forKey: .relayName)) ?? rSummary
        self.relayAddress = (try? c.decode(String.self, forKey: .relayAddress)) ?? rSummary
        self.isVipleTakerRelay = (try? c.decode(Bool.self, forKey: .isVipleTakerRelay))
            ?? mode.localizedCaseInsensitiveContains("Taker")
        self.upsTrackingNumber = (try? c.decode(String.self, forKey: .upsTrackingNumber))
            ?? (try? c.decode(String.self, forKey: .trackingNumber))
            ?? ""
        self.vipleDeliveryBarcode = (try? c.decode(String.self, forKey: .vipleDeliveryBarcode)) ?? ""
        self.status = (try? c.decode(String.self, forKey: .status)) ?? "Confirmée"
        self.createdAtDisplay = (try? c.decode(String.self, forKey: .createdAtDisplay)) ?? "Aujourd'hui"
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(orderNumber, forKey: .orderNumber)
        try c.encode(listingId, forKey: .listingId)
        try c.encode(listingTitle, forKey: .listingTitle)
        try c.encode(listingPhoto, forKey: .listingPhoto)
        try c.encode(category, forKey: .category)
        try c.encode(buyerUsername, forKey: .buyerUsername)
        try c.encode(sellerUsername, forKey: .sellerUsername)
        try c.encode(itemPrice, forKey: .itemPrice)
        try c.encode(livriaCommission, forKey: .livriaCommission)
        try c.encode(shippingFee, forKey: .shippingFee)
        try c.encode(totalPaid, forKey: .totalPaid)
        try c.encode(paymentMethod, forKey: .paymentMethod)
        try c.encode(deliveryMode, forKey: .deliveryMode)
        try c.encodeIfPresent(relayId, forKey: .relayId)
        try c.encodeIfPresent(relayName, forKey: .relayName)
        try c.encodeIfPresent(relayAddress, forKey: .relayAddress)
        try c.encode(isVipleTakerRelay, forKey: .isVipleTakerRelay)
        try c.encode(upsTrackingNumber, forKey: .upsTrackingNumber)
        try c.encode(vipleDeliveryBarcode, forKey: .vipleDeliveryBarcode)
        try c.encode(status, forKey: .status)
        try c.encode(createdAtDisplay, forKey: .createdAtDisplay)
    }
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
        return id.hasPrefix("TAKER-") || name.localizedCaseInsensitiveContains("Taker")
    }

    public init(
        id: String,
        name: String,
        address: String,
        postalCode: String,
        city: String,
        distanceKm: Double,
        openingHours: String,
        latitude: Double,
        longitude: Double,
        isAvailable: Bool,
        isVipleTaker: Bool?,
        takerDisplayName: String?,
        remunerationPerParcel: Double?
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.distanceKm = distanceKm
        self.openingHours = openingHours
        self.latitude = latitude
        self.longitude = longitude
        self.isAvailable = isAvailable
        self.isVipleTaker = isVipleTaker
        self.takerDisplayName = takerDisplayName
        self.remunerationPerParcel = remunerationPerParcel
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, type, address, postalCode, city, distanceKm, openingHours
        case latitude, longitude, isAvailable, isActive, isVipleTaker, takerDisplayName, remunerationPerParcel
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .id) {
            self.id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            self.id = "RELAY-\(i)"
        } else {
            self.id = UUID().uuidString
        }
        let nm = (try? c.decode(String.self, forKey: .name)) ?? "Point Relais"
        self.name = nm
        let rType = (try? c.decode(String.self, forKey: .type)) ?? ""
        self.address = (try? c.decode(String.self, forKey: .address)) ?? ""
        self.postalCode = (try? c.decode(String.self, forKey: .postalCode)) ?? ""
        self.city = (try? c.decode(String.self, forKey: .city)) ?? ""
        self.distanceKm = (try? c.decode(Double.self, forKey: .distanceKm)) ?? 0.8
        self.openingHours = (try? c.decode(String.self, forKey: .openingHours)) ?? "Lun-Sam 09h00-19h30"
        self.latitude = (try? c.decode(Double.self, forKey: .latitude)) ?? 48.8566
        self.longitude = (try? c.decode(Double.self, forKey: .longitude)) ?? 2.3522
        self.isAvailable = (try? c.decode(Bool.self, forKey: .isAvailable))
            ?? (try? c.decode(Bool.self, forKey: .isActive))
            ?? true
        let isTaker = (try? c.decode(Bool.self, forKey: .isVipleTaker))
            ?? (nm.localizedCaseInsensitiveContains("Taker") || rType.localizedCaseInsensitiveContains("Taker"))
        self.isVipleTaker = isTaker
        self.takerDisplayName = try? c.decode(String.self, forKey: .takerDisplayName)
        self.remunerationPerParcel = (try? c.decode(Double.self, forKey: .remunerationPerParcel)) ?? 1.00
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(address, forKey: .address)
        try c.encode(postalCode, forKey: .postalCode)
        try c.encode(city, forKey: .city)
        try c.encode(distanceKm, forKey: .distanceKm)
        try c.encode(openingHours, forKey: .openingHours)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encode(isAvailable, forKey: .isAvailable)
        try c.encodeIfPresent(isVipleTaker, forKey: .isVipleTaker)
        try c.encodeIfPresent(takerDisplayName, forKey: .takerDisplayName)
        try c.encodeIfPresent(remunerationPerParcel, forKey: .remunerationPerParcel)
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

    public init(
        id: String,
        userId: String,
        username: String,
        fullName: String,
        email: String,
        phone: String,
        streetAddress: String,
        postalCode: String,
        city: String,
        availabilityHours: String,
        storageCapacityParcels: Int,
        housingType: String,
        motivation: String,
        acceptsCharter: Bool,
        status: String,
        requestedAdditionalInfo: String?,
        applicantAdditionalReply: String?,
        adminComment: String?,
        relayPointId: String?,
        loobyTakerCode: String,
        remunerationPerParcel: Double,
        parcelsDeliveredCount: Int,
        totalEarnedEuros: Double,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.userId = userId
        self.username = username
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.streetAddress = streetAddress
        self.postalCode = postalCode
        self.city = city
        self.availabilityHours = availabilityHours
        self.storageCapacityParcels = storageCapacityParcels
        self.housingType = housingType
        self.motivation = motivation
        self.acceptsCharter = acceptsCharter
        self.status = status
        self.requestedAdditionalInfo = requestedAdditionalInfo
        self.applicantAdditionalReply = applicantAdditionalReply
        self.adminComment = adminComment
        self.relayPointId = relayPointId
        self.loobyTakerCode = loobyTakerCode
        self.remunerationPerParcel = remunerationPerParcel
        self.parcelsDeliveredCount = parcelsDeliveredCount
        self.totalEarnedEuros = totalEarnedEuros
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, reference, userId, username, displayName, firstName, lastName, fullName
        case email, phone, streetAddress, address, postalCode, city
        case availabilityHours, openingHours, storageCapacityParcels, storageCapacity
        case housingType, motivation, motivationAndAccessNotes, acceptsCharter
        case status, requestedAdditionalInfo, applicantAdditionalReply, applicantSupplementaryResponse
        case adminComment, adminNotes, relayPointId, linkedRelayPointId, loobyTakerCode
        case remunerationPerParcel, commissionPerParcel, parcelsDeliveredCount, totalEarnedEuros
        case createdAt, createdAtUtc, updatedAt, updatedAtUtc
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .id) {
            self.id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            self.id = String(i)
        } else {
            self.id = "1"
        }
        if let s = try? c.decode(String.self, forKey: .userId) {
            self.userId = s
        } else if let i = try? c.decode(Int.self, forKey: .userId) {
            self.userId = String(i)
        } else {
            self.userId = "0"
        }
        let mail = (try? c.decode(String.self, forKey: .email)) ?? ""
        self.email = mail
        self.username = (try? c.decode(String.self, forKey: .username))
            ?? (mail.components(separatedBy: "@").first ?? "membre")
        let fn = (try? c.decode(String.self, forKey: .firstName)) ?? ""
        let ln = (try? c.decode(String.self, forKey: .lastName)) ?? ""
        let combined = "\(fn) \(ln)".trimmingCharacters(in: .whitespaces)
        self.fullName = (try? c.decode(String.self, forKey: .fullName))
            ?? (!combined.isEmpty ? combined : ((try? c.decode(String.self, forKey: .displayName)) ?? ""))
        self.phone = (try? c.decode(String.self, forKey: .phone)) ?? ""
        self.streetAddress = (try? c.decode(String.self, forKey: .streetAddress))
            ?? (try? c.decode(String.self, forKey: .address))
            ?? ""
        self.postalCode = (try? c.decode(String.self, forKey: .postalCode)) ?? ""
        self.city = (try? c.decode(String.self, forKey: .city)) ?? ""
        self.availabilityHours = (try? c.decode(String.self, forKey: .availabilityHours))
            ?? (try? c.decode(String.self, forKey: .openingHours))
            ?? "Lun-Sam 17h00-20h30"
        if let capInt = try? c.decode(Int.self, forKey: .storageCapacityParcels) {
            self.storageCapacityParcels = capInt
        } else if let capStr = try? c.decode(String.self, forKey: .storageCapacity) {
            let digits = capStr.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
            self.storageCapacityParcels = digits.last ?? 20
        } else {
            self.storageCapacityParcels = 20
        }
        self.housingType = (try? c.decode(String.self, forKey: .housingType)) ?? "Maison / Rez-de-chaussée"
        self.motivation = (try? c.decode(String.self, forKey: .motivation))
            ?? (try? c.decode(String.self, forKey: .motivationAndAccessNotes))
            ?? ""
        self.acceptsCharter = (try? c.decode(Bool.self, forKey: .acceptsCharter)) ?? true
        self.status = (try? c.decode(String.self, forKey: .status)) ?? "Envoyée"
        let reqInfo = (try? c.decode(String.self, forKey: .requestedAdditionalInfo))?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.requestedAdditionalInfo = (reqInfo?.isEmpty == false) ? reqInfo : nil
        let appReply = ((try? c.decode(String.self, forKey: .applicantAdditionalReply))
            ?? (try? c.decode(String.self, forKey: .applicantSupplementaryResponse)))?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.applicantAdditionalReply = (appReply?.isEmpty == false) ? appReply : nil
        let adm = ((try? c.decode(String.self, forKey: .adminComment))
            ?? (try? c.decode(String.self, forKey: .adminNotes)))?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.adminComment = (adm?.isEmpty == false) ? adm : nil
        if let rStr = try? c.decode(String.self, forKey: .relayPointId) {
            self.relayPointId = rStr
        } else if let rInt = try? c.decode(Int.self, forKey: .linkedRelayPointId) {
            self.relayPointId = String(rInt)
        } else {
            self.relayPointId = nil
        }
        self.loobyTakerCode = (try? c.decode(String.self, forKey: .loobyTakerCode))
            ?? (try? c.decode(String.self, forKey: .reference))
            ?? "TAKER-\(self.id)"
        self.remunerationPerParcel = (try? c.decode(Double.self, forKey: .remunerationPerParcel))
            ?? (try? c.decode(Double.self, forKey: .commissionPerParcel))
            ?? 1.00
        self.parcelsDeliveredCount = (try? c.decode(Int.self, forKey: .parcelsDeliveredCount)) ?? 0
        self.totalEarnedEuros = (try? c.decode(Double.self, forKey: .totalEarnedEuros)) ?? 0.0
        self.createdAt = (try? c.decode(String.self, forKey: .createdAt))
            ?? (try? c.decode(String.self, forKey: .createdAtUtc))
            ?? ""
        self.updatedAt = (try? c.decode(String.self, forKey: .updatedAt))
            ?? (try? c.decode(String.self, forKey: .updatedAtUtc))
            ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(username, forKey: .username)
        try c.encode(fullName, forKey: .fullName)
        try c.encode(email, forKey: .email)
        try c.encode(phone, forKey: .phone)
        try c.encode(streetAddress, forKey: .streetAddress)
        try c.encode(postalCode, forKey: .postalCode)
        try c.encode(city, forKey: .city)
        try c.encode(availabilityHours, forKey: .availabilityHours)
        try c.encode(storageCapacityParcels, forKey: .storageCapacityParcels)
        try c.encode(housingType, forKey: .housingType)
        try c.encode(motivation, forKey: .motivation)
        try c.encode(acceptsCharter, forKey: .acceptsCharter)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(requestedAdditionalInfo, forKey: .requestedAdditionalInfo)
        try c.encodeIfPresent(applicantAdditionalReply, forKey: .applicantAdditionalReply)
        try c.encodeIfPresent(adminComment, forKey: .adminComment)
        try c.encodeIfPresent(relayPointId, forKey: .relayPointId)
        try c.encode(loobyTakerCode, forKey: .loobyTakerCode)
        try c.encode(remunerationPerParcel, forKey: .remunerationPerParcel)
        try c.encode(parcelsDeliveredCount, forKey: .parcelsDeliveredCount)
        try c.encode(totalEarnedEuros, forKey: .totalEarnedEuros)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct MarketplaceTakerStatusResponse: Codable, Hashable, Sendable {
    public var ok: Bool
    public var hasApplication: Bool
    public var application: MarketplaceVipleTakerApplication?
    public var validatedTakerRelays: [MarketplaceRelayPoint]?
    public var message: String?

    private enum CodingKeys: String, CodingKey {
        case ok, hasApplication, application, validatedTakerRelays, message
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.ok = (try? c.decode(Bool.self, forKey: .ok)) ?? true
        let app = try? c.decode(MarketplaceVipleTakerApplication.self, forKey: .application)
        self.application = app
        self.hasApplication = (try? c.decode(Bool.self, forKey: .hasApplication)) ?? (app != nil)
        self.validatedTakerRelays = try? c.decode([MarketplaceRelayPoint].self, forKey: .validatedTakerRelays)
        self.message = try? c.decode(String.self, forKey: .message)
    }
}

// MARK: - Profil Utilisateur Viple Live ID & Cross-App SSO

public struct MarketplaceUserProfile: Codable, Hashable, Sendable {
    public var id: String
    public var cid: String?
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

    public var numericUserId: Int {
        Int(id) ?? 0
    }

    public init(
        id: String,
        cid: String? = nil,
        username: String,
        displayName: String,
        email: String,
        avatarUrl: String?,
        bio: String,
        motto: String,
        level: Int,
        xp: Int,
        isLivriaPlus: Bool,
        firstName: String,
        lastName: String,
        phone: String,
        address: String,
        postalCode: String,
        city: String,
        walletBalance: Double
    ) {
        self.id = id
        self.cid = cid
        self.username = username
        self.displayName = displayName
        self.email = email
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.motto = motto
        self.level = level
        self.xp = xp
        self.isLivriaPlus = isLivriaPlus
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.walletBalance = walletBalance
    }

    private enum CodingKeys: String, CodingKey {
        case id, userId, cid, username, displayName, email, avatarUrl
        case bio, motto, level, xp, isLivriaPlus
        case firstName, lastName, phone, address, postalCode, city
        case walletBalance, cashbackBalance
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else if let uIntId = try? c.decode(Int.self, forKey: .userId) {
            self.id = String(uIntId)
        } else if let uStrId = try? c.decode(String.self, forKey: .userId) {
            self.id = uStrId
        } else {
            self.id = "0"
        }
        self.cid = try? c.decode(String.self, forKey: .cid)
        let mail = (try? c.decode(String.self, forKey: .email)) ?? ""
        self.email = mail
        let rawUsername = (try? c.decode(String.self, forKey: .username))
            ?? (mail.components(separatedBy: "@").first ?? "membre")
        self.username = rawUsername.hasPrefix("@") ? String(rawUsername.dropFirst()) : rawUsername
        self.displayName = (try? c.decode(String.self, forKey: .displayName)) ?? self.username
        self.avatarUrl = try? c.decode(String.self, forKey: .avatarUrl)
        self.bio = (try? c.decode(String.self, forKey: .bio)) ?? ""
        self.motto = (try? c.decode(String.self, forKey: .motto)) ?? ""
        self.level = (try? c.decode(Int.self, forKey: .level)) ?? 1
        self.xp = (try? c.decode(Int.self, forKey: .xp)) ?? 0
        self.isLivriaPlus = (try? c.decode(Bool.self, forKey: .isLivriaPlus)) ?? false
        self.firstName = (try? c.decode(String.self, forKey: .firstName)) ?? ""
        self.lastName = (try? c.decode(String.self, forKey: .lastName)) ?? ""
        self.phone = (try? c.decode(String.self, forKey: .phone)) ?? ""
        self.address = (try? c.decode(String.self, forKey: .address)) ?? ""
        self.postalCode = (try? c.decode(String.self, forKey: .postalCode)) ?? ""
        self.city = (try? c.decode(String.self, forKey: .city)) ?? ""
        self.walletBalance = (try? c.decode(Double.self, forKey: .walletBalance))
            ?? (try? c.decode(Double.self, forKey: .cashbackBalance))
            ?? 0.0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(cid, forKey: .cid)
        try c.encode(username, forKey: .username)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(email, forKey: .email)
        try c.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try c.encode(bio, forKey: .bio)
        try c.encode(motto, forKey: .motto)
        try c.encode(level, forKey: .level)
        try c.encode(xp, forKey: .xp)
        try c.encode(isLivriaPlus, forKey: .isLivriaPlus)
        try c.encode(firstName, forKey: .firstName)
        try c.encode(lastName, forKey: .lastName)
        try c.encode(phone, forKey: .phone)
        try c.encode(address, forKey: .address)
        try c.encode(postalCode, forKey: .postalCode)
        try c.encode(city, forKey: .city)
        try c.encode(walletBalance, forKey: .walletBalance)
    }
}

public struct MarketplaceCrossAppDiscoverResponse: Codable, Hashable, Sendable {
    public let hasSession: Bool
    public let sourceApp: String?
    public let token: String?
    public let user: MarketplaceUserProfile?

    private enum CodingKeys: String, CodingKey {
        case hasSession, hasDetectedAccount, sourceApp, token, user, account
    }

    private struct AccountSourceHelper: Decodable {
        let sourceApp: String?
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.hasSession = (try? c.decode(Bool.self, forKey: .hasSession))
            ?? (try? c.decode(Bool.self, forKey: .hasDetectedAccount))
            ?? false
        self.token = try? c.decode(String.self, forKey: .token)
        self.user = (try? c.decode(MarketplaceUserProfile.self, forKey: .user))
            ?? (try? c.decode(MarketplaceUserProfile.self, forKey: .account))
        let topSource = try? c.decode(String.self, forKey: .sourceApp)
        let nestedSource = (try? c.decode(AccountSourceHelper.self, forKey: .account))?.sourceApp
        self.sourceApp = topSource ?? nestedSource ?? "Livria Store"
    }
}

public struct MarketplaceAuthResponse: Codable, Hashable, Sendable {
    public var success: Bool
    public var message: String
    public var token: String?
    public var user: MarketplaceUserProfile?

    private enum CodingKeys: String, CodingKey {
        case ok, success, message, error, token, user
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.success = (try? c.decode(Bool.self, forKey: .ok))
            ?? (try? c.decode(Bool.self, forKey: .success))
            ?? false
        self.message = (try? c.decode(String.self, forKey: .message))
            ?? (try? c.decode(String.self, forKey: .error))
            ?? (self.success ? "Connecté à Viple Live ID" : "Identifiants Viple Live ID incorrects.")
        self.token = try? c.decode(String.self, forKey: .token)
        self.user = try? c.decode(MarketplaceUserProfile.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(success, forKey: .success)
        try c.encode(message, forKey: .message)
        try c.encodeIfPresent(token, forKey: .token)
        try c.encodeIfPresent(user, forKey: .user)
    }
}

public struct MarketplaceBootstrapResponse: Codable, Hashable, Sendable {
    public var maintenanceMode: Bool?
    public var maintenanceMessage: String?
    public var commissionFee: Double?
    public var commissionLabel: String?
    public var shippingFee: Double?
    public var listings: [MarketplaceListing]
    public var favoriteListingIds: [Int]
    public var conversations: [MarketplaceConversationPreview]
    public var offers: [MarketplaceOffer]
    public var orders: [MarketplaceOrder]
    public var relayPoints: [MarketplaceRelayPoint]
    public var takerApplication: MarketplaceVipleTakerApplication?
    public var currentUser: MarketplaceUserProfile?

    private enum CodingKeys: String, CodingKey {
        case maintenanceMode, maintenanceEnabled, maintenanceMessage
        case commissionFee, commissionAmount, commissionLabel, shippingFee
        case listings, favoriteListingIds, conversations, offers, orders
        case relayPoints, communityRelays, upsRelays
        case takerApplication, currentUser, user
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
        let favIds = (try? c.decode([Int].self, forKey: .favoriteListingIds)) ?? []
        self.favoriteListingIds = favIds
        var decodedListings = (try? c.decode([MarketplaceListing].self, forKey: .listings)) ?? []
        if !favIds.isEmpty {
            let favSet = Set(favIds.map { String($0) })
            for idx in decodedListings.indices {
                if favSet.contains(decodedListings[idx].id) {
                    decodedListings[idx].isFavorited = true
                }
            }
        }
        self.listings = decodedListings
        self.conversations = (try? c.decode([MarketplaceConversationPreview].self, forKey: .conversations)) ?? []
        self.offers = (try? c.decode([MarketplaceOffer].self, forKey: .offers)) ?? []
        self.orders = (try? c.decode([MarketplaceOrder].self, forKey: .orders)) ?? []

        let directRelays = (try? c.decode([MarketplaceRelayPoint].self, forKey: .relayPoints)) ?? []
        let commRelays = (try? c.decode([MarketplaceRelayPoint].self, forKey: .communityRelays)) ?? []
        let upsPoints = (try? c.decode([MarketplaceRelayPoint].self, forKey: .upsRelays)) ?? []
        self.relayPoints = directRelays + commRelays + upsPoints

        self.takerApplication = try? c.decode(MarketplaceVipleTakerApplication.self, forKey: .takerApplication)
        self.currentUser = (try? c.decode(MarketplaceUserProfile.self, forKey: .currentUser))
            ?? (try? c.decode(MarketplaceUserProfile.self, forKey: .user))
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(maintenanceMode, forKey: .maintenanceMode)
        try c.encodeIfPresent(maintenanceMessage, forKey: .maintenanceMessage)
        try c.encodeIfPresent(commissionFee, forKey: .commissionFee)
        try c.encodeIfPresent(commissionLabel, forKey: .commissionLabel)
        try c.encodeIfPresent(shippingFee, forKey: .shippingFee)
        try c.encode(listings, forKey: .listings)
        try c.encode(favoriteListingIds, forKey: .favoriteListingIds)
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

    private enum CodingKeys: String, CodingKey {
        case id, title, url, gifUrl
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.title = (try? c.decode(String.self, forKey: .title)) ?? "GIF"
        self.url = (try? c.decode(String.self, forKey: .gifUrl))
            ?? (try? c.decode(String.self, forKey: .url))
            ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(url, forKey: .url)
    }
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
