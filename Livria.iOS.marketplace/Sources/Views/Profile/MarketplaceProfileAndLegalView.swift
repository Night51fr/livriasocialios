import SwiftUI
import PhotosUI
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Mon Profil Viple Live ID, Recadrage Photo de Profil, Mes Annonces (Modif/Suppr), Accès Rapide, CGU & Suppression de Compte

public struct MarketplaceProfileView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel

    @State private var selectedAvatarItem: PhotosPickerItem? = nil
    @State private var avatarImageForCrop: UIImage? = nil
    @State private var isShowingAvatarCropper: Bool = false
    @State private var isUploadingAvatar: Bool = false
    @State private var showingDeleteAccountAlert: Bool = false
    @State private var listingPendingDeletion: MarketplaceListing? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            if !store.isAuthenticated {
                MarketplaceVipleLiveIDRequiredGateView(
                    featureTitle: "Mon Profil Viple Live ID",
                    featureSubtitle: "L'accès à votre profil, le recadrage de votre photo, le suivi de vos commandes et la gestion de vos annonces sont réservés aux utilisateurs connectés avec Viple Live ID.",
                    icon: "person.crop.circle.badge.checkmark",
                    showQuickAccessAndLegal: true
                )
                .environmentObject(store)
                .navigationTitle("Mon Profil & Paramètres")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        quickAccessEcosystemCard
                        authenticatedProfileHeaderCard
                        myListingsManagementCard
                        settingsAndAppStoreComplianceCard
                    }
                    .padding(16)
                }
                .background(MarketplacePalette.background.ignoresSafeArea())
                .navigationTitle("Mon Profil & Paramètres")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: selectedAvatarItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    #if canImport(UIKit)
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        await MainActor.run {
                            avatarImageForCrop = uiImg
                            isShowingAvatarCropper = true
                            selectedAvatarItem = nil
                        }
                    }
                    #endif
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $isShowingAvatarCropper) {
                if let img = avatarImageForCrop {
                    MarketplaceImageCropperSheet(
                        image: img,
                        title: "Recadrer ma photo de profil Viple Live ID",
                        isCircularMask: true,
                        onCropped: { croppedData in
                            isShowingAvatarCropper = false
                            isUploadingAvatar = true
                            Task {
                                _ = await store.uploadCroppedAvatar(jpegData: croppedData)
                                await MainActor.run {
                                    isUploadingAvatar = false
                                }
                            }
                        },
                        onCancel: {
                            isShowingAvatarCropper = false
                        }
                    )
                }
            }
            #endif
            .alert("Supprimer cette annonce ?", isPresented: Binding(
                get: { listingPendingDeletion != nil },
                set: { if !$0 { listingPendingDeletion = nil } }
            )) {
                Button("Annuler", role: .cancel) { listingPendingDeletion = nil }
                Button("Supprimer", role: .destructive) {
                    if let item = listingPendingDeletion {
                        Task {
                            await store.deleteListing(item)
                            listingPendingDeletion = nil
                        }
                    }
                }
            } message: {
                Text("L'annonce sera immédiatement supprimée de Livria Marketplace.")
            }
            .alert("Supprimer définitivement mon compte Viple Live ID ?", isPresented: $showingDeleteAccountAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Oui, supprimer mon compte", role: .destructive) {
                    Task {
                        _ = await store.deleteVipleAccount()
                    }
                }
            } message: {
                Text("Cette action est irréversible et supprimera votre compte Viple Live ID, vos annonces, vos messages et vos données associées.")
            }
        }
    }

    // MARK: - Accès Rapide sur Livria Marketplace (Livria Store, Livria Social, Les Trocs & Viple Taker)

    private var quickAccessEcosystemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Accès rapide")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Spacer()
                Text("Écosystème Livria")
                    .font(.system(size: 10.5, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(MarketplacePalette.primarySoft))
                    .foregroundStyle(MarketplacePalette.primary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                Button {
                    store.openLivriaStoreApp()
                } label: {
                    quickAccessTile(
                        title: "Livria Store",
                        subtitle: "Librairie officielle & Catalogue neuf",
                        icon: "book.fill",
                        tint: MarketplacePalette.primary
                    )
                }
                .buttonStyle(.plain)

                Button {
                    store.openLivriaSocialApp()
                } label: {
                    quickAccessTile(
                        title: "Livria Social",
                        subtitle: "Réseau social, Clubs & Communauté",
                        icon: "bubble.left.and.bubble.right.fill",
                        tint: MarketplacePalette.coral
                    )
                }
                .buttonStyle(.plain)

                Button {
                    store.openLivriaStoreTroc()
                } label: {
                    quickAccessTile(
                        title: "Les Trocs",
                        subtitle: "Ouvre directement Troc dans Livria Store",
                        icon: "arrow.triangle.2.circlepath",
                        tint: Color(red: 0.85, green: 0.52, blue: 0.05)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    store.isShowingTakerApplicationSheet = true
                } label: {
                    quickAccessTile(
                        title: "Viple Taker",
                        subtitle: "Point relais particulier (1,00 € / colis)",
                        icon: "house.and.flag.fill",
                        tint: MarketplacePalette.green
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .marketplaceCard()
    }

    private func quickAccessTile(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(tint))
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)
            Text(subtitle)
                .font(.system(size: 10.5))
                .foregroundStyle(MarketplacePalette.inkMuted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.background))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(MarketplacePalette.border, lineWidth: 1))
    }

    // MARK: - En-tête Utilisateur Viple Live ID + Upload & Recadrage Photo de Profil

    private var authenticatedProfileHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                MarketplaceAvatarRing(
                    avatarUrl: store.currentUser?.avatarUrl,
                    displayName: store.currentUser?.displayName ?? "Membre Livria",
                    level: store.currentUser?.level ?? 7,
                    size: 76
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(store.currentUser?.displayName ?? "Membre Livria")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(MarketplacePalette.primary)
                    }
                    Text("@\(store.currentUser?.username ?? "membre.livria")")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MarketplacePalette.primary)
                    Text(store.currentUser?.email ?? "")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
                Spacer()
            }

            PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.crop.circle.fill")
                    Text("Uploader & Recadrer ma photo de profil")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "crop")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MarketplacePalette.heroGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isUploadingAvatar)
        }
        .marketplaceCard()
    }

    private var guestConnectCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MarketplacePalette.primarySoft)
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(MarketplacePalette.primary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Compte Unique Viple Live ID")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text("Connectez-vous pour synchroniser votre profil avec Livria Store et Livria Social, publier vos annonces et recadrer votre photo de profil.")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.isShowingAuthSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                        Text("Se connecter avec Viple Live ID")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    Image(systemName: "crop")
                        .font(.system(size: 16, weight: .bold))
                        .padding(13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }
            }
        }
        .marketplaceCard()
    }

    // MARK: - Mes Annonces (Créer, Modifier, Supprimer)

    private var myOwnListings: [MarketplaceListing] {
        guard let me = store.currentUser else { return [] }
        return store.listings.filter {
            $0.sellerUsername.caseInsensitiveCompare(me.username) == .orderedSame ||
            ($0.sellerUserId > 0 && $0.sellerUserId == me.numericUserId)
        }
    }

    private var myListingsManagementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mes Annonces & Ventes (\(myOwnListings.count))")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Spacer()
                Button {
                    store.editingListing = nil
                    store.selectedTab = .sell
                } label: {
                    Label("Nouvelle annonce", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MarketplacePalette.primary)
                }
            }

            if myOwnListings.isEmpty {
                Text(store.isAuthenticated
                     ? "Vous n'avez pas encore publié d'annonce. Appuyez sur « Nouvelle annonce » pour mettre en vente un livre, CD/DVD, accessoire ou vêtement."
                     : "Connectez-vous avec Viple Live ID pour publier et gérer vos annonces.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(MarketplacePalette.inkMuted)
                    .padding(.vertical, 6)
            } else {
                ForEach(myOwnListings) { item in
                HStack(spacing: 10) {
                    MarketplaceSmartImage(urlString: item.photos.first, contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                        Text("\(String(format: "%.2f €", item.price)) • \(item.parsedCategory.title)")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Spacer()

                    Button {
                        store.editingListing = item
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12.5, weight: .bold))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(MarketplacePalette.primarySoft))
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Button(role: .destructive) {
                        listingPendingDeletion = item
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12.5, weight: .bold))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.red.opacity(0.14)))
                            .foregroundStyle(.red)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                }
            }
        }
        .marketplaceCard()
    }

    // MARK: - Paramètres, Relecture des CGU & Suppression de Compte (Obligatoire App Store)

    private var settingsAndAppStoreComplianceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paramètres, Commandes & Mentions Légales")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)

            Button {
                store.isShowingOrdersSheet = true
            } label: {
                settingsRow(
                    icon: "shippingbox.fill",
                    title: "Mes Commandes & Suivi UPS / Viple Taker",
                    subtitle: "Consultez vos achats, numéros UPS et étiquettes Viple Delivery"
                )
            }
            .buttonStyle(.plain)

            Button {
                store.isShowingTermsReviewSheet = true
            } label: {
                settingsRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Relire les Conditions d'Utilisation (CGU / CGV)",
                    subtitle: "Garantie et Maintien du service (1,00 €), Livraison 0 €, Viple Taker & RGPD"
                )
            }
            .buttonStyle(.plain)

            if store.isAuthenticated {
                Button {
                    store.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Se déconnecter de Viple Live ID")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                    .foregroundStyle(MarketplacePalette.ink)
                }
            }

            Button(role: .destructive) {
                showingDeleteAccountAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Supprimer mon compte Viple Live ID depuis l'application")
                        .font(.system(size: 13.5, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.14)))
                .foregroundStyle(.red)
            }
        }
        .marketplaceCard()
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MarketplacePalette.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(MarketplacePalette.primarySoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(MarketplacePalette.inkMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(MarketplacePalette.inkMuted)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
    }
}

