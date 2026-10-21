import SwiftUI

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

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeaderCard

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
                profileStatBox(label: "Cagnotte", value: String(format: "%.2f €", user?.affiliateBalanceEur ?? 0), icon: "eurosign.circle.fill", color: LivriaSocialPalette.emerald)
                profileStatBox(label: "Mes Listes", value: "\(social.myLists.count)", icon: "books.vertical.fill", color: LivriaSocialPalette.gold)
            }
        }
        .padding(16)
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

// MARK: - Vue Publique du Profil Personnalisé d'un Membre

public struct MemberPublicProfileView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    public let memberId: Int
    public let initialSummary: SocialMemberSummary?

    @State private var detail: SocialMemberPublicProfileResponse? = nil
    @State private var isLoading: Bool = true

    public init(memberId: Int, initialSummary: SocialMemberSummary? = nil) {
        self.memberId = memberId
        self.initialSummary = initialSummary
    }

    public var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Chargement de l'univers du lecteur...")
                    .tint(LivriaSocialPalette.primary)
                    .padding(.top, 48)
            } else if let member = detail?.member {
                VStack(spacing: 16) {
                    // Carte d'identité du membre
                    VStack(spacing: 12) {
                        SocialAvatarRingView(
                            name: member.displayName,
                            avatarUrl: member.avatarUrl,
                            accentHex: member.accentColor,
                            size: 76
                        )

                        Text(member.displayName)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(member.handle) • Niveau \(member.level) (\(member.xpPoints) XP)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.gold)

                        if !member.customTitleBadge.isEmpty {
                            Text(member.customTitleBadge)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color(hex: member.accentColor).opacity(0.35)))
                        }

                        if !member.motto.isEmpty {
                            Text("« \(member.motto) »")
                                .font(.system(size: 13, design: .serif))
                                .italic()
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        if !member.bio.isEmpty {
                            Text(member.bio)
                                .font(.system(size: 13))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .multilineTextAlignment(.center)
                        }

                        NavigationLink {
                            ConversationThreadView(
                                otherUserId: member.id,
                                otherDisplayName: member.displayName,
                                otherHandle: member.handle,
                                otherAvatarUrl: member.avatarUrl,
                                otherAccentColor: member.accentColor
                            )
                        } label: {
                            Label("Envoyer un message privé", systemImage: "paperplane.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .socialCard(opacity: Double(member.cardOpacity) / 100.0)

                    // Listes du membre
                    if let lists = detail?.lists, !lists.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("📚 LISTES DE LECTURE DE \(member.displayName.uppercased())")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LivriaSocialPalette.gold)

                            ForEach(lists) { list in
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
                        .socialCard(opacity: Double(member.cardOpacity) / 100.0)
                    }
                }
                .padding(16)
            }
        }
        .socialCustomBackground(
            type: detail?.member.pageBackgroundType,
            value: detail?.member.pageBackgroundValue
        )
        .navigationTitle(detail?.member.displayName ?? "Profil Lecteur")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            detail = await social.fetchMemberProfile(memberId: memberId)
            isLoading = false
        }
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
