import SwiftUI
import AVKit

// MARK: - Onglet 5 : Mon Profil & Studio de Personnalisation Complète (Arrière-plan, Couleurs, Opacité & Viple Live ID)

public struct SocialProfileView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var displayName: String = ""
    @State private var motto: String = ""
    @State private var bio: String = ""
    @State private var accentColor: String = "#8b5cf6"
    @State private var favoriteGenres: String = ""
    @State private var avatarUrl: String = ""
    @State private var bannerUrl: String = ""
    @State private var customTitleBadge: String = "✨ Membre Fondateur"
    @State private var pageBackgroundType: String = "preset"
    @State private var pageBackgroundValue: String = "aurora-night"
    @State private var cardStyle: String = "glass"
    @State private var cardOpacity: Double = 85
    @State private var didLoadInitialForm: Bool = false
    @State private var showingDeleteAccountConfirmation: Bool = false

    private let accentChoices = ["#8b5cf6", "#ec4899", "#06b6d4", "#f59e0b", "#10b981", "#ef4444"]

    public init() {}

    private var myPublishedPosts: [SocialFeedPost] {
        guard let uid = social.currentUser?.id else { return [] }
        return social.posts.filter { $0.userId == uid || $0.author.id == uid }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeaderCard

                    myPostsSectionCard

                    vipleLiveIdAccountCard

                    backgroundStudioCard

                    identityEditorCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .socialCustomBackground(
                type: pageBackgroundType,
                value: pageBackgroundValue
            )
            .navigationTitle("Mon Profil & Studio")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                syncFormWithUser()
            }
            .onChange(of: social.currentUser?.id) { _, _ in
                syncFormWithUser()
            }
            .alert("Êtes-vous sûr de vouloir supprimer votre compte Viple Live ID ?", isPresented: $showingDeleteAccountConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Oui, supprimer définitivement", role: .destructive) {
                    Task {
                        _ = await social.deleteVipleAccount()
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer définitivement votre compte Viple Live ID ? Cette action est irréversible et entraînera la suppression de votre profil et de vos données sur Livria et Viple Live ID.")
            }
        }
    }

    private func syncFormWithUser() {
        guard let u = social.currentUser else { return }
        displayName = u.displayName
        motto = u.motto
        bio = u.bio
        accentColor = u.accentColor
        favoriteGenres = u.favoriteGenres
        avatarUrl = u.avatarUrl
        bannerUrl = u.bannerUrl
        customTitleBadge = u.customTitleBadge
        pageBackgroundType = u.pageBackgroundType
        pageBackgroundValue = u.pageBackgroundValue
        cardStyle = u.cardStyle
        cardOpacity = Double(u.cardOpacity)
        didLoadInitialForm = true
    }

    // MARK: - Aperçu Temps Réel du Profil avec Bannière & Barre d'XP

    private var profileHeaderCard: some View {
        let user = social.currentUser
        let xp = user?.xpPoints ?? 120
        let levelProgress = Double(xp % 120) / 120.0

        return VStack(spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                SocialMeshHeaderBackground()
                    .frame(height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        HStack {
                            Spacer()
                            LivriaSocialBrandLogoView(compact: true)
                                .padding(12)
                        },
                        alignment: .topTrailing
                    )

                HStack(spacing: 14) {
                    SocialAvatarRingView(
                        name: displayName.isEmpty ? (user?.displayName ?? "Lecteur") : displayName,
                        avatarUrl: avatarUrl,
                        level: user?.level ?? 1,
                        accentHex: accentColor,
                        size: 74
                    )
                    .background(Circle().fill(LivriaSocialPalette.background).padding(-3))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(displayName.isEmpty ? (user?.displayName ?? "Lecteur Livria") : displayName)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(LivriaSocialPalette.gold)
                                .font(.caption)
                        }

                        Text(user?.handle ?? "@lecteur")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.goldSoft)

                        if !customTitleBadge.isEmpty {
                            Text(customTitleBadge)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: accentColor).opacity(0.32)))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .offset(y: 26)
            }
            .padding(.bottom, 22)

            if !motto.isEmpty {
                Text("« \(motto) »")
                    .font(.system(size: 13.5, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 13))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Barre de progression XP vers le niveau suivant
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Label("Niveau \(user?.level ?? 1)", systemImage: "bolt.fill")
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(LivriaSocialPalette.gold)
                    Spacer()
                    Text("\(xp % 120) / 120 XP avant le Niv. \((user?.level ?? 1) + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                            .frame(height: 8)
                        Capsule()
                            .fill(LivriaSocialPalette.brandGradient)
                            .frame(width: max(20, geo.size.width * max(0.12, levelProgress)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))

            HStack(spacing: 10) {
                profileStatBox(label: "Points XP", value: "\(xp) XP", icon: "bolt.fill", color: LivriaSocialPalette.accent)
                profileStatBox(label: "Publications", value: "\(myPublishedPosts.count)", icon: "text.bubble.fill", color: LivriaSocialPalette.coral)
                profileStatBox(label: "Cagnotte", value: String(format: "%.2f €", user?.affiliateBalanceEur ?? 0), icon: "eurosign.circle.fill", color: LivriaSocialPalette.emerald)
                profileStatBox(label: "Mes Listes", value: "\(social.myLists.count)", icon: "books.vertical.fill", color: LivriaSocialPalette.gold)
            }
        }
        .padding(16)
        .socialCard(opacity: cardOpacity / 100.0)
    }

    // MARK: - Mes Publications sur Mon Profil

    private var myPostsSectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("MES PUBLICATIONS (\(myPublishedPosts.count))", systemImage: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.gold)
                Spacer()
                Button {
                    social.isShowingCreatePostSheet = true
                } label: {
                    Label("Publier", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if myPublishedPosts.isEmpty {
                VStack(spacing: 8) {
                    Text("Vous n'avez pas encore publié de contenu.")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Partagez un livre coup de cœur, une photo ou une vidéo pour animer votre profil (+15 XP) !")
                        .font(.system(size: 12))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                VStack(spacing: 12) {
                    ForEach(myPublishedPosts) { post in
                        ProfileFeedPostCardView(post: post)
                    }
                }
            }
        }
        .padding(15)
        .socialCard(opacity: cardOpacity / 100.0)
    }

    private func profileStatBox(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(LivriaSocialPalette.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.28), lineWidth: 1))
    }

    // MARK: - Mon Compte Livria

    private var vipleLiveIdAccountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("MON COMPTE LIVRIA", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.accent)
                Spacer()
                Text(social.isAuthenticated ? "Connecté ✓" : "Session Invité")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill((social.isAuthenticated ? LivriaSocialPalette.emerald : LivriaSocialPalette.gold).opacity(0.18)))
                    .foregroundStyle(social.isAuthenticated ? LivriaSocialPalette.emerald : LivriaSocialPalette.gold)
            }

            Text(social.isAuthenticated
                 ? "Connecté avec \(social.currentUser?.email ?? ""). Votre cagnotte et vos listes de lecture sont reliées à votre espace Livria Store."
                 : "Connectez-vous avec votre compte Livria pour retrouver vos listes rémunérées, vos amis et votre cagnotte.")
                .font(.system(size: 12.5))
                .foregroundStyle(LivriaSocialPalette.textMuted)

            HStack(spacing: 10) {
                Button {
                    social.isShowingAuthSheet = true
                } label: {
                    Label(social.isAuthenticated ? "Changer de compte" : "Se connecter / Créer un compte", systemImage: "person.fill.checkmark")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                }

                if social.isAuthenticated {
                    Button(role: .destructive) {
                        social.signOut()
                    } label: {
                        Text("Se déconnecter")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.vertical, 4)

            Button {
                social.isShowingTermsReviewSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(LivriaSocialPalette.gold)
                    Text("Conditions Générales d'Utilisation (Livria & Viple Live ID)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)

            if social.isAuthenticated {
                Button(role: .destructive) {
                    showingDeleteAccountConfirmation = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(Color(hex: "#FCA5A5"))
                        Text("Supprimer mon compte Viple Live ID")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(Color(hex: "#FCA5A5"))
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "#FCA5A5"))
                    }
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.45), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(15)
        .socialCard(opacity: cardOpacity / 100.0)
    }

    // MARK: - Studio d'Arrière-Plan & Apparence (12 thèmes + Image Perso)

    private var backgroundStudioCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("🎨 STUDIO D'ARRIÈRE-PLAN & THÈME")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LivriaSocialPalette.gold)

            HStack(spacing: 8) {
                Button {
                    withAnimation { pageBackgroundType = "preset" }
                } label: {
                    Label("Thèmes Dégradés", systemImage: "paintpalette.fill")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(pageBackgroundType == "preset" ? AnyShapeStyle(LivriaSocialPalette.brandGradient) : AnyShapeStyle(Color.white.opacity(0.06)))
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { pageBackgroundType = "image" }
                } label: {
                    Label("Image Perso", systemImage: "photo.fill")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(pageBackgroundType == "image" ? AnyShapeStyle(LivriaSocialPalette.brandGradient) : AnyShapeStyle(Color.white.opacity(0.06)))
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if pageBackgroundType == "preset" {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(social.backgroundPresets) { preset in
                        let isSelected = pageBackgroundValue == preset.key
                        Button {
                            withAnimation {
                                pageBackgroundValue = preset.key
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(LivriaSocialPalette.presetGradient(for: preset.key))
                                    .frame(width: 24, height: 24)
                                Text(preset.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(LivriaSocialPalette.gold)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(isSelected ? 0.14 : 0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? LivriaSocialPalette.gold : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                TextField("URL de votre image de fond (https://...)", text: $pageBackgroundValue)
                    .textInputAutocapitalization(.never)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                    .foregroundStyle(.white)
            }

            // Couleur d'accentuation
            VStack(alignment: .leading, spacing: 8) {
                Text("Couleur d'accentuation du profil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    ForEach(accentChoices, id: \.self) { hex in
                        Button {
                            accentColor = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: accentColor == hex ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Opacité des cartes
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Opacité des cartes verre")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(cardOpacity)) %")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(LivriaSocialPalette.gold)
                }
                Slider(value: $cardOpacity, in: 45...100, step: 5)
                    .tint(LivriaSocialPalette.primary)
            }
        }
        .padding(16)
        .socialCard(opacity: cardOpacity / 100.0)
    }

    // MARK: - Éditeur d'Identité, Bio & Sauvegarde

    private var identityEditorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✏️ IDENTITÉ LITTÉRAIRE")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LivriaSocialPalette.accent)

            customField("Nom affiché", text: $displayName)
            customField("Badge / Titre (ex: ✨ Critique Passionné)", text: $customTitleBadge)
            customField("Devise littéraire", text: $motto)
            customField("Biographie", text: $bio)
            customField("Genres favoris (ex: Polar, SF, Fantasy)", text: $favoriteGenres)
            customField("URL de l'avatar (optionnel)", text: $avatarUrl)

            Button {
                Task {
                    await social.saveProfileCustomization(
                        displayName: displayName,
                        motto: motto,
                        bio: bio,
                        accentColor: accentColor,
                        favoriteGenres: favoriteGenres,
                        avatarUrl: avatarUrl,
                        pageBackgroundType: pageBackgroundType,
                        pageBackgroundValue: pageBackgroundValue,
                        cardStyle: cardStyle,
                        cardOpacity: Int(cardOpacity),
                        bannerUrl: bannerUrl,
                        customTitleBadge: customTitleBadge
                    )
                }
            } label: {
                Label("Enregistrer mon profil & mon thème", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .socialCard(opacity: cardOpacity / 100.0)
    }

    private func customField(_ placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LivriaSocialPalette.textMuted)
            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Vue Publique du Profil Personnalisé d'un Membre (Identité, Publications, Listes & Livres)

public struct MemberPublicProfileView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    public let memberId: Int
    public let initialSummary: SocialMemberSummary?

    @State private var detail: SocialMemberPublicProfileResponse? = nil
    @State private var isLoading: Bool = true
    @State private var selectedSection: Int = 0 // 0 = Publications, 1 = Listes & Livres

    public init(memberId: Int, initialSummary: SocialMemberSummary? = nil) {
        self.memberId = memberId
        self.initialSummary = initialSummary
    }

    private var memberPosts: [SocialFeedPost] {
        let fromDetail = detail?.posts ?? []
        if !fromDetail.isEmpty {
            return fromDetail
        }
        return social.posts.filter { $0.userId == memberId || $0.author.id == memberId }
    }

    private var memberLists: [SocialBookListModel] {
        let fromDetail = detail?.lists ?? []
        if !fromDetail.isEmpty {
            return fromDetail
        }
        return social.lists.filter { $0.userId == memberId || $0.creator.id == memberId }
    }

    public var body: some View {
        ScrollView {
            if isLoading && detail == nil && initialSummary == nil {
                ProgressView("Chargement de l'univers du lecteur...")
                    .tint(LivriaSocialPalette.primary)
                    .padding(.top, 48)
            } else {
                let displayName = detail?.member.displayName ?? initialSummary?.displayName ?? "Lecteur Livria"
                let avatarUrl = detail?.member.avatarUrl ?? initialSummary?.avatarUrl ?? ""
                let accentColor = detail?.member.accentColor ?? initialSummary?.accentColor ?? "#7c4dff"
                let handle = detail?.member.handle ?? initialSummary?.handle ?? "@lecteur"
                let level = detail?.member.level ?? initialSummary?.level ?? 1
                let xp = detail?.member.xpPoints ?? initialSummary?.xp ?? 100
                let badge = detail?.member.customTitleBadge ?? (initialSummary?.isLivriaPlus == true ? "👑 Membre Looby+" : "🌟 Explorateur")
                let motto = detail?.member.motto ?? initialSummary?.motto ?? ""
                let bio = detail?.member.bio ?? initialSummary?.bio ?? ""
                let cardOpacity = Double(detail?.member.cardOpacity ?? 88) / 100.0

                VStack(spacing: 16) {
                    // 1. Carte d'identité du membre
                    VStack(spacing: 12) {
                        SocialAvatarRingView(
                            name: displayName,
                            avatarUrl: avatarUrl,
                            level: level,
                            accentHex: accentColor,
                            size: 78
                        )

                        Text(displayName)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(handle) • Niveau \(level) (\(xp) XP)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.gold)

                        if !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color(hex: accentColor).opacity(0.35)))
                        }

                        if !motto.isEmpty {
                            Text("« \(motto) »")
                                .font(.system(size: 13, design: .serif))
                                .italic()
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }

                        if !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 13))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .multilineTextAlignment(.center)
                        }

                        // Statistiques du profil
                        HStack(spacing: 10) {
                            memberStatPill(value: "\(memberPosts.count)", label: "Posts", icon: "text.bubble.fill")
                            memberStatPill(value: "\(memberLists.count)", label: "Listes", icon: "books.vertical.fill")
                            memberStatPill(value: "\(detail?.booksReadCount ?? 0)", label: "Lus", icon: "book.closed.fill")
                            memberStatPill(value: "\(xp)", label: "XP", icon: "bolt.fill")
                        }
                        .padding(.top, 4)

                        NavigationLink {
                            ConversationThreadView(
                                otherUserId: memberId,
                                otherDisplayName: displayName,
                                otherHandle: handle,
                                otherAvatarUrl: avatarUrl,
                                otherAccentColor: accentColor
                            )
                        } label: {
                            Label("Envoyer un message privé", systemImage: "paperplane.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                        }
                        .padding(.top, 2)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .socialCard(opacity: cardOpacity)

                    // 2. Sélecteur de section : Publications du profil | Listes & Lectures
                    SocialSegmentedPillBar(
                        items: [
                            (0, "Publications (\(memberPosts.count))", "sparkles.rectangle.stack.fill"),
                            (1, "Listes (\(memberLists.count))", "books.vertical.fill")
                        ],
                        selection: $selectedSection
                    )

                    if selectedSection == 0 {
                        // Publications (Posts) du profil en question
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("PUBLICATIONS DE \(displayName.uppercased())", systemImage: "text.bubble.fill")
                                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                                    .foregroundStyle(LivriaSocialPalette.gold)
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .tint(LivriaSocialPalette.gold)
                                        .scaleEffect(0.8)
                                }
                            }

                            if memberPosts.isEmpty && !isLoading {
                                VStack(spacing: 10) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 36))
                                        .foregroundStyle(LivriaSocialPalette.gold)
                                    Text("\(displayName) n'a pas encore publié de post")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("Les recommandations de livres, photos et vidéos de ce lecteur s'afficheront ici dès leur publication.")
                                        .font(.system(size: 12.5))
                                        .foregroundStyle(LivriaSocialPalette.textMuted)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 22)
                                .socialCard(opacity: cardOpacity)
                            } else {
                                ForEach(memberPosts) { post in
                                    ProfileFeedPostCardView(
                                        post: post,
                                        onChanged: {
                                            Task {
                                                detail = await social.fetchMemberProfile(memberId: memberId)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    } else {
                        // Listes de lecture & Livres lus du membre
                        VStack(alignment: .leading, spacing: 14) {
                            if !memberLists.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("📚 LISTES DE LECTURE DE \(displayName.uppercased())")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(LivriaSocialPalette.gold)

                                    ForEach(memberLists) { list in
                                        HStack {
                                            Text(list.themeEmoji)
                                                .font(.system(size: 22))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(list.title)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(.white)
                                                Text("\(list.booksCount) livres recommandés")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                                            }
                                            Spacer()
                                            if let url = URL(string: list.shareUrl) {
                                                Link("Voir", destination: url)
                                                    .font(.system(size: 12, weight: .black))
                                                    .foregroundStyle(LivriaSocialPalette.accent)
                                            }
                                        }
                                        .padding(10)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                                    }
                                }
                                .padding(14)
                                .socialCard(opacity: cardOpacity)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "books.vertical")
                                        .font(.system(size: 32))
                                        .foregroundStyle(LivriaSocialPalette.gold)
                                    Text("Aucune liste publique créée pour le moment")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(20)
                                .socialCard(opacity: cardOpacity)
                            }

                            if let readBooks = detail?.readBooks, !readBooks.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("📖 BIBLIOTHÈQUE DE \(displayName.uppercased())")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(LivriaSocialPalette.gold)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(readBooks) { book in
                                                Button {
                                                    LivriaSocialBookLinkOpener.openBook(bookId: book.id, storeUrl: book.storeUrl)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 5) {
                                                        SocialBookCoverView(
                                                            coverUrl: book.coverUrl,
                                                            title: book.title,
                                                            width: 78,
                                                            height: 114
                                                        )
                                                        Text(book.title)
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundStyle(.white)
                                                            .lineLimit(1)
                                                            .frame(width: 78, alignment: .leading)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .padding(14)
                                .socialCard(opacity: cardOpacity)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .socialCustomBackground(
            type: detail?.member.pageBackgroundType,
            value: detail?.member.pageBackgroundValue
        )
        .navigationTitle(detail?.member.displayName ?? initialSummary?.displayName ?? "Profil Lecteur")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            detail = await social.fetchMemberProfile(memberId: memberId)
            isLoading = false
        }
        .refreshable {
            detail = await social.fetchMemberProfile(memberId: memberId)
        }
    }

    private func memberStatPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LivriaSocialPalette.gold)
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(LivriaSocialPalette.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
    }
}

// MARK: - Carte d'une Publication Affichée dans un Profil (Texte, Photo, Vidéo, Livre Livria, Réactions & Commentaires)

private struct ProfileFeedPostCardView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    let post: SocialFeedPost
    var onChanged: (() -> Void)? = nil

    @State private var commentDraft: String = ""
    @State private var isExpandedComments: Bool = false
    @State private var isEditingPost: Bool = false
    @State private var showingDeleteConfirm: Bool = false

    private var isMyPost: Bool {
        guard let uid = social.currentUser?.id else { return false }
        return post.userId == uid || post.author.id == uid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SocialAvatarRingView(
                    avatarUrl: post.author.avatarUrl,
                    displayName: post.author.displayName,
                    level: post.author.level,
                    accentHex: post.author.accentColor,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(post.author.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        if post.author.isLivriaPlus {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(LivriaSocialPalette.gold)
                        }
                    }
                    Text(post.createdAt)
                        .font(.system(size: 11))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                }

                Spacer()

                Text(post.moodBadge)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(LivriaSocialPalette.primary.opacity(0.25)))
                    .foregroundStyle(.white)

                if isMyPost {
                    Menu {
                        Button {
                            isEditingPost = true
                        } label: {
                            Label("Modifier la publication", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Supprimer la publication", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                            .padding(.leading, 2)
                    }
                }
            }

            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 14.5))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineSpacing(3)
            }

            if !post.mediaUrl.isEmpty, let mediaURL = URL(string: post.mediaUrl.hasPrefix("http") ? post.mediaUrl : "https://livriasocial.viplenetwork.com\(post.mediaUrl)") {
                let lowerUrl = post.mediaUrl.lowercased()
                let isVideoPost = post.mediaType == "video"
                    || post.postType == "video"
                    || lowerUrl.hasSuffix(".mp4")
                    || lowerUrl.hasSuffix(".mov")
                    || lowerUrl.hasSuffix(".m4v")

                if isVideoPost {
                    VideoPlayer(player: AVPlayer(url: mediaURL))
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    AsyncImage(url: mediaURL) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }

            if let book = post.recommendedBook {
                HStack(spacing: 12) {
                    SocialBookCoverView(coverUrl: book.coverUrl, title: book.title, width: 60, height: 88)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("📖 Livre recommandé sur Livria Store")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.gold)
                        Text(book.title)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text("par \(book.author)")
                            .font(.system(size: 11.5))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                        Text(String(format: "%.2f € • %@", book.price, book.availabilityBadge))
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundStyle(LivriaSocialPalette.gold)
                    }
                    Spacer()
                    Button {
                        LivriaSocialBookLinkOpener.openBook(bookId: book.id, storeUrl: book.storeUrl)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Voir")
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 12).fill(LivriaSocialPalette.primary))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
                .contentShape(Rectangle())
                .onTapGesture {
                    LivriaSocialBookLinkOpener.openBook(bookId: book.id, storeUrl: book.storeUrl)
                }
            }

            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 8) {
                reactionButton(emoji: "❤️", count: post.likesCount, type: "like")
                reactionButton(emoji: "🔥", count: post.fireCount, type: "fire")
                reactionButton(emoji: "📖", count: post.bookLoveCount, type: "book")
                reactionButton(emoji: "👏", count: post.clapCount, type: "clap")

                Spacer()

                Button {
                    isExpandedComments.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .symbolRenderingMode(.monochrome)
                        Text("\(post.comments.count)")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if isExpandedComments || !post.comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments.suffix(4)) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(comment.authorName.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(LivriaSocialPalette.colorFromHex(comment.authorAccent)))

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(comment.createdAt)
                                        .font(.system(size: 10))
                                        .foregroundStyle(LivriaSocialPalette.textMuted)
                                }
                                Text(comment.content)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    }

                    HStack(spacing: 8) {
                        TextField("Ajouter un commentaire (+5 XP)...", text: $commentDraft)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

                        Button {
                            let text = commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            commentDraft = ""
                            Task {
                                await social.addComment(postId: post.id, content: text)
                                onChanged?()
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .symbolRenderingMode(.monochrome)
                                .font(.system(size: 12.5, weight: .bold))
                                .padding(8)
                                .background(Circle().fill(LivriaSocialPalette.primary))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LivriaSocialPalette.border, lineWidth: 1)
                )
        )
        .sheet(isPresented: $isEditingPost) {
            EditPostSheetView(post: post, onCompleted: onChanged)
                .environmentObject(social)
        }
        .alert("Supprimer cette publication ?", isPresented: $showingDeleteConfirm) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await social.deletePost(postId: post.id)
                    onChanged?()
                }
            }
        } message: {
            Text("Cette publication ainsi que ses commentaires seront définitivement supprimés.")
        }
    }

    private func reactionButton(emoji: String, count: Int, type: String) -> some View {
        Button {
            Task {
                await social.reactToPost(postId: post.id, reactionType: type)
                onChanged?()
            }
        } label: {
            HStack(spacing: 4) {
                Text(emoji)
                Text("\(count)")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(LivriaSocialPalette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feuille d'Authentification Unifiée Viple Live ID

public struct SocialAuthSheetView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isRegisterMode: Bool = false
    @State private var email: String = ""
    @State private var displayName: String = ""
    @State private var password: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $isRegisterMode) {
                        Text("Connexion Viple Live ID").tag(false)
                        Text("Créer un compte").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Identifiants unifiés Livria Store & Social") {
                    TextField("Adresse e-mail", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    if isRegisterMode {
                        TextField("Votre pseudo de lecteur", text: $displayName)
                    }

                    SecureField("Mot de passe", text: $password)
                }

                if let err = social.authErrorMessage {
                    Section {
                        Text(err)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            if isRegisterMode {
                                await social.registerAccount(email: email, displayName: displayName, password: password)
                            } else {
                                await social.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if social.isLoading {
                                ProgressView()
                            } else {
                                Text(isRegisterMode ? "Créer mon compte Livria Social" : "Se connecter")
                                    .font(.system(size: 14, weight: .black))
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                }
            }
            .navigationTitle("Viple Live ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