// MARK: - Vue d'Accès Réservé aux Utilisateurs Connectés « Viple Live ID » (Vendre, Messages, Mon Profil)

public struct MarketplaceVipleLiveIDRequiredGateView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    public let featureTitle: String
    public let featureSubtitle: String
    public let icon: String
    public var showQuickAccessAndLegal: Bool = false

    public init(
        featureTitle: String,
        featureSubtitle: String,
        icon: String,
        showQuickAccessAndLegal: Bool = false
    ) {
        self.featureTitle = featureTitle
        self.featureSubtitle = featureSubtitle
        self.icon = icon
        self.showQuickAccessAndLegal = showQuickAccessAndLegal
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(MarketplacePalette.primarySoft)
                            .frame(width: 78, height: 78)
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("RÉSERVÉ AUX MEMBRES VIPLE LIVE ID")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .tracking(0.6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(MarketplacePalette.primarySoft))
                    .foregroundStyle(MarketplacePalette.primary)

                    Text(featureTitle)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                        .multilineTextAlignment(.center)

                    Text(featureSubtitle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Button {
                        store.isShowingAuthSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("Se connecter avec Viple Live ID")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(MarketplacePalette.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .marketplaceCard(padding: 24, cornerRadius: 24)

                if showQuickAccessAndLegal {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accès Rapide & Mentions Légales")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        Button {
                            store.openLivriaStoreApp()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "book.fill")
                                    .foregroundStyle(MarketplacePalette.primary)
                                Text("Ouvrir Livria Store")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)
                                Spacer()
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundStyle(MarketplacePalette.primary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.openLivriaSocialApp()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundStyle(MarketplacePalette.coral)
                                Text("Ouvrir Livria Social")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)
                                Spacer()
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundStyle(MarketplacePalette.coral)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.openLivriaStoreTroc()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(Color(red: 0.85, green: 0.52, blue: 0.05))
                                Text("Ouvrir Les Trocs dans Livria Store")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)
                                Spacer()
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundStyle(Color(red: 0.85, green: 0.52, blue: 0.05))
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.isShowingTermsReviewSheet = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundStyle(MarketplacePalette.primary)
                                Text("Relire les Conditions d'Utilisation (CGU / CGV)")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(MarketplacePalette.inkMuted)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                        }
                        .buttonStyle(.plain)
                    }
                    .marketplaceCard()
                }
            }
            .padding(16)
        }
        .background(MarketplacePalette.background.ignoresSafeArea())
    }
}

