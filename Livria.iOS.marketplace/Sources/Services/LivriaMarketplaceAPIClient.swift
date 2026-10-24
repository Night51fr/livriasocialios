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

// MARK: - Client API Livria Marketplace (Connecté à livria.store/api/mobile/v1)

public actor LivriaMarketplaceAPIClient {
    public static let shared = LivriaMarketplaceAPIClient()

    public static let globalOutageMessage = "Oups, le serveur a le moral dans les chaussette, il revient bientot"

    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?

    public init(baseURLString: String = MarketplaceURLResolver.baseURL) {
        self.baseURL = URL(string: baseURLString) ?? URL(string: "https://livria.store")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        self.session = URLSession(configuration: config)
        self.authToken = UserDefaults.standard.string(forKey: "livria_marketplace_viple_token")
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
        let url = baseURL.appendingPathComponent("api/mobile/v1/marketplace/bootstrap")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 20
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

    // MARK: - Authentification Viple Live ID & Cross-App SSO

    public func loginVipleLiveId(emailOrUsername: String, password: String) async throws -> MarketplaceAuthResponse {
        return try await postJSON(
            path: "api/mobile/v1/auth/login",
            body: ["emailOrUsername": emailOrUsername, "password": password]
        )
    }

    public func registerVipleLiveId(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> MarketplaceAuthResponse {
        return try await postJSON(
            path: "api/mobile/v1/auth/register",
            body: [
                "username": username,
                "displayName": displayName,
                "email": email,
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
        return try await postJSON(
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
        guard let token = authToken, !token.isEmpty else { return }
        struct Payload: Encodable {
            let sourceApp: String
            let token: String
        }
        struct Resp: Decodable { let ok: Bool? }
        _ = try? await postJSON(
            path: "api/mobile/v1/auth/cross-app-register",
            body: Payload(sourceApp: sourceApp, token: token)
        ) as Resp
    }

    public func clearCrossAppSession() async {
        struct EmptyBody: Encodable {}
        struct Resp: Decodable { let ok: Bool? }
        _ = try? await postJSON(path: "api/mobile/v1/auth/cross-app-clear", body: EmptyBody()) as Resp
    }

    public func discoverCrossAppSession(targetApp: String = "Livria Marketplace") async -> MarketplaceCrossAppDiscoverResponse? {
        let encoded = targetApp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Livria%20Marketplace"
        guard let url = URL(string: "\(baseURL.absoluteString)/api/mobile/v1/auth/cross-app-discover?targetApp=\(encoded)") else {
            return nil
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 8
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

    public func deleteAccount() async -> Bool {
        struct EmptyBody: Encodable {}
        struct DeleteResp: Decodable {
            let ok: Bool?
            let success: Bool?
        }
        if let resp: DeleteResp = try? await postJSON(path: "api/mobile/v1/auth/delete-account", body: EmptyBody()) {
            return (resp.ok ?? resp.success ?? true)
        }
        return true
    }

    // MARK: - Upload Photo de Profil Recadrée (In-App Avatar Cropper)

    public func uploadCroppedAvatar(jpegData: Data, fileName: String = "avatar_cropped.jpg") async -> String? {
        struct UploadPayload: Encodable {
            let fileName: String
            let mimeType: String
            let base64Data: String
        }
        struct UploadResp: Decodable {
            let ok: Bool?
            let avatarUrl: String?
        }
        let b64 = jpegData.base64EncodedString()
        if let resp: UploadResp = try? await postJSON(
            path: "api/mobile/v1/profile/avatar",
            body: UploadPayload(fileName: fileName, mimeType: "image/jpeg", base64Data: b64)
        ), let avatarUrl = resp.avatarUrl, !avatarUrl.isEmpty {
            return MarketplaceURLResolver.resolveMediaURL(avatarUrl)
        }
        return nil
    }

    // MARK: - Upload Média Marketplace (Photos d'Annonces, Photos Chat, Messages Vocaux .m4a)

    public func uploadMarketplaceMedia(data: Data, fileName: String, mimeType: String) async -> String? {
        struct UploadPayload: Encodable {
            let fileName: String
            let mimeType: String
            let base64Data: String
        }
        struct UploadResp: Decodable {
            let ok: Bool?
            let url: String?
        }
        let b64 = data.base64EncodedString()
        if let resp: UploadResp = try? await postJSON(
            path: "api/mobile/v1/marketplace/media/upload",
            body: UploadPayload(fileName: fileName, mimeType: mimeType, base64Data: b64)
        ), let url = resp.url, !url.isEmpty {
            return MarketplaceURLResolver.resolveMediaURL(url)
        }
        return nil
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
        struct Resp: Decodable {
            let ok: Bool?
            let listing: MarketplaceListing?
        }
        let resp: Resp = try await postJSON(path: "api/mobile/v1/marketplace/listings/create", body: listing)
        return resp.listing ?? listing
    }

    public func updateListing(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        struct Resp: Decodable {
            let ok: Bool?
            let listing: MarketplaceListing?
        }
        let resp: Resp = try await postJSON(path: "api/mobile/v1/marketplace/listings/update", body: listing)
        return resp.listing ?? listing
    }

    public func deleteListing(listingId: String) async throws -> Bool {
        struct Payload: Encodable { let listingId: String }
        struct Resp: Decodable { let ok: Bool? }
        let resp: Resp = try await postJSON(path: "api/mobile/v1/marketplace/listings/delete", body: Payload(listingId: listingId))
        return resp.ok ?? true
    }

    public func toggleFavorite(listingId: String) async -> Bool? {
        struct Payload: Encodable { let listingId: String }
        struct Resp: Decodable {
            let ok: Bool?
            let isFavorited: Bool?
        }
        if let resp: Resp = try? await postJSON(path: "api/mobile/v1/marketplace/listings/favorite", body: Payload(listingId: listingId)) {
            return resp.isFavorited
        }
        return nil
    }

    // MARK: - Offres de Prix & Messagerie Directe sur Annonces

    public func createOffer(listingId: String, offeredPrice: Double, message: String) async throws -> (MarketplaceOffer?, String?) {
        struct Payload: Encodable {
            let listingId: String
            let offeredPrice: Double
            let message: String
        }
        struct Resp: Decodable {
            let ok: Bool?
            let offer: MarketplaceOffer?
            let conversationId: String?
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/offers/create",
            body: Payload(listingId: listingId, offeredPrice: offeredPrice, message: message)
        )
        return (resp.offer, resp.conversationId)
    }

    public func respondToOffer(offerId: String, accept: Bool) async throws -> MarketplaceOffer? {
        struct Payload: Encodable {
            let offerId: String
            let accept: Bool
        }
        struct Resp: Decodable {
            let ok: Bool?
            let offer: MarketplaceOffer?
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/offers/respond",
            body: Payload(offerId: offerId, accept: accept)
        )
        return resp.offer
    }

    public func fetchConversationThread(conversationId: String) async throws -> MarketplaceThreadResponse {
        let encoded = conversationId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? conversationId
        return try await getJSON(path: "api/mobile/v1/marketplace/messages/thread/\(encoded)")
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
            let conversationId: String?
            let listingId: String
            let recipientUsername: String
            let text: String
            let imageUrl: String?
            let gifUrl: String?
            let audioUrl: String?
            let audioDurationSeconds: Int?
            let offerAmount: Double?
        }
        struct Resp: Decodable {
            let ok: Bool?
            let conversationId: String?
            let message: MarketplaceDirectMessage?
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/messages/send",
            body: Payload(
                conversationId: conversationId,
                listingId: listingId,
                recipientUsername: recipientUsername,
                text: text,
                imageUrl: imageUrl,
                gifUrl: gifUrl,
                audioUrl: audioUrl,
                audioDurationSeconds: audioDurationSeconds,
                offerAmount: offerAmount
            )
        )
        return (resp.message, resp.conversationId)
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
            let listingId: String
            let agreedPrice: Double?
            let paymentMethod: String
            let deliveryMode: String
            let relayId: String?
            let relayName: String?
            let relayAddress: String?
            let isVipleTakerRelay: Bool
        }
        struct Resp: Decodable {
            let ok: Bool?
            let order: MarketplaceOrder
        }
        let resp: Resp = try await postJSON(
            path: "api/mobile/v1/marketplace/checkout",
            body: Payload(
                listingId: listingId,
                agreedPrice: agreedPrice,
                paymentMethod: paymentMethod,
                deliveryMode: deliveryMode,
                relayId: relayId,
                relayName: relayName,
                relayAddress: relayAddress,
                isVipleTakerRelay: isVipleTakerRelay
            )
        )
        return resp.order
    }

    // MARK: - Recherche Live Points Relais UPS & Viple Taker

    public func searchRelays(postalCode: String, city: String) async -> [MarketplaceRelayPoint] {
        let cp = postalCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let c = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let points: [MarketplaceRelayPoint] = try? await getJSON(path: "api/mobile/v1/relays?postalCode=\(cp)&city=\(c)") {
            return points
        }
        return []
    }

    // MARK: - Devenir Viple Taker (Point Relais Particulier — 1,00 € / colis)

    public func fetchTakerStatus() async throws -> MarketplaceTakerStatusResponse {
        return try await getJSON(path: "api/mobile/v1/taker/status")
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
            let fullName: String
            let email: String
            let phone: String
            let streetAddress: String
            let postalCode: String
            let city: String
            let availabilityHours: String
            let storageCapacityParcels: Int
            let housingType: String
            let motivation: String
            let acceptsCharter: Bool
            let additionalReply: String?
        }
        return try await postJSON(
            path: "api/mobile/v1/taker/apply",
            body: Payload(
                fullName: fullName,
                email: email,
                phone: phone,
                streetAddress: streetAddress,
                postalCode: postalCode,
                city: city,
                availabilityHours: availabilityHours,
                storageCapacityParcels: storageCapacityParcels,
                housingType: housingType,
                motivation: motivation,
                acceptsCharter: acceptsCharter,
                additionalReply: additionalReply
            )
        )
    }

    public func cancelTakerApplication(applicationId: String?) async throws -> MarketplaceTakerStatusResponse {
        struct Payload: Encodable { let applicationId: String? }
        return try await postJSON(path: "api/mobile/v1/taker/cancel", body: Payload(applicationId: applicationId))
    }

    // MARK: - Helpers HTTP

    private func getJSON<T: Decodable>(path: String) async throws -> T {
        let fullURL = URL(string: "\(baseURL.absoluteString)/\(path)") ?? baseURL.appendingPathComponent(path)
        var req = URLRequest(url: fullURL)
        req.httpMethod = "GET"
        req.timeoutInterval = 20
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
}
