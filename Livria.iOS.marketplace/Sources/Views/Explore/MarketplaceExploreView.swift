import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Explorer Livria Marketplace (Priorité N°1 Livres > CD/DVD > Accessoires > Vêtements + Cards Multi-Photos Swipeables)

public struct MarketplaceExploreView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @State private var selectedListingForDetail: MarketplaceListing? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroBookstoreEditorialBanner
                    searchAndFilterSection
                    categoryPriorityTabsSection

                    if !store.recentlyViewedListings.isEmpty && store.searchQuery.isEmpty && !store.showOnlyFavorites {
                        recentlyViewedSection
                    }

                    if store.selectedCategory != .all {
                        subcategoryPillsSection
                        dedicatedCategorySection(for: store.selectedCategory)
                    } else if !store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.showOnlyFavorites || store.selectedConditionFilter != "Tous états" || store.maxPriceCeiling > 0 {
                        filteredResultsSection
                    } else {
                        // Vue structurée par rubriques bien séparées dans l'ordre strict :
                        // 1. Livres (Priorité N°1) -> 2. CD & DVD/Blu-Ray -> 3. Accessoires -> 4. Vêtements
                        ForEach(MarketplaceCategory.orderedCreationCategories) { cat in
                            separatedCategorySectionBlock(for: cat)
                        }
                    }

                    vipleTakerPromoBanner
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
            .refreshable {
                await store.bootstrap()
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationDestination(item: $selectedListingForDetail) { listing in
                MarketplaceListingDetailView(listing: listing)
                    .environmentObject(store)
            }
            .onAppear {
                if let target = store.deepLinkedListing {
                    selectedListingForDetail = target
                    store.deepLinkedListing = nil
                }
            }
            .onChange(of: store.deepLinkedListing) { _, target in
                if let target {
                    selectedListingForDetail = target
                    store.deepLinkedListing = nil
                }
            }
        }
    }

    // MARK: - Bannière Éditoriale Librairie en Ligne Livria (Commission 1,00 € • Livraison 0,00 €)

    private var heroBookstoreEditorialBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                        Text("ÉDITÉ PAR LA LIBRAIRIE EN LIGNE LIVRIA")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Text("Achetez & revendez vos Livres, CD/DVD, Accessoires et Vêtements")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MarketplacePalette.primary)
                    Text("1,00 € Garantie et Maintien du service")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(MarketplacePalette.primarySoft))

                HStack(spacing: 5) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(MarketplacePalette.green)
                    Text("0,00 € Frais de livraison")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(MarketplacePalette.green.opacity(0.12)))
            }

            HStack(spacing: 10) {
                Button {
                    store.openSellTab()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Vendre un livre ou article")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }

                Button {
                    store.openLivriaStoreTroc()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Découvrir les Trocs")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(MarketplacePalette.background))
                    .overlay(Capsule().stroke(MarketplacePalette.border, lineWidth: 1))
                    .foregroundStyle(MarketplacePalette.ink)
                }
            }
        }
        .marketplaceCard(padding: 16, cornerRadius: 22)
    }

    // MARK: - Barre de Recherche & Filtres (Recherches Récentes, État, Plafond de Prix, Favoris)

    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(MarketplacePalette.primary)
                    TextField("Rechercher un livre, ISBN, auteur, CD, DVD, mug...", text: $store.searchQuery)
                        .font(.system(size: 14))
                        .submitLabel(.search)
                        .onSubmit {
                            store.addRecentSearch(store.searchQuery)
                        }
                    if !store.searchQuery.isEmpty {
                        Button {
                            store.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(MarketplacePalette.inkMuted)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(MarketplacePalette.border, lineWidth: 1))

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.showOnlyFavorites.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: store.showOnlyFavorites ? "heart.fill" : "heart")
                            .foregroundStyle(store.showOnlyFavorites ? .white : MarketplacePalette.coral)
                        Text("\(store.favoriteListings.count)")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(store.showOnlyFavorites ? .white : MarketplacePalette.ink)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(store.showOnlyFavorites ? MarketplacePalette.coral : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(store.showOnlyFavorites ? MarketplacePalette.coral : MarketplacePalette.border, lineWidth: 1)
                    )
                }
            }

            // Recherches récentes sauvegardées localement (visibles uniquement si l'utilisateur a cherché)
            if !store.recentSearchQueries.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                        ForEach(store.recentSearchQueries, id: \.self) { recent in
                            Button {
                                store.searchQuery = recent
                            } label: {
                                Text(recent)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4.5)
                                    .background(Capsule().fill(Color.white))
                                    .overlay(Capsule().stroke(MarketplacePalette.border, lineWidth: 1))
                                    .foregroundStyle(MarketplacePalette.ink)
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            store.clearRecentSearches()
                        } label: {
                            Text("Effacer")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundStyle(MarketplacePalette.coral)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Filtres rapides : État de l'article & Plafond de prix
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(["Tous états", "Neuf", "Comme neuf", "Très bon état", "Bon état"], id: \.self) { cond in
                            Button {
                                store.selectedConditionFilter = cond
                            } label: {
                                HStack {
                                    Text(cond)
                                    if store.selectedConditionFilter == cond {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                            Text(store.selectedConditionFilter)
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(store.selectedConditionFilter == "Tous états" ? Color.white : MarketplacePalette.primarySoft))
                        .overlay(Capsule().stroke(MarketplacePalette.border, lineWidth: 1))
                        .foregroundStyle(store.selectedConditionFilter == "Tous états" ? MarketplacePalette.ink : MarketplacePalette.primary)
                    }

                    ForEach([(0.0, "Tous prix"), (5.0, "≤ 5 €"), (10.0, "≤ 10 €"), (20.0, "≤ 20 €"), (35.0, "≤ 35 €")], id: \.0) { ceiling, label in
                        let isSelected = store.maxPriceCeiling == ceiling
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                store.maxPriceCeiling = ceiling
                            }
                        } label: {
                            Text(label)
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(isSelected ? MarketplacePalette.primary : Color.white))
                                .overlay(Capsule().stroke(isSelected ? MarketplacePalette.primary : MarketplacePalette.border, lineWidth: 1))
                                .foregroundStyle(isSelected ? .white : MarketplacePalette.ink)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Section Récemment Consultés (Locale & Sans Données Démo)

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Récemment consultés", systemImage: "eye.fill")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Spacer()
                Button("Effacer") {
                    store.clearRecentlyViewedListings()
                }
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(MarketplacePalette.inkMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.recentlyViewedListings.prefix(10)) { item in
                        Button {
                            selectedListingForDetail = item
                        } label: {
                            HStack(spacing: 8) {
                                MarketplaceSmartImage(urlString: item.photos.first, contentMode: .fill)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(MarketplacePalette.ink)
                                        .lineLimit(1)
                                    Text(String(format: "%.2f € • %@", item.price, item.condition))
                                        .font(.system(size: 10.5, weight: .semibold))
                                        .foregroundStyle(MarketplacePalette.primary)
                                }
                            }
                            .frame(width: 195, alignment: .leading)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(MarketplacePalette.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Sélecteur des 4 Rubriques Strictement Séparées (1. Livres > 2. CD/DVD > 3. Accessoires > 4. Vêtements)

    private var categoryPriorityTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarketplaceCategory.allCases) { cat in
                    let isSelected = store.selectedCategory == cat
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            store.selectedCategory = cat
                            store.selectedSubcategory = "Tous"
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 13.5, weight: .bold))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(cat.shortTitle)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                if let badge = cat.priorityBadge {
                                    Text(badge)
                                        .font(.system(size: 9, weight: .bold))
                                        .opacity(0.85)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(MarketplacePalette.heroGradient) : AnyShapeStyle(Color.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? Color.clear : MarketplacePalette.border, lineWidth: 1)
                        )
                        .foregroundStyle(isSelected ? .white : MarketplacePalette.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var subcategoryPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.selectedCategory.subcategories, id: \.self) { sub in
                    let isSubSelected = store.selectedSubcategory == sub
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            store.selectedSubcategory = sub
                        }
                    } label: {
                        Text(sub)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(isSubSelected ? MarketplacePalette.primary : Color.white)
                            )
                            .overlay(
                                Capsule().stroke(isSubSelected ? MarketplacePalette.primary : MarketplacePalette.border, lineWidth: 1)
                            )
                            .foregroundStyle(isSubSelected ? .white : MarketplacePalette.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Bloc Rubrique Séparée (1. Livres, 2. CD & DVD / Blu-Ray, 3. Accessoires, 4. Vêtements)

    private func separatedCategorySectionBlock(for category: MarketplaceCategory) -> some View {
        let items = store.listingsForCategory(category)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(category == .books ? AnyShapeStyle(MarketplacePalette.heroGradient) : AnyShapeStyle(MarketplacePalette.primarySoft))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(category == .books ? .white : MarketplacePalette.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(category.title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        if let badge = category.priorityBadge {
                            Text(badge)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(category == .books ? MarketplacePalette.primary : MarketplacePalette.primarySoft))
                                .foregroundStyle(category == .books ? .white : MarketplacePalette.primary)
                        }
                    }
                    Text(category.subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    withAnimation {
                        store.selectedCategory = category
                        store.selectedSubcategory = "Tous"
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Voir tout (\(items.count))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(MarketplacePalette.primary)
                }
            }

            if items.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(MarketplacePalette.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(MarketplacePalette.primarySoft))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aucune annonce dans \(category.shortTitle) pour le moment")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        Text("Publiez la première annonce de cette rubrique en 4 étapes.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                    }

                    Spacer()

                    Button {
                        store.openSellTab()
                    } label: {
                        Text("Vendre")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(MarketplacePalette.primary))
                            .foregroundStyle(.white)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.background))
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                    ForEach(items) { listing in
                        MarketplaceListingCard(
                            listing: listing,
                            onOpenDetail: { selectedListingForDetail = listing }
                        )
                        .environmentObject(store)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.035), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(category == .books ? MarketplacePalette.primary.opacity(0.32) : MarketplacePalette.border, lineWidth: category == .books ? 1.5 : 1)
        )
    }

    private func dedicatedCategorySection(for category: MarketplaceCategory) -> some View {
        let items = store.filteredListings
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text(category.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
                Spacer()
                Text("\(items.count) annonce(s)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MarketplacePalette.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(MarketplacePalette.primarySoft))
            }

            if items.isEmpty {
                emptyResultsCard
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                    ForEach(items) { listing in
                        MarketplaceListingCard(
                            listing: listing,
                            onOpenDetail: { selectedListingForDetail = listing }
                        )
                        .environmentObject(store)
                    }
                }
            }
        }
    }

    private var filteredResultsSection: some View {
        let items = store.filteredListings
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.showOnlyFavorites ? "Vos annonces favorites ❤️" : "Résultats de recherche")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Spacer()
                Text("\(items.count) résultat(s)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MarketplacePalette.primary)
            }

            if items.isEmpty {
                emptyResultsCard
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                    ForEach(items) { listing in
                        MarketplaceListingCard(
                            listing: listing,
                            onOpenDetail: { selectedListingForDetail = listing }
                        )
                        .environmentObject(store)
                    }
                }
            }
        }
    }

    private var emptyResultsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(MarketplacePalette.primary)
            Text("Aucune annonce dans cette sélection")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)
            Text("Soyez le premier à publier un article dans cette rubrique avec seulement 1,00 € de commission Livria et 0,00 € de livraison !")
                .font(.system(size: 12.5))
                .foregroundStyle(MarketplacePalette.inkMuted)
                .multilineTextAlignment(.center)
            Button {
                store.openSellTab()
            } label: {
                Text("Créer une annonce maintenant")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(MarketplacePalette.primary))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .marketplaceCard(padding: 24)
    }

    // MARK: - Bannière Devenir Viple Taker (Point Relais Particulier — 1,00 € / colis)

    private var vipleTakerPromoBanner: some View {
        Button {
            guard store.requireVipleLiveID(for: "devenir Viple Taker") else { return }
            store.isShowingTakerApplicationSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MarketplacePalette.heroGradient)
                        .frame(width: 54, height: 54)
                    Image(systemName: "house.and.flag.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Devenir Viple Taker")
                            .font(.system(size: 15.5, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        Text("1,00 € / colis")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(MarketplacePalette.green.opacity(0.15)))
                            .foregroundStyle(MarketplacePalette.green)
                    }
                    Text("Devenez point relais particulier pour Livria Store & Marketplace : réceptionnez les colis Viple Delivery / UPS, scannez avec Looby Taker et gagnez 1,00 € par colis remis !")
                        .font(.system(size: 11.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(MarketplacePalette.primary)
            }
            .marketplaceCard(padding: 16, cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card d'Annonce avec Swipe Multi-Photos Direct (Sans Ouvrir la Card !) + 4 Boutons Icônes

public struct MarketplaceListingCard: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    public let listing: MarketplaceListing
    public let onOpenDetail: () -> Void

    @State private var currentPhotoIndex: Int = 0

    public var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            // 1. Carrousel Multi-Photos Swipeable au doigt SANS ouvrir l'annonce en détail !
            ZStack(alignment: .top) {
                TabView(selection: $currentPhotoIndex) {
                    ForEach(Array(listing.photos.enumerated()), id: \.offset) { index, photoUrl in
                        MarketplaceSmartImage(urlString: photoUrl, contentMode: .fill)
                            .frame(height: 172)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 172)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Badges en haut de la photo
                HStack {
                    Text(listing.condition)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.black.opacity(0.68)))
                        .foregroundStyle(.white)

                    Spacer()

                    if listing.photos.count > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 8.5))
                            Text("\(currentPhotoIndex + 1)/\(listing.photos.count)")
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.black.opacity(0.68)))
                        .foregroundStyle(.white)
                    }
                }
                .padding(8)

                // Indicateurs de points en bas de la photo pour encourager le swipe direct
                if listing.photos.count > 1 {
                    VStack {
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(0..<listing.photos.count, id: \.self) { idx in
                                Capsule()
                                    .fill(idx == currentPhotoIndex ? Color.white : Color.white.opacity(0.45))
                                    .frame(width: idx == currentPhotoIndex ? 14 : 5, height: 5)
                                    .animation(.spring(response: 0.25), value: currentPhotoIndex)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.38)))
                        .padding(.bottom, 7)
                    }
                }
            }
            .frame(height: 172)

            // 2. Zone cliquable pour ouvrir le détail de l'annonce
            Button {
                onOpenDetail()
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(listing.title)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let author = listing.authorOrArtist, !author.isEmpty {
                        Text(author)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MarketplacePalette.primary)
                            .lineLimit(1)
                    } else {
                        Text(listing.subcategory)
                            .font(.system(size: 11))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                            .lineLimit(1)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(String(format: "%.2f €", listing.price))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        Text("+1€ Livria • 0€ port")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MarketplacePalette.green)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(MarketplacePalette.primary)
                        Text("@\(listing.sellerUsername)")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(MarketplacePalette.gold)
                        Text(String(format: "%.1f", listing.sellerRating))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MarketplacePalette.ink)
                    }
                }
            }
            .buttonStyle(.plain)

            Divider()

            // 3. Les 4 Boutons sous forme de petites icônes demandés (Réservés Viple Live ID) :
            // [🛒 Caddie : Acheter] [🏷️ Faire une offre] [❤️ Favoris] [📤 Partager]
            HStack(spacing: 6) {
                // Icône 1 : Caddie pour Acheter (Viple Live ID requis)
                Button {
                    store.startCheckout(for: listing)
                } label: {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 13.5, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.primary))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Acheter")

                // Icône 2 : Faire une offre (Viple Live ID requis)
                Button {
                    store.startMakeOffer(for: listing)
                } label: {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }
                .accessibilityLabel("Faire une offre")

                // Icône 3 : Mettre l'annonce dans ses favoris (Viple Live ID requis)
                Button {
                    store.toggleFavorite(for: listing)
                } label: {
                    Image(systemName: listing.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(listing.isFavorited ? MarketplacePalette.coral.opacity(0.16) : MarketplacePalette.background)
                        )
                        .foregroundStyle(listing.isFavorited ? MarketplacePalette.coral : MarketplacePalette.ink)
                }
                .accessibilityLabel("Favoris")

                // Icône 4 : Partager l'annonce (en message ou iOS Share — Viple Live ID requis)
                Button {
                    store.startShareListing(listing)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12.5, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.background))
                        .foregroundStyle(MarketplacePalette.ink)
                }
                .accessibilityLabel("Partager l'annonce")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.045), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MarketplacePalette.border, lineWidth: 1)
        )
    }
}

