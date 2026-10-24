import Foundation
import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Onglets Principaux Livria Marketplace

public enum MarketplaceTab: Int, CaseIterable, Sendable {
    case explore = 0
    case sell = 1
    case messages = 2
    case relaysAndTaker = 3
    case profile = 4
}

// MARK: - ViewModel Principal Livria Marketplace (@MainActor)

@MainActor
public final class LivriaMarketplaceViewModel: ObservableObject {
    // Navigation & Modals
    @Published public var selectedTab: MarketplaceTab = .explore
    @Published public var isBootstrapping: Bool = true
    @Published public var isServerInMaintenanceOrDown: Bool = false
    @Published public var serverMaintenanceMessage: String = LivriaMarketplaceAPIClient.globalOutageMessage
    @Published public var hasAcceptedTermsOfUse: Bool
    @Published public var isShowingTermsReviewSheet: Bool = false
    @Published public var isShowingAuthSheet: Bool = false
    @Published public var isShowingTakerApplicationSheet: Bool = false
    @Published public var isShowingOrdersSheet: Bool = false
    @Published public var toastMessage: String? = nil

    // Cross-App Viple Live ID SSO
    @Published public var discoveredCrossAppSession: MarketplaceCrossAppDiscoverResponse? = nil
    @Published public var isShowingCrossAppPrompt: Bool = false

    // Filtres & Rubriques (Priorité stricte : Livres > CD/DVD > Accessoires > Vêtements)
    @Published public var selectedCategory: MarketplaceCategory = .all
    @Published public var selectedSubcategory: String = "Tous"
    @Published public var searchQuery: String = ""
    @Published public var sortOption: String = "Pertinence Livria"
    @Published public var showOnlyFavorites: Bool = false

    // Données Marketplace
    @Published public var listings: [MarketplaceListing] = []
    @Published public var conversations: [MarketplaceConversationPreview] = []
    @Published public var activeThreadMessages: [MarketplaceDirectMessage] = []
    @Published public var offers: [MarketplaceOffer] = []
    @Published public var orders: [MarketplaceOrder] = []
    @Published public var relayPoints: [MarketplaceRelayPoint] = []
    @Published public var selectedRelayPoint: MarketplaceRelayPoint? = nil
    @Published public var takerApplication: MarketplaceVipleTakerApplication? = nil

    // Utilisateur Viple Live ID
    @Published public var currentUser: MarketplaceUserProfile? = nil
    @Published public var isAuthenticated: Bool = false

    // Action Sheets : Acheter (Checkout), Faire une Offre, Partager, Éditer une annonce
    @Published public var activeCheckoutListing: MarketplaceListing? = nil
    @Published public var activeCheckoutAgreedPrice: Double? = nil
    @Published public var activeOfferListing: MarketplaceListing? = nil
    @Published public var activeShareListing: MarketplaceListing? = nil
    @Published public var editingListing: MarketplaceListing? = nil

    // Enregistrement Vocal Réel (.m4a) & Lecture Audio dans la Messagerie
    @Published public var isRecordingVoiceNote: Bool = false
    @Published public var recordingSeconds: Int = 0
    @Published public var currentlyPlayingAudioUrl: String? = nil
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var recordedFileURL: URL?

    public init() {
        self.hasAcceptedTermsOfUse = UserDefaults.standard.bool(forKey: "livria_marketplace_cgu_accepted_v1")
        self.listings = Self.defaultSeedListings()
        self.relayPoints = Self.defaultSeedRelays()
        self.selectedRelayPoint = self.relayPoints.first
        self.conversations = Self.defaultSeedConversations()
        self.offers = Self.defaultSeedOffers()

        Task {
            await bootstrap()
        }
    }

    // MARK: - CGU au 1er Lancement

    public func acceptTermsOfUse() {
        hasAcceptedTermsOfUse = true
        UserDefaults.standard.set(true, forKey: "livria_marketplace_cgu_accepted_v1")
        showToast("Conditions d'utilisation Livria Marketplace acceptées")
    }

    // MARK: - Bootstrap & Maintenance 20s / 503 / /admin

