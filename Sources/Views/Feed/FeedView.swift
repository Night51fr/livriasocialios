import SwiftUI

// MARK: - Fil d'Actualité « Livria (social) » (Posts, Photos, Vidéos, Livres recommandés, Listes & Recherche Livres/Membres)

public struct FeedView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var searchText: String = ""
    @State private var searchScope: Int = 0 // 0 = Membres, 1 = Livres
    @State private var isSearching: Bool = false
    @State private var selectedMemberForProfile: SocialMemberSummary? = nil
    @State private var commentDrafts: [Int: String] = [:]
    @State private var expandedCommentsPostIds: Set<Int> = []

    private let filters: [(id: String, label: String, icon: String)] = [
        ("all", "🌈 Tout le fil", "sparkles"),
        ("books", "📖 Livres", "book.fill"),
        ("lists", "🗂️ Listes (€)", "list.bullet.rectangle.portrait.fill"),
        ("media", "📸 Photos & Vidéos", "photo.on.rectangle.angled")
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    socialHeroBanner
                    omniboxSearchCard
                    if isSearching && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        omniboxSearchResultsSection
                    }
                    topMembersCarousel
                    composerQuickBar
                    filterChipsBar
                    feedPostsStack
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .socialCustomBackground(
                bgType: social.currentUser?.pageBackgroundType ?? "preset",
                bgValue: social.currentUser?.pageBackgroundValue ?? "aurora"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Livria")
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [LivriaSocialPalette.primary, LivriaSocialPalette.coral],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("(social)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(LivriaSocialPalette.coral)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        social.isShowingCreatePostSheet = true
                    } label: {
                        Image(systemName: "plus.bubble.fill")
                            .symbolRenderingMode(.monochrome)
                    }
                    .tint(LivriaSocialPalette.primary)

                    Button {
                        social.selectedTab = 2
                    } label: {
                        if social.unreadMessagesCount > 0 {
                            Text("\(Image(systemName: "paperplane.fill")) \(social.unreadMessagesCount)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        } else {
                            Image(systemName: "paperplane.fill")
                                .symbolRenderingMode(.monochrome)
                        }
                    }
                    .tint(LivriaSocialPalette.primary)
                }
            }
            .refreshable {
                await social.refreshBootstrap()
            }
            .navigationDestination(item: $selectedMemberForProfile) { member in
                MemberPublicProfileView(memberId: member.id, initialSummary: member)
            }
        }
    }

    // MARK: - En-tête Coloré & Gamifié Livria (social)

    private var socialHeroBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SocialAvatarRingView(
                    avatarUrl: social.currentUser?.avatarUrl,
                    displayName: social.currentUser?.displayName ?? "Lecteur",
                    level: social.currentUser?.level ?? 1,
                    accentHex: social.currentUser?.accentColor ?? "#7c4dff",
                    size: 62
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(social.currentUser?.displayName ?? "Communauté Livria")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(social.currentUser?.customTitleBadge ?? "🌟 Explorateur")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.22)))
                            .foregroundStyle(.white)
                    }

                    Text("Partagez vos lectures, créez des listes rémunérées (0,50 € à 1,00 €/achat) & jouez pour gagner des XP !")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        Label("\(social.currentUser?.xp ?? 0) XP", systemImage: "bolt.fill")
                        Label("\(social.currentUser?.loyaltyPoints ?? 0) pts", systemImage: "star.fill")
                        Label(String(format: "%.2f € Cagnotte", social.currentUser?.cashbackBalance ?? 0), systemImage: "eurosign.circle.fill")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(LivriaSocialPalette.goldSoft)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    social.isShowingCreatePostSheet = true
                } label: {
                    Label("Publier un post", systemImage: "sparkles")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.white))
                        .foregroundStyle(LivriaSocialPalette.primaryDeep)
                }
                .buttonStyle(.plain)

                Button {
                    social.isShowingCreateListSheet = true
                } label: {
                    Label("Créer une liste (€)", systemImage: "plus.rectangle.on.folder.fill")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(LivriaSocialPalette.gold))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            SocialMeshHeaderBackground()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .shadow(color: LivriaSocialPalette.primary.opacity(0.26), radius: 14, x: 0, y: 6)
    }

    // MARK: - Recherche Double : 👥 Membres Publics | 📚 Livres Boutique

    private var omniboxSearchCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LivriaSocialPalette.accent)
                TextField("Chercher un membre public ou un livre Livria...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.white)
                    .onChange(of: searchText) { _, newValue in
                        isSearching = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                        Task {
                            await social.searchMembers(query: newValue)
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        isSearching = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LivriaSocialPalette.border, lineWidth: 1))

            if isSearching {
                Picker("Section de recherche", selection: $searchScope) {
                    Text("👥 Membres (\(social.searchedMembers.count))").tag(0)
                    Text("📚 Livres Boutique").tag(1)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var omniboxSearchResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if searchScope == 0 {
                ForEach(social.searchedMembers) { member in
                    Button {
                        selectedMemberForProfile = member
                    } label: {
                        HStack(spacing: 12) {
                            SocialAvatarRingView(
                                avatarUrl: member.avatarUrl,
                                displayName: member.displayName,
                                level: member.level,
                                accentHex: member.accentColor,
                                size: 48
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(member.bio)
                                    .font(.system(size: 12))
                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("Voir profil →")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LivriaSocialPalette.gold)
                        }
                        .socialCard(padding: 12)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let matchingBooks = social.booksCatalog.filter {
                    q.isEmpty ||
                    $0.title.localizedCaseInsensitiveContains(q) ||
                    $0.author.localizedCaseInsensitiveContains(q) ||
                    $0.genre.localizedCaseInsensitiveContains(q)
                }.prefix(8)

                ForEach(Array(matchingBooks)) { book in
                    HStack(spacing: 12) {
                        SocialBookCoverView(coverUrl: book.coverUrl, title: book.title, width: 50, height: 74)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(book.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(book.author)
                                .font(.system(size: 12))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                            Text(String(format: "%.2f € • %@", book.price, book.availabilityBadge))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LivriaSocialPalette.gold)
                        }
                        Spacer()
                        if let url = URL(string: book.storeUrl) {
                            Link(destination: url) {
                                Text("Boutique ↗")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(LivriaSocialPalette.primary))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .socialCard(padding: 10)
                }
            }
        }
    }

    // MARK: - Carrousel des Membres Publics de la Communauté

    private var topMembersCarousel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Lecteurs à découvrir", systemImage: "person.3.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("Profils 100% personnalisés")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LivriaSocialPalette.gold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(social.topMembers) { member in
                        Button {
                            selectedMemberForProfile = member
                        } label: {
                            VStack(spacing: 6) {
                                SocialAvatarRingView(
                                    avatarUrl: member.avatarUrl,
                                    displayName: member.displayName,
                                    level: member.level,
                                    accentHex: member.accentColor,
                                    size: 56
                                )
                                Text(member.displayName)
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .frame(width: 78)
                                Text("\(member.xp) XP")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(LivriaSocialPalette.gold)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(LivriaSocialPalette.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Barre Rapide de Publication

    private var composerQuickBar: some View {
        Button {
            social.isShowingCreatePostSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LivriaSocialPalette.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Que lisez-vous en ce moment ?")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Post, photo, vidéo ou recommandation de livre avec lien direct vers la boutique (+15 XP)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(LivriaSocialPalette.gold)
            }
            .socialCard(padding: 13)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtres du Fil d'Actualité

    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.id) { item in
                    let isSelected = social.feedFilter == item.id
                    Button {
                        social.feedFilter = item.id
                        Task {
                            await social.refreshBootstrap(filter: item.id)
                        }
                    } label: {
                        Text(item.label)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    isSelected
                                        ? LivriaSocialPalette.primary
                                        : Color.white.opacity(0.09)
                                )
                            )
                            .foregroundStyle(.white)
                            .overlay(Capsule().stroke(LivriaSocialPalette.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Cartes du Fil d'Actualité

    private var feedPostsStack: some View {
        VStack(spacing: 16) {
            if social.posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 44))
                        .foregroundStyle(LivriaSocialPalette.gold)
                    Text("Aucune publication dans cette catégorie")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Soyez le premier à partager un coup de cœur, une photo ou une recommandation de livre (+15 XP) !")
                        .font(.system(size: 13))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        social.isShowingCreatePostSheet = true
                    } label: {
                        Text("Publier maintenant (+15 XP)")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(LivriaSocialPalette.primary))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .socialCard(padding: 24)
            } else {
                ForEach(social.posts) { post in
                    feedPostCard(post: post)
                }
            }
        }
    }

    private func feedPostCard(post: SocialFeedPost) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête Auteur
            HStack(spacing: 10) {
                Button {
                    selectedMemberForProfile = post.author
                } label: {
                    HStack(spacing: 10) {
                        SocialAvatarRingView(
                            avatarUrl: post.author.avatarUrl,
                            displayName: post.author.displayName,
                            level: post.author.level,
                            accentHex: post.author.accentColor,
                            size: 44
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Text(post.author.displayName)
                                    .font(.system(size: 14.5, weight: .bold))
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
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text(post.moodBadge)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(LivriaSocialPalette.primary.opacity(0.25)))
                    .foregroundStyle(.white)
            }

            // Contenu texte
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 14.5))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineSpacing(3)
            }

            // Média Photo / Vidéo éventuel
            if !post.mediaUrl.isEmpty, let mediaURL = URL(string: post.mediaUrl.hasPrefix("http") ? post.mediaUrl : "https://livriasocial.viplenetwork.com\(post.mediaUrl)") {
                AsyncImage(url: mediaURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }

            // Livre recommandé avec lien direct vers la boutique Livria Store
            if let book = post.recommendedBook {
                HStack(spacing: 12) {
                    SocialBookCoverView(coverUrl: book.coverUrl, title: book.title, width: 64, height: 94)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("📖 Livre recommandé sur Livria Store")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.gold)
                        Text(book.title)
                            .font(.system(size: 14.5, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text("par \(book.author)")
                            .font(.system(size: 12))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                        HStack(spacing: 8) {
                            Text(String(format: "%.2f €", book.price))
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(LivriaSocialPalette.gold)
                            Text(book.availabilityBadge)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(LivriaSocialPalette.coral.opacity(0.22)))
                                .foregroundStyle(LivriaSocialPalette.coral)
                        }
                    }
                    Spacer()
                    if let storeUrl = URL(string: book.storeUrl) {
                        Link(destination: storeUrl) {
                            VStack(spacing: 3) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Voir")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(LivriaSocialPalette.primary))
                            .foregroundStyle(.white)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
            }

            // Liste de livres partagée
            if let list = post.sharedList {
                HStack(spacing: 12) {
                    Text(list.themeEmoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Color.white.opacity(0.25)))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Liste rémunérée (0,50 € à 1,00 €/achat)")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.goldSoft)
                        Text(list.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        if !list.description.isEmpty {
                            Text(list.description)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Button {
                        social.selectedTab = 1
                    } label: {
                        Text("Explorer →")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.white))
                            .foregroundStyle(LivriaSocialPalette.primaryDeep)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(LivriaSocialPalette.socialHeroGradient))
            }

            Divider().overlay(Color.white.opacity(0.1))

            // Barre de Réactions Gamifiées
            HStack(spacing: 8) {
                reactionPill(emoji: "❤️", count: post.likesCount) {
                    Task { await social.reactToPost(postId: post.id, reactionType: "like") }
                }
                reactionPill(emoji: "🔥", count: post.fireCount) {
                    Task { await social.reactToPost(postId: post.id, reactionType: "fire") }
                }
                reactionPill(emoji: "📖", count: post.bookLoveCount) {
                    Task { await social.reactToPost(postId: post.id, reactionType: "book") }
                }
                reactionPill(emoji: "👏", count: post.clapCount) {
                    Task { await social.reactToPost(postId: post.id, reactionType: "clap") }
                }

                Spacer()

                Button {
                    if expandedCommentsPostIds.contains(post.id) {
                        expandedCommentsPostIds.remove(post.id)
                    } else {
                        expandedCommentsPostIds.insert(post.id)
                    }
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

            // Commentaires
            if expandedCommentsPostIds.contains(post.id) || !post.comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments.suffix(4)) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(comment.authorName.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(LivriaSocialPalette.colorFromHex(comment.authorAccent)))

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(comment.createdAt)
                                        .font(.system(size: 10))
                                        .foregroundStyle(LivriaSocialPalette.textMuted)
                                }
                                Text(comment.content)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    }

                    HStack(spacing: 8) {
                        TextField(
                            "Ajouter un commentaire (+5 XP)...",
                            text: Binding(
                                get: { commentDrafts[post.id] ?? "" },
                                set: { commentDrafts[post.id] = $0 }
                            )
                        )
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

                        Button {
                            let text = (commentDrafts[post.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            commentDrafts[post.id] = ""
                            Task {
                                await social.addComment(postId: post.id, content: text)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .symbolRenderingMode(.monochrome)
                                .font(.system(size: 13, weight: .bold))
                                .padding(8)
                                .background(Circle().fill(LivriaSocialPalette.primary))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .socialCard(padding: 15)
    }

    private func reactionPill(emoji: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(LivriaSocialPalette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feuille de Création de Publication (Post, Photo, Vidéo, Livre de la Boutique)

public struct CreatePostSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var postType: String = "book"
    @State private var content: String = ""
    @State private var mediaUrl: String = ""
    @State private var selectedBookId: Int = 0
    @State private var selectedMood: String = "✨ Coup de cœur"

    private let moods = [
        "✨ Coup de cœur",
        "📖 Lecture en cours",
        "🔥 Pépite absolue",
        "☕ Moment lecture cosy",
        "🤔 Débat littéraire",
        "🎉 Pile à lire"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Type de publication (+15 XP)") {
                    Picker("Format", selection: $postType) {
                        Text("📖 Recommander un Livre").tag("book")
                        Text("💬 Post Texte").tag("post")
                        Text("📸 Photo / Image").tag("photo")
                        Text("🎬 Vidéo").tag("video")
                    }
                    .pickerStyle(.segmented)

                    Picker("Humeur / Badge", selection: $selectedMood) {
                        ForEach(moods, id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                }

                if postType == "book" {
                    Section("Livre de la boutique Livria à recommander") {
                        Picker("Choisir un livre", selection: $selectedBookId) {
                            Text("Sélectionner un ouvrage...").tag(0)
                            ForEach(social.booksCatalog) { book in
                                Text("\(book.title) — \(book.author) (\(String(format: "%.2f €", book.price)))")
                                    .tag(book.id)
                            }
                        }
                    }
                }

                if postType == "photo" || postType == "video" {
                    Section(postType == "photo" ? "URL de la photo" : "URL de la vidéo") {
                        TextField("https://...", text: $mediaUrl)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Votre message pour la communauté") {
                    TextEditor(text: $content)
                        .frame(minHeight: 110)
                }
            }
            .navigationTitle("Nouvelle publication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Publier") {
                        Task {
                            let ok = await social.createPost(
                                postType: postType,
                                content: content,
                                mediaUrl: mediaUrl,
                                mediaType: postType == "photo" ? "image" : (postType == "video" ? "video" : "none"),
                                bookId: selectedBookId > 0 ? selectedBookId : nil,
                                moodBadge: selectedMood
                            )
                            if ok { dismiss() }
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedBookId == 0)
                }
            }
        }
    }
}