// MARK: - Page Détail d'une Annonce (Carrousel Grand Format + 4 Boutons Icônes + Infos + Édition/Suppression Vendeur)

public struct MarketplaceListingDetailView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    public let listing: MarketplaceListing

    @State private var currentPhotoIndex: Int = 0
    @State private var showingDeleteConfirm: Bool = false
    @State private var showingReportSheet: Bool = false

    private var liveListing: MarketplaceListing {
        store.listings.first(where: { $0.id == listing.id }) ?? listing
    }

    private var isMyListing: Bool {
        if liveListing.sellerUsername == "vous.livria" { return true }
        guard let currentUsername = store.currentUser?.username else { return false }
        return liveListing.sellerUsername.caseInsensitiveCompare(currentUsername) == .orderedSame
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Carrousel Photo Grand Format Swipeable
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(Array(liveListing.photos.enumerated()), id: \.offset) { index, url in
                            MarketplaceSmartImage(urlString: url, contentMode: .fill)
                                .frame(height: 330)
                                .clipped()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    HStack {
                        Text(liveListing.parsedCategory.title)
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(MarketplacePalette.primary))
                            .foregroundStyle(.white)

                        Spacer()

                        Text("Photo \(currentPhotoIndex + 1) / \(max(1, liveListing.photos.count))")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.black.opacity(0.65)))
                            .foregroundStyle(.white)
                    }
                    .padding(14)
                }

                // Barre des 4 Boutons sous forme d'icônes (Acheter / Faire une offre / Favoris / Partager — Réservés Viple Live ID)
                HStack(spacing: 12) {
                    Button {
                        store.startCheckout(for: liveListing)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 20, weight: .bold))
                            Text("Acheter")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(MarketplacePalette.heroGradient))
                        .foregroundStyle(.white)
                    }

                    Button {
                        store.startMakeOffer(for: liveListing)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Faire une offre")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                    }

                    Button {
                        store.toggleFavorite(for: liveListing)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: liveListing.isFavorited ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .bold))
                            Text("Favoris (\(liveListing.favoritesCount))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(liveListing.isFavorited ? MarketplacePalette.coral.opacity(0.16) : Color.white)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MarketplacePalette.border, lineWidth: 1))
                        .foregroundStyle(liveListing.isFavorited ? MarketplacePalette.coral : MarketplacePalette.ink)
                    }

                    Button {
                        store.startShareListing(liveListing)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Partager")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MarketplacePalette.border, lineWidth: 1))
                        .foregroundStyle(MarketplacePalette.ink)
                    }
                }

                // Détails Prix & Garantie Livria 1,00 € + Livraison 0,00 €
                VStack(alignment: .leading, spacing: 12) {
                    Text(liveListing.title)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)

                    Text(liveListing.subtitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MarketplacePalette.primary)

                    HStack(alignment: .bottom, spacing: 12) {
                        Text(String(format: "%.2f €", liveListing.price))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        if let retail = liveListing.originalRetailPrice, retail > liveListing.price {
                            Text(String(format: "Prix neuf : %.2f €", retail))
                                .font(.system(size: 13, weight: .semibold))
                                .strikethrough()
                                .foregroundStyle(MarketplacePalette.inkMuted)
                        }

                        Spacer()

                        Text(liveListing.condition)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(MarketplacePalette.primarySoft))
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Divider()

                    VStack(spacing: 7) {
                        HStack {
                            Label("Prix vendeur", systemImage: "tag.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                            Spacer()
                            Text(String(format: "%.2f €", liveListing.price))
                                .font(.system(size: 13, weight: .bold))
                        }
                        HStack {
                            Label("Commission Livria (« Garantie et Maintien du service »)", systemImage: "checkmark.shield.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MarketplacePalette.primary)
                            Spacer()
                            Text("1,00 €")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                        HStack {
                            Label("Frais de livraison (UPS / Viple Taker)", systemImage: "shippingbox.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MarketplacePalette.green)
                            Spacer()
                            Text("0,00 € (Offerts)")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(MarketplacePalette.green)
                        }
                        Divider()
                        HStack {
                            Text("Total tout compris")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                            Spacer()
                            Text(String(format: "%.2f €", liveListing.totalBuyerPrice))
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.background))
                }
                .marketplaceCard()

                // Fiche Technique & Description
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description & Caractéristiques")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)

                    Text(liveListing.description)
                        .font(.system(size: 14))
                        .foregroundStyle(MarketplacePalette.ink)
                        .lineSpacing(3)

                    Divider()

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            Text("Rubrique").font(.caption.bold()).foregroundStyle(MarketplacePalette.inkMuted)
                            Text("\(liveListing.parsedCategory.title) • \(liveListing.subcategory)").font(.caption.bold())
                        }
                        if let author = liveListing.authorOrArtist, !author.isEmpty {
                            GridRow {
                                Text("Auteur / Artiste").font(.caption.bold()).foregroundStyle(MarketplacePalette.inkMuted)
                                Text(author).font(.caption.bold())
                            }
                        }
                        if let pub = liveListing.publisherOrBrand, !pub.isEmpty {
                            GridRow {
                                Text("Éditeur / Marque").font(.caption.bold()).foregroundStyle(MarketplacePalette.inkMuted)
                                Text(pub).font(.caption.bold())
                            }
                        }
                        if let isbn = liveListing.isbn, !isbn.isEmpty {
                            GridRow {
                                Text("Code ISBN").font(.caption.bold()).foregroundStyle(MarketplacePalette.inkMuted)
                                HStack(spacing: 6) {
                                    Text(isbn).font(.caption.monospaced().bold())
                                    Button {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = isbn
                                        #endif
                                        store.showToast("ISBN \(isbn) copié")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption2.bold())
                                            .foregroundStyle(MarketplacePalette.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if let size = liveListing.clothingSize, !size.isEmpty {
                            GridRow {
                                Text("Taille").font(.caption.bold()).foregroundStyle(MarketplacePalette.inkMuted)
                                Text(size).font(.caption.bold())
                            }
                        }
                    }
                }
                .marketplaceCard()

                // Carte Vendeur + Bouton Contacter dans la Messagerie
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        MarketplaceAvatarRing(
                            avatarUrl: liveListing.sellerAvatarUrl,
                            displayName: liveListing.sellerDisplayName,
                            level: liveListing.sellerLevel,
                            size: 52
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 5) {
                                Text(liveListing.sellerDisplayName)
                                    .font(.system(size: 15.5, weight: .black, design: .rounded))
                                    .foregroundStyle(MarketplacePalette.ink)
                                if liveListing.isVipleVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(MarketplacePalette.primary)
                                        .font(.system(size: 13))
                                }
                            }
                            Text("@\(liveListing.sellerUsername) • \(liveListing.sellerCity)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(MarketplacePalette.gold)
                                    .font(.system(size: 11))
                                Text("\(String(format: "%.2f", liveListing.sellerRating)) (\(liveListing.sellerSalesCount) ventes certifiées Livria)")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)
                            }
                        }
                        Spacer()
                    }

                    Button {
                        guard store.requireVipleLiveID(for: "envoyer un message au vendeur") else { return }
                        if store.ensureConversation(for: liveListing) != nil {
                            dismiss()
                            store.selectedTab = .messages
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Envoyer un message à @\(liveListing.sellerUsername)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                    }
                }
                .marketplaceCard()

                // Si c'est notre annonce : Options Modifier & Supprimer l'annonce
                if isMyListing {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gestion de votre annonce")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        HStack(spacing: 10) {
                            Button {
                                store.editingListing = liveListing
                            } label: {
                                Label("Modifier l'annonce", systemImage: "pencil")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primary))
                                    .foregroundStyle(.white)
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirm = true
                            } label: {
                                Label("Supprimer", systemImage: "trash.fill")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.14)))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .marketplaceCard()
                } else {
                    HStack {
                        Button {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = "livriamarketplace://listing/\(liveListing.id)"
                            #endif
                            store.showToast("Lien de l'annonce copié")
                        } label: {
                            Label("Copier le lien de l'annonce", systemImage: "link")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            showingReportSheet = true
                        } label: {
                            Label("Signaler l'annonce", systemImage: "flag")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MarketplacePalette.coral)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                }
            }
            .padding(16)
        }
        .background(MarketplacePalette.background.ignoresSafeArea())
        .navigationTitle(liveListing.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.recordListingViewed(liveListing)
        }
        .confirmationDialog("Signaler cette annonce à la modération Livria", isPresented: $showingReportSheet, titleVisibility: .visible) {
            ForEach(["Article non conforme à la rubrique", "Prix ou description trompeuse", "Contrefaçon ou contenu interdit", "Spam / Doublon"], id: \.self) { reason in
                Button(reason) {
                    Task {
                        await store.reportListing(liveListing, reason: reason, details: "Signalé depuis iOS Marketplace")
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .alert("Supprimer cette annonce ?", isPresented: $showingDeleteConfirm) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer définitivement", role: .destructive) {
                Task {
                    await store.deleteListing(liveListing)
                    dismiss()
                }
            }
        } message: {
            Text("Cette annonce sera immédiatement retirée de Livria Marketplace.")
        }
    }
}

