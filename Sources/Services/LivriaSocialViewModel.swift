import Foundation
import SwiftUI

// MARK: - ViewModel Principal « Livria Social » (store.livria.social • Fil d'Actu, Listes Rémunérées, Messagerie, Profils & Jeux XP)

@MainActor
public final class LivriaSocialViewModel: ObservableObject {
    @Published public var selectedTab: Int = 0
    @Published public var isShowingAuthSheet: Bool = false
    @Published public var isShowingTermsReviewSheet: Bool = false
    @Published public var isShowingCreatePostSheet: Bool = false
    @Published public var isShowingCreateListSheet: Bool = false
    @Published public var activeToastMessage: String? = nil
    @Published public var isInitialBootstrapping: Bool = true
    @Published public var isLoading: Bool = false
    @Published public var authErrorMessage: String? = nil
    @Published public var applePasswordSetupNotice: String? = nil
    @Published public var pendingAppleOnboardingUserId: String? = nil
    @Published public var pendingAppleOnboardingEmail: String? = nil
    @Published public var pendingAppleFirstName: String = ""
    @Published public var pendingAppleLastName: String = ""

    // Conditions Générales d'Utilisation (obligatoires au 1er lancement)
    @Published public var hasAcceptedTermsOfUse: Bool = false

    // Session Viple Live ID obligatoire pour utiliser Livria Social
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: SocialUserProfile? = nil

    // Verrous quotidiens locaux + serveur (1 bonus quotidien / jour et 1 roue / jour)
    @Published public var hasClaimedDailyToday: Bool = false
    @Published public var hasSpunWheelToday: Bool = false

    // Données LivriaSocial synchronisées avec https://livriasocial.viplenetwork.com/api/mobile/v1/bootstrap
    @Published public var feedFilter: String = "all"
    @Published public var posts: [SocialFeedPost] = []
    @Published public var lists: [SocialBookListModel] = []
    @Published public var myLists: [SocialBookListModel] = []
    @Published public var conversations: [SocialConversationSummary] = []
    @Published public var topMembers: [SocialMemberSummary] = []
    @Published public var booksCatalog: [SocialBookItem] = []
    @Published public var backgroundPresets: [SocialBackgroundPreset] = []
    @Published public var games: SocialGamesState? = nil

    // Recherche de membres
    @Published public var searchedMembers: [SocialMemberSummary] = []

    // Profil membre ouvert par lien direct depuis Livria Store (livriasocial://profile/{id})
    @Published public var deepLinkedMemberProfile: SocialMemberSummary? = nil

    private let defaults = UserDefaults.standard
    private let acceptedTermsKey = "livria.social.ios.acceptedCGU.v1"
    private let savedEmailKey = "livria.social.ios.authEmail.v2"
    private let savedUserIdKey = "livria.social.ios.authUserId.v2"
    private let savedTokenKey = "livria.social.ios.authToken.v2"

