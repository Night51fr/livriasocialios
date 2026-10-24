import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Client Réseau REST Natif « Livria Social » (store.livria.social • @MainActor pour Swift 6 Concurrency)

@MainActor
public final class LivriaSocialAPIClient {
    public static let shared = LivriaSocialAPIClient()

    public let baseAPI = "https://livriasocial.viplenetwork.com/api/mobile/v1"
    public let storeBaseAPI = "https://livria.store/api/mobile/v1"
    private let session: URLSession
    private let decoder: JSONDecoder

    public static let serverOutageMessage = "Oups, le serveur a le moral dans les chaussette, il revient bientot"

    public init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 20
        self.session = URLSession(configuration: cfg)
        self.decoder = JSONDecoder()
    }

    private func applyVipleDeviceHeaders(to req: inout URLRequest) {
        req.setValue("Livria Social", forHTTPHeaderField: "X-Viple-App-Name")
        #if canImport(UIKit)
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString, !vendorId.isEmpty {
            req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        }
        let dev = UIDevice.current
        let bounds = UIScreen.main.bounds
        let deviceSignature = "\(dev.model)|\(dev.systemName)-\(dev.systemVersion)|\(Int(bounds.width))x\(Int(bounds.height))"
        req.setValue(deviceSignature, forHTTPHeaderField: "X-Viple-Device-Info")
        #endif
    }

    private func performRequest(_ req: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "LivriaSocialServerOutage",
                    code: 503,
                    userInfo: [NSLocalizedDescriptionKey: Self.serverOutageMessage]
                )
            }
            if http.statusCode >= 500 {
                throw NSError(
                    domain: "LivriaSocialServerOutage",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: Self.serverOutageMessage]
                )
            }
            return (data, http)
        } catch let nsErr as NSError where nsErr.domain == "LivriaSocialServerOutage" {
            throw nsErr
        } catch {
            throw NSError(
                domain: "LivriaSocialServerOutage",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: Self.serverOutageMessage]
            )
        }
    }

    public func fetchMaintenanceStatus() async throws -> Bool {
        var storeMaintenance = false
        if let storeUrl = URL(string: "\(storeBaseAPI)/payment-settings") {
            var storeReq = URLRequest(url: storeUrl)
            storeReq.timeoutInterval = 20
            storeReq.httpMethod = "GET"
            storeReq.setValue("application/json", forHTTPHeaderField: "Accept")
            if let (sData, sResp) = try? await session.data(for: storeReq),
               let sHttp = sResp as? HTTPURLResponse,
               (200...299).contains(sHttp.statusCode),
               let decoded = try? decoder.decode(SocialMaintenanceStatusResponse.self, from: sData) {
                if decoded.mobileAppMaintenanceEnabled {
                    return true
                }
                storeMaintenance = decoded.mobileAppMaintenanceEnabled
            }
        }

        let socialStatus: SocialMaintenanceStatusResponse = try await getJSON("/maintenance-status")
        return storeMaintenance || socialStatus.mobileAppMaintenanceEnabled
    }

    public func getJSON<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(string: path.hasPrefix("http") ? path : "\(baseAPI)\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/26.0 (Bundle/store.livria.social; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        applyVipleDeviceHeaders(to: &req)

        let (data, http) = try await performRequest(req)
        if !(200...299).contains(http.statusCode) {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: Self.serverOutageMessage])
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NSError(domain: "LivriaSocialServerOutage", code: 503, userInfo: [NSLocalizedDescriptionKey: Self.serverOutageMessage])
        }
    }

    public func postJSON<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: path.hasPrefix("http") ? path : "\(baseAPI)\(path)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/26.0 (Bundle/store.livria.social; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        applyVipleDeviceHeaders(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, http) = try await performRequest(req)
        if !(200...299).contains(http.statusCode) {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: Self.serverOutageMessage])
        }
        return try decoder.decode(T.self, from: data)
    }

    public func postRaw(_ path: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: path.hasPrefix("http") ? path : "\(baseAPI)\(path)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/26.0 (Bundle/store.livria.social; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        applyVipleDeviceHeaders(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, http) = try await performRequest(req)
        let dict = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        if !(200...299).contains(http.statusCode) {
            let msg = (dict["error"] as? String) ?? Self.serverOutageMessage
            throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return dict
    }

    // MARK: - Viple Live ID Cross-App SSO (Livria Store <-> Livria Social)

    public func discoverCrossAppAccount() async -> SocialCrossAppAccount? {
        let items = [URLQueryItem(name: "currentApp", value: "Livria Social")]
        if let res: SocialCrossAppDiscoverResponse = try? await getJSON("/sso/discover", queryItems: items),
           res.hasDetectedAccount, let account = res.account {
            return account
        }
        if let resStore: SocialCrossAppDiscoverResponse = try? await getJSON("\(storeBaseAPI)/sso/discover", queryItems: items),
           resStore.hasDetectedAccount, let account = resStore.account {
            return account
        }
        return nil
    }

    public func announceCrossAppSession(userId: Int, email: String) async {
        let payload: [String: Any] = [
            "sourceApp": "Livria Social",
            "appName": "Livria Social",
            "userId": userId,
            "email": email
        ]
        _ = try? await postRaw("/sso/announce", body: payload)
        _ = try? await postRaw("\(storeBaseAPI)/sso/announce", body: payload)
    }

    public func clearCrossAppSession() async {
        let payload: [String: Any] = [
            "sourceApp": "Livria Social",
            "appName": "Livria Social"
        ]
        _ = try? await postRaw("/sso/clear", body: payload)
        _ = try? await postRaw("\(storeBaseAPI)/sso/clear", body: payload)
    }

    public func acceptCrossAppAccount(userId: Int, email: String) async throws -> SocialAuthResponse {
        let payload: [String: Any] = [
            "userId": userId,
            "email": email
        ]
        return try await postJSON("/sso/accept", body: payload)
    }

    public func fetchBootstrap(email: String?, userId: Int?, filter: String = "all") async throws -> SocialBootstrapResponse {
        var items: [URLQueryItem] = [URLQueryItem(name: "filter", value: filter)]
        if let email, !email.isEmpty {
            items.append(URLQueryItem(name: "email", value: email))
        }
        if let userId, userId > 0 {
            items.append(URLQueryItem(name: "userId", value: String(userId)))
        }
        return try await getJSON("/bootstrap", queryItems: items)
    }

    public func fetchThread(otherUserId: Int, email: String?, userId: Int?) async throws -> SocialThreadResponse {
        var items: [URLQueryItem] = []
        if let email, !email.isEmpty {
            items.append(URLQueryItem(name: "email", value: email))
        }
        if let userId, userId > 0 {
            items.append(URLQueryItem(name: "userId", value: String(userId)))
        }
        return try await getJSON("/messages/thread/\(otherUserId)", queryItems: items)
    }

    public func fetchMemberPublicProfile(memberId: Int) async throws -> SocialMemberPublicProfileResponse {
        var res: SocialMemberPublicProfileResponse = try await getJSON("/members/\(memberId)")
        if res.marketplaceListings.isEmpty {
            let mkt = await fetchMemberMarketplaceListings(
                userId: memberId,
                email: res.user.email,
                displayName: res.user.displayName
            )
            if !mkt.isEmpty {
                res.marketplaceListings = mkt
            }
        }
        return res
    }

    public func fetchMemberMarketplaceListings(
        userId: Int,
        email: String? = nil,
        displayName: String? = nil
    ) async -> [SocialMarketplaceListingItem] {
        guard var components = URLComponents(string: "https://livria.store/api/mobile/v1/marketplace/member-listings") else {
            return []
        }
        var q: [URLQueryItem] = []
        if userId > 0 {
            q.append(URLQueryItem(name: "userId", value: String(userId)))
        }
        if let email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            q.append(URLQueryItem(name: "email", value: email.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        if let displayName, !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            q.append(URLQueryItem(name: "displayName", value: displayName.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        components.queryItems = q
        guard let url = components.url else { return [] }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/2.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(SocialMemberMarketplaceListingsResponse.self, from: data)
            return decoded.listings
        } catch {
            return []
        }
    }

    public func searchMembers(query: String, excludeUserId: Int?) async throws -> [SocialMemberSummary] {
        var items = [URLQueryItem(name: "q", value: query)]
        if let excludeUserId {
            items.append(URLQueryItem(name: "excludeUserId", value: String(excludeUserId)))
        }
        let res: SocialMemberSearchResponse = try await getJSON("/members/search", queryItems: items)
        return res.members.filter { !$0.isVisitorOrGuest }
    }

    public func uploadMedia(mediaKind: String, fileExtension: String, data: Data) async throws -> String {
        let res: SocialMediaUploadResponse = try await postJSON("/media/upload", body: [
            "mediaKind": mediaKind,
            "extension": fileExtension,
            "base64Data": data.base64EncodedString()
        ])
        guard res.ok, let url = res.url, !url.isEmpty else {
            throw NSError(
                domain: "LivriaSocialAPI",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: res.error ?? "Impossible de téléverser le fichier média."]
            )
        }
        return url
    }

    public func searchGifs(query: String) async throws -> [SocialGifItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let res: SocialGifSearchResponse = try await getJSON(
                "/gifs/search",
                queryItems: trimmed.isEmpty ? [] : [URLQueryItem(name: "q", value: trimmed)]
            )
            if !res.gifs.isEmpty {
                return res.gifs
            }
        } catch {
            // Fallback direct vers l'API Giphy si nécessaire
        }

        let apiKey = "GlVGYHkr3WSBnllca54iNt0yFbjz7L65"
        let giphyEndpoint: String
        if trimmed.isEmpty {
            giphyEndpoint = "https://api.giphy.com/v1/gifs/trending?api_key=\(apiKey)&limit=24&rating=g"
        } else {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            giphyEndpoint = "https://api.giphy.com/v1/gifs/search?api_key=\(apiKey)&q=\(encoded)&limit=24&rating=g&lang=fr"
        }

        guard let url = URL(string: giphyEndpoint) else { return [] }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: req)
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = root["data"] as? [[String: Any]] else {
            return []
        }

        var items: [SocialGifItem] = []
        for item in arr {
            let id = (item["id"] as? String) ?? UUID().uuidString
            let title = (item["title"] as? String) ?? "GIF"
            let images = item["images"] as? [String: Any]
            let fh = images?["fixed_height"] as? [String: Any]
            let fhs = images?["fixed_height_small"] as? [String: Any]
            let orig = images?["original"] as? [String: Any]
            let gifUrl = (fh?["url"] as? String) ?? (orig?["url"] as? String) ?? ""
            let previewUrl = (fhs?["url"] as? String) ?? gifUrl
            if !gifUrl.isEmpty {
                items.append(SocialGifItem(id: id, title: title, gifUrl: gifUrl, previewUrl: previewUrl))
            }
        }
        return items
    }
}
