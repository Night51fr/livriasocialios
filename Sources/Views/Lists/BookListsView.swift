import SwiftUI

// MARK: - Onglet 2 : Listes de Livres Rémunérées (0,50 € à 1,00 € par achat généré sur Livria Store)

public struct BookListsView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @State private var selectedSegment: Int = 0 // 0 = Toutes les listes, 1 = Mes listes rémunérées
    @State private var selectedListForAddBook: SocialBookListModel? = nil

    public init() {}

    private var displayedLists: [SocialBookListModel] {
        selectedSegment == 0 ? social.lists : social.myLists
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    remunerationHeroBanner

                    SocialSegmentedPillBar(
                        items: [
                            (0, "Toutes les listes (\(social.lists.count))", "sparkles"),
                            (1, "Mes listes (\(social.myLists.count))", "folder.fill.badge.person.crop")
                        ],
                        selection: $selectedSegment
                    )

                    if displayedLists.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "books.vertical.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(LivriaSocialPalette.gold)
                            Text(selectedSegment == 0 ? "Aucune liste publique pour le moment" : "Vous n'avez pas encore créé de liste")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Créez une sélection thématique de livres Livria Store et percevez entre 0,50 € et 1,00 € sur chaque achat généré via votre lien !")
                                .font(.system(size: 13))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .multilineTextAlignment(.center)
                            Button {
                                social.isShowingCreateListSheet = true
                            } label: {
                                Label("Créer ma 1re liste rémunérée (+25 XP)", systemImage: "plus.circle.fill")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(LivriaSocialPalette.ink)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 11)
                                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .socialCard()
                    } else {
                        ForEach(displayedLists) { list in
                            BookListCardView(
                                list: list,
                                isMine: list.userId == social.currentUser?.id,
                                onAddBook: {
                                    selectedListForAddBook = list
                                },
                                onShareInFeed: {
                                    Task {
                                        _ = await social.createPost(
                                            postType: "list_share",
                                            content: "Découvrez ma sélection « \(list.title) » (\(list.booksCount) livres) sur Livria !",
                                            bookListId: list.id,
                                            moodBadge: "\(list.themeEmoji) Liste recommandée"
                                        )
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await social.deleteBookList(listId: list.id)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .socialCustomBackground(
                type: social.currentUser?.pageBackgroundType,
                value: social.currentUser?.pageBackgroundValue
            )
            .navigationTitle("Listes Rémunérées")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        social.isShowingCreateListSheet = true
                    } label: {
                        Text("\(Image(systemName: "plus.circle.fill")) Créer")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .tint(LivriaSocialPalette.gold)
                }
            }
            .refreshable {
                await social.refreshBootstrap()
            }
            .sheet(item: $selectedListForAddBook) { list in
                AddBookToListSheetView(list: list)
                    .environmentObject(social)
            }
        }
    }

    private var remunerationHeroBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("💸 PROGRAMME PARTENAIRE LIVRIA")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))

                Spacer()

                if let user = social.currentUser {
                    Text(String(format: "Cagnotte : %.2f €", user.affiliateBalanceEur))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LivriaSocialPalette.emerald)
                }
            }

            Text("Gagnez 0,50 € à 1,00 € par livre commandé")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Composez vos listes de lecture à partir du catalogue officiel Livria Store. Chaque commande passée depuis votre liste crédite automatiquement votre cagnotte Viple Live ID.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.84))

            HStack(spacing: 10) {
                Button {
                    social.isShowingCreateListSheet = true
                } label: {
                    Label("Nouvelle liste (+25 XP)", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                }

                Link(destination: URL(string: "https://my.livria.store/listes")!) {
                    Label("Portail my.livria.store", systemImage: "arrow.up.right.square")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1E1B4B"), Color(hex: "#311042"), Color(hex: "#0F172A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(LivriaSocialPalette.gold.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - Carte d'une Liste de Livres

private struct BookListCardView: View {
    let list: SocialBookListModel
    let isMine: Bool
    let onAddBook: () -> Void
    let onShareInFeed: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(list.themeEmoji)
                    .font(.system(size: 28))
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LivriaSocialPalette.brandGradient.opacity(0.35))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(list.title)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        if list.isMonetized {
                            Text("0,50€–1€ / achat")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(LivriaSocialPalette.emerald)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(LivriaSocialPalette.emerald.opacity(0.16)))
                        }
                    }

                    NavigationLink {
                        MemberPublicProfileView(memberId: list.creator.id, initialSummary: list.creator)
                    } label: {
                        Text("Par \(list.creatorName) (\(list.creatorHandle)) • \(list.booksCount) livres")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if isMine {
                    Menu {
                        Button {
                            onAddBook()
                        } label: {
                            Label("Ajouter un livre", systemImage: "plus.circle")
                        }
                        Button {
                            onShareInFeed()
                        } label: {
                            Label("Partager dans le fil", systemImage: "megaphone")
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Supprimer la liste", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }
                }
            }

            if !list.description.isEmpty {
                Text(list.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.88))
            }

            // Carrousel des livres de la liste
            if !list.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(list.items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                SocialBookCoverView(title: item.bookTitle, imageUrl: item.coverUrl, width: 84, height: 122)

                                Text(item.bookTitle)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .frame(width: 84, alignment: .leading)

                                Text(String(format: "%.2f €", item.priceTtc))
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(LivriaSocialPalette.gold)

                                Button {
                                    LivriaSocialBookLinkOpener.openBook(bookId: item.book.id, storeUrl: item.storeUrl)
                                } label: {
                                    Text("Acheter")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(.white)
                                        .frame(width: 84)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(LivriaSocialPalette.primary))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                LivriaSocialBookLinkOpener.openBook(bookId: item.book.id, storeUrl: item.storeUrl)
                            }
                        }
                    }
                }
            }

            Divider().overlay(Color.white.opacity(0.08))

            // Pied de carte : Statistiques & Actions
            HStack(spacing: 12) {
                Label("\(list.viewsCount) vues", systemImage: "eye.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LivriaSocialPalette.textMuted)

                Label(String(format: "%.2f € générés", list.estimatedEarningsEur), systemImage: "eurosign.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LivriaSocialPalette.emerald)

                Spacer()

                Button {
                    onAddBook()
                } label: {
                    Label("+ Livre", systemImage: "plus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }

                if let url = URL(string: list.shareUrl) {
                    ShareLink(item: url) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(LivriaSocialPalette.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                    }
                }
            }
        }
        .padding(15)
        .socialCard()
    }
}

// MARK: - Feuille de Création d'une Liste de Livres Rémunérée

public struct CreateBookListSheetView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var themeEmoji: String = "📚"
    @State private var curatorNote: String = "Incontournable de ma bibliothèque !"
    @State private var selectedBookIds: Set<Int> = []
    @State private var bookSearchQuery: String = ""

    private let emojis = ["📚", "🔥", "💜", "🐉", "🕵️", "🚀", "🌙", "☕", "🏆", "💎"]

    public init() {}

    private var filteredBooks: [SocialBookItem] {
        let q = bookSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return social.booksCatalog }
        return social.booksCatalog.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.author.localizedCaseInsensitiveContains(q)
                || $0.genre.localizedCaseInsensitiveContains(q)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Identité de votre liste rémunérée") {
                    TextField("Titre (ex: Mes Polars d'Hiver)", text: $title)
                    TextField("Description pour vos lecteurs...", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    themeEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 22))
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(themeEmoji == emoji ? LivriaSocialPalette.primary.opacity(0.3) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Note de recommandation") {
                    TextField("Pourquoi recommandez-vous ces livres ?", text: $curatorNote)
                }

                Section("Sélectionnez des livres Livria Store (\(selectedBookIds.count) choisis)") {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(LivriaSocialPalette.gold)
                        TextField("Rechercher un livre ou un auteur...", text: $bookSearchQuery)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !bookSearchQuery.isEmpty {
                            Button {
                                bookSearchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ForEach(filteredBooks) { book in
                        let isSelected = selectedBookIds.contains(book.id)
                        Button {
                            if isSelected {
                                selectedBookIds.remove(book.id)
                            } else {
                                selectedBookIds.insert(book.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                SocialBookCoverView(
                                    coverUrl: book.coverUrl,
                                    title: book.title,
                                    width: 46,
                                    height: 66,
                                    cornerRadius: 8
                                )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(book.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    Text("\(book.author) • \(String(format: "%.2f €", book.priceTtc))")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? LivriaSocialPalette.emerald : .secondary)
                                    .font(.system(size: 22))
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Créer une Liste (€)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer (+25 XP)") {
                        Task {
                            let ok = await social.createBookList(
                                title: title,
                                description: description,
                                themeEmoji: themeEmoji,
                                themeGradient: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                                bookIds: Array(selectedBookIds),
                                curatorNote: curatorNote
                            )
                            if ok { dismiss() }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Feuille d'Ajout d'un Livre à une Liste Existante

private struct AddBookToListSheetView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @Environment(\.dismiss) private var dismiss
    let list: SocialBookListModel

    @State private var selectedBookId: Int = 0
    @State private var note: String = "À lire absolument !"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Liste : \(list.themeEmoji) \(list.title)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Recherchez un livre avec sa couverture pour l'ajouter à votre liste rémunérée.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }

                    SocialBookPickerButtonCard(
                        books: social.booksCatalog,
                        selectedBookId: $selectedBookId,
                        placeholderTitle: "Choisir un livre Livria",
                        placeholderSubtitle: "Rechercher par titre ou auteur avec les couvertures"
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Votre avis sur ce livre")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        TextField("Pourquoi recommandez-vous ce livre ?", text: $note)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                            .foregroundStyle(.white)
                    }
                    .socialCard(padding: 14)
                }
                .padding(16)
            }
            .socialCustomBackground(bgType: "preset", bgValue: "aurora")
            .navigationTitle("Ajouter un livre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        guard selectedBookId > 0 else { return }
                        Task {
                            await social.addBookToList(listId: list.id, bookId: selectedBookId, note: note)
                            dismiss()
                        }
                    }
                    .disabled(selectedBookId == 0)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
