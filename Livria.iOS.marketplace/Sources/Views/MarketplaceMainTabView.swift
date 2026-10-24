import SwiftUI

// MARK: - Conteneur Principal Livria Marketplace (Splash Screen, Maintenance 20s/503, CGU 1er Lancement, Cross-App SSO & 5 Onglets)

public struct MarketplaceMainTabView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            if !store.hasAcceptedTermsOfUse {
                MarketplaceFirstLaunchTermsGateView()
                    .transition(.opacity)
            } else if store.isBootstrapping {
                MarketplaceSplashLoadingView()
                    .transition(.opacity)
            } else if store.isServerInMaintenanceOrDown {
                MarketplaceServerOutageMaintenanceView()
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    topAppBar

                    TabView(selection: $store.selectedTab) {
                        MarketplaceExploreView()
                            .tabItem {
                                Label("Explorer", systemImage: "books.vertical.fill")
                            }
                            .tag(MarketplaceTab.explore)

                        CreateOrEditListingView()
                            .tabItem {
                                Label("Vendre", systemImage: "plus.circle.fill")
                            }
                            .tag(MarketplaceTab.sell)

                        MarketplaceMessagesView()
                            .tabItem {
                                Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                            }
                            .badge(unreadMessagesCount)
                            .tag(MarketplaceTab.messages)

                        MarketplaceRelaysAndTakerView()
                            .tabItem {
                                Label("Points Relais", systemImage: "shippingbox.fill")
                            }
                            .tag(MarketplaceTab.relaysAndTaker)

                        MarketplaceProfileView()
                            .tabItem {
                                Label("Mon Profil", systemImage: "person.crop.circle.fill")
                            }
                            .tag(MarketplaceTab.profile)
                    }
                    .tint(MarketplacePalette.primary)
                }
            }

            if let toast = store.toastMessage {
                Text(toast)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(MarketplacePalette.ink.opacity(0.94))
                            .shadow(color: .black.opacity(0.22), radius: 12, y: 5)
                    )
                    .padding(.bottom, 68)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .sheet(isPresented: $store.isShowingAuthSheet) {
            MarketplaceAuthSheetView()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.isShowingTermsReviewSheet) {
            MarketplaceTermsReviewSheetView()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.isShowingTakerApplicationSheet) {
            MarketplaceVipleTakerApplicationSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.isShowingOrdersSheet) {
            MarketplaceOrdersHistorySheet()
                .environmentObject(store)
        }
        .sheet(item: $store.activeCheckoutListing) { listing in
            MarketplaceCheckoutSheetView(
                listing: listing,
                agreedPrice: store.activeCheckoutAgreedPrice
            )
            .environmentObject(store)
        }
        .sheet(item: $store.activeOfferListing) { listing in
            MarketplaceMakeOfferSheetView(listing: listing)
                .environmentObject(store)
        }
        .sheet(item: $store.activeShareListing) { listing in
            MarketplaceShareListingSheetView(listing: listing)
                .environmentObject(store)
        }
        .sheet(item: $store.editingListing) { listing in
            NavigationStack {
                CreateOrEditListingView(existingListing: listing)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $store.isShowingCrossAppPrompt) {
            if let discovered = store.discoveredCrossAppSession,
               let user = discovered.user {
                MarketplaceCrossAppSsoPromptSheet(
                    sourceApp: discovered.sourceApp ?? "Livria Store",
                    targetApp: "Livria Marketplace",
                    user: user,
                    onConfirm: {
                        Task { await store.acceptCrossAppSingleSignOn() }
                    },
                    onDecline: {
                        store.declineCrossAppSingleSignOn()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, !store.isAuthenticated, store.hasAcceptedTermsOfUse, !store.isBootstrapping {
                Task {
                    await store.checkCrossAppSingleSignOn()
                }
            }
        }
    }

    private var unreadMessagesCount: Int {
        store.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Barre Supérieure Blanche avec Logo Livria Marketplace + Accès Rapide (Livria Store, Livria Social, Les Trocs)

    private var topAppBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image("LivriaMarketplaceLogoHorizontal")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                }

                Spacer()

                Button {
                    store.isShowingOrdersSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.and.arrow.backward.fill")
                            .font(.system(size: 12.5, weight: .bold))
                        Text("Commandes")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        if !store.orders.isEmpty {
                            Text("\(store.orders.count)")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(.white))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(MarketplacePalette.primary))
                    .foregroundStyle(.white)
                }

                Button {
                    if store.isAuthenticated {
                        store.selectedTab = .profile
                    } else {
                        store.isShowingAuthSheet = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: store.isAuthenticated ? "checkmark.seal.fill" : "person.crop.circle.badge.plus")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(store.isAuthenticated ? MarketplacePalette.green : MarketplacePalette.primary)
                        Text(store.isAuthenticated ? (store.currentUser?.displayName ?? "Mon Compte") : "Connexion")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(MarketplacePalette.background))
                    .overlay(Capsule().stroke(MarketplacePalette.border, lineWidth: 1))
                }
            }

            // Barre d'Accès Rapide demandée : Livria Store, Livria Social, et Les Trocs (ouvre Troc dans Livria Store) + Viple Taker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .black))
                        Text("Accès rapide :")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(MarketplacePalette.inkMuted)

                    Button {
                        store.openLivriaStoreApp()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("Livria Store")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                    }

                    Button {
                        store.openLivriaSocialApp()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("Livria Social")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(MarketplacePalette.coral.opacity(0.14)))
                        .foregroundStyle(MarketplacePalette.coral)
                    }

                    Button {
                        store.openLivriaStoreTroc()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("Les Trocs (Livria Store)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(MarketplacePalette.goldSoft))
                        .foregroundStyle(Color(red: 0.65, green: 0.42, blue: 0.02))
                    }

                    Button {
                        store.isShowingTakerApplicationSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "house.and.flag.fill")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("Devenir Viple Taker (1€/colis)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(MarketplacePalette.green.opacity(0.14)))
                        .foregroundStyle(MarketplacePalette.green)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(MarketplacePalette.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Écran de Chargement Identique à Livria Store & Livria Social (avec le Même Message que Livria Store)

public struct MarketplaceSplashLoadingView: View {
    @State private var pulseLogo: Bool = false
    @State private var progressValue: CGFloat = 0.22

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.96, green: 0.93, blue: 1.0),
                    Color(red: 0.99, green: 0.94, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(MarketplacePalette.primary.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 42)
                .offset(x: -95, y: -170)

            Circle()
                .fill(MarketplacePalette.coral.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 38)
                .offset(x: 110, y: 185)

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 14) {
                    Image("LivriaLogoTransparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 84)
                        .scaleEffect(pulseLogo ? 1.04 : 0.97)
                        .shadow(color: MarketplacePalette.primary.opacity(0.18), radius: 14, y: 5)

                    Text("MARKETPLACE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(4.0)
                        .foregroundStyle(MarketplacePalette.coral)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(MarketplacePalette.primarySoft))
                }

                // Exactement le même message de chargement que Livria Store :
                Text("Mais sur quelles pépites allons-nous encore tomber !?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(MarketplacePalette.primarySoft)
                            .frame(width: 215, height: 7)

                        Capsule()
                            .fill(MarketplacePalette.heroGradient)
                            .frame(width: 215 * progressValue, height: 7)
                    }

                    Text("Livres • CD & DVD • Accessoires • Vêtements")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
                .padding(.top, 4)

                Spacer()

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(MarketplacePalette.primary)
                        Text("Édité par la librairie en ligne Livria • Viple Live ID")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                    }
                    Text("Commission unique 1,00 € (Garantie et Maintien du service) • Livraison 0,00 €")
                        .font(.system(size: 11))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseLogo = true
            }
            withAnimation(.easeInOut(duration: 1.35)) {
                progressValue = 1.0
            }
        }
    }
}

