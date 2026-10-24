import Foundation

// MARK: - Erreurs Réseau & Maintenance Livria Marketplace

public enum MarketplaceServerError: Error, LocalizedError, Sendable {
    case maintenanceOrDown(String)

    public var errorDescription: String? {
        switch self {
        case .maintenanceOrDown(let msg):
            return msg
        }
    }
}

public enum MarketplaceURLResolver {
    public static let baseURL = "https://livria.store"
    public static let identityWebURL = "https://id.viple.fr"

    public static func resolveMediaURL(_ raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return raw
        }
        let path = raw.hasPrefix("/") ? raw : "/\(raw)"
        return "\(baseURL)\(path)"
    }
}

// MARK: - Client API Livria Marketplace (Connecté en temps réel à livria.store/api/mobile/v1 & Viple Live ID)

public actor LivriaMarketplaceAPIClient {
    public static let shared = LivriaMarketplaceAPIClient()

    public static let globalOutageMessage = "Oups, le serveur a le moral dans les chaussette, il revient bientot"

    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?
    private var currentUserId: Int = 0
    private var currentEmail: String = ""
    private var currentCid: String = ""
    private let vendorId: String

    public init(baseURLString: String = MarketplaceURLResolver.baseURL) {
        self.baseURL = URL(string: baseURLString) ?? URL(string: "https://livria.store")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        self.session = URLSession(configuration: config)
        self.authToken = UserDefaults.standard.string(forKey: "livria_marketplace_viple_token")
        if let savedVendor = UserDefaults.standard.string(forKey: "livria_marketplace_vendor_id"), !savedVendor.isEmpty {
            self.vendorId = savedVendor
        } else {
            let generated = UUID().uuidString
            UserDefaults.standard.set(generated, forKey: "livria_marketplace_vendor_id")
            self.vendorId = generated
        }
        if let savedData = UserDefaults.standard.data(forKey: "livria_marketplace_viple_user_v1"),
           let savedUser = try? JSONDecoder().decode(MarketplaceUserProfile.self, from: savedData) {
            self.currentUserId = savedUser.numericUserId
            self.currentEmail = savedUser.email
            self.currentCid = savedUser.cid ?? ""
        }
    }

    public func setSession(token: String?, user: MarketplaceUserProfile?) {
        self.authToken = token
        if let token, !token.isEmpty {
            UserDefaults.standard.set(token, forKey: "livria_marketplace_viple_token")
        } else {
            UserDefaults.standard.removeObject(forKey: "livria_marketplace_viple_token")
        }

        if let user {
            self.currentUserId = user.numericUserId
            self.currentEmail = user.email
            self.currentCid = user.cid ?? ""
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "livria_marketplace_viple_user_v1")
            }
        } else {
            self.currentUserId = 0
            self.currentEmail = ""
            self.currentCid = ""
            UserDefaults.standard.removeObject(forKey: "livria_marketplace_viple_user_v1")
        }
    }

    public func setToken(_ token: String?) {
        self.authToken = token
        if let token, !token.isEmpty {
            UserDefaults.standard.set(token, forKey: "livria_marketplace_viple_token")
        } else {
            UserDefaults.standard.removeObject(forKey: "livria_marketplace_viple_token")
        }
    }

    public func getToken() -> String? {
        authToken
    }

    // MARK: - Bootstrap & Maintenance Check (20s Timeout / HTTP 503 / /admin Maintenance)

    public func fetchBootstrap() async throws -> MarketplaceBootstrapResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/mobile/v1/marketplace/bootstrap"), resolvingAgainstBaseURL: false)
        var queryItems: [URLQueryItem] = []
        if currentUserId > 0 {
            queryItems.append(URLQueryItem(name: "userId", value: String(currentUserId)))
        }
        if !currentEmail.isEmpty {
            queryItems.append(URLQueryItem(name: "email", value: currentEmail))
        }
        if !currentCid.isEmpty {
            queryItems.append(URLQueryItem(name: "cid", value: currentCid))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        let url = components?.url ?? baseURL.appendingPathComponent("api/mobile/v1/marketplace/bootstrap")

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 20
        req.setValue("Livria Marketplace", forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw MarketplaceServerError.maintenanceOrDown(Self.globalOutageMessage)
        }

        guard let http = response as? HTTPURLResponse else {
            throw MarketplaceServerError.maintenanceOrDown(Self.globalOutageMessage)
        }
        if http.statusCode >= 500 {
            throw MarketplaceServerError.maintenanceOrDown(Self.globalOutageMessage)
        }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(MarketplaceBootstrapResponse.self, from: data)
        if decoded.maintenanceMode == true {
            throw MarketplaceServerError.maintenanceOrDown(decoded.maintenanceMessage ?? Self.globalOutageMessage)
        }
        return decoded
    }

    // MARK: - Authentification Viple Live ID Réelle & Cross-App SSO

    public func loginVipleLiveId(emailOrUsername: String, password: String) async throws -> MarketplaceAuthResponse {
        return try await postAuthJSON(
            path: "api/mobile/v1/auth/login",
            body: [
                "email": emailOrUsername,
                "emailOrUsername": emailOrUsername,
                "password": password
            ]
        )
    }

    public func registerVipleLiveId(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> MarketplaceAuthResponse {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await postAuthJSON(
            path: "api/mobile/v1/auth/register",
            body: [
                "emailMode": "custom",
                "customEmail": cleanEmail,
                "email": cleanEmail,
                "username": username,
                "displayName": displayName,
                "firstName": displayName,
                "lastName": "",
                "password": password
            ]
        )
    }

    public func loginWithApple(
        appleUserId: String,
        email: String?,
        fullName: String?,
        identityToken: String?
    ) async throws -> MarketplaceAuthResponse {
        return try await postAuthJSON(
            path: "api/mobile/v1/auth/apple",
            body: [
                "appleUserId": appleUserId,
                "email": email ?? "",
                "fullName": fullName ?? "",
                "identityToken": identityToken ?? ""
            ]
        )
    }

    public func registerCrossAppSession(sourceApp: String = "Livria Marketplace") async {
        guard currentUserId > 0 || !currentEmail.isEmpty else { return }
        struct Payload: Encodable {
            let sourceApp: String
            let userId: Int
            let email: String
            let cid: String
            let vendorId: String
        }
        struct Resp: Decodable { let ok: Bool? }
        _ = try? await postJSON(
            path: "api/mobile/v1/sso/announce",
            body: Payload(
                sourceApp: sourceApp,
                userId: currentUserId,
                email: currentEmail,
                cid: currentCid,
                vendorId: vendorId
            )
        ) as Resp
    }

    public func clearCrossAppSession() async {
        struct Payload: Encodable {
            let sourceApp: String
            let vendorId: String
        }
        struct Resp: Decodable { let ok: Bool? }
        _ = try? await postJSON(
            path: "api/mobile/v1/sso/clear",
            body: Payload(sourceApp: "Livria Marketplace", vendorId: vendorId)
        ) as Resp
    }

    public func discoverCrossAppSession(targetApp: String = "Livria Marketplace") async -> MarketplaceCrossAppDiscoverResponse? {
        let encodedApp = targetApp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Livria%20Marketplace"
        let encodedVendor = vendorId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vendorId
        guard let url = URL(string: "\(baseURL.absoluteString)/api/mobile/v1/sso/discover?app=\(encodedApp)&vendorId=\(encodedVendor)") else {
            return nil
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 8
        req.setValue("Livria Marketplace", forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        guard let (data, response) = try? await session.data(for: req),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(MarketplaceCrossAppDiscoverResponse.self, from: data),
              decoded.hasSession,
              decoded.user != nil else {
            return nil
        }
        return decoded
    }

    public func acceptCrossAppSession(user: MarketplaceUserProfile) async -> MarketplaceAuthResponse? {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let vendorId: String
        }
        return try? await postAuthJSON(
            path: "api/mobile/v1/sso/accept",
            body: Payload(
                userId: user.numericUserId,
                email: user.email,
                cid: user.cid ?? "",
                vendorId: vendorId
            )
        )
    }

    public func deleteAccount() async -> Bool {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
        }
        struct DeleteResp: Decodable {
            let ok: Bool?
            let success: Bool?
        }
        if let resp: DeleteResp = try? await postJSON(
            path: "api/mobile/v1/auth/delete-account",
            body: Payload(userId: currentUserId, email: currentEmail, cid: currentCid)
        ) {
            return (resp.ok ?? resp.success ?? false)
        }
        return false
    }

    // MARK: - Upload Photo de Profil Recadrée (In-App Avatar Cropper)

    public func uploadCroppedAvatar(jpegData: Data, fileName: String = "avatar_cropped.jpg") async -> String? {
        struct UploadPayload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let fileName: String
            let extensionName: String
            let mimeType: String
            let base64Data: String

            enum CodingKeys: String, CodingKey {
                case userId, email, cid, fileName
                case extensionName = "extension"
                case mimeType, base64Data
            }
        }
        struct UploadResp: Decodable {
            let ok: Bool?
            let avatarUrl: String?
        }
        let b64 = jpegData.base64EncodedString()
        if let resp: UploadResp = try? await postJSON(
            path: "api/mobile/v1/profile/avatar",
            body: UploadPayload(
                userId: currentUserId,
                email: currentEmail,
                cid: currentCid,
                fileName: fileName,
                extensionName: "jpg",
                mimeType: "image/jpeg",
                base64Data: b64
            )
        ), let avatarUrl = resp.avatarUrl, !avatarUrl.isEmpty {
            return MarketplaceURLResolver.resolveMediaURL(avatarUrl)
        }
        return nil
    }

    // MARK: - Upload Média Marketplace (Photos d'Annonces, Photos Chat, Messages Vocaux .m4a)

    public func uploadMarketplaceMedia(data: Data, fileName: String, mimeType: String) async -> String? {
        struct UploadPayload: Encodable {
            let mediaKind: String
            let extensionName: String
            let fileName: String
            let mimeType: String
            let base64Data: String

            enum CodingKeys: String, CodingKey {
                case mediaKind
                case extensionName = "extension"
                case fileName, mimeType, base64Data
            }
        }
        struct UploadResp: Decodable {
            let ok: Bool?
            let url: String?
        }
        let isVoice = mimeType.lowercased().contains("audio") || fileName.lowercased().hasSuffix(".m4a")
        let b64 = data.base64EncodedString()
        if let resp: UploadResp = try? await postJSON(
            path: "api/mobile/v1/marketplace/media/upload",
            body: UploadPayload(
                mediaKind: isVoice ? "voice" : "image",
                extensionName: isVoice ? "m4a" : "jpg",
                fileName: fileName,
                mimeType: mimeType,
                base64Data: b64
            )
        ), let url = resp.url, !url.isEmpty {
            return MarketplaceURLResolver.resolveMediaURL(url)
        }
        return nil
    }

    // MARK: - Recherche ISBN Réelle (Catalogue Livria + Google Books)

    public func lookupISBN(_ isbn: String) async -> MarketplaceISBNLookupResult? {
        struct ISBNBackendResp: Decodable {
            let ok: Bool?
            let found: Bool?
            let isbn: String?
            let title: String?
            let author: String?
            let publisher: String?
            let subcategory: String?
            let description: String?
            let coverUrl: String?
            let suggestedPrice: Double?
        }
        let clean = isbn.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? clean
        guard let resp: ISBNBackendResp = try? await getJSON(path: "api/mobile/v1/marketplace/isbn/\(encoded)"),
              resp.found == true,
              let title = resp.title, !title.isEmpty else {
            return nil
        }
        let suggested = resp.suggestedPrice ?? 8.00
        return MarketplaceISBNLookupResult(
            isbn: resp.isbn ?? clean,
            title: title,
            author: resp.author ?? "",
            publisher: resp.publisher ?? "",
            releaseYear: "2024",
            suggestedPrice: suggested,
            originalRetailPrice: max(suggested + 4.00, suggested * 1.6),
            subcategory: resp.subcategory ?? "Romans & Littérature",
            coverUrl: resp.coverUrl ?? "",
            summary: resp.description ?? ""
        )
    }

    // MARK: - Recherche de GIFs Animés (API Giphy via Backend Livria)

    public func searchGifs(query: String) async -> [MarketplaceGifItem] {
        struct GifResp: Decodable {
            let ok: Bool?
            let gifs: [MarketplaceGifItem]?
        }
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "\(baseURL.absoluteString)/api/mobile/v1/marketplace/gifs/search?q=\(q)") else {
            return []
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 10
        if let (data, response) = try? await session.data(for: req),
           let http = response as? HTTPURLResponse,
           (200...299).contains(http.statusCode),
           let decoded = try? JSONDecoder().decode(GifResp.self, from: data),
           let gifs = decoded.gifs {
            return gifs
        }
        return []
    }

    // MARK: - Annonces Marketplace (Création, Modification, Suppression, Favoris)

    public func createListing(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        struct CreatePayload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let category: String
            let subcategory: String
            let title: String
            let subtitleOrCreator: String
            let description: String
            let condition: String
            let sellerPrice: Double
            let photoUrls: [String]
            let isbnOrBarcode: String
            let publisherOrLabel: String
            let formatOrMedium: String
            let clothingSize: String
            let brand: String
            let publicationYear: Int
        }
        struct Resp: Decodable {
            let ok: Bool?
            let listing: MarketplaceListing?
        }
        let payload = CreatePayload(
            userId: currentUserId,
            email: currentEmail,
            cid: currentCid,
            category: listing.category,
            subcategory: listing.subcategory,
            title: listing.title,
            subtitleOrCreator: listing.authorOrArtist?.isEmpty == false ? listing.authorOrArtist! : listing.subtitle,
            description: listing.description,
            condition: listing.condition,
            sellerPrice: listing.price,
            photoUrls: listing.photos,
            isbnOrBarcode: listing.isbn ?? "",
            publisherOrLabel: listing.publisherOrBrand ?? "",
            formatOrMedium: listing.subtitle,
            clothingSize: listing.clothingSize ?? "",
            brand: listing.publisherOrBrand ?? "",
            publicationYear: Int(listing.releaseYear ?? "2024") ?? 2024
        )
        let resp: Resp = try await postJSON(path: "api/mobile/v1/marketplace/listings/create", body: payload)
        return resp.listing ?? listing
    }

    public func updateListing(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        struct UpdatePayload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let listingId: Int
            let category: String
            let subcategory: String
            let title: String
            let subtitleOrCreator: String
            let description: String
            let condition: String
            let sellerPrice: Double
            let photoUrls: [String]
            let isbnOrBarcode: String
            let publisherOrLabel: String
            let clothingSize: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let listing: MarketplaceListing?
        }
        let payload = UpdatePayload(
            userId: currentUserId,
            email: currentEmail,
            cid: currentCid,
            listingId: Int(listing.id) ?? 0,
            category: listing.category,
            subcategory: listing.subcategory,
            title: listing.title,
            subtitleOrCreator: listing.authorOrArtist?.isEmpty == false ? listing.authorOrArtist! : listing.subtitle,
            description: listing.description,
            condition: listing.condition,
            sellerPrice: listing.price,
            photoUrls: listing.photos,
            isbnOrBarcode: listing.isbn ?? "",
            publisherOrLabel: listing.publisherOrBrand ?? "",
            clothingSize: listing.clothingSize ?? ""
        )
        let resp: Resp = try await postJSON(path: "api/mobile/v1/marketplace/listings/update", body: payload)
        return resp.listing ?? listing
    }

    public func deleteListing(listingId: String) async throws -> Bool {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let listingId: String
        }
        struct Resp: Decodable { let ok: Bool? }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/listings/delete",
            body: Payload(userId: currentUserId, email: currentEmail, cid: currentCid, listingId: listingId)
        )
        return resp.ok ?? false
    }

    public func toggleFavorite(listingId: String) async -> Bool? {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let listingId: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let isFavorite: Bool?
            let isFavorited: Bool?
        }
        if let resp: Resp = try? await postJSON(
            path: "api/mobile/v1/marketplace/listings/favorite",
            body: Payload(userId: currentUserId, email: currentEmail, cid: currentCid, listingId: listingId)
        ) {
            return resp.isFavorite ?? resp.isFavorited
        }
        return nil
    }

    // MARK: - Offres de Prix & Messagerie Directe sur Annonces

    public func createOffer(listingId: String, offeredPrice: Double, message: String) async throws -> (MarketplaceOffer?, String?) {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let listingId: String
            let offeredPrice: Double
            let message: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let offer: MarketplaceOffer?
            let conversationId: Int?
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/offers/create",
            body: Payload(
                userId: currentUserId,
                email: currentEmail,
                cid: currentCid,
                listingId: listingId,
                offeredPrice: offeredPrice,
                message: message
            )
        )
        return (resp.offer, resp.conversationId.map { String($0) })
    }

    public func respondToOffer(offerId: String, accept: Bool) async throws -> MarketplaceOffer? {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let offerId: String
            let action: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let offer: MarketplaceOffer?
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/offers/respond",
            body: Payload(
                userId: currentUserId,
                email: currentEmail,
                cid: currentCid,
                offerId: offerId,
                action: accept ? "accept" : "decline"
            )
        )
        return resp.offer
    }

    public func fetchConversationThread(conversationId: String) async throws -> MarketplaceThreadResponse {
        let encoded = conversationId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? conversationId
        let encodedEmail = currentEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await getJSON(path: "api/mobile/v1/marketplace/messages/thread/\(encoded)?userId=\(currentUserId)&email=\(encodedEmail)")
    }

    public func sendDirectMessage(
        conversationId: String?,
        listingId: String,
        recipientUsername: String,
        text: String,
        imageUrl: String? = nil,
        gifUrl: String? = nil,
        audioUrl: String? = nil,
        audioDurationSeconds: Int? = nil,
        offerAmount: Double? = nil
    ) async throws -> (MarketplaceDirectMessage?, String?) {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let conversationId: Int
            let listingId: Int
            let body: String
            let attachmentType: String
            let attachmentUrl: String
            let voiceDurationSec: Int
        }
        struct Resp: Decodable {
            let ok: Bool?
            let conversationId: Int?
            let messageItem: MarketplaceDirectMessage?
        }
        let attType: String
        let attUrl: String
        if let audioUrl, !audioUrl.isEmpty {
            attType = "voice"
            attUrl = audioUrl
        } else if let gifUrl, !gifUrl.isEmpty {
            attType = "gif"
            attUrl = gifUrl
        } else if let imageUrl, !imageUrl.isEmpty {
            attType = "image"
            attUrl = imageUrl
        } else {
            attType = "none"
            attUrl = ""
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/messages/send",
            body: Payload(
                userId: currentUserId,
                email: currentEmail,
                cid: currentCid,
                conversationId: Int(conversationId ?? "0") ?? 0,
                listingId: Int(listingId) ?? 0,
                body: text,
                attachmentType: attType,
                attachmentUrl: attUrl,
                voiceDurationSec: audioDurationSeconds ?? 0
            )
        )
        return (resp.messageItem, resp.conversationId.map { String($0) })
    }

    // MARK: - Checkout Complet (PayPal, Apple Pay, UPS Access Point & Viple Taker)

    public func checkoutListing(
        listingId: String,
        agreedPrice: Double?,
        paymentMethod: String,
        deliveryMode: String,
        relayId: String?,
        relayName: String?,
        relayAddress: String?,
        isVipleTakerRelay: Bool
    ) async throws -> MarketplaceOrder {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let listingId: String
            let agreedPrice: Double?
            let paymentMethod: String
            let deliveryMode: String
            let relayOrAddress: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let order: MarketplaceOrder
        }
        let summary = [relayName, relayAddress].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/checkout",
            body: Payload(
                userId: currentUserId,
                email: currentEmail,
                cid: currentCid,
                listingId: listingId,
                agreedPrice: agreedPrice,
                paymentMethod: paymentMethod,
                deliveryMode: deliveryMode,
                relayOrAddress: summary.isEmpty ? deliveryMode : summary
            )
        )
        return resp.order
    }

    // MARK: - Recherche Live Points Relais UPS & Viple Taker

    public func searchRelays(postalCode: String, city: String) async -> [MarketplaceRelayPoint] {
        struct RelaysEnvelope: Decodable {
            let communityRelays: [MarketplaceRelayPoint]?
            let upsRelays: [MarketplaceRelayPoint]?
            let points: [MarketplaceRelayPoint]?
        }
        let cp = postalCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let c = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let env: RelaysEnvelope = try? await getJSON(path: "api/mobile/v1/relays?postalCode=\(cp)&city=\(c)") {
            return (env.communityRelays ?? []) + (env.upsRelays ?? []) + (env.points ?? [])
        }
        if let points: [MarketplaceRelayPoint] = try? await getJSON(path: "api/mobile/v1/relays?postalCode=\(cp)&city=\(c)") {
            return points
        }
        return []
    }

    // MARK: - Devenir Viple Taker (Point Relais Particulier — 1,00 € / colis)

    public func fetchTakerStatus() async throws -> MarketplaceTakerStatusResponse {
        let encodedEmail = currentEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await getJSON(path: "api/mobile/v1/taker/status?userId=\(currentUserId)&email=\(encodedEmail)")
    }

    public func submitTakerApplication(
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
        additionalReply: String?
    ) async throws -> MarketplaceTakerStatusResponse {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let displayName: String
            let firstName: String
            let lastName: String
            let phone: String
            let address: String
            let postalCode: String
            let city: String
            let openingHours: String
            let storageCapacity: String
            let housingType: String
            let motivationAndAccessNotes: String
            let supplementaryResponse: String
            let sourceApp: String
        }
        let parts = fullName.split(separator: " ", maxSplits: 1).map(String.init)
        let first = parts.first ?? fullName
        let last = parts.count > 1 ? parts[1] : ""
        return try await postJSON(
            path: "api/mobile/v1/taker/apply",
            body: Payload(
                userId: currentUserId,
                email: email.isEmpty ? currentEmail : email,
                cid: currentCid,
                displayName: fullName,
                firstName: first,
                lastName: last,
                phone: phone,
                address: streetAddress,
                postalCode: postalCode,
                city: city,
                openingHours: availabilityHours,
                storageCapacity: "\(storageCapacityParcels) colis / semaine",
                housingType: housingType,
                motivationAndAccessNotes: motivation,
                supplementaryResponse: additionalReply ?? "",
                sourceApp: "Livria Marketplace"
            )
        )
    }

    public func cancelTakerApplication(applicationId: String?) async throws -> MarketplaceTakerStatusResponse {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let applicationId: String?
        }
        return try await postJSON(
            path: "api/mobile/v1/taker/cancel",
            body: Payload(userId: currentUserId, email: currentEmail, applicationId: applicationId)
        )
    }

    // MARK: - Suivi Colis Viple Delivery Intégré (Sans Ouvrir le Site Externe) & Confirmation de Réception

    public func trackVipleDelivery(trackingOrOrderCode: String, orderId: String? = nil) async -> MarketplaceVipleDeliveryTrackResponse? {
        let cleanCode = trackingOrOrderCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedCode = cleanCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanCode
        let encodedOrder = (orderId ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let path = "api/mobile/v1/delivery/track?code=\(encodedCode)&orderId=\(encodedOrder)&source=marketplace&userId=\(currentUserId)"
        return try? await getJSON(path: path)
    }

    public func confirmOrderReceipt(orderId: String) async -> (ok: Bool, message: String, newStatus: String?) {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let cid: String
            let orderId: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let message: String?
            let status: String?
        }
        if let resp: Resp = try? await postJSON(
            path: "api/mobile/v1/marketplace/orders/confirm-receipt",
            body: Payload(userId: currentUserId, email: currentEmail, cid: currentCid, orderId: orderId)
        ) {
            return (resp.ok ?? true, resp.message ?? "Réception du colis confirmée (+25 XP) !", resp.status)
        }
        return (true, "Réception du colis confirmée !", "Colis remis et réception confirmée")
    }

    public func reportListing(listingId: String, reason: String, details: String) async -> Bool {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let listingId: String
            let reason: String
            let details: String
        }
        struct Resp: Decodable {
            let ok: Bool?
        }
        if let resp: Resp = try? await postJSON(
            path: "api/mobile/v1/marketplace/listings/report",
            body: Payload(userId: currentUserId, email: currentEmail, listingId: listingId, reason: reason, details: details)
        ) {
            return resp.ok ?? true
        }
        return true
    }

    // MARK: - Réglages Synchronisés, Export RGPD & Diagnostics Non-Bloquants

    public func fetchUserPreferences() async -> MarketplaceUserPreferences? {
        struct Resp: Decodable {
            let ok: Bool?
            let preferences: MarketplaceUserPreferences?
        }
        let encodedEmail = currentEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let resp: Resp = try? await getJSON(path: "api/mobile/v1/account/preferences?userId=\(currentUserId)&email=\(encodedEmail)&app=marketplace") {
            return resp.preferences
        }
        return nil
    }

    public func saveUserPreferences(_ prefs: MarketplaceUserPreferences) async -> Bool {
        struct Payload: Encodable {
            let userId: Int
            let email: String
            let app: String
            let preferences: MarketplaceUserPreferences
        }
        struct Resp: Decodable { let ok: Bool? }
        if let resp: Resp = try? await postJSON(
            path: "api/mobile/v1/account/preferences",
            body: Payload(userId: currentUserId, email: currentEmail, app: "marketplace", preferences: prefs)
        ) {
            return resp.ok ?? true
        }
        return false
    }

    public func exportPrivacyData() async -> String? {
        let encodedEmail = currentEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let fullURL = URL(string: "\(baseURL.absoluteString)/api/mobile/v1/account/privacy-export?userId=\(currentUserId)&email=\(encodedEmail)")
            ?? baseURL.appendingPathComponent("api/mobile/v1/account/privacy-export")
        var req = URLRequest(url: fullURL)
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.setValue("Livria Marketplace", forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue("26.10", forHTTPHeaderField: "X-Viple-Client-Version")
        req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Viple-Request-Id")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        guard let (data, response) = try? await session.data(for: req),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let jsonObj = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return str
    }

    public func pingDiagnostics() async -> (ping: MarketplaceDiagnosticsPingResponse?, latencyMs: Int) {
        let start = Date()
        let resp: MarketplaceDiagnosticsPingResponse? = try? await getJSON(path: "api/mobile/v1/diagnostics/ping?app=marketplace")
        let ms = max(1, Int(Date().timeIntervalSince(start) * 1000))
        return (resp, ms)
    }

    // MARK: - Helpers HTTP (Avec En-têtes d'Audit & Idempotence Non-Bloquants)

    private func getJSON<T: Decodable>(path: String) async throws -> T {
        let fullURL = URL(string: "\(baseURL.absoluteString)/\(path)") ?? baseURL.appendingPathComponent(path)
        var req = URLRequest(url: fullURL)
        req.httpMethod = "GET"
        req.timeoutInterval = 20
        req.setValue("Livria Marketplace", forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue("26.10", forHTTPHeaderField: "X-Viple-Client-Version")
        req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Viple-Request-Id")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func postJSON<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        let fullURL = URL(string: "\(baseURL.absoluteString)/\(path)") ?? baseURL.appendingPathComponent(path)
        var req = URLRequest(url: fullURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Livria Marketplace", forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue("26.10", forHTTPHeaderField: "X-Viple-Client-Version")
        req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Viple-Request-Id")
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Idempotency-Key")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func postAuthJSON<B: Encodable>(path: String, body: B) async throws -> MarketplaceAuthResponse {
        let fullURL = URL(string: "\(baseURL.absoluteString)/\(path)") ?? baseURL.appendingPathComponent(path)
        var req = URLRequest(url: fullURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Livria Marketplace", forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue("26.10", forHTTPHeaderField: "X-Viple-Client-Version")
        req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Viple-Request-Id")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(MarketplaceAuthResponse.self, from: data)
    }
}
