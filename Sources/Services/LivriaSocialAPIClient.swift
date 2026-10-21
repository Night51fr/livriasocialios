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
}
