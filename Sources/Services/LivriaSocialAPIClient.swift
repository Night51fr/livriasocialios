import Foundation

// MARK: - Client Réseau REST Natif « Livria Social » (store.livria.social • @MainActor pour Swift 6 Concurrency)

@MainActor
public final class LivriaSocialAPIClient {
    public static let shared = LivriaSocialAPIClient()

    public let baseAPI = "https://livriasocial.viplenetwork.com/api/mobile/v1"
    private let session: URLSession
    private let decoder: JSONDecoder

    public init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 25
        cfg.timeoutIntervalForResource = 45
        self.session = URLSession(configuration: cfg)
        self.decoder = JSONDecoder()
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
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/26.0 (Bundle/store.livria.social; iOS 18.0+)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erreur serveur HTTP \(http.statusCode)"])
        }
        return try decoder.decode(T.self, from: data)
    }

    public func postJSON<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: path.hasPrefix("http") ? path : "\(baseAPI)\(path)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/26.0 (Bundle/store.livria.social; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erreur serveur HTTP \(http.statusCode)"])
        }
        return try decoder.decode(T.self, from: data)
    }

    public func postRaw(_ path: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: path.hasPrefix("http") ? path : "\(baseAPI)\(path)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("LivriaSocial-iOS/26.0 (Bundle/store.livria.social; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        let dict = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (dict["error"] as? String) ?? "Erreur serveur (\(http.statusCode))"
            throw NSError(domain: "LivriaSocialAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return dict
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
        try await getJSON("/members/\(memberId)")
    }

    public func searchMembers(query: String, excludeUserId: Int?) async throws -> [SocialMemberSummary] {
        var items = [URLQueryItem(name: "q", value: query)]
        if let excludeUserId {
            items.append(URLQueryItem(name: "excludeUserId", value: String(excludeUserId)))
        }
        let res: SocialMemberSearchResponse = try await getJSON("/members/search", queryItems: items)
        return res.members
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