// MARK: - Conditions Générales d'Utilisation (CGU / CGV) à Accepter au 1er Lancement + Relecture dans les Paramètres

public struct MarketplaceFirstLaunchTermsGateView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @State private var hasCheckedAgreement: Bool = false

    public var body: some View {
        ZStack {
            MarketplacePalette.background.ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image("LivriaMarketplaceLogoHorizontal")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)

                    Text("Conditions Générales d'Utilisation & de Vente")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                        .multilineTextAlignment(.center)

                    Text("Veuillez lire et accepter les conditions d'utilisation de Livria Marketplace avant de continuer.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)

                ScrollView {
                    MarketplaceLegalTermsContentText()
                        .padding(16)
                }
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(MarketplacePalette.border, lineWidth: 1))
                .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    Toggle(isOn: $hasCheckedAgreement) {
                        Text("J'ai lu et j'accepte sans réserve les Conditions Générales d'Utilisation (CGU / CGV) de Livria Marketplace et la Politique de Confidentialité Viple Live ID.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MarketplacePalette.ink)
                    }
                    .tint(MarketplacePalette.primary)

                    Button {
                        store.acceptTermsOfUse()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Accepter et entrer sur Livria Marketplace")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(hasCheckedAgreement ? AnyShapeStyle(MarketplacePalette.heroGradient) : AnyShapeStyle(Color.gray.opacity(0.35)))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!hasCheckedAgreement)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

public struct MarketplaceTermsReviewSheetView: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ScrollView {
                MarketplaceLegalTermsContentText()
                    .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("CGU / CGV Livria Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

public struct MarketplaceLegalTermsContentText: View {
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                Text("1. Éditeur & Objet de Livria Marketplace")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Livria Marketplace est une application éditée par la librairie en ligne Livria (écosystème Viple). Elle permet d'acheter et de revendre entre particuliers et passionnés dans 4 rubriques strictement encadrées, par ordre de priorité : 1° les Livres, 2° les CD & DVD/Blu-Ray, 3° les Accessoires (tasses, goodies, affiches, marque-pages), et 4° les Vêtements.")

                Text("2. Commission Unique de 1,00 € & Livraison 0,00 €")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Pour chaque transaction réalisée sur Livria Marketplace, une commission fixe unique de 1,00 € TTC intitulée « Garantie et Maintien du service » est appliquée pour couvrir la sécurisation du paiement (Apple Pay / PayPal), la protection acheteur/vendeur et la maintenance de l'infrastructure. Les frais de livraison demeurent toujours à 0,00 €.")

                Text("3. Programme Viple Taker (Point Relais Particulier — 1,00 € / colis)")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Tout membre majeur vérifié peut déposer une demande pour devenir Viple Taker (point relais particulier), soumise à validation dans l'espace /admin de Livria. Le Viple Taker réceptionne les colis livrés par Viple Delivery (service interne) ou par UPS (une étiquette Viple Delivery y est apposée), scanne le code-barres via l'application « Looby Taker » pour confirmer la réception, programme le créneau de remise avec l'acheteur et perçoit 1,00 € par colis remis, exactement comme les commerces points relais classiques.")

                Text("4. Messagerie, Modération & Suppression de Compte")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Les échanges dans la messagerie Livria Marketplace (textes, offres, photos, GIFs, messages vocaux) doivent rester courtois et conformes à la loi. Conformément aux directives de l'App Store et au RGPD, vous pouvez supprimer définitivement votre compte Viple Live ID à tout moment depuis l'onglet Mon Profil > Supprimer mon compte.")
            }
            .font(.system(size: 12.5))
            .foregroundStyle(MarketplacePalette.ink)
        }
    }
}

// MARK: - Feuille d'Authentification Viple Live ID + Sign in with Apple

public struct MarketplaceAuthSheetView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isRegisterMode: Bool = false
    @State private var emailOrUsername: String = ""
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var password: String = ""

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image("LivriaMarketplaceLogoHorizontal")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .padding(.top, 10)

                    Text(isRegisterMode ? "Créer mon compte Viple Live ID" : "Connexion Viple Live ID")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)

                    Text("Votre compte Viple Live ID fonctionne automatiquement sur Livria Store, Livria Social et Livria Marketplace.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        if isRegisterMode {
                            TextField("Pseudo (ex: claire.lecture)", text: $username)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                            TextField("Nom affiché (ex: Claire Lecture)", text: $displayName)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                        }

                        TextField("Email ou Pseudo Viple Live ID", text: $emailOrUsername)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))

                        SecureField("Mot de passe", text: $password)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))

                        Button {
                            Task {
                                if isRegisterMode {
                                    _ = await store.registerAccount(
                                        username: username,
                                        displayName: displayName,
                                        email: emailOrUsername,
                                        password: password
                                    )
                                } else {
                                    _ = await store.signIn(
                                        emailOrUsername: emailOrUsername,
                                        password: password
                                    )
                                }
                            }
                        } label: {
                            Text(isRegisterMode ? "Créer mon compte Viple Live ID" : "Se connecter à Livria Marketplace")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(MarketplacePalette.heroGradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            if case .success(let auth) = result,
                               let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                                let name = [cred.fullName?.givenName, cred.fullName?.familyName]
                                    .compactMap { $0 }
                                    .joined(separator: " ")
                                Task {
                                    await store.signInWithApple(
                                        appleUserId: cred.user,
                                        email: cred.email,
                                        fullName: name.isEmpty ? nil : name,
                                        identityToken: cred.identityToken.flatMap { String(data: $0, encoding: .utf8) }
                                    )
                                }
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .marketplaceCard()

                    Button {
                        withAnimation {
                            isRegisterMode.toggle()
                        }
                    } label: {
                        Text(isRegisterMode ? "Déjà un compte Viple Live ID ? Se connecter" : "Pas encore de compte ? Créer un compte Viple Live ID")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