    public init() {
        // Nettoyage des anciennes clés v1 qui pouvaient contenir le compte fallback par défaut
        defaults.removeObject(forKey: "livria.social.ios.vipleLiveEmail")
        defaults.removeObject(forKey: "livria.social.ios.vipleLiveUserId")

        self.hasAcceptedTermsOfUse = defaults.bool(forKey: acceptedTermsKey)

        let savedEmail = defaults.string(forKey: savedEmailKey) ?? ""
        let savedUid = defaults.integer(forKey: savedUserIdKey)
        let savedToken = defaults.string(forKey: savedTokenKey) ?? ""

        if !savedEmail.isEmpty && savedUid > 0 && !savedToken.isEmpty {
            self.isAuthenticated = true
            self.syncLocalDailyLocks(userId: savedUid)
            Task {
                async let minSplashDelay: Void = {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                }()
                await refreshBootstrap(email: savedEmail, userId: savedUid)
                _ = await minSplashDelay
                withAnimation(.easeInOut(duration: 0.45)) {
                    self.isInitialBootstrapping = false
                }
            }
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeInOut(duration: 0.45)) {
                    self.isInitialBootstrapping = false
                }
            }
        }
    }

    public func acceptTermsOfUse() {
        defaults.set(true, forKey: acceptedTermsKey)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            hasAcceptedTermsOfUse = true
        }
    }

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func dailyClaimKey(for userId: Int) -> String {
        "livria.social.ios.dailyClaim.\(userId)"
    }

    private func wheelSpinKey(for userId: Int) -> String {
        "livria.social.ios.wheelSpin.\(userId)"
    }

    private func syncLocalDailyLocks(userId: Int) {
        let today = Self.todayDateString()
        let claimedDate = defaults.string(forKey: dailyClaimKey(for: userId)) ?? ""
        let spunDate = defaults.string(forKey: wheelSpinKey(for: userId)) ?? ""
        self.hasClaimedDailyToday = (claimedDate == today)
        self.hasSpunWheelToday = (spunDate == today)
    }

    public var canClaimDailyBonusToday: Bool {
        if hasClaimedDailyToday { return false }
        return games?.canClaimDaily ?? true
    }

    public var canSpinFortuneWheelToday: Bool {
        if hasSpunWheelToday { return false }
        return games?.canSpinWheel ?? true
    }

    public var unreadMessagesCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    public func showToast(_ text: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeToastMessage = text
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if activeToastMessage == text {
                withAnimation {
                    activeToastMessage = nil
                }
            }
        }
    }

    private var authPayload: [String: Any] {
        [
            "userId": currentUser?.id ?? defaults.integer(forKey: savedUserIdKey),
            "email": currentUser?.email ?? defaults.string(forKey: savedEmailKey) ?? ""
        ]
    }

    // MARK: - 1. Synchronisation Globale (Uniquement si connecté à Viple Live ID)

    public func refreshBootstrap(email: String? = nil, userId: Int? = nil, filter: String? = nil) async {
        let activeFilter = filter ?? feedFilter
        let activeEmail = (email ?? currentUser?.email ?? defaults.string(forKey: savedEmailKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let activeUid = userId ?? currentUser?.id ?? defaults.integer(forKey: savedUserIdKey)

        guard !activeEmail.isEmpty || activeUid > 0 else {
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }

        do {
            let boot = try await LivriaSocialAPIClient.shared.fetchBootstrap(
                email: activeEmail.isEmpty ? nil : activeEmail,
                userId: activeUid > 0 ? activeUid : nil,
                filter: activeFilter
            )
            self.currentUser = boot.user
            self.isAuthenticated = true
            self.posts = boot.posts
            self.lists = boot.lists
            self.myLists = boot.myLists
            self.conversations = boot.conversations
            self.topMembers = boot.topMembers
            self.booksCatalog = boot.booksCatalog
            self.backgroundPresets = boot.backgroundPresets

            let today = Self.todayDateString()
            if !boot.games.canClaimDaily {
                defaults.set(today, forKey: dailyClaimKey(for: boot.user.id))
            }
            if !boot.games.canSpinWheel {
                defaults.set(today, forKey: wheelSpinKey(for: boot.user.id))
            }
            syncLocalDailyLocks(userId: boot.user.id)

            var syncedGames = boot.games
            if hasClaimedDailyToday { syncedGames.canClaimDaily = false }
            if hasSpunWheelToday { syncedGames.canSpinWheel = false }
            self.games = syncedGames
        } catch {
            print("[LivriaSocial.iOS] Erreur bootstrap: \(error.localizedDescription)")
        }
    }

    // MARK: - 2. Authentification Viple Live ID Obligatoire

    public func signIn(email: String, password: String) async {
        isLoading = true
        authErrorMessage = nil
        applePasswordSetupNotice = nil
        defer { isLoading = false }
        do {
            let res: SocialAuthResponse = try await LivriaSocialAPIClient.shared.postJSON("/auth/login", body: [
                "email": email,
                "password": password
            ])
            if res.requiresApplePasswordSetup == true {
                let msg = res.message ?? res.error ?? "Un lien pour créer votre mot de passe vient d'être envoyé sur votre boîte mail iCloud."
                applePasswordSetupNotice = msg
                showToast("Vérifiez votre boîte mail iCloud pour créer votre mot de passe.")
                return
            }
            guard res.ok, let user = res.user else {
                authErrorMessage = res.error ?? "Identifiant Viple Live ID ou mot de passe incorrect."
                return
            }
            self.currentUser = user
            self.isAuthenticated = true
            defaults.set(user.email, forKey: savedEmailKey)
            defaults.set(user.id, forKey: savedUserIdKey)
            defaults.set(res.token ?? "ls-token-\(user.id)", forKey: savedTokenKey)
            syncLocalDailyLocks(userId: user.id)
            isShowingAuthSheet = false
            showToast("Connecté sur Livria Social (\(user.displayName)) !")
            await refreshBootstrap(email: user.email, userId: user.id)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    public func handleSignInWithApple(
        appleUserId: String,
        email: String?,
        firstName: String?,
        lastName: String?,
        identityToken: String?
    ) async {
        isLoading = true
        authErrorMessage = nil
        applePasswordSetupNotice = nil
        defer { isLoading = false }
        do {
            let res: SocialAuthResponse = try await LivriaSocialAPIClient.shared.postJSON("/auth/apple", body: [
                "appleUserId": appleUserId,
                "email": email ?? "",
                "firstName": firstName ?? "",
                "lastName": lastName ?? "",
                "identityToken": identityToken ?? ""
            ])
            if res.needsOnboarding == true || res.requiresAppleOnboarding == true {
                self.pendingAppleOnboardingUserId = res.appleUserId ?? appleUserId
                self.pendingAppleOnboardingEmail = res.appleEmail ?? email
                self.pendingAppleFirstName = res.suggestedFirstName ?? res.appleFirstName ?? firstName ?? ""
                self.pendingAppleLastName = res.suggestedLastName ?? res.appleLastName ?? lastName ?? ""
                return
            }
            guard res.ok, let user = res.user else {
                authErrorMessage = res.error ?? "Connexion avec Apple impossible."
                return
            }
            self.pendingAppleOnboardingUserId = nil
            self.pendingAppleOnboardingEmail = nil
            self.currentUser = user
            self.isAuthenticated = true
            defaults.set(user.email, forKey: savedEmailKey)
            defaults.set(user.id, forKey: savedUserIdKey)
            defaults.set(res.token ?? "ls-token-\(user.id)", forKey: savedTokenKey)
            syncLocalDailyLocks(userId: user.id)
            isShowingAuthSheet = false
            showToast("Connecté avec Apple (\(user.displayName)) !")
            await refreshBootstrap(email: user.email, userId: user.id)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    public func completeAppleOnboarding(
        firstName: String,
        lastName: String,
        displayName: String,
        viplemailUser: String
    ) async {
        guard let appleUserId = pendingAppleOnboardingUserId, !appleUserId.isEmpty else { return }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let res: SocialAuthResponse = try await LivriaSocialAPIClient.shared.postJSON("/auth/apple-complete", body: [
                "appleUserId": appleUserId,
                "appleEmail": pendingAppleOnboardingEmail ?? "",
                "firstName": firstName,
                "lastName": lastName,
                "displayName": displayName,
                "vipleMailUser": viplemailUser,
                "viplemailUser": viplemailUser
            ])
            guard res.ok, let user = res.user else {
                authErrorMessage = res.error ?? "Impossible de finaliser l'adresse @viplemail.fr."
                return
            }
            self.pendingAppleOnboardingUserId = nil
            self.pendingAppleOnboardingEmail = nil
            self.currentUser = user
            self.isAuthenticated = true
            defaults.set(user.email, forKey: savedEmailKey)
            defaults.set(user.id, forKey: savedUserIdKey)
            defaults.set(res.token ?? "ls-token-\(user.id)", forKey: savedTokenKey)
            syncLocalDailyLocks(userId: user.id)
            isShowingAuthSheet = false
            showToast("Compte Viple Live ID créé (\(user.email)) !")
            await refreshBootstrap(email: user.email, userId: user.id)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    public func linkAppleToExistingAccount(
        email: String,
        password: String
    ) async {
        guard let appleUserId = pendingAppleOnboardingUserId, !appleUserId.isEmpty else { return }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let res: SocialAuthResponse = try await LivriaSocialAPIClient.shared.postJSON("/auth/apple-link-existing", body: [
                "appleUserId": appleUserId,
                "appleEmail": pendingAppleOnboardingEmail ?? "",
                "email": email,
                "password": password
            ])
            guard res.ok, let user = res.user else {
                authErrorMessage = res.error ?? "Identifiant Viple Live ID ou mot de passe incorrect."
                return
            }
            self.pendingAppleOnboardingUserId = nil
            self.pendingAppleOnboardingEmail = nil
            self.currentUser = user
            self.isAuthenticated = true
            defaults.set(user.email, forKey: savedEmailKey)
            defaults.set(user.id, forKey: savedUserIdKey)
            defaults.set(res.token ?? "ls-token-\(user.id)", forKey: savedTokenKey)
            syncLocalDailyLocks(userId: user.id)
            isShowingAuthSheet = false
            showToast("Votre compte Viple Live ID (\(user.displayName)) est désormais associé à votre compte Apple !")
            await refreshBootstrap(email: user.email, userId: user.id)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    public func deleteVipleAccount() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/auth/delete-account", body: authPayload)
            let ok = (res["ok"] as? Bool) ?? false
            if ok {
                defaults.removeObject(forKey: savedEmailKey)
                defaults.removeObject(forKey: savedUserIdKey)
                defaults.removeObject(forKey: savedTokenKey)
                currentUser = nil
                isAuthenticated = false
                posts = []
                myLists = []
                conversations = []
                games = nil
                showToast("Votre compte Viple Live ID a été définitivement supprimé.")
                return true
            } else {
                showToast((res["error"] as? String) ?? "Impossible de supprimer le compte.")
                return false
            }
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    public func registerAccount(email: String, displayName: String, password: String) async {
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let res: SocialAuthResponse = try await LivriaSocialAPIClient.shared.postJSON("/auth/register", body: [
                "email": email,
                "displayName": displayName,
                "password": password
            ])
            guard res.ok, let user = res.user else {
                authErrorMessage = res.error ?? "Impossible de créer le compte."
                return
            }
            self.currentUser = user
            self.isAuthenticated = true
            defaults.set(user.email, forKey: savedEmailKey)
            defaults.set(user.id, forKey: savedUserIdKey)
            defaults.set(res.token ?? "ls-token-\(user.id)", forKey: savedTokenKey)
            syncLocalDailyLocks(userId: user.id)
            isShowingAuthSheet = false
            showToast("Bienvenue sur Livria Social, \(user.displayName) !")
            await refreshBootstrap(email: user.email, userId: user.id)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    public func signOut() {
        defaults.removeObject(forKey: savedEmailKey)
        defaults.removeObject(forKey: savedUserIdKey)
        defaults.removeObject(forKey: savedTokenKey)
        currentUser = nil
        isAuthenticated = false
        posts = []
        myLists = []
        conversations = []
        games = nil
        showToast("Vous êtes déconnecté de votre compte Viple Live ID.")
    }

    // MARK: - 3. Fil d'Actualité : Publications, Réactions & Commentaires

    public func createPost(
        postType: String,
        content: String,
        mediaUrl: String = "",
        mediaType: String = "none",
        bookId: Int? = nil,
        bookListId: Int? = nil,
        moodBadge: String = "✨ Coup de cœur"
    ) async -> Bool {
        var payload = authPayload
        payload["postType"] = postType
        payload["content"] = content
        payload["mediaUrl"] = mediaUrl
        payload["mediaType"] = mediaType
        payload["moodBadge"] = moodBadge
        if let bookId, bookId > 0 { payload["bookId"] = bookId }
        if let bookListId, bookListId > 0 { payload["bookListId"] = bookListId }

        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/posts/create", body: payload)
            showToast((res["message"] as? String) ?? "Publication partagée (+15 XP) !")
            await refreshBootstrap()
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    public func reactToPost(postId: Int, reactionType: String) async {
        do {
            _ = try await LivriaSocialAPIClient.shared.postRaw("/posts/react", body: [
                "postId": postId,
                "reactionType": reactionType
            ])
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    public func addComment(postId: Int, content: String) async {
        var payload = authPayload
        payload["postId"] = postId
        payload["content"] = content
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/posts/comment", body: payload)
            showToast((res["message"] as? String) ?? "Commentaire publié (+5 XP) !")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    public func updatePost(
        postId: Int,
        content: String,
        moodBadge: String,
        bookId: Int? = nil,
        mediaUrl: String? = nil,
        mediaType: String? = nil
    ) async -> Bool {
        var payload = authPayload
        payload["postId"] = postId
        payload["content"] = content
        payload["moodBadge"] = moodBadge
        payload["bookId"] = bookId ?? 0
        if let mediaUrl {
            payload["mediaUrl"] = mediaUrl
        }
        if let mediaType {
            payload["mediaType"] = mediaType
        }
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/posts/update", body: payload)
            let ok = (res["ok"] as? Bool) ?? true
            showToast((res["message"] as? String) ?? "Publication modifiée !")
            await refreshBootstrap()
            return ok
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    public func deletePost(postId: Int) async {
        var payload = authPayload
        payload["postId"] = postId
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/posts/delete", body: payload)
            showToast((res["message"] as? String) ?? "Publication supprimée.")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    public func openBookInStoreOrWeb(bookId: Int?, storeUrl: String = "") {
        LivriaSocialBookLinkOpener.openBook(bookId: bookId, storeUrl: storeUrl)
    }

    // MARK: - 4. Listes de Livres Rémunérées (0,50 € à 1,00 € par achat généré)

    public func createBookList(
        title: String,
        description: String,
        themeEmoji: String,
        themeGradient: String,
        bookIds: [Int],
        curatorNote: String
    ) async -> Bool {
        var payload = authPayload
        payload["title"] = title
        payload["description"] = description
        payload["themeEmoji"] = themeEmoji
        payload["themeGradient"] = themeGradient
        payload["bookIds"] = bookIds
        payload["curatorNote"] = curatorNote
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/lists/create", body: payload)
            showToast((res["message"] as? String) ?? "Liste de livres créée (+25 XP) !")
            await refreshBootstrap()
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    public func addBookToList(listId: Int, bookId: Int, note: String) async {
        var payload = authPayload
        payload["listId"] = listId
        payload["bookId"] = bookId
        payload["note"] = note
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/lists/add-book", body: payload)
            showToast((res["message"] as? String) ?? "Livre ajouté à la liste !")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    public func deleteBookList(listId: Int) async {
        var payload = authPayload
        payload["listId"] = listId
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/lists/delete", body: payload)
            showToast((res["message"] as? String) ?? "Liste supprimée.")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    // MARK: - 5. Messagerie Instantanée Riche (Photos, Vocaux, GIFs, Livres Boutique, Liens)

    public func loadConversationThread(otherUserId: Int) async -> [SocialRichMessageItem] {
        do {
            let res = try await LivriaSocialAPIClient.shared.fetchThread(
                otherUserId: otherUserId,
                email: currentUser?.email ?? defaults.string(forKey: savedEmailKey),
                userId: currentUser?.id
            )
            await refreshBootstrap()
            return res.messages
        } catch {
            return []
        }
    }

    public func sendRichMessage(
        recipientId: Int,
        body: String,
        attachmentType: String = "none",
        attachmentUrl: String = "",
        attachmentTitle: String = "",
        attachmentMeta: String = "",
        bookId: Int? = nil,
        voiceDurationSec: Int = 0
    ) async -> Bool {
        var payload = authPayload
        payload["recipientId"] = recipientId
        payload["body"] = body
        payload["attachmentType"] = attachmentType
        payload["attachmentUrl"] = attachmentUrl
        payload["attachmentTitle"] = attachmentTitle
        payload["attachmentMeta"] = attachmentMeta
        payload["voiceDurationSec"] = voiceDurationSec
        if let bookId, bookId > 0 { payload["bookId"] = bookId }

        do {
            _ = try await LivriaSocialAPIClient.shared.postRaw("/messages/send", body: payload)
            await refreshBootstrap()
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    public func searchGifs(query: String) async -> [SocialGifItem] {
        do {
            return try await LivriaSocialAPIClient.shared.searchGifs(query: query)
        } catch {
            return []
        }
    }

    public func uploadPhotoData(_ data: Data, fileExtension: String = "jpg") async -> String? {
        do {
            return try await LivriaSocialAPIClient.shared.uploadMedia(
                mediaKind: "image",
                fileExtension: fileExtension,
                data: data
            )
        } catch {
            showToast(error.localizedDescription)
            return nil
        }
    }

    public func uploadVoiceData(_ data: Data, fileExtension: String = "m4a") async -> String? {
        do {
            return try await LivriaSocialAPIClient.shared.uploadMedia(
                mediaKind: "voice",
                fileExtension: fileExtension,
                data: data
            )
        } catch {
            showToast(error.localizedDescription)
            return nil
        }
    }

    public func uploadVideoData(_ data: Data, fileExtension: String = "mp4") async -> String? {
        do {
            return try await LivriaSocialAPIClient.shared.uploadMedia(
                mediaKind: "video",
                fileExtension: fileExtension,
                data: data
            )
        } catch {
            showToast(error.localizedDescription)
            return nil
        }
    }

    // MARK: - 6. Recherche de Membres & Personnalisation Complète du Profil

    public func searchMembers(query: String) async {
        do {
            searchedMembers = try await LivriaSocialAPIClient.shared.searchMembers(query: query, excludeUserId: currentUser?.id)
        } catch {
            searchedMembers = []
        }
    }

    public func fetchMemberProfile(memberId: Int) async -> SocialMemberPublicProfileResponse? {
        try? await LivriaSocialAPIClient.shared.fetchMemberPublicProfile(memberId: memberId)
    }

    public func saveProfileCustomization(
        displayName: String,
        motto: String,
        bio: String,
        accentColor: String,
        favoriteGenres: String,
        avatarUrl: String,
        pageBackgroundType: String,
        pageBackgroundValue: String,
        cardStyle: String,
        cardOpacity: Int,
        bannerUrl: String,
        customTitleBadge: String
    ) async {
        var payload = authPayload
        payload["displayName"] = displayName
        payload["motto"] = motto
        payload["bio"] = bio
        payload["accentColor"] = accentColor
        payload["favoriteGenres"] = favoriteGenres
        payload["avatarUrl"] = avatarUrl
        payload["pageBackgroundType"] = pageBackgroundType
        payload["pageBackgroundValue"] = pageBackgroundValue
        payload["cardStyle"] = cardStyle
        payload["cardOpacity"] = cardOpacity
        payload["bannerUrl"] = bannerUrl
        payload["customTitleBadge"] = customTitleBadge

        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/profile/customize", body: payload)
            showToast((res["message"] as? String) ?? "Profil et arrière-plan enregistrés !")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    // MARK: - 7. Espace Jeux de Livria (1 Bonus Quotidien / jour & 1 Roue de la Fortune / jour)

    public func claimDailyGameBonus() async {
        guard canClaimDailyBonusToday else {
            showToast("Vous avez déjà récupéré votre bonus quotidien aujourd'hui. Revenez demain !")
            return
        }
        let uid = currentUser?.id ?? defaults.integer(forKey: savedUserIdKey)
        let today = Self.todayDateString()

        // Verrouillage immédiat pour empêcher les clics multiples
        hasClaimedDailyToday = true
        games?.canClaimDaily = false
        if uid > 0 {
            defaults.set(today, forKey: dailyClaimKey(for: uid))
        }

        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/games/daily-claim", body: authPayload)
            showToast((res["message"] as? String) ?? "Bonus quotidien réclamé !")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
            await refreshBootstrap()
        }
    }

    public func spinFortuneWheel() async -> String? {
        guard canSpinFortuneWheelToday else {
            showToast("Vous avez déjà lancé la Roue de la Fortune aujourd'hui. Revenez demain !")
            return nil
        }
        let uid = currentUser?.id ?? defaults.integer(forKey: savedUserIdKey)
        let today = Self.todayDateString()

        // Verrouillage immédiat pour empêcher les lancers multiples
        hasSpunWheelToday = true
        games?.canSpinWheel = false
        if uid > 0 {
            defaults.set(today, forKey: wheelSpinKey(for: uid))
        }

        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/games/wheel-spin", body: authPayload)
            let reward = (res["prizeLabel"] as? String) ?? (res["message"] as? String) ?? "Gain crédité !"
            showToast(reward)
            await refreshBootstrap()
            return reward
        } catch {
            showToast(error.localizedDescription)
            await refreshBootstrap()
            return nil
        }
    }

    public func submitGameScore(game: String, score: Int, xp: Int) async {
        var payload = authPayload
        payload["game"] = game
        payload["score"] = score
        payload["xp"] = xp
        do {
            let res = try await LivriaSocialAPIClient.shared.postRaw("/games/submit", body: payload)
            showToast((res["message"] as? String) ?? "+\(xp) XP gagnés !")
            await refreshBootstrap()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    // MARK: - 8. Ouverture Directe d'un Profil depuis Livria Store (livriasocial://profile/{id})

    public func handleIncomingURL(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "livriasocial" else { return }

        let host = url.host?.lowercased() ?? ""
        let pathParts = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        var extractedId: Int? = nil
        if (host == "profile" || host == "member" || host == "u"), let first = pathParts.first, let id = Int(first) {
            extractedId = id
        } else if let first = pathParts.first, (first == "profile" || first == "u" || first == "member"), pathParts.count > 1, let id = Int(pathParts[1]) {
            extractedId = id
        } else if let idStr = queryItems.first(where: { $0.name == "id" || $0.name == "memberId" })?.value, let id = Int(idStr) {
            extractedId = id
        } else if let id = Int(host) {
            extractedId = id
        }

        guard let memberId = extractedId, memberId > 0 else { return }
        let nameParam = queryItems.first(where: { $0.name == "name" })?.value ?? "Lecteur Livria"

        if let existing = topMembers.first(where: { $0.id == memberId }) ?? searchedMembers.first(where: { $0.id == memberId }) {
            self.deepLinkedMemberProfile = existing
        } else {
            self.deepLinkedMemberProfile = SocialMemberSummary(
                id: memberId,
                displayName: nameParam,
                email: nil,
                bio: "",
                motto: "",
                favoriteGenres: "",
                accentColor: "#7C3AED",
                avatarUrl: "",
                xp: 100,
                level: 1,
                isLivriaPlus: false,
                profileUrl: "https://livriasocial.viplenetwork.com/u/\(memberId)"
            )
        }
    }
}