// MARK: - Écran de Maintenance / Panne Serveur (20s Timeout ou HTTP 503 ou Maintenance /admin Livria)

public struct MarketplaceServerOutageMaintenanceView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @State private var isRetrying: Bool = false

    public var body: some View {
        ZStack {
            MarketplacePalette.background.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                Image("LivriaLogoTransparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 68)

                ZStack {
                    Circle()
                        .fill(MarketplacePalette.primarySoft)
                        .frame(width: 98, height: 98)

                    Image(systemName: "cloud.bolt.rain.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(MarketplacePalette.heroGradient)
                }

                Text("Oups, le serveur a le moral dans les chaussette, il revient bientot")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text("Nos équipes Livria & Viple remettent les rayons en ordre. Réessayez dans quelques instants.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MarketplacePalette.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Button {
                    guard !isRetrying else { return }
                    isRetrying = true
                    Task {
                        await store.bootstrap()
                        isRetrying = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isRetrying {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                        }
                        Text(isRetrying ? "Vérification en cours..." : "Réessayer maintenant")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(MarketplacePalette.heroGradient))
                    .shadow(color: MarketplacePalette.primary.opacity(0.25), radius: 12, y: 5)
                }
                .padding(.top, 8)

                Spacer()
            }
        }
    }
}

// MARK: - Invitation Automatique Cross-App Viple Live ID SSO

public struct MarketplaceCrossAppSsoPromptSheet: View {
    public let sourceApp: String
    public let targetApp: String
    public let user: MarketplaceUserProfile
    public let onConfirm: () -> Void
    public let onDecline: () -> Void

    public var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            HStack(spacing: 8) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Continuité Viple Live ID")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(MarketplacePalette.primarySoft))

            Text("Nous avons détecté que vous étiez connecté depuis \(sourceApp)")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text("Souhaitez-vous vous connecter au même compte avec \(targetApp) ?")
                .font(.system(size: 14.5, weight: .medium, design: .rounded))
                .foregroundStyle(MarketplacePalette.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 14) {
                MarketplaceAvatarRing(
                    avatarUrl: user.avatarUrl,
                    displayName: user.displayName,
                    level: user.level,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.displayName)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Text("@\(user.username)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.primary)

                    if !user.email.isEmpty {
                        Text(user.email)
                            .font(.system(size: 12))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(MarketplacePalette.border, lineWidth: 1))
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                Button {
                    onConfirm()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Oui, continuer en tant que \(user.displayName)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    onDecline()
                } label: {
                    Text("Rester en mode invité ou utiliser un autre compte")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(MarketplacePalette.background.ignoresSafeArea())
    }
}