// MARK: - Sheet « Faire une Offre » (Depuis la Card ou la Page de l'Annonce)

public struct MarketplaceMakeOfferSheetView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    public let listing: MarketplaceListing

    @State private var offerPriceText: String = ""
    @State private var personalMessage: String = ""

    private var offeredPriceValue: Double {
        Double(offerPriceText.replacingOccurrences(of: ",", with: ".")) ?? max(1.0, listing.price * 0.85)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Résumé de l'annonce
                    HStack(spacing: 12) {
                        MarketplaceSmartImage(urlString: listing.photos.first)
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.title)
                                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MarketplacePalette.ink)
                                .lineLimit(2)
                            Text("Prix affiché : \(String(format: "%.2f €", listing.price)) • Vendeur @\(listing.sellerUsername)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                        Spacer()
                    }
                    .marketplaceCard(padding: 12)

                    // Suggestions rapides (-10%, -15%, -20%)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choisissez ou saisissez votre offre")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        HStack(spacing: 10) {
                            ForEach([
                                ("-10%", max(1.0, (listing.price * 0.90).rounded())),
                                ("-15%", max(1.0, (listing.price * 0.85).rounded())),
                                ("-20%", max(1.0, (listing.price * 0.80).rounded()))
                            ], id: \.0) { label, amount in
                                Button {
                                    offerPriceText = String(format: "%.2f", amount)
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(label)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(MarketplacePalette.primary)
                                        Text(String(format: "%.2f €", amount))
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(MarketplacePalette.ink)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primarySoft))
                                }
                            }
                        }

                        HStack {
                            TextField("Votre prix en €", text: $offerPriceText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                            Text("€")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(MarketplacePalette.border, lineWidth: 1))

                        VStack(spacing: 6) {
                            HStack {
                                Text("Offre au vendeur")
                                Spacer()
                                Text(String(format: "%.2f €", offeredPriceValue)).bold()
                            }
                            HStack {
                                Text("Garantie et Maintien du service Livria")
                                Spacer()
                                Text("1,00 €").bold().foregroundStyle(MarketplacePalette.primary)
                            }
                            HStack {
                                Text("Livraison UPS / Viple Taker")
                                Spacer()
                                Text("0,00 €").bold().foregroundStyle(MarketplacePalette.green)
                            }
                            Divider()
                            HStack {
                                Text("Total si l'offre est acceptée").bold()
                                Spacer()
                                Text(String(format: "%.2f €", offeredPriceValue + 1.00))
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(MarketplacePalette.primary)
                            }
                        }
                        .font(.system(size: 12.5))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                    }
                    .marketplaceCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message au vendeur (optionnel)")
                            .font(.system(size: 13.5, weight: .bold))
                        TextField("Bonjour ! Je suis très intéressé par votre annonce...", text: $personalMessage, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarketplacePalette.border, lineWidth: 1))
                    }
                    .marketplaceCard()

                    Button {
                        Task {
                            await store.submitPriceOffer(
                                for: listing,
                                offeredPrice: offeredPriceValue,
                                message: personalMessage
                            )
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tag.fill")
                            Text("Envoyer mon offre à \(String(format: "%.2f €", offeredPriceValue))")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(MarketplacePalette.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Faire une offre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                offerPriceText = String(format: "%.2f", max(1.0, (listing.price * 0.90).rounded()))
            }
        }
    }
}

