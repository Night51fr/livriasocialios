import SwiftUI
import PhotosUI
import AVKit
#if canImport(UIKit)
import UIKit
#endif

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
            .navigationTitle("Livria Social")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        social.isShowingCreatePostSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.bubble.fill")
                            Text("Publier")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                        .foregroundStyle(.white)
                    }

                    Button {
                        social.selectedTab = 4
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.gold)
                    }
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
                SocialSegmentedPillBar(
                    items: [
                        (0, "Membres (\(social.searchedMembers.count))", "person.2.fill"),
                        (1, "Livres Boutique", "book.closed.fill")
                    ],
                    selection: $searchScope
                )
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
                let lowerUrl = post.mediaUrl.lowercased()
                let isVideoPost = post.mediaType == "video"
                    || post.postType == "video"
                    || lowerUrl.hasSuffix(".mp4")
                    || lowerUrl.hasSuffix(".mov")
                    || lowerUrl.hasSuffix(".m4v")

                if isVideoPost {
                    VideoPlayer(player: AVPlayer(url: mediaURL))
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
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

// MARK: - Assistant de Publication Étape par Étape (Galerie Photo/Vidéo iPhone & Recherche Visuelle de Livres avec Couvertures)

public struct CreatePostSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var currentStep: Int = 1 // 1 = Format & Humeur, 2 = Média / Livre / Message, 3 = Aperçu & Publier
    @State private var postType: String = "book" // book, post, photo, video
    @State private var selectedMood: String = "✨ Coup de cœur"
    @State private var selectedBookId: Int = 0
    @State private var content: String = ""
    @State private var mediaUrl: String = ""

    // Importation Photo / Vidéo depuis la galerie de l'iPhone (PhotosUI)
    @State private var selectedMediaPickerItem: PhotosPickerItem? = nil
    @State private var localPhotoPreviewData: Data? = nil
    @State private var isUploadingMedia: Bool = false
    @State private var isPublishing: Bool = false

    private let postFormats: [(id: String, title: String, subtitle: String, icon: String, accent: Color)] = [
        ("book", "Recommander un Livre", "Présentez un ouvrage Livria avec sa couverture et son lien boutique", "book.closed.fill", LivriaSocialPalette.gold),
        ("photo", "Photo de lecture", "Importez une photo directement depuis la galerie de votre iPhone", "photo.on.rectangle.angled", LivriaSocialPalette.coral),
        ("video", "Vidéo / BookTok", "Importez une vidéo depuis la galerie de votre iPhone", "video.fill", LivriaSocialPalette.accent),
        ("post", "Message & Débat", "Partagez un avis, une citation ou lancez une discussion", "text.bubble.fill", LivriaSocialPalette.primary)
    ]

    private let moods = [
        "✨ Coup de cœur",
        "📖 Lecture en cours",
        "🔥 Pépite absolue",
        "☕ Moment lecture cosy",
        "🤔 Débat littéraire",
        "🎉 Pile à lire"
    ]

    public init() {}

    private var selectedBook: SocialBookItem? {
        social.booksCatalog.first(where: { $0.id == selectedBookId })
    }

    private var canProceedFromStep2: Bool {
        if isUploadingMedia { return false }
        let hasText = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if postType == "book" {
            return selectedBookId > 0 || hasText
        }
        if postType == "photo" || postType == "video" {
            return !mediaUrl.isEmpty || hasText
        }
        return hasText || selectedBookId > 0 || !mediaUrl.isEmpty
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepProgressHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if currentStep == 1 {
                            step1FormatAndMoodView
                        } else if currentStep == 2 {
                            step2ContentMediaAndBookView
                        } else {
                            step3PreviewAndConfirmView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }

                bottomStepNavigationBar
            }
            .socialCustomBackground(bgType: "preset", bgValue: "aurora")
            .navigationTitle("Publier (+15 XP)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedMediaPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await handlePickedGalleryMedia(item: newItem)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Barre de Progression Étape 1 -> 2 -> 3

    private var stepProgressHeader: some View {
        let steps: [(num: Int, title: String, icon: String)] = [
            (1, "Format", "sparkles"),
            (2, "Contenu", "plus.rectangle.on.rectangle"),
            (3, "Aperçu", "checkmark.seal.fill")
        ]

        return HStack(spacing: 8) {
            ForEach(steps, id: \.num) { step in
                let isCurrent = currentStep == step.num
                let isDone = currentStep > step.num
                Button {
                    if step.num < currentStep || (step.num == 2 && currentStep == 1) || (step.num == 3 && canProceedFromStep2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentStep = step.num
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    isCurrent
                                        ? AnyShapeStyle(LivriaSocialPalette.goldGradient)
                                        : (isDone ? AnyShapeStyle(LivriaSocialPalette.mint) : AnyShapeStyle(Color.white.opacity(0.14)))
                                )
                                .frame(width: 24, height: 24)
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.black)
                            } else {
                                Text("\(step.num)")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(isCurrent ? LivriaSocialPalette.ink : .white)
                            }
                        }

                        Text(step.title)
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundStyle(isCurrent ? .white : LivriaSocialPalette.textMuted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isCurrent ? Color.white.opacity(0.14) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isCurrent ? LivriaSocialPalette.gold.opacity(0.6) : Color.clear, lineWidth: 1.2)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Étape 1 : Choisir le Type de Publication & l'Humeur

    private var step1FormatAndMoodView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Étape 1 • Que souhaitez-vous partager ?")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Choisissez le format de votre publication pour guider la création.")
                    .font(.system(size: 13))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
            }

            VStack(spacing: 10) {
                ForEach(postFormats, id: \.id) { format in
                    let isSelected = postType == format.id
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            if postType != format.id {
                                postType = format.id
                                selectedMediaPickerItem = nil
                                localPhotoPreviewData = nil
                                mediaUrl = ""
                            }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(format.accent.opacity(0.22))
                                    .frame(width: 50, height: 50)
                                Image(systemName: format.icon)
                                    .font(.system(size: 21, weight: .bold))
                                    .foregroundStyle(format.accent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(format.title)
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(format.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(isSelected ? LivriaSocialPalette.gold : Color.white.opacity(0.28))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(isSelected ? 0.13 : 0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            isSelected ? LivriaSocialPalette.gold : LivriaSocialPalette.border,
                                            lineWidth: isSelected ? 2 : 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Quelle est votre humeur de lecture ?")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(moods, id: \.self) { mood in
                        let active = selectedMood == mood
                        Button {
                            selectedMood = mood
                        } label: {
                            Text(mood)
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            active
                                                ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                                : AnyShapeStyle(Color.white.opacity(0.07))
                                        )
                                )
                                .foregroundStyle(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(active ? Color.white.opacity(0.45) : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .socialCard(padding: 14)
        }
    }

    // MARK: - Étape 2 : Livre avec Couvertures, Photo/Vidéo Galerie iPhone & Message

    private var step2ContentMediaAndBookView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Étape 2 • Composez votre publication")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Ajoutez votre média ou livre Livria, puis écrivez votre message.")
                    .font(.system(size: 13))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
            }

            // 1. Sélection Photo ou Vidéo depuis la galerie de l'iPhone
            if postType == "photo" || postType == "video" {
                galleryMediaUploadCard
            }

            // 2. Sélection d'un Livre Livria avec recherche et couvertures (principal pour "book", optionnel pour les autres)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        postType == "book" ? "Livre Livria à recommander" : "Associer un livre Livria (optionnel)",
                        systemImage: "book.closed.fill"
                    )
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.gold)
                    Spacer()
                }

                SocialBookPickerButtonCard(
                    books: social.booksCatalog,
                    selectedBookId: $selectedBookId,
                    placeholderTitle: "Choisir un livre Livria",
                    placeholderSubtitle: "Ouvrir la recherche avec les couvertures des livres"
                )
            }
            .socialCard(padding: 14)

            // 3. Message écrit
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Votre message pour la communauté", systemImage: "square.and.pencil")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(content.count) car.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                }

                TextField(
                    "Partagez votre ressenti, une citation marquante ou pourquoi vous conseillez cette lecture...",
                    text: $content,
                    axis: .vertical
                )
                .lineLimit(5...10)
                .font(.system(size: 14.5))
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(LivriaSocialPalette.border, lineWidth: 1)
                        )
                )

                // Idées rapides pour inspirer l'utilisateur
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickPromptChip("Impossible de lâcher ce livre !")
                        quickPromptChip("Une plume incroyable du début à la fin ✨")
                        quickPromptChip("Qui d'autre l'a lu ? Vos avis ?")
                    }
                }
            }
            .socialCard(padding: 14)
        }
    }

    private var galleryMediaUploadCard: some View {
        let isVideo = (postType == "video")
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    isVideo ? "Vidéo depuis votre iPhone" : "Photo depuis votre iPhone",
                    systemImage: isVideo ? "video.badge.plus" : "photo.badge.plus"
                )
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LivriaSocialPalette.gold)

                Spacer()

                if isUploadingMedia {
                    HStack(spacing: 6) {
                        ProgressView().tint(LivriaSocialPalette.gold)
                        Text("Importation...")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.gold)
                    }
                } else if !mediaUrl.isEmpty {
                    Label("Prêt ✓", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(LivriaSocialPalette.mint)
                }
            }

            PhotosPicker(
                selection: $selectedMediaPickerItem,
                matching: isVideo ? .videos : .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LivriaSocialPalette.brandGradient)
                            .frame(width: 46, height: 46)
                        Image(systemName: isVideo ? "film.stack.fill" : "photo.on.rectangle.angled")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaUrl.isEmpty
                             ? (isVideo ? "Choisir une vidéo dans la galerie iPhone" : "Choisir une photo dans la galerie iPhone")
                             : (isVideo ? "Changer la vidéo sélectionnée" : "Changer la photo sélectionnée"))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Importation directe depuis la photothèque de votre iPhone")
                            .font(.system(size: 11.5))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LivriaSocialPalette.gold)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(LivriaSocialPalette.border, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            // Aperçu du média importé
            if !isVideo, let data = localPhotoPreviewData {
                #if canImport(UIKit)
                if let uiImage = UIImage(data: data) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 190)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Button(role: .destructive) {
                            selectedMediaPickerItem = nil
                            localPhotoPreviewData = nil
                            mediaUrl = ""
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                #endif
            } else if isVideo, !mediaUrl.isEmpty, let resolved = resolvedPreviewMediaURL {
                ZStack(alignment: .topTrailing) {
                    VideoPlayer(player: AVPlayer(url: resolved))
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button(role: .destructive) {
                        selectedMediaPickerItem = nil
                        mediaUrl = ""
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .socialCard(padding: 14)
    }

    private func quickPromptChip(_ text: String) -> some View {
        Button {
            if content.isEmpty {
                content = text
            } else {
                content += " \(text)"
            }
        } label: {
            Text("+ \(text)")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Étape 3 : Aperçu en Direct & Validation

    private var step3PreviewAndConfirmView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Étape 3 • Aperçu avant publication")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Voici exactement comment votre publication apparaîtra dans le fil Livria Social.")
                    .font(.system(size: 13))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
            }

            // Carte d'aperçu fidèle au fil d'actualité
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    SocialAvatarRingView(
                        avatarUrl: social.currentUser?.avatarUrl,
                        displayName: social.currentUser?.displayName ?? "Vous",
                        level: social.currentUser?.level ?? 1,
                        accentHex: social.currentUser?.accentColor ?? "#7c4dff",
                        size: 44
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(social.currentUser?.displayName ?? "Vous")
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(.white)
                        Text("À l'instant")
                            .font(.system(size: 11))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }

                    Spacer()

                    Text(selectedMood)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(LivriaSocialPalette.primary.opacity(0.28)))
                        .foregroundStyle(.white)
                }

                if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(content)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineSpacing(3)
                }

                if postType == "photo", let data = localPhotoPreviewData {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    #endif
                } else if postType == "video", let resolved = resolvedPreviewMediaURL {
                    VideoPlayer(player: AVPlayer(url: resolved))
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if let book = selectedBook {
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
                            Text(String(format: "%.2f € • %@", book.price, book.availabilityBadge))
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(LivriaSocialPalette.gold)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
                }
            }
            .socialCard(padding: 16)

            HStack(spacing: 10) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundStyle(LivriaSocialPalette.gold)
                Text("Publier ce contenu vous rapporte immédiatement +15 XP sur votre profil Livria Social !")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
        }
    }

    // MARK: - Barre de Navigation Inférieure (Précédent / Suivant / Publier)

    private var bottomStepNavigationBar: some View {
        HStack(spacing: 12) {
            if currentStep > 1 {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            if currentStep < 3 {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        currentStep += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentStep == 1 ? "Continuer vers le contenu" : "Voir l'aperçu")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        Capsule().fill(
                            (currentStep == 1 || canProceedFromStep2)
                                ? AnyShapeStyle(LivriaSocialPalette.goldGradient)
                                : AnyShapeStyle(Color.white.opacity(0.18))
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(currentStep == 2 && !canProceedFromStep2)
            } else {
                Button {
                    Task {
                        await publishPostNow()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isPublishing {
                            ProgressView().tint(LivriaSocialPalette.ink)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Publier maintenant (+15 XP)")
                        }
                    }
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                }
                .buttonStyle(.plain)
                .disabled(isPublishing || !canProceedFromStep2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(LivriaSocialPalette.cardSurface.opacity(0.96))
    }

    private var resolvedPreviewMediaURL: URL? {
        guard !mediaUrl.isEmpty else { return nil }
        if mediaUrl.hasPrefix("http") {
            return URL(string: mediaUrl)
        }
        return URL(string: "https://livriasocial.viplenetwork.com\(mediaUrl.hasPrefix("/") ? "" : "/")\(mediaUrl)")
    }

    private func handlePickedGalleryMedia(item: PhotosPickerItem) async {
        isUploadingMedia = true
        defer { isUploadingMedia = false }

        do {
            guard let rawData = try await item.loadTransferable(type: Data.self), !rawData.isEmpty else {
                social.showToast("Impossible de lire le fichier sélectionné dans votre galerie.")
                return
            }

            if postType == "video" {
                if let uploadedUrl = await social.uploadVideoData(rawData, fileExtension: "mp4") {
                    mediaUrl = uploadedUrl
                }
            } else {
                var uploadData = rawData
                #if canImport(UIKit)
                if let img = UIImage(data: rawData), let jpeg = img.jpegData(compressionQuality: 0.84) {
                    uploadData = jpeg
                }
                #endif
                localPhotoPreviewData = uploadData
                if let uploadedUrl = await social.uploadPhotoData(uploadData, fileExtension: "jpg") {
                    mediaUrl = uploadedUrl
                }
            }
        } catch {
            social.showToast("Erreur lors de l'importation depuis la galerie : \(error.localizedDescription)")
        }
    }

    private func publishPostNow() async {
        guard !isPublishing else { return }
        isPublishing = true
        defer { isPublishing = false }

        let ok = await social.createPost(
            postType: postType,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaUrl: mediaUrl,
            mediaType: postType == "photo" ? "image" : (postType == "video" ? "video" : "none"),
            bookId: selectedBookId > 0 ? selectedBookId : nil,
            moodBadge: selectedMood
        )
        if ok {
            dismiss()
        }
    }
}