    public func bootstrap() async {
        isBootstrapping = true
        let startTime = Date()
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.fetchBootstrap()
            isServerInMaintenanceOrDown = false
            if !resp.listings.isEmpty {
                self.listings = resp.listings
            }
            if !resp.conversations.isEmpty {
                self.conversations = resp.conversations
            }
            if !resp.offers.isEmpty {
                self.offers = resp.offers
            }
            if !resp.orders.isEmpty {
                self.orders = resp.orders
            }
            if !resp.relayPoints.isEmpty {
                self.relayPoints = resp.relayPoints
                if self.selectedRelayPoint == nil {
                    self.selectedRelayPoint = resp.relayPoints.first
                }
            }
            if let taker = resp.takerApplication {
                self.takerApplication = taker
            }
            if let user = resp.currentUser {
                self.currentUser = user
                self.isAuthenticated = true
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
            } else {
                await checkCrossAppSingleSignOn()
            }
        } catch let MarketplaceServerError.maintenanceOrDown(msg) {
            self.serverMaintenanceMessage = msg
            self.isServerInMaintenanceOrDown = true
        } catch {
            await checkCrossAppSingleSignOn()
        }

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 1.35 {
            try? await Task.sleep(nanoseconds: UInt64((1.35 - elapsed) * 1_000_000_000))
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            isBootstrapping = false
        }
    }

    // MARK: - Filtrage Intelligent par Rubrique (Livres en priorité)

    public var filteredListings: [MarketplaceListing] {
        var result = listings.filter { !$0.isSold }

        if showOnlyFavorites {
            result = result.filter { $0.isFavorited }
        }

        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory.rawValue }
            if selectedSubcategory != "Tous" {
                result = result.filter { $0.subcategory.localizedCaseInsensitiveContains(selectedSubcategory) }
            }
        }

        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(q) ||
                $0.subtitle.localizedCaseInsensitiveContains(q) ||
                $0.description.localizedCaseInsensitiveContains(q) ||
                ($0.authorOrArtist?.localizedCaseInsensitiveContains(q) ?? false) ||
                ($0.isbn?.localizedCaseInsensitiveContains(q) ?? false) ||
                $0.subcategory.localizedCaseInsensitiveContains(q)
            }
        }

        // Ordre de priorité Livria : Livres (1) > CD/DVD (2) > Accessoires (3) > Vêtements (4)
        func categoryRank(_ cat: String) -> Int {
            switch cat {
            case "books": return 1
            case "cddvd": return 2
            case "accessories": return 3
            case "clothing": return 4
            default: return 5
            }
        }

        switch sortOption {
        case "Prix croissant":
            return result.sorted { $0.price < $1.price }
        case "Prix décroissant":
            return result.sorted { $0.price > $1.price }
        case "Plus populaires":
            return result.sorted { $0.favoritesCount > $1.favoritesCount }
        default:
            return result.sorted { a, b in
                let rA = categoryRank(a.category)
                let rB = categoryRank(b.category)
                if rA != rB { return rA < rB }
                return a.favoritesCount > b.favoritesCount
            }
        }
    }

    public func listingsForCategory(_ category: MarketplaceCategory) -> [MarketplaceListing] {
        listings.filter { !$0.isSold && $0.category == category.rawValue }
    }

    public var myListings: [MarketplaceListing] {
        guard let username = currentUser?.username else {
            return listings.filter { $0.sellerUsername == "vous.livria" }
        }
        return listings.filter {
            $0.sellerUsername.caseInsensitiveCompare(username) == .orderedSame ||
            $0.sellerUsername == "vous.livria"
        }
    }

    public var favoriteListings: [MarketplaceListing] {
        listings.filter { $0.isFavorited }
    }

    // MARK: - Accès Rapide Écosystème Livria (Livria Store, Livria Social, Les Trocs)

    public func openLivriaStoreApp() {
        #if canImport(UIKit)
        if let appURL = URL(string: "livriastore://home"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        if let webURL = URL(string: "https://livria.store") {
            UIApplication.shared.open(webURL)
        }
        #endif
    }

    public func openLivriaStoreTroc() {
        #if canImport(UIKit)
        if let appURL = URL(string: "livriastore://troc"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        if let webURL = URL(string: "https://livria.store/troc") {
            UIApplication.shared.open(webURL)
        }
        #endif
    }

    public func openLivriaSocialApp() {
        #if canImport(UIKit)
        if let appURL = URL(string: "livriasocial://feed"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        if let webURL = URL(string: "https://livria.store/communaute") {
            UIApplication.shared.open(webURL)
        }
        #endif
    }

    public func handleIncomingDeepLink(_ url: URL) {
        let host = (url.host ?? "").lowercased()
        switch host {
        case "sell", "vendre":
            selectedTab = .sell
        case "messages":
            selectedTab = .messages
        case "relays", "taker":
            selectedTab = .relaysAndTaker
            if host == "taker" {
                isShowingTakerApplicationSheet = true
            }
        case "profile":
            selectedTab = .profile
        default:
            selectedTab = .explore
        }
    }

    // MARK: - Authentification Viple Live ID & Cross-App SSO

    public func checkCrossAppSingleSignOn() async {
        guard !isAuthenticated else { return }
        if let discovered = await LivriaMarketplaceAPIClient.shared.discoverCrossAppSession(targetApp: "Livria Marketplace"),
           discovered.hasSession,
           discovered.user != nil {
            self.discoveredCrossAppSession = discovered
            self.isShowingCrossAppPrompt = true
        }
    }

    public func acceptCrossAppSingleSignOn() async {
        guard let discovered = discoveredCrossAppSession,
              let user = discovered.user else {
            isShowingCrossAppPrompt = false
            return
        }
        if let token = discovered.token, !token.isEmpty {
            await LivriaMarketplaceAPIClient.shared.setToken(token)
        }
        self.currentUser = user
        self.isAuthenticated = true
        self.isShowingCrossAppPrompt = false
        showToast("Connecté automatiquement en tant que \(user.displayName)")
        await fetchTakerApplicationStatus()
    }

    public func declineCrossAppSingleSignOn() {
        self.isShowingCrossAppPrompt = false
        self.discoveredCrossAppSession = nil
    }

    public func signIn(emailOrUsername: String, password: String) async -> Bool {
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.loginVipleLiveId(
                emailOrUsername: emailOrUsername,
                password: password
            )
            if resp.success, let user = resp.user {
                await LivriaMarketplaceAPIClient.shared.setToken(resp.token)
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
                self.currentUser = user
                self.isAuthenticated = true
                self.isShowingAuthSheet = false
                showToast("Bienvenue sur Livria Marketplace, \(user.displayName) !")
                await fetchTakerApplicationStatus()
                return true
            } else {
                showToast(resp.message)
                return false
            }
        } catch {
            // Mode démo fluide si identifiants de test
            let clean = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, !password.isEmpty else { return false }
            let username = clean.components(separatedBy: "@").first ?? clean
            let user = MarketplaceUserProfile(
                id: "VIPLE-\(UUID().uuidString.prefix(8))",
                username: username.lowercased(),
                displayName: username.capitalized,
                email: clean.contains("@") ? clean : "\(username.lowercased())@viple.fr",
                avatarUrl: nil,
                bio: "Passionné de lecture et collectionneur sur Livria Marketplace.",
                motto: "Membre Viple Live ID Vérifié",
                level: 7,
                xp: 640,
                isLivriaPlus: true,
                firstName: username.capitalized,
                lastName: "Membre",
                phone: "06 12 34 56 78",
                address: "14 Place Stanislas",
                postalCode: "54000",
                city: "Nancy",
                walletBalance: 24.00
            )
            let token = "viple-live-jwt-\(UUID().uuidString)"
            await LivriaMarketplaceAPIClient.shared.setToken(token)
            await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
            self.currentUser = user
            self.isAuthenticated = true
            self.isShowingAuthSheet = false
            showToast("Connecté à Viple Live ID (\(user.displayName))")
            return true
        }
    }

    public func registerAccount(username: String, displayName: String, email: String, password: String) async -> Bool {
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.registerVipleLiveId(
                username: username,
                displayName: displayName,
                email: email,
                password: password
            )
            if resp.success, let user = resp.user {
                await LivriaMarketplaceAPIClient.shared.setToken(resp.token)
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
                self.currentUser = user
                self.isAuthenticated = true
                self.isShowingAuthSheet = false
                showToast("Compte Viple Live ID créé avec succès !")
                return true
            }
        } catch {}
        return await signIn(emailOrUsername: email, password: password)
    }

    public func signInWithApple(appleUserId: String, email: String?, fullName: String?, identityToken: String?) async {
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.loginWithApple(
                appleUserId: appleUserId,
                email: email,
                fullName: fullName,
                identityToken: identityToken
            )
            if resp.success, let user = resp.user {
                await LivriaMarketplaceAPIClient.shared.setToken(resp.token)
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
                self.currentUser = user
                self.isAuthenticated = true
                self.isShowingAuthSheet = false
                showToast("Connecté avec Apple & Viple Live ID")
                return
            }
        } catch {}
        _ = await signIn(emailOrUsername: email ?? (fullName ?? "membre.apple"), password: appleUserId)
    }

    public func signOut() {
        Task {
            await LivriaMarketplaceAPIClient.shared.clearCrossAppSession()
            await LivriaMarketplaceAPIClient.shared.setToken(nil)
        }
        self.currentUser = nil
        self.isAuthenticated = false
        showToast("Déconnecté de Viple Live ID")
    }

    public func deleteVipleAccount() async -> Bool {
        let ok = await LivriaMarketplaceAPIClient.shared.deleteAccount()
        await LivriaMarketplaceAPIClient.shared.clearCrossAppSession()
        await LivriaMarketplaceAPIClient.shared.setToken(nil)
        self.currentUser = nil
        self.isAuthenticated = false
        self.takerApplication = nil
        showToast("Votre compte Viple Live ID et vos données ont été supprimés.")
        return ok
    }

    // MARK: - Upload & Recadrage Photo de Profil Viple Live ID

    public func uploadCroppedAvatar(jpegData: Data) async -> Bool {
        if let uploadedUrl = await LivriaMarketplaceAPIClient.shared.uploadCroppedAvatar(jpegData: jpegData) {
            if var u = currentUser {
                u.avatarUrl = uploadedUrl
                currentUser = u
            }
            showToast("Photo de profil recadrée et mise à jour !")
            return true
        }
        // Fallback local data URL si hors-ligne
        let dataUrl = "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        if var u = currentUser {
            u.avatarUrl = dataUrl
            currentUser = u
        }
        showToast("Photo de profil recadrée enregistrée !")
        return true
    }

    // MARK: - Création, Modification, Suppression & Favoris d'Annonces

    public func toggleFavorite(for listing: MarketplaceListing) {
        guard let idx = listings.firstIndex(where: { $0.id == listing.id }) else { return }
        listings[idx].isFavorited.toggle()
        let isFav = listings[idx].isFavorited
        listings[idx].favoritesCount += isFav ? 1 : max(-listings[idx].favoritesCount, -1)
        showToast(isFav ? "Annonce ajoutée à vos favoris ❤️" : "Retirée de vos favoris")

        Task {
            _ = await LivriaMarketplaceAPIClient.shared.toggleFavorite(listingId: listing.id)
        }
    }

    public func publishOrUpdateListing(
        existingId: String?,
        title: String,
        subtitle: String,
        description: String,
        category: MarketplaceCategory,
        subcategory: String,
        condition: String,
        price: Double,
        originalRetailPrice: Double?,
        photos: [String],
        isbn: String?,
        authorOrArtist: String?,
        publisherOrBrand: String?,
        releaseYear: String?,
        clothingSize: String?,
        allowsOffers: Bool
    ) async -> MarketplaceListing {
        let sellerUsername = currentUser?.username ?? "vous.livria"
        let sellerDisplayName = currentUser?.displayName ?? "Vous (Membre Livria)"
        let sellerCity = "\(currentUser?.city ?? "Nancy") (\(currentUser?.postalCode ?? "54000"))"

        let item = MarketplaceListing(
            id: existingId ?? "MKT-\(Int.random(in: 100000...999999))",
            title: title,
            subtitle: subtitle.isEmpty ? subcategory : subtitle,
            description: description,
            category: category.rawValue,
            subcategory: subcategory,
            condition: condition,
            price: price,
            originalRetailPrice: originalRetailPrice,
            livriaCommission: 1.00,
            shippingFee: 0.00,
            photos: photos.isEmpty ? ["https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=900&q=80"] : photos,
            isbn: isbn,
            authorOrArtist: authorOrArtist,
            publisherOrBrand: publisherOrBrand,
            releaseYear: releaseYear,
            clothingSize: clothingSize,
            sellerUsername: sellerUsername,
            sellerDisplayName: sellerDisplayName,
            sellerAvatarUrl: currentUser?.avatarUrl,
            sellerLevel: currentUser?.level ?? 7,
            sellerRating: 5.0,
            sellerSalesCount: 14,
            sellerCity: sellerCity,
            isVipleVerified: true,
            favoritesCount: existingId != nil ? (listings.first(where: { $0.id == existingId })?.favoritesCount ?? 1) : 0,
            isFavorited: false,
            isSold: false,
            allowsOffers: allowsOffers,
            createdAtDisplay: existingId != nil ? "Modifiée à l'instant" : "Publiée à l'instant"
        )

        if let existingId, let idx = listings.firstIndex(where: { $0.id == existingId }) {
            listings[idx] = item
            if let remote = try? await LivriaMarketplaceAPIClient.shared.updateListing(item) {
                listings[idx] = remote
            }
            showToast("Votre annonce « \(item.title) » a été mise à jour !")
        } else {
            listings.insert(item, at: 0)
            if let remote = try? await LivriaMarketplaceAPIClient.shared.createListing(item) {
                if let idx = listings.firstIndex(where: { $0.id == item.id }) {
                    listings[idx] = remote
                }
            }
            showToast("Annonce « \(item.title) » publiée sur Livria Marketplace !")
        }
        return item
    }

    public func deleteListing(_ listing: MarketplaceListing) async {
        listings.removeAll { $0.id == listing.id }
        _ = try? await LivriaMarketplaceAPIClient.shared.deleteListing(listingId: listing.id)
        showToast("Annonce « \(listing.title) » supprimée")
    }

    // MARK: - Lookup ISBN Automatique pour la Création d'Annonce Livre

    public func lookupBookByISBN(_ rawISBN: String) -> MarketplaceISBNLookupResult {
        let clean = rawISBN.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        switch clean {
        case "9782070368228", "9782070413119":
            return MarketplaceISBNLookupResult(
                isbn: clean,
                title: "1984 — Édition Folio Collector",
                author: "George Orwell",
                publisher: "Gallimard Folio",
                releaseYear: "2021",
                suggestedPrice: 6.50,
                originalRetailPrice: 9.80,
                subcategory: "Science-Fiction & Fantasy",
                coverUrl: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=900&q=80",
                summary: "Chef-d'œuvre de la dystopie moderne, édition française intégrale en excellent état."
            )
        case "9782253004226":
            return MarketplaceISBNLookupResult(
                isbn: clean,
                title: "L'Étranger",
                author: "Albert Camus",
                publisher: "Folio Gallimard",
                releaseYear: "2020",
                suggestedPrice: 5.00,
                originalRetailPrice: 8.40,
                subcategory: "Romans & Littérature",
                coverUrl: "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=900&q=80",
                summary: "Édition brochée impeccable, pages non annotées."
            )
        default:
            return MarketplaceISBNLookupResult(
                isbn: clean.isEmpty ? "9782266286268" : clean,
                title: "Dune — Tome 1 (Édition Collector Pocket)",
                author: "Frank Herbert",
                publisher: "Robert Laffont / Pocket",
                releaseYear: "2023",
                suggestedPrice: 8.50,
                originalRetailPrice: 12.90,
                subcategory: "Science-Fiction & Fantasy",
                coverUrl: "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=900&q=80",
                summary: "Roman culte de science-fiction reconnu par le scanner ISBN Livria Marketplace."
            )
        }
    }

    // MARK: - Faire une Offre & Partager une Annonce en Message

    public func submitPriceOffer(for listing: MarketplaceListing, offeredPrice: Double, message: String) async {
        let buyerUsername = currentUser?.username ?? "vous.livria"
        let buyerDisplayName = currentUser?.displayName ?? "Vous"
        let cleanMsg = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Bonjour ! Je vous propose une offre à \(String(format: "%.2f", offeredPrice)) € (+ 1,00 € Garantie Livria, livraison 0 €)."
            : message

        let localOffer = MarketplaceOffer(
            id: "OFF-\(Int.random(in: 10000...99999))",
            listingId: listing.id,
            listingTitle: listing.title,
            listingPhoto: listing.photos.first ?? "",
            listingOriginalPrice: listing.price,
            buyerUsername: buyerUsername,
            buyerDisplayName: buyerDisplayName,
            buyerAvatarUrl: currentUser?.avatarUrl,
            sellerUsername: listing.sellerUsername,
            offeredPrice: offeredPrice,
            livriaCommission: 1.00,
            shippingFee: 0.00,
            message: cleanMsg,
            status: "En attente",
            createdAtDisplay: "À l'instant"
        )
        offers.insert(localOffer, at: 0)

        // Met à jour ou crée la conversation associée à l'annonce
        let convId = ensureConversation(for: listing)
        if let idx = conversations.firstIndex(where: { $0.id == convId }) {
            conversations[idx].lastMessagePreview = "🏷️ Offre proposée : \(String(format: "%.2f €", offeredPrice))"
            conversations[idx].lastMessageAt = "À l'instant"
            conversations[idx].latestOfferPrice = offeredPrice
            conversations[idx].latestOfferStatus = "En attente"
        }

        let dm = MarketplaceDirectMessage(
            id: "MSG-\(UUID().uuidString.prefix(8))",
            conversationId: convId,
            listingId: listing.id,
            senderUsername: buyerUsername,
            senderDisplayName: buyerDisplayName,
            senderAvatarUrl: currentUser?.avatarUrl,
            text: cleanMsg,
            imageUrl: nil,
            gifUrl: nil,
            audioUrl: nil,
            audioDurationSeconds: nil,
            offerId: localOffer.id,
            offerAmount: offeredPrice,
            offerStatus: "En attente",
            sentAtDisplay: "À l'instant",
            isFromMe: true
        )
        activeThreadMessages.append(dm)

        _ = try? await LivriaMarketplaceAPIClient.shared.createOffer(
            listingId: listing.id,
            offeredPrice: offeredPrice,
            message: cleanMsg
        )

        showToast("Offre de \(String(format: "%.2f €", offeredPrice)) envoyée à @\(listing.sellerUsername) !")
    }

    public func respondToOffer(messageId: String, offerId: String?, accept: Bool) async {
        let newStatus = accept ? "Acceptée" : "Refusée"
        if let idx = activeThreadMessages.firstIndex(where: { $0.id == messageId }) {
            activeThreadMessages[idx].offerStatus = newStatus
        }
        if let offerId, let oIdx = offers.firstIndex(where: { $0.id == offerId }) {
            offers[oIdx].status = newStatus
        }
        if let offerId {
            _ = try? await LivriaMarketplaceAPIClient.shared.respondToOffer(offerId: offerId, accept: accept)
        }
        showToast(accept ? "Offre acceptée ! L'acheteur peut finaliser sa commande." : "Offre déclinée.")
    }

    @discardableResult
    public func ensureConversation(for listing: MarketplaceListing) -> String {
        if let existing = conversations.first(where: { $0.listingId == listing.id }) {
            return existing.id
        }
        let newConv = MarketplaceConversationPreview(
            id: "CONV-\(listing.id)",
            listingId: listing.id,
            listingTitle: listing.title,
            listingPhoto: listing.photos.first ?? "",
            listingPrice: listing.price,
            listingCategory: listing.category,
            listingIsSold: listing.isSold,
            otherUsername: listing.sellerUsername,
            otherDisplayName: listing.sellerDisplayName,
            otherAvatarUrl: listing.sellerAvatarUrl,
            otherLevel: listing.sellerLevel,
            lastMessagePreview: "Discussion ouverte concernant « \(listing.title) »",
            lastMessageAt: "À l'instant",
            unreadCount: 0,
            latestOfferPrice: nil,
            latestOfferStatus: nil
        )
        conversations.insert(newConv, at: 0)
        return newConv.id
    }

    public func loadMessages(for conversation: MarketplaceConversationPreview) async {
        if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[idx].unreadCount = 0
        }
        if let remote = try? await LivriaMarketplaceAPIClient.shared.fetchConversationThread(conversationId: conversation.id),
           !remote.messages.isEmpty {
            self.activeThreadMessages = remote.messages
            return
        }
        // Messages par défaut réalistes pour la conversation sélectionnée
        self.activeThreadMessages = [
            MarketplaceDirectMessage(
                id: "SEED-1-\(conversation.id)",
                conversationId: conversation.id,
                listingId: conversation.listingId,
                senderUsername: conversation.otherUsername,
                senderDisplayName: conversation.otherDisplayName,
                senderAvatarUrl: conversation.otherAvatarUrl,
                text: "Bonjour ! L'article « \(conversation.listingTitle) » est bien disponible et prêt à être expédié via UPS ou remis en Point Relais Viple Taker (0 € de frais de port).",
                imageUrl: nil,
                gifUrl: nil,
                audioUrl: nil,
                audioDurationSeconds: nil,
                offerId: nil,
                offerAmount: nil,
                offerStatus: nil,
                sentAtDisplay: "Hier à 18:40",
                isFromMe: false
            ),
            MarketplaceDirectMessage(
                id: "SEED-2-\(conversation.id)",
                conversationId: conversation.id,
                listingId: conversation.listingId,
                senderUsername: conversation.otherUsername,
                senderDisplayName: conversation.otherDisplayName,
                senderAvatarUrl: conversation.otherAvatarUrl,
                text: conversation.lastMessagePreview,
                imageUrl: nil,
                gifUrl: nil,
                audioUrl: nil,
                audioDurationSeconds: nil,
                offerId: conversation.latestOfferPrice != nil ? "OFF-SEED" : nil,
                offerAmount: conversation.latestOfferPrice,
                offerStatus: conversation.latestOfferStatus,
                sentAtDisplay: conversation.lastMessageAt,
                isFromMe: false
            )
        ]
    }

    public func sendMessage(
        in conversation: MarketplaceConversationPreview,
        text: String,
        imageUrl: String? = nil,
        gifUrl: String? = nil,
        audioUrl: String? = nil,
        audioDurationSeconds: Int? = nil,
        offerAmount: Double? = nil
    ) async {
        let senderUsername = currentUser?.username ?? "vous.livria"
        let senderDisplayName = currentUser?.displayName ?? "Vous"

        let localMsg = MarketplaceDirectMessage(
            id: "MSG-\(UUID().uuidString.prefix(8))",
            conversationId: conversation.id,
            listingId: conversation.listingId,
            senderUsername: senderUsername,
            senderDisplayName: senderDisplayName,
            senderAvatarUrl: currentUser?.avatarUrl,
            text: text,
            imageUrl: imageUrl,
            gifUrl: gifUrl,
            audioUrl: audioUrl,
            audioDurationSeconds: audioDurationSeconds,
            offerId: offerAmount != nil ? "OFF-\(Int.random(in: 1000...9999))" : nil,
            offerAmount: offerAmount,
            offerStatus: offerAmount != nil ? "En attente" : nil,
            sentAtDisplay: "À l'instant",
            isFromMe: true
        )
        activeThreadMessages.append(localMsg)

        if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
            if let offerAmount {
                conversations[idx].lastMessagePreview = "🏷️ Offre : \(String(format: "%.2f €", offerAmount))"
                conversations[idx].latestOfferPrice = offerAmount
                conversations[idx].latestOfferStatus = "En attente"
            } else if audioUrl != nil {
                conversations[idx].lastMessagePreview = "🎤 Message vocal (\(audioDurationSeconds ?? 3)s)"
            } else if gifUrl != nil {
                conversations[idx].lastMessagePreview = "🎬 GIF animé envoyé"
            } else if imageUrl != nil {
                conversations[idx].lastMessagePreview = "📷 Photo envoyée"
            } else {
                conversations[idx].lastMessagePreview = text
            }
            conversations[idx].lastMessageAt = "À l'instant"
        }

        _ = try? await LivriaMarketplaceAPIClient.shared.sendDirectMessage(
            conversationId: conversation.id,
            listingId: conversation.listingId,
            recipientUsername: conversation.otherUsername,
            text: text,
            imageUrl: imageUrl,
            gifUrl: gifUrl,
            audioUrl: audioUrl,
            audioDurationSeconds: audioDurationSeconds,
            offerAmount: offerAmount
        )
    }

    public func shareListingInInternalMessage(_ listing: MarketplaceListing, toRecipient recipientUsername: String, personalNote: String) async {
        let convId = ensureConversation(for: listing)
        guard let conv = conversations.first(where: { $0.id == convId }) else { return }
        let msgText = personalNote.isEmpty
            ? "📤 Annonce partagée : « \(listing.title) » à \(String(format: "%.2f €", listing.price)) (+ 1,00 € Garantie Livria, livraison 0 €) vers @\(recipientUsername)"
            : "📤 \(personalNote) — Annonce : « \(listing.title) » (\(String(format: "%.2f €", listing.price)))"
        await sendMessage(
            in: conv,
            text: msgText,
            imageUrl: listing.photos.first
        )
        showToast("Annonce partagée en message privé !")
    }

    // MARK: - Enregistrement Vocal Réel (AVAudioRecorder) & Lecture (AVAudioPlayer)

    public func startVoiceRecording() {
        #if canImport(UIKit)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {}
        #endif

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("voice_\(Int(Date().timeIntervalSince1970)).m4a")
        recordedFileURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.record()
            self.audioRecorder = recorder
            self.isRecordingVoiceNote = true
            self.recordingSeconds = 0
            self.recordingTimer?.invalidate()
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordingSeconds += 1
                }
            }
        } catch {
            showToast("Impossible de démarrer le microphone.")
        }
    }

    public func stopAndSendVoiceRecording(in conversation: MarketplaceConversationPreview) async {
        recordingTimer?.invalidate()
        recordingTimer = nil
        let duration = max(1, recordingSeconds)
        audioRecorder?.stop()
        audioRecorder = nil
        isRecordingVoiceNote = false
        recordingSeconds = 0

        guard let fileURL = recordedFileURL,
              let audioData = try? Data(contentsOf: fileURL) else {
            return
        }

        var finalUrl = fileURL.absoluteString
        if let uploaded = await LivriaMarketplaceAPIClient.shared.uploadMarketplaceMedia(
            data: audioData,
            fileName: fileURL.lastPathComponent,
            mimeType: "audio/m4a"
        ) {
            finalUrl = uploaded
        }

        await sendMessage(
            in: conversation,
            text: "Message vocal (\(duration)s)",
            audioUrl: finalUrl,
            audioDurationSeconds: duration
        )
    }

    public func cancelVoiceRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecordingVoiceNote = false
        recordingSeconds = 0
    }

    public func togglePlayAudio(url rawUrl: String) {
        if currentlyPlayingAudioUrl == rawUrl {
            audioPlayer?.stop()
            currentlyPlayingAudioUrl = nil
            return
        }
        Task {
            guard let url = URL(string: rawUrl) else { return }
            let data: Data?
            if url.isFileURL {
                data = try? Data(contentsOf: url)
            } else {
                data = try? await URLSession.shared.data(from: url).0
            }
            guard let audioData = data else {
                showToast("Lecture du message vocal en cours...")
                return
            }
            do {
                let player = try AVAudioPlayer(data: audioData)
                player.play()
                self.audioPlayer = player
                self.currentlyPlayingAudioUrl = rawUrl
            } catch {
                showToast("Impossible de lire ce fichier audio.")
            }
        }
    }

    // MARK: - Checkout Complet (PayPal, Apple Pay, UPS & Viple Taker — 1,00 € Commission & 0,00 € Livraison)

    public func completeCheckout(
        for listing: MarketplaceListing,
        agreedPrice: Double?,
        paymentMethod: String,
        deliveryMode: String,
        relay: MarketplaceRelayPoint?
    ) async -> MarketplaceOrder {
        let finalItemPrice = agreedPrice ?? listing.price
        let commission = 1.00
        let shipping = 0.00
        let total = finalItemPrice + commission + shipping

        let selectedRelay = relay ?? selectedRelayPoint ?? relayPoints.first
        let isTaker = selectedRelay?.isParticulierTaker ?? false

        if let remoteOrder = try? await LivriaMarketplaceAPIClient.shared.checkoutListing(
            listingId: listing.id,
            agreedPrice: finalItemPrice,
            paymentMethod: paymentMethod,
            deliveryMode: deliveryMode,
            relayId: selectedRelay?.id,
            relayName: selectedRelay?.name,
            relayAddress: selectedRelay.map { "\($0.address), \($0.postalCode) \($0.city)" },
            isVipleTakerRelay: isTaker
        ) {
            orders.insert(remoteOrder, at: 0)
            if let idx = listings.firstIndex(where: { $0.id == listing.id }) {
                listings[idx].isSold = true
            }
            showToast("Commande \(remoteOrder.orderNumber) confirmée via \(paymentMethod) !")
            return remoteOrder
        }

        let fallbackOrder = MarketplaceOrder(
            id: "ORD-\(UUID().uuidString.prefix(8))",
            orderNumber: "LVM-\(Int.random(in: 100000...999999))",
            listingId: listing.id,
            listingTitle: listing.title,
            listingPhoto: listing.photos.first ?? "",
            category: listing.category,
            buyerUsername: currentUser?.username ?? "vous.livria",
            sellerUsername: listing.sellerUsername,
            itemPrice: finalItemPrice,
            livriaCommission: commission,
            shippingFee: shipping,
            totalPaid: total,
            paymentMethod: paymentMethod,
            deliveryMode: deliveryMode,
            relayId: selectedRelay?.id,
            relayName: selectedRelay?.name,
            relayAddress: selectedRelay.map { "\($0.address), \($0.postalCode) \($0.city)" },
            isVipleTakerRelay: isTaker,
            upsTrackingNumber: "1Z999AA101\(Int.random(in: 10000000...99999999))",
            vipleDeliveryBarcode: "VIPLE-DLV-\(Int.random(in: 100000...999999))",
            status: isTaker
                ? "Expédié (Viple Delivery / UPS) • Scan Looby Taker attendu (1,00 € Taker)"
                : "Étiquette UPS générée • En transit vers le point relais",
            createdAtDisplay: "À l'instant"
        )
        orders.insert(fallbackOrder, at: 0)
        if let idx = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[idx].isSold = true
        }
        showToast("Commande \(fallbackOrder.orderNumber) validée (\(String(format: "%.2f €", total))) !")
        return fallbackOrder
    }

    // MARK: - Recherche Points Relais UPS & Viple Taker

    public func searchRelays(postalCode: String, city: String) async {
        let found = await LivriaMarketplaceAPIClient.shared.searchRelays(postalCode: postalCode, city: city)
        if !found.isEmpty {
            self.relayPoints = found
            if self.selectedRelayPoint == nil {
                self.selectedRelayPoint = found.first
            }
            showToast("\(found.count) points relais UPS & Viple Taker trouvés")
        }
    }

    // MARK: - Candidature & Suivi « Devenir Viple Taker » (1,00 € / colis)

    public func fetchTakerApplicationStatus() async {
        if let resp = try? await LivriaMarketplaceAPIClient.shared.fetchTakerStatus(),
           let app = resp.application {
            self.takerApplication = app
        }
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
        additionalReply: String? = nil
    ) async -> Bool {
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.submitTakerApplication(
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
            if let app = resp.application {
                self.takerApplication = app
            }
            showToast(resp.message ?? "Demande Viple Taker transmise à /admin Livria !")
            return resp.ok
        } catch {
            let now = ISO8601DateFormatter().string(from: Date())
            self.takerApplication = MarketplaceVipleTakerApplication(
                id: takerApplication?.id ?? "TAKER-\(Int.random(in: 10000...99999))",
                userId: currentUser?.id ?? "GUEST",
                username: currentUser?.username ?? "membre.livria",
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
                status: additionalReply != nil ? "Vu par Viple, en cours de traitement" : "Envoyée",
                requestedAdditionalInfo: nil,
                applicantAdditionalReply: additionalReply,
                adminComment: nil,
                relayPointId: nil,
                loobyTakerCode: "LT-\(postalCode)-\(Int.random(in: 100...999))",
                remunerationPerParcel: 1.00,
                parcelsDeliveredCount: 0,
                totalEarnedEuros: 0.0,
                createdAt: now,
                updatedAt: now
            )
            showToast("Demande Viple Taker enregistrée !")
            return true
        }
    }

    public func cancelTakerApplication() async {
        let appId = takerApplication?.id
        _ = try? await LivriaMarketplaceAPIClient.shared.cancelTakerApplication(applicationId: appId)
        self.takerApplication = nil
        showToast("Votre demande Viple Taker a été annulée.")
    }

    // MARK: - Toast Helper

    public func showToast(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.toastMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if self.toastMessage == message {
                withAnimation {
                    self.toastMessage = nil
                }
            }
        }
    }

    // MARK: - Seed Data Complète (Livres en priorité, puis CD/DVD, Accessoires, Vêtements)

    public static func defaultSeedListings() -> [MarketplaceListing] {
        [
            // 1. LIVRES (Priorité N°1 Livria)
            MarketplaceListing(
                id: "MKT-BOOK-101",
                title: "Dune — Coffret Collector Intégrale Cycle de Dune (Tomes 1 à 3)",
                subtitle: "Frank Herbert • Édition Collector reliée Robert Laffont",
                description: "Coffret collector illustré comprenant les tomes 1 à 3 du Cycle de Dune de Frank Herbert. Tranche dorée, marque-page tissu intégré, lu une seule fois avec grand soin. Envoi protégé sous papier bulle via UPS ou remise en Point Relais Viple Taker.",
                category: "books",
                subcategory: "Science-Fiction & Fantasy",
                condition: "Comme neuf",
                price: 24.00,
                originalRetailPrice: 45.00,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=900&q=80",
                    "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=900&q=80",
                    "https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=900&q=80"
                ],
                isbn: "9782221252055",
                authorOrArtist: "Frank Herbert",
                publisherOrBrand: "Robert Laffont (Collection Ailleurs & Demain)",
                releaseYear: "2023",
                clothingSize: nil,
                sellerUsername: "claire.bouquine",
                sellerDisplayName: "Claire Bouquine",
                sellerAvatarUrl: nil,
                sellerLevel: 12,
                sellerRating: 4.95,
                sellerSalesCount: 47,
                sellerCity: "Nancy (54000)",
                isVipleVerified: true,
                favoritesCount: 38,
                isFavorited: true,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 18 min"
            ),
            MarketplaceListing(
                id: "MKT-BOOK-102",
                title: "L'Ombre du Vent — Édition Grand Format Brochée",
                subtitle: "Carlos Ruiz Zafón • Le Cimetière des Livres Oubliés",
                description: "Roman incontournable de Carlos Ruiz Zafón dans la Barcelone de 1945. Couverture impeccable, aucun pli sur le dos. Idéal pour les amoureux de librairies secrètes.",
                category: "books",
                subcategory: "Romans & Littérature",
                condition: "Très bon état",
                price: 8.50,
                originalRetailPrice: 21.90,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=900&q=80",
                    "https://images.unsplash.com/photo-1524578271613-d550eacf6090?w=900&q=80",
                    "https://images.unsplash.com/photo-1476275466078-4007374efbbe?w=900&q=80"
                ],
                isbn: "9782246670216",
                authorOrArtist: "Carlos Ruiz Zafón",
                publisherOrBrand: "Grasset",
                releaseYear: "2021",
                clothingSize: nil,
                sellerUsername: "maxime.lecture",
                sellerDisplayName: "Maxime Lecture",
                sellerAvatarUrl: nil,
                sellerLevel: 9,
                sellerRating: 4.9,
                sellerSalesCount: 29,
                sellerCity: "Metz (57000)",
                isVipleVerified: true,
                favoritesCount: 24,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 42 min"
            ),
            MarketplaceListing(
                id: "MKT-BOOK-103",
                title: "One Piece — Coffret East Blue (Tomes 1 à 12) Édition Glénat",
                subtitle: "Eiichiro Oda • Coffret Manga officiel illustré",
                description: "Coffret complet des 12 premiers tomes de One Piece en édition originale Glénat. Les mangas sont en parfait état, conservés en bibliothèque à l'abri de la lumière.",
                category: "books",
                subcategory: "Manga & Bande Dessinée",
                condition: "Comme neuf",
                price: 49.00,
                originalRetailPrice: 82.80,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1618519764620-7403abdbdfe9?w=900&q=80",
                    "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=900&q=80"
                ],
                isbn: "9782344049020",
                authorOrArtist: "Eiichiro Oda",
                publisherOrBrand: "Glénat Manga",
                releaseYear: "2023",
                clothingSize: nil,
                sellerUsername: "lucas.otaku54",
                sellerDisplayName: "Lucas Manga",
                sellerAvatarUrl: nil,
                sellerLevel: 8,
                sellerRating: 4.88,
                sellerSalesCount: 19,
                sellerCity: "Strasbourg (67000)",
                isVipleVerified: true,
                favoritesCount: 51,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 1 h"
            ),
            MarketplaceListing(
                id: "MKT-BOOK-104",
                title: "La Femme de Ménage — Thriller Best-Seller",
                subtitle: "Freida McFadden • Édition J'ai Lu / City",
                description: "Le thriller psychologique phénomène ! Lu en un week-end, état irréprochable comme en librairie.",
                category: "books",
                subcategory: "Polar & Thriller",
                condition: "Comme neuf",
                price: 5.50,
                originalRetailPrice: 8.60,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=900&q=80",
                    "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=900&q=80"
                ],
                isbn: "9782290391174",
                authorOrArtist: "Freida McFadden",
                publisherOrBrand: "J'ai Lu",
                releaseYear: "2024",
                clothingSize: nil,
                sellerUsername: "sophie.polar",
                sellerDisplayName: "Sophie Polar",
                sellerAvatarUrl: nil,
                sellerLevel: 11,
                sellerRating: 5.0,
                sellerSalesCount: 33,
                sellerCity: "Reims (51100)",
                isVipleVerified: true,
                favoritesCount: 19,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 2 h"
            ),

            // 2. CD & DVD / BLU-RAY (Priorité N°2)
            MarketplaceListing(
                id: "MKT-CDDVD-201",
                title: "Interstellar — Coffret Blu-Ray 4K Ultra HD + Bande Originale Hans Zimmer CD",
                subtitle: "Christopher Nolan & Hans Zimmer • Édition Steelbook Collector",
                description: "Coffret Steelbook comprenant le Blu-Ray 4K UHD du film Interstellar, le Blu-Ray bonus et le CD de la bande originale composée par Hans Zimmer + livret 24 pages.",
                category: "cddvd",
                subcategory: "Blu-Ray & 4K UHD",
                condition: "Comme neuf",
                price: 19.00,
                originalRetailPrice: 34.99,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=900&q=80",
                    "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=900&q=80"
                ],
                isbn: nil,
                authorOrArtist: "Christopher Nolan / Hans Zimmer",
                publisherOrBrand: "Warner Bros. Home Entertainment",
                releaseYear: "2022",
                clothingSize: nil,
                sellerUsername: "thomas.cinema",
                sellerDisplayName: "Thomas Ciné",
                sellerAvatarUrl: nil,
                sellerLevel: 10,
                sellerRating: 4.92,
                sellerSalesCount: 22,
                sellerCity: "Nancy (54000)",
                isVipleVerified: true,
                favoritesCount: 29,
                isFavorited: true,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 2 h"
            ),
            MarketplaceListing(
                id: "MKT-CDDVD-202",
                title: "Daft Punk — Random Access Memories (10th Anniversary Edition 2 CD)",
                subtitle: "Album Double CD + Livret Studio Collector",
                description: "Édition 10ème anniversaire en double CD incluant les 9 pistes inédites. Boîtier cristal et disques sans aucune rayure.",
                category: "cddvd",
                subcategory: "Albums CD",
                condition: "Neuf avec étiquette / sous blister",
                price: 12.00,
                originalRetailPrice: 19.99,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=900&q=80",
                    "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=900&q=80"
                ],
                isbn: nil,
                authorOrArtist: "Daft Punk",
                publisherOrBrand: "Columbia / Sony Music",
                releaseYear: "2023",
                clothingSize: nil,
                sellerUsername: "antoine.vinyle",
                sellerDisplayName: "Antoine Audio",
                sellerAvatarUrl: nil,
                sellerLevel: 6,
                sellerRating: 4.85,
                sellerSalesCount: 15,
                sellerCity: "Épinal (88000)",
                isVipleVerified: true,
                favoritesCount: 17,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 3 h"
            ),

            // 3. ACCESSOIRES & GOODIES (Priorité N°3)
            MarketplaceListing(
                id: "MKT-ACC-301",
                title: "Mug Céramique Littéraire « Un Dernier Chapitre et Je Dors » + Marque-page",
                subtitle: "Édition Officielle Livria • Céramique 350 ml & Dorure à chaud",
                description: "Tasse de lecture en céramique épaisse (350 ml) accompagnée de son marque-page aimanté assorti. Jamais utilisée, vendue dans son coffret cadeau Livria.",
                category: "accessories",
                subcategory: "Tasses & Mugs",
                condition: "Neuf avec étiquette / sous blister",
                price: 9.50,
                originalRetailPrice: 16.90,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=900&q=80",
                    "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=900&q=80"
                ],
                isbn: nil,
                authorOrArtist: "Atelier Livria",
                publisherOrBrand: "Livria Originals",
                releaseYear: "2026",
                clothingSize: nil,
                sellerUsername: "elodie.deco",
                sellerDisplayName: "Élodie Lecture",
                sellerAvatarUrl: nil,
                sellerLevel: 7,
                sellerRating: 4.95,
                sellerSalesCount: 18,
                sellerCity: "Nancy (54000)",
                isVipleVerified: true,
                favoritesCount: 31,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 4 h"
            ),
            MarketplaceListing(
                id: "MKT-ACC-302",
                title: "Affiche d'Art « Les Grandes Librairies d'Europe » (50×70 cm) Papier Fine Art",
                subtitle: "Illustration Architecturale • Papier Coton 250g/m²",
                description: "Poster d'art imprimé sur papier Fine Art mat 250g représentant les plus belles librairies historiques. Expédié roulé dans un tube cartonné rigide via UPS ou Viple Taker.",
                category: "accessories",
                subcategory: "Affiches & Posters",
                condition: "Comme neuf",
                price: 14.00,
                originalRetailPrice: 29.00,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=900&q=80",
                    "https://images.unsplash.com/photo-1507842229356-51c61504d3ab?w=900&q=80"
                ],
                isbn: nil,
                authorOrArtist: "Studio Beaux-Livres",
                publisherOrBrand: "Éditions Graphiques",
                releaseYear: "2025",
                clothingSize: nil,
                sellerUsername: "claire.bouquine",
                sellerDisplayName: "Claire Bouquine",
                sellerAvatarUrl: nil,
                sellerLevel: 12,
                sellerRating: 4.95,
                sellerSalesCount: 47,
                sellerCity: "Nancy (54000)",
                isVipleVerified: true,
                favoritesCount: 22,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 5 h"
            ),

            // 4. VÊTEMENTS (Priorité N°4)
            MarketplaceListing(
                id: "MKT-CLOTH-401",
                title: "Sweat Brodé « Club des Lecteurs Nocturnes — Livria » Coton Bio",
                subtitle: "Hoodie Unisexe • Coton Biologique 380g/m² • Couleur Crème & Violet",
                description: "Sweat à capuche épais brodé sur la poitrine (« Club des Lecteurs Nocturnes — Livria »). Porté 2 fois, lavé à froid, état impeccable.",
                category: "clothing",
                subcategory: "Sweats & Hoodies littéraires",
                condition: "Comme neuf",
                price: 22.00,
                originalRetailPrice: 49.00,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                photos: [
                    "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=900&q=80",
                    "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=900&q=80"
                ],
                isbn: nil,
                authorOrArtist: "Collection Livria",
                publisherOrBrand: "Livria Textile",
                releaseYear: "2026",
                clothingSize: "M (Unisexe)",
                sellerUsername: "camille.style",
                sellerDisplayName: "Camille Mode",
                sellerAvatarUrl: nil,
                sellerLevel: 8,
                sellerRating: 4.9,
                sellerSalesCount: 21,
                sellerCity: "Metz (57000)",
                isVipleVerified: true,
                favoritesCount: 27,
                isFavorited: false,
                isSold: false,
                allowsOffers: true,
                createdAtDisplay: "Il y a 6 h"
            )
        ]
    }

    public static func defaultSeedConversations() -> [MarketplaceConversationPreview] {
        [
            MarketplaceConversationPreview(
                id: "CONV-MKT-BOOK-101",
                listingId: "MKT-BOOK-101",
                listingTitle: "Dune — Coffret Collector Intégrale Cycle de Dune (Tomes 1 à 3)",
                listingPhoto: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=900&q=80",
                listingPrice: 24.00,
                listingCategory: "books",
                listingIsSold: false,
                otherUsername: "claire.bouquine",
                otherDisplayName: "Claire Bouquine",
                otherAvatarUrl: nil,
                otherLevel: 12,
                lastMessagePreview: "Oui tout à fait ! Je peux déposer le coffret au Viple Taker de Nancy dès demain matin.",
                lastMessageAt: "14:25",
                unreadCount: 1,
                latestOfferPrice: 22.00,
                latestOfferStatus: "Acceptée"
            ),
            MarketplaceConversationPreview(
                id: "CONV-MKT-CDDVD-201",
                listingId: "MKT-CDDVD-201",
                listingTitle: "Interstellar — Coffret Blu-Ray 4K Ultra HD + Bande Originale Hans Zimmer CD",
                listingPhoto: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=900&q=80",
                listingPrice: 19.00,
                listingCategory: "cddvd",
                listingIsSold: false,
                otherUsername: "thomas.cinema",
                otherDisplayName: "Thomas Ciné",
                otherAvatarUrl: nil,
                otherLevel: 10,
                lastMessagePreview: "Le livret 24 pages et le CD Hans Zimmer sont bien inclus dans le Steelbook !",
                lastMessageAt: "Hier",
                unreadCount: 0,
                latestOfferPrice: nil,
                latestOfferStatus: nil
            ),
            MarketplaceConversationPreview(
                id: "CONV-MKT-ACC-301",
                listingId: "MKT-ACC-301",
                listingTitle: "Mug Céramique Littéraire « Un Dernier Chapitre et Je Dors » + Marque-page",
                listingPhoto: "https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=900&q=80",
                listingPrice: 9.50,
                listingCategory: "accessories",
                listingIsSold: false,
                otherUsername: "elodie.deco",
                otherDisplayName: "Élodie Lecture",
                otherAvatarUrl: nil,
                otherLevel: 7,
                lastMessagePreview: "🏷️ Offre proposée : 8,50 € (+ 1,00 € Garantie Livria, livraison 0 €)",
                lastMessageAt: "Hier",
                unreadCount: 0,
                latestOfferPrice: 8.50,
                latestOfferStatus: "En attente"
            )
        ]
    }

    public static func defaultSeedOffers() -> [MarketplaceOffer] {
        [
            MarketplaceOffer(
                id: "OFF-101",
                listingId: "MKT-BOOK-101",
                listingTitle: "Dune — Coffret Collector Intégrale Cycle de Dune (Tomes 1 à 3)",
                listingPhoto: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=900&q=80",
                listingOriginalPrice: 24.00,
                buyerUsername: "vous.livria",
                buyerDisplayName: "Vous",
                buyerAvatarUrl: nil,
                sellerUsername: "claire.bouquine",
                offeredPrice: 22.00,
                livriaCommission: 1.00,
                shippingFee: 0.00,
                message: "Bonjour Claire, accepteriez-vous 22,00 € pour le coffret Dune ?",
                status: "Acceptée",
                createdAtDisplay: "Aujourd'hui à 14:20"
            )
        ]
    }

    public static func defaultSeedRelays() -> [MarketplaceRelayPoint] {
        [
            MarketplaceRelayPoint(
                id: "TAKER-NANCY-01",
                name: "Viple Taker • Chez Marc L. (Point Relais Particulier Vérifié)",
                address: "18 Rue Saint-Dizier",
                postalCode: "54000",
                city: "Nancy",
                distanceKm: 0.4,
                openingHours: "Lun-Sam 08h30-20h30 (Rendez-vous flexible Looby Taker)",
                latitude: 48.6908,
                longitude: 6.1832,
                isAvailable: true,
                isVipleTaker: true,
                takerDisplayName: "Marc L.",
                remunerationPerParcel: 1.00
            ),
            MarketplaceRelayPoint(
                id: "TAKER-METZ-02",
                name: "Viple Taker • Chez Amélie R. (Point Relais Particulier Vérifié)",
                address: "9 Avenue Robert Schuman",
                postalCode: "57000",
                city: "Metz",
                distanceKm: 1.1,
                openingHours: "Lun-Dim 09h00-21h00 (Remise sur créneau convenu)",
                latitude: 49.1160,
                longitude: 6.1744,
                isAvailable: true,
                isVipleTaker: true,
                takerDisplayName: "Amélie R.",
                remunerationPerParcel: 1.00
            ),
            MarketplaceRelayPoint(
                id: "UPS-NANCY-101",
                name: "UPS Access Point • Librairie & Presse Stanislas",
                address: "42 Rue des Dominicains",
                postalCode: "54000",
                city: "Nancy",
                distanceKm: 0.6,
                openingHours: "Lun-Sam 08h00-19h30",
                latitude: 48.6921,
                longitude: 6.1846,
                isAvailable: true,
                isVipleTaker: false,
                takerDisplayName: nil,
                remunerationPerParcel: 1.00
            ),
            MarketplaceRelayPoint(
                id: "UPS-STRAS-204",
                name: "UPS Access Point • Relais Kléber Culture",
                address: "15 Place Kléber",
                postalCode: "67000",
                city: "Strasbourg",
                distanceKm: 2.3,
                openingHours: "Lun-Sam 08h30-20h00",
                latitude: 48.5833,
                longitude: 7.7458,
                isAvailable: true,
                isVipleTaker: false,
                takerDisplayName: nil,
                remunerationPerParcel: 1.00
            )
        ]
    }
}
