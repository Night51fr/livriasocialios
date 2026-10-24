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

// MARK: - ViewModel Principal Livria Marketplace (@MainActor — 100% Données Réelles & Viple Live ID)

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

    // Données Marketplace Réelles (Aucune donnée de démo)
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

    // Ouverture directe d'une annonce depuis Livria Social (livriamarketplace://listing/{id})
    @Published public var deepLinkedListing: MarketplaceListing? = nil
    private var pendingDeepLinkedListingId: String? = nil

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
        if let savedData = UserDefaults.standard.data(forKey: "livria_marketplace_viple_user_v1"),
           let savedUser = try? JSONDecoder().decode(MarketplaceUserProfile.self, from: savedData) {
            self.currentUser = savedUser
            self.isAuthenticated = true
        }

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
            self.listings = resp.listings
            self.conversations = resp.conversations
            self.offers = resp.offers
            self.orders = resp.orders
            self.relayPoints = resp.relayPoints
            if self.selectedRelayPoint == nil {
                self.selectedRelayPoint = resp.relayPoints.first
            }
            self.takerApplication = resp.takerApplication

            if let pendingId = self.pendingDeepLinkedListingId,
               let matched = self.listings.first(where: { $0.id == pendingId }) {
                self.deepLinkedListing = matched
                self.pendingDeepLinkedListingId = nil
            }

            if let user = resp.currentUser, user.numericUserId > 0 {
                self.currentUser = user
                self.isAuthenticated = true
                await LivriaMarketplaceAPIClient.shared.setSession(
                    token: await LivriaMarketplaceAPIClient.shared.getToken(),
                    user: user
                )
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
            } else if !self.isAuthenticated {
                await checkCrossAppSingleSignOn()
            }
        } catch let MarketplaceServerError.maintenanceOrDown(msg) {
            self.serverMaintenanceMessage = msg
            self.isServerInMaintenanceOrDown = true
        } catch {
            if !self.isAuthenticated {
                await checkCrossAppSingleSignOn()
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 1.25 {
            try? await Task.sleep(nanoseconds: UInt64((1.25 - elapsed) * 1_000_000_000))
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
        guard let user = currentUser else { return [] }
        return listings.filter {
            $0.sellerUsername.caseInsensitiveCompare(user.username) == .orderedSame ||
            $0.sellerDisplayName.caseInsensitiveCompare(user.displayName) == .orderedSame
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
        let pathParts = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        // Si Livria Social ou Livria Store transmet la session Viple Live ID dans l'URL
        if !isAuthenticated,
           let ssoEmail = queryItems.first(where: { $0.name == "ssoEmail" })?.value,
           !ssoEmail.isEmpty,
           !ssoEmail.lowercased().hasSuffix("@guest.livria.store") {
            Task {
                await checkCrossAppSingleSignOn()
            }
        }

        // Lien direct vers une annonce : livriamarketplace://listing/{id}
        if host == "listing" || host == "annonce" || host == "item" {
            let listingId = pathParts.first ?? queryItems.first(where: { $0.name == "id" })?.value ?? ""
            selectedTab = .explore
            if !listingId.isEmpty {
                if let matched = listings.first(where: { $0.id == listingId }) {
                    deepLinkedListing = matched
                } else {
                    pendingDeepLinkedListingId = listingId
                    Task { await bootstrap() }
                }
            }
            return
        }

        if let firstPart = pathParts.first?.lowercased(),
           (firstPart == "listing" || firstPart == "marketplace"),
           pathParts.count > 1 {
            let listingId = pathParts[1]
            selectedTab = .explore
            if let matched = listings.first(where: { $0.id == listingId }) {
                deepLinkedListing = matched
            } else {
                pendingDeepLinkedListingId = listingId
                Task { await bootstrap() }
            }
            return
        }

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

    // MARK: - Contrôle d'Accès Réservé aux Utilisateurs Connectés Viple Live ID

    @discardableResult
    public func requireVipleLiveID(for actionLabel: String) -> Bool {
        guard isAuthenticated, let u = currentUser, u.numericUserId > 0 else {
            showToast("Connectez-vous avec Viple Live ID pour \(actionLabel).")
            isShowingAuthSheet = true
            return false
        }
        return true
    }

    public func startCheckout(for listing: MarketplaceListing, agreedPrice: Double? = nil) {
        guard requireVipleLiveID(for: "acheter un article sur Livria Marketplace") else { return }
        activeCheckoutAgreedPrice = agreedPrice
        activeCheckoutListing = listing
    }

    public func startMakeOffer(for listing: MarketplaceListing) {
        guard requireVipleLiveID(for: "faire une offre au vendeur") else { return }
        activeOfferListing = listing
    }

    public func startShareListing(_ listing: MarketplaceListing) {
        guard requireVipleLiveID(for: "partager une annonce en message") else { return }
        activeShareListing = listing
    }

    public func openSellTab(editing: MarketplaceListing? = nil) {
        guard requireVipleLiveID(for: "publier ou gérer une annonce") else { return }
        editingListing = editing
        selectedTab = .sell
    }

    // MARK: - Authentification Viple Live ID Réelle & Cross-App SSO

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
        if let ssoResp = await LivriaMarketplaceAPIClient.shared.acceptCrossAppSession(user: user),
           ssoResp.success,
           let confirmedUser = ssoResp.user {
            await LivriaMarketplaceAPIClient.shared.setSession(token: ssoResp.token, user: confirmedUser)
            self.currentUser = confirmedUser
        } else {
            await LivriaMarketplaceAPIClient.shared.setSession(token: discovered.token, user: user)
            self.currentUser = user
        }
        self.isAuthenticated = true
        self.isShowingCrossAppPrompt = false
        showToast("Connecté via Viple Live ID (\(self.currentUser?.displayName ?? user.displayName))")
        await bootstrap()
    }

    public func declineCrossAppSingleSignOn() {
        self.isShowingCrossAppPrompt = false
        self.discoveredCrossAppSession = nil
    }

    public func signIn(emailOrUsername: String, password: String) async -> Bool {
        let cleanEmail = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            showToast("Veuillez saisir votre e-mail Viple Live ID et votre mot de passe.")
            return false
        }
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.loginVipleLiveId(
                emailOrUsername: cleanEmail,
                password: password
            )
            if resp.success, let user = resp.user {
                await LivriaMarketplaceAPIClient.shared.setSession(token: resp.token, user: user)
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
                self.currentUser = user
                self.isAuthenticated = true
                self.isShowingAuthSheet = false
                showToast("Bienvenue sur Livria Marketplace, \(user.displayName) !")
                await bootstrap()
                return true
            } else {
                showToast(resp.message)
                return false
            }
        } catch {
            showToast("Impossible de joindre le service d'authentification Viple Live ID.")
            return false
        }
    }

    public func registerAccount(username: String, displayName: String, email: String, password: String) async -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            showToast("Veuillez renseigner tous les champs pour créer votre Viple Live ID.")
            return false
        }
        do {
            let resp = try await LivriaMarketplaceAPIClient.shared.registerVipleLiveId(
                username: username,
                displayName: displayName.isEmpty ? username : displayName,
                email: cleanEmail,
                password: password
            )
            if resp.success, let user = resp.user {
                await LivriaMarketplaceAPIClient.shared.setSession(token: resp.token, user: user)
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
                self.currentUser = user
                self.isAuthenticated = true
                self.isShowingAuthSheet = false
                showToast("Compte Viple Live ID créé avec succès !")
                await bootstrap()
                return true
            } else {
                showToast(resp.message)
                return false
            }
        } catch {
            showToast("Erreur lors de la création du compte Viple Live ID.")
            return false
        }
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
                await LivriaMarketplaceAPIClient.shared.setSession(token: resp.token, user: user)
                await LivriaMarketplaceAPIClient.shared.registerCrossAppSession(sourceApp: "Livria Marketplace")
                self.currentUser = user
                self.isAuthenticated = true
                self.isShowingAuthSheet = false
                showToast("Connecté avec Apple & Viple Live ID (\(user.displayName))")
                await bootstrap()
            } else {
                showToast(resp.message)
            }
        } catch {
            showToast("Impossible de finaliser la connexion Apple / Viple Live ID.")
        }
    }

    public func signOut() {
        Task {
            await LivriaMarketplaceAPIClient.shared.clearCrossAppSession()
            await LivriaMarketplaceAPIClient.shared.setSession(token: nil, user: nil)
        }
        self.currentUser = nil
        self.isAuthenticated = false
        self.conversations = []
        self.orders = []
        self.takerApplication = nil
        showToast("Déconnecté de Viple Live ID")
    }

    public func deleteVipleAccount() async -> Bool {
        let ok = await LivriaMarketplaceAPIClient.shared.deleteAccount()
        await LivriaMarketplaceAPIClient.shared.clearCrossAppSession()
        await LivriaMarketplaceAPIClient.shared.setSession(token: nil, user: nil)
        self.currentUser = nil
        self.isAuthenticated = false
        self.conversations = []
        self.orders = []
        self.takerApplication = nil
        showToast("Votre compte Viple Live ID et vos données ont été supprimés.")
        return ok
    }

    // MARK: - Upload & Recadrage Photo de Profil Viple Live ID

    public func uploadCroppedAvatar(jpegData: Data) async -> Bool {
        guard isAuthenticated else {
            showToast("Connectez-vous à votre Viple Live ID pour modifier votre photo.")
            return false
        }
        if let uploadedUrl = await LivriaMarketplaceAPIClient.shared.uploadCroppedAvatar(jpegData: jpegData) {
            if var u = currentUser {
                u.avatarUrl = uploadedUrl
                currentUser = u
                await LivriaMarketplaceAPIClient.shared.setSession(
                    token: await LivriaMarketplaceAPIClient.shared.getToken(),
                    user: u
                )
            }
            showToast("Photo de profil recadrée et synchronisée sur Viple Live ID !")
            return true
        }
        showToast("Impossible de téléverser la photo de profil sur le serveur.")
        return false
    }

    // MARK: - Création, Modification, Suppression & Favoris d'Annonces

    public func toggleFavorite(for listing: MarketplaceListing) {
        guard isAuthenticated else {
            showToast("Connectez-vous avec Viple Live ID pour ajouter des favoris.")
            isShowingAuthSheet = true
            return
        }
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
        let sellerUsername = currentUser?.username ?? "membre"
        let sellerDisplayName = currentUser?.displayName ?? "Membre Livria"
        let sellerCity = currentUser.map { $0.city.isEmpty ? "France" : "\($0.city) (\($0.postalCode))" } ?? "France"

        let item = MarketplaceListing(
            id: existingId ?? "0",
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
            photos: photos,
            isbn: isbn,
            authorOrArtist: authorOrArtist,
            publisherOrBrand: publisherOrBrand,
            releaseYear: releaseYear,
            clothingSize: clothingSize,
            sellerUsername: sellerUsername,
            sellerDisplayName: sellerDisplayName,
            sellerAvatarUrl: currentUser?.avatarUrl,
            sellerLevel: currentUser?.level ?? 1,
            sellerRating: 5.0,
            sellerSalesCount: 1,
            sellerCity: sellerCity,
            isVipleVerified: true,
            favoritesCount: existingId != nil ? (listings.first(where: { $0.id == existingId })?.favoritesCount ?? 1) : 1,
            isFavorited: false,
            isSold: false,
            allowsOffers: allowsOffers,
            createdAtDisplay: existingId != nil ? "Modifiée à l'instant" : "Publiée à l'instant"
        )

        if let existingId, let idx = listings.firstIndex(where: { $0.id == existingId }) {
            if let remote = try? await LivriaMarketplaceAPIClient.shared.updateListing(item) {
                listings[idx] = remote
                showToast("Votre annonce « \(remote.title) » a été mise à jour !")
                return remote
            }
            listings[idx] = item
            showToast("Votre annonce « \(item.title) » a été mise à jour !")
            return item
        } else {
            if let remote = try? await LivriaMarketplaceAPIClient.shared.createListing(item) {
                listings.insert(remote, at: 0)
                showToast("Annonce « \(remote.title) » publiée sur Livria Marketplace !")
                return remote
            }
            showToast("Erreur lors de la publication sur le serveur.")
            return item
        }
    }

    public func deleteListing(_ listing: MarketplaceListing) async {
        listings.removeAll { $0.id == listing.id }
        _ = try? await LivriaMarketplaceAPIClient.shared.deleteListing(listingId: listing.id)
        showToast("Annonce « \(listing.title) » supprimée")
    }

    // MARK: - Lookup ISBN Réel (Catalogue Livria + Google Books)

    public func lookupBookByISBNAsync(_ rawISBN: String) async -> MarketplaceISBNLookupResult? {
        return await LivriaMarketplaceAPIClient.shared.lookupISBN(rawISBN)
    }

    // MARK: - Faire une Offre & Partager une Annonce en Message

    public func submitPriceOffer(for listing: MarketplaceListing, offeredPrice: Double, message: String) async {
        guard isAuthenticated else {
            showToast("Connectez-vous avec Viple Live ID pour faire une offre.")
            isShowingAuthSheet = true
            return
        }
        let cleanMsg = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Proposition d'achat à \(String(format: "%.2f", offeredPrice)) € (+ 1,00 € Garantie et Maintien du service Livria, livraison 0 €)."
            : message

        do {
            let (remoteOffer, remoteConvId) = try await LivriaMarketplaceAPIClient.shared.createOffer(
                listingId: listing.id,
                offeredPrice: offeredPrice,
                message: cleanMsg
            )
            if let remoteOffer {
                offers.insert(remoteOffer, at: 0)
            }
            await bootstrap()
            if let remoteConvId,
               let conv = conversations.first(where: { $0.id == remoteConvId }) {
                await loadMessages(for: conv)
            }
            showToast("Offre de \(String(format: "%.2f €", offeredPrice)) envoyée à @\(listing.sellerUsername) !")
        } catch {
            showToast("Impossible d'envoyer l'offre pour le moment.")
        }
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
            id: "0",
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
            lastMessagePreview: "Nouvelle discussion concernant « \(listing.title) »",
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
        if let remote = try? await LivriaMarketplaceAPIClient.shared.fetchConversationThread(conversationId: conversation.id) {
            self.activeThreadMessages = remote.messages
        } else {
            self.activeThreadMessages = []
        }
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
        guard isAuthenticated else {
            showToast("Connectez-vous avec Viple Live ID pour envoyer un message.")
            isShowingAuthSheet = true
            return
        }
        let senderUsername = currentUser?.username ?? "membre"
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
            offerId: nil,
            offerAmount: offerAmount,
            offerStatus: offerAmount != nil ? "En attente" : nil,
            sentAtDisplay: "À l'instant",
            isFromMe: true
        )
        activeThreadMessages.append(localMsg)

        if let (remoteMsg, remoteConvId) = try? await LivriaMarketplaceAPIClient.shared.sendDirectMessage(
            conversationId: conversation.id,
            listingId: conversation.listingId,
            recipientUsername: conversation.otherUsername,
            text: text,
            imageUrl: imageUrl,
            gifUrl: gifUrl,
            audioUrl: audioUrl,
            audioDurationSeconds: audioDurationSeconds,
            offerAmount: offerAmount
        ) {
            if let remoteMsg, let idx = activeThreadMessages.firstIndex(where: { $0.id == localMsg.id }) {
                activeThreadMessages[idx] = remoteMsg
            }
            if let remoteConvId, let cIdx = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[cIdx].id = remoteConvId
                conversations[cIdx].lastMessagePreview = remoteMsg?.text ?? text
                conversations[cIdx].lastMessageAt = "À l'instant"
            }
        }
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
    ) async -> MarketplaceOrder? {
        guard isAuthenticated else {
            showToast("Connectez-vous avec votre Viple Live ID pour finaliser l'achat.")
            isShowingAuthSheet = true
            return nil
        }

        let finalItemPrice = agreedPrice ?? listing.price
        let selectedRelay = relay ?? selectedRelayPoint ?? relayPoints.first
        let isTaker = selectedRelay?.isParticulierTaker ?? false

        do {
            let remoteOrder = try await LivriaMarketplaceAPIClient.shared.checkoutListing(
                listingId: listing.id,
                agreedPrice: finalItemPrice,
                paymentMethod: paymentMethod,
                deliveryMode: deliveryMode,
                relayId: selectedRelay?.id,
                relayName: selectedRelay?.name,
                relayAddress: selectedRelay.map { "\($0.address), \($0.postalCode) \($0.city)" },
                isVipleTakerRelay: isTaker
            )
            orders.insert(remoteOrder, at: 0)
            if let idx = listings.firstIndex(where: { $0.id == listing.id }) {
                listings[idx].isSold = true
            }
            showToast("Commande \(remoteOrder.orderNumber) confirmée via \(paymentMethod) !")
            return remoteOrder
        } catch {
            showToast("Impossible de valider la commande sur le serveur.")
            return nil
        }
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
        } else {
            showToast("Aucun point relais trouvé pour ce secteur.")
        }
    }

    // MARK: - Candidature & Suivi « Devenir Viple Taker » (1,00 € / colis)

    public func fetchTakerApplicationStatus() async {
        if let resp = try? await LivriaMarketplaceAPIClient.shared.fetchTakerStatus() {
            self.takerApplication = resp.application
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
            showToast("Impossible d'envoyer la demande Viple Taker au serveur.")
            return false
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
}