// MARK: - Sheet « Partager l'Annonce » (En Message Interne Livria ou via iOS ShareLink)

public struct MarketplaceShareListingSheetView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    public let listing: MarketplaceListing

    @State private var recipientUsername: String = ""
    @State private var noteText: String = "Regarde cette annonce sur Livria Marketplace !"

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    MarketplaceSmartImage(urlString: listing.photos.first)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(2)
                        Text(String(format: "%.2f € (+1€ Livria • 0€ port)", listing.price))
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }
                    Spacer()
                }
                .marketplaceCard(padding: 12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Partager en message sur Livria Marketplace")
                        .font(.system(size: 15, weight: .black, design: .rounded))

                    TextField("Pseudo du destinataire (ex: claire.bouquine)", text: $recipientUsername)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))

                    TextField("Ajouter un petit mot...", text: $noteText)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))

                    Button {
                        Task {
                            await store.shareListingInInternalMessage(
                                listing,
                                toRecipient: recipientUsername,
                                personalNote: noteText
                            )
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Envoyer dans la messagerie Livria")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(MarketplacePalette.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .marketplaceCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Partager via iMessage, WhatsApp, AirDrop...")
                        .font(.system(size: 15, weight: .black, design: .rounded))

                    ShareLink(
                        item: URL(string: "https://livria.store/marketplace/\(listing.id)")!,
                        subject: Text(listing.title),
                        message: Text("Découvre « \(listing.title) » à \(String(format: "%.2f €", listing.price)) sur Livria Marketplace (0 € de frais de livraison) !")
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Ouvrir le menu de partage iOS")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                    }
                }
                .marketplaceCard()

                Spacer()
            }
            .padding(16)
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Partager l'annonce")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
