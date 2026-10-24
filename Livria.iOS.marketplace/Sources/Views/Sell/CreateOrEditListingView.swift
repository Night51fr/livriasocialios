import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Assistant Étape par Étape de Création / Modification / Suppression d'Annonce (Avec Upload Multi-Photos & Recadrage)

public struct CreateOrEditListingView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    public var existingListing: MarketplaceListing? = nil

    @State private var currentStep: Int = 1

    // Étape 1 : Rubrique (1. Livres, 2. CD/DVD, 3. Accessoires, 4. Vêtements) & Scan ISBN
    @State private var selectedCategory: MarketplaceCategory = .books
    @State private var selectedSubcategory: String = "Romans & Littérature"
    @State private var isbnCode: String = ""
    @State private var isShowingISBNScanner: Bool = false

    // Étape 2 : Upload Multi-Photos + Recadrage Photo
    @State private var uploadedPhotoUrls: [String] = []
    @State private var multiPhotoItems: [PhotosPickerItem] = []
    @State private var singleCropPickerItem: PhotosPickerItem? = nil
    @State private var imagePendingCrop: UIImage? = nil
    @State private var isShowingImageCropper: Bool = false
    @State private var isUploadingMedia: Bool = false

    // Étape 3 : Titre, Sous-titre, Auteur/Artiste, Éditeur/Marque, Taille, État, Description
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var authorOrArtist: String = ""
    @State private var publisherOrBrand: String = ""
    @State private var releaseYear: String = "2024"
    @State private var clothingSize: String = "M"
    @State private var selectedCondition: String = MarketplaceItemCondition.likeNew.rawValue
    @State private var descriptionText: String = ""

    // Étape 4 : Prix, Commission Livria 1,00 € ("Garantie et Maintien du service") & Livraison 0,00 €
    @State private var priceString: String = "9.50"
    @State private var retailPriceString: String = "19.90"
    @State private var allowsOffers: Bool = true
    @State private var showingDeleteAlert: Bool = false

    public init(existingListing: MarketplaceListing? = nil) {
        self.existingListing = existingListing
    }

    private var numericPrice: Double {
        max(1.0, Double(priceString.replacingOccurrences(of: ",", with: ".")) ?? 9.50)
    }

    private var numericRetailPrice: Double? {
        Double(retailPriceString.replacingOccurrences(of: ",", with: "."))
    }

    public var body: some View {
        NavigationStack {
            if !store.isAuthenticated {
                MarketplaceVipleLiveIDRequiredGateView(
                    featureTitle: "Vendre sur Livria Marketplace",
                    featureSubtitle: "La publication, la modification et la gestion de vos annonces (Livres, CD/DVD, Accessoires et Vêtements) sont réservées aux membres connectés avec Viple Live ID.",
                    icon: "plus.rectangle.on.folder.fill"
                )
                .environmentObject(store)
                .navigationTitle("Vendre sur Livria Marketplace")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        wizardStepHeader

                        if existingListing == nil, let draft = store.savedListingDraft {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.badge.clock")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Brouillon enregistré : « \(draft.title.isEmpty ? "Annonce en cours" : draft.title) »")
                                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(MarketplacePalette.ink)
                                    Text("Reprenez votre saisie là où vous l'aviez laissée.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(MarketplacePalette.inkMuted)
                                }
                                Spacer()
                                Button("Restaurer") {
                                    restoreFromDraft(draft)
                                }
                                .font(.system(size: 11.5, weight: .black, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(MarketplacePalette.primary))
                                .foregroundStyle(.white)

                                Button {
                                    store.clearListingDraft()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(MarketplacePalette.inkMuted)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.primarySoft.opacity(0.6)))
                        }

                        switch currentStep {
                        case 1:
                            step1CategoryAndISBNView
                        case 2:
                            step2PhotosUploadAndCropperView
                        case 3:
                            step3DetailsAndConditionView
                        default:
                            step4PricingAndReviewView
                        }

                        wizardNavigationFooter

                        if let existingListing {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Supprimer définitivement cette annonce")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.14)))
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(MarketplacePalette.background.ignoresSafeArea())
                .navigationTitle(existingListing != nil ? "Modifier mon annonce" : "Vendre sur Livria Marketplace")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            populateIfEditing()
            }
            .onChange(of: multiPhotoItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    await handleMultiPhotosSelection(newItems)
                }
            }
            .onChange(of: singleCropPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    #if canImport(UIKit)
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        await MainActor.run {
                            imagePendingCrop = uiImg
                            isShowingImageCropper = true
                            singleCropPickerItem = nil
                        }
                    }
                    #endif
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $isShowingImageCropper) {
                if let img = imagePendingCrop {
                    MarketplaceImageCropperSheet(
                        image: img,
                        title: "Recadrer la photo de l'annonce",
                        isCircularMask: false,
                        onCropped: { croppedData in
                            isShowingImageCropper = false
                            Task {
                                await uploadSingleCroppedListingPhoto(croppedData)
                            }
                        },
                        onCancel: {
                            isShowingImageCropper = false
                        }
                    )
                }
            }
            .sheet(isPresented: $isShowingISBNScanner) {
                MarketplaceBarcodeScannerSheet { scannedISBN in
                    Task {
                        await applyISBNLookup(scannedISBN)
                    }
                }
            }
            #endif
            .alert("Supprimer votre annonce ?", isPresented: $showingDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    if let existingListing {
                        Task {
                            await store.deleteListing(existingListing)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Votre annonce sera retirée de Livria Marketplace.")
            }
    }

    // MARK: - Barre de Progression des 4 Étapes (1, 2, 3, 4 en haut et mot entier en dessous)

    private var wizardStepHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .top) {
                // Ligne horizontale de liaison derrière les cercles 1 - 2 - 3 - 4
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { step in
                        Rectangle()
                            .fill(step < currentStep ? MarketplacePalette.primary : MarketplacePalette.border)
                            .frame(height: 2.5)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 38)
                .padding(.top, 15)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(1...4, id: \.self) { step in
                        let isDone = step < currentStep
                        let isCurrent = step == currentStep
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentStep = step
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(isCurrent || isDone ? MarketplacePalette.primary : MarketplacePalette.primarySoft)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                    if isDone {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("\(step)")
                                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                                            .foregroundStyle(isCurrent ? .white : MarketplacePalette.primary)
                                    }
                                }

                                Text(stepTitle(for: step))
                                    .font(.system(size: 12, weight: isCurrent ? .black : .semibold, design: .rounded))
                                    .foregroundStyle(isCurrent ? MarketplacePalette.primary : (isDone ? MarketplacePalette.ink : MarketplacePalette.inkMuted))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text(stepSubtitle(for: currentStep))
                .font(.system(size: 12))
                .foregroundStyle(MarketplacePalette.inkMuted)
        }
        .marketplaceCard(padding: 14)
    }

    private func stepTitle(for step: Int) -> String {
        switch step {
        case 1: return "Rubrique"
        case 2: return "Photos"
        case 3: return "Description"
        default: return "Prix & Envoi"
        }
    }

    private func stepSubtitle(for step: Int) -> String {
        switch step {
        case 1:
            return "Étape 1/4 : Choisissez la rubrique (Livres en priorité, CD/DVD, Accessoires ou Vêtements) ou scannez un ISBN."
        case 2:
            return "Étape 2/4 : Importez et recadrez vos photos d'annonce. Les acheteurs pourront les swiper directement depuis le flux !"
        case 3:
            return "Étape 3/4 : Précisez le titre, l'état de l'article et ses caractéristiques."
        default:
            return "Étape 4/4 : Fixez votre prix. Livria applique uniquement 1,00 € de Garantie et Maintien du service et 0,00 € de livraison."
        }
    }

    // MARK: - Étape 1 : Choix de la Rubrique & Scan ISBN

    private var step1CategoryAndISBNView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dans quelle rubrique souhaitez-vous vendre ?")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)

            ForEach(MarketplaceCategory.orderedCreationCategories) { cat in
                let isSelected = selectedCategory == cat
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedCategory = cat
                        selectedSubcategory = cat.subcategories.dropFirst().first ?? "Tous"
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(MarketplacePalette.heroGradient) : AnyShapeStyle(MarketplacePalette.primarySoft))
                                .frame(width: 48, height: 48)
                            Image(systemName: cat.icon)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(isSelected ? .white : MarketplacePalette.primary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(cat.title)
                                    .font(.system(size: 15.5, weight: .black, design: .rounded))
                                    .foregroundStyle(MarketplacePalette.ink)
                                if let badge = cat.priorityBadge {
                                    Text(badge)
                                        .font(.system(size: 9.5, weight: .black))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(MarketplacePalette.primarySoft))
                                        .foregroundStyle(MarketplacePalette.primary)
                                }
                            }
                            Text(cat.subtitle)
                                .font(.system(size: 11.5))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(isSelected ? MarketplacePalette.primary : MarketplacePalette.border)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? MarketplacePalette.primarySoft.opacity(0.45) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? MarketplacePalette.primary : MarketplacePalette.border, lineWidth: isSelected ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Sous-rubrique
            VStack(alignment: .leading, spacing: 8) {
                Text("Sous-rubrique \(selectedCategory.title)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedCategory.subcategories.filter { $0 != "Tous" }, id: \.self) { sub in
                            let isSub = selectedSubcategory == sub
                            Button {
                                selectedSubcategory = sub
                            } label: {
                                Text(sub)
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(isSub ? MarketplacePalette.primary : Color.white))
                                    .overlay(Capsule().stroke(isSub ? MarketplacePalette.primary : MarketplacePalette.border, lineWidth: 1))
                                    .foregroundStyle(isSub ? .white : MarketplacePalette.ink)
                            }
                        }
                    }
                }
            }
            .marketplaceCard()

            // Si Livre : Scanner ISBN Automatique
            if selectedCategory == .books {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3.bold())
                            .foregroundStyle(MarketplacePalette.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gain de temps : Scan ISBN Livria")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                            Text("Scannez le code-barres au dos du livre pour pré-remplir automatiquement le titre, l'auteur, l'éditeur et la couverture.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                        }
                    }

                    HStack(spacing: 10) {
                        TextField("ISBN-13 (ex: 9782070368228)", text: $isbnCode)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))

                        Button {
                            Task {
                                await applyISBNLookup(isbnCode)
                            }
                        } label: {
                            Text("Rechercher ISBN")
                                .font(.system(size: 12.5, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primarySoft))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                    }

                    Button {
                        isShowingISBNScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text("Ouvrir le scanner ISBN avec l'appareil photo")
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MarketplacePalette.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .marketplaceCard()
            }
        }
    }

    // MARK: - Étape 2 : Upload Multi-Photos & Studio de Recadrage

    private var step2PhotosUploadAndCropperView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Photos de votre annonce (\(uploadedPhotoUrls.count)/8)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text("Ajoutez plusieurs angles (couverture, dos, tranche, intérieur). Les acheteurs peuvent les swiper directement depuis les cards !")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
                Spacer()
                if isUploadingMedia {
                    ProgressView()
                        .tint(MarketplacePalette.primary)
                }
            }
            .marketplaceCard()

            // Boutons d'import depuis la galerie iPhone (Multi-photos + Photo recadrée)
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $multiPhotoItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 22, weight: .bold))
                        Text("Importer plusieurs photos")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        Text("Jusqu'à 8 photos d'un coup")
                            .font(.system(size: 10))
                            .opacity(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                PhotosPicker(
                    selection: $singleCropPickerItem,
                    matching: .images
                ) {
                    VStack(spacing: 6) {
                        Image(systemName: "crop")
                            .font(.system(size: 22, weight: .bold))
                        Text("Importer & Recadrer")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        Text("Avec outil de zoom & cadrage")
                            .font(.system(size: 10))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(MarketplacePalette.primary, lineWidth: 1.5))
                    .foregroundStyle(MarketplacePalette.primary)
                }
            }

            // Grille des photos ajoutées avec suppression & choix de la photo principale
            if uploadedPhotoUrls.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(MarketplacePalette.primary)
                    Text("Aucune photo importée pour le moment")
                        .font(.system(size: 14, weight: .bold))
                    Text("Utilisez les boutons ci-dessus pour importer et recadrer les photos réelles de votre article depuis votre iPhone.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .marketplaceCard(padding: 20)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Aperçu de vos photos (glissez ou réordonnez) :")
                        .font(.system(size: 13, weight: .bold))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(uploadedPhotoUrls.enumerated()), id: \.offset) { index, url in
                                ZStack(alignment: .topTrailing) {
                                    MarketplaceSmartImage(urlString: url, contentMode: .fill)
                                        .frame(width: 135, height: 155)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(index == 0 ? MarketplacePalette.primary : MarketplacePalette.border, lineWidth: index == 0 ? 2.5 : 1)
                                        )

                                    VStack {
                                        HStack {
                                            if index == 0 {
                                                Text("N°1 Couverture")
                                                    .font(.system(size: 9, weight: .black))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(Capsule().fill(MarketplacePalette.primary))
                                                    .foregroundStyle(.white)
                                            } else {
                                                Button {
                                                    let item = uploadedPhotoUrls.remove(at: index)
                                                    uploadedPhotoUrls.insert(item, at: 0)
                                                } label: {
                                                    Text("Mettre N°1")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 3)
                                                        .background(Capsule().fill(Color.black.opacity(0.7)))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            Spacer()
                                            Button {
                                                uploadedPhotoUrls.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(.white)
                                                    .background(Circle().fill(Color.red))
                                            }
                                        }
                                        .padding(6)
                                        Spacer()
                                    }
                                    .frame(width: 135, height: 155)
                                }
                            }
                        }
                    }
                }
                .marketplaceCard()
            }
        }
    }

    // MARK: - Étape 3 : Titre, État & Caractéristiques Détaillées

    private var step3DetailsAndConditionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Titre de l'annonce *")
                    .font(.system(size: 13, weight: .bold))
                TextField("Ex : Dune — Coffret Collector Tomes 1 à 3", text: $title)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sous-titre / Précision d'édition")
                    .font(.system(size: 13, weight: .bold))
                TextField("Ex : Édition Collector reliée Robert Laffont", text: $subtitle)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedCategory == .books ? "Auteur" : (selectedCategory == .cddvd ? "Artiste / Réalisateur" : "Créateur / Collection"))
                        .font(.system(size: 12.5, weight: .bold))
                    TextField("Nom...", text: $authorOrArtist)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedCategory == .books ? "Maison d'édition" : "Marque / Label")
                        .font(.system(size: 12.5, weight: .bold))
                    TextField("Éditeur / Marque...", text: $publisherOrBrand)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                }
            }

            if selectedCategory == .clothing {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Taille du vêtement")
                        .font(.system(size: 13, weight: .bold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["XS", "S", "M", "L", "XL", "XXL", "Taille Unique"], id: \.self) { sz in
                                Button {
                                    clothingSize = sz
                                } label: {
                                    Text(sz)
                                        .font(.system(size: 12.5, weight: .bold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(clothingSize == sz ? MarketplacePalette.primary : MarketplacePalette.background))
                                        .foregroundStyle(clothingSize == sz ? .white : MarketplacePalette.ink)
                                }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("État de l'article *")
                    .font(.system(size: 13, weight: .bold))
                ForEach(MarketplaceItemCondition.allCases) { cond in
                    let isSelected = selectedCondition == cond.rawValue
                    Button {
                        selectedCondition = cond.rawValue
                    } label: {
                        HStack {
                            Text(cond.rawValue)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(MarketplacePalette.ink)
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? MarketplacePalette.primary : MarketplacePalette.border)
                        }
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? MarketplacePalette.primarySoft : MarketplacePalette.background))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Description complète *")
                    .font(.system(size: 13, weight: .bold))
                TextField("Décrivez l'état des pages, du boîtier ou du tissu, l'édition, etc...", text: $descriptionText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }
        }
        .marketplaceCard()
    }

    // MARK: - Étape 4 : Prix, Commission Livria 1,00 € ("Garantie et Maintien du service") & Livraison 0,00 €

    private var step4PricingAndReviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fixez votre prix de vente")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Votre prix net vendeur (€) *")
                            .font(.system(size: 12.5, weight: .bold))
                        TextField("Ex: 12.00", text: $priceString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Prix neuf indicatif (€)")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                        TextField("Ex: 22.90", text: $retailPriceString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                    }
                }

                Toggle(isOn: $allowsOffers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Autoriser les acheteurs à faire une offre")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Active le bouton icône « Faire une offre » sur votre annonce")
                            .font(.system(size: 11.5))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                    }
                }
                .tint(MarketplacePalette.primary)
            }
            .marketplaceCard()

            // Récapitulatif transparent de la Commission 1,00 € Livria & 0,00 € Livraison
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(MarketplacePalette.primary)
                    Text("Transparence Tarifaire Livria Marketplace")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Ce que vous gagnez (100% reversé)")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(String(format: "%.2f €", numericPrice))
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(MarketplacePalette.green)
                    }
                    HStack {
                        Text("Commission Livria (« Garantie et Maintien du service »)")
                            .font(.system(size: 13))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                        Spacer()
                        Text("1,00 €")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }
                    HStack {
                        Text("Frais de livraison (UPS / Viple Taker / Viple Delivery)")
                            .font(.system(size: 13))
                            .foregroundStyle(MarketplacePalette.inkMuted)
                        Spacer()
                        Text("0,00 € (Toujours offerts)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MarketplacePalette.green)
                    }
                    Divider()
                    HStack {
                        Text("Prix total payé par l'acheteur")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Spacer()
                        Text(String(format: "%.2f €", numericPrice + 1.00))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.primary)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }
            .marketplaceCard()
        }
    }

    // MARK: - Boutons Précédent / Suivant / Publier

    private var wizardNavigationFooter: some View {
        HStack(spacing: 12) {
            if currentStep > 1 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentStep -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Étape précédente")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(MarketplacePalette.border, lineWidth: 1))
                    .foregroundStyle(MarketplacePalette.ink)
                }
            }

            if currentStep < 4 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentStep += 1
                    }
                } label: {
                    HStack {
                        Text("Continuer (\(currentStep)/4)")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            } else {
                Button {
                    Task {
                        await submitListing()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                        Text(existingListing != nil ? "Enregistrer les modifications" : "Publier mon annonce sur Livria")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        if existingListing == nil {
            Button {
                let draft = MarketplaceListingDraft(
                    categoryRaw: selectedCategory.rawValue,
                    subcategory: selectedSubcategory,
                    title: title,
                    subtitle: subtitle,
                    descriptionText: descriptionText,
                    condition: selectedCondition,
                    priceString: priceString,
                    originalPriceString: retailPriceString,
                    isbnInput: isbnCode,
                    authorOrArtist: authorOrArtist,
                    publisherOrBrand: publisherOrBrand,
                    releaseYear: releaseYear,
                    clothingSize: clothingSize,
                    photos: uploadedPhotoUrls
                )
                store.saveListingDraft(draft)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text("Sauvegarder cette annonce en brouillon local")
                }
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primarySoft.opacity(0.5)))
                .foregroundStyle(MarketplacePalette.primary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers & Actions

    private func restoreFromDraft(_ draft: MarketplaceListingDraft) {
        selectedCategory = MarketplaceCategory(rawValue: draft.categoryRaw) ?? .books
        selectedSubcategory = draft.subcategory
        title = draft.title
        subtitle = draft.subtitle
        descriptionText = draft.descriptionText
        selectedCondition = draft.condition
        priceString = draft.priceString
        retailPriceString = draft.originalPriceString
        isbnCode = draft.isbnInput
        authorOrArtist = draft.authorOrArtist
        publisherOrBrand = draft.publisherOrBrand
        releaseYear = draft.releaseYear
        clothingSize = draft.clothingSize
        uploadedPhotoUrls = draft.photos
        store.showToast("Brouillon restauré !")
    }

    private func populateIfEditing() {
        guard let item = existingListing else { return }
        selectedCategory = item.parsedCategory
        selectedSubcategory = item.subcategory
        isbnCode = item.isbn ?? ""
        uploadedPhotoUrls = item.photos
        title = item.title
        subtitle = item.subtitle
        authorOrArtist = item.authorOrArtist ?? ""
        publisherOrBrand = item.publisherOrBrand ?? ""
        releaseYear = item.releaseYear ?? "2024"
        clothingSize = item.clothingSize ?? "M"
        selectedCondition = item.condition
        descriptionText = item.description
        priceString = String(format: "%.2f", item.price)
        if let retail = item.originalRetailPrice {
            retailPriceString = String(format: "%.2f", retail)
        }
        allowsOffers = item.allowsOffers
    }

    private func applyISBNLookup(_ rawISBN: String) async {
        let clean = rawISBN.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            store.showToast("Veuillez saisir ou scanner un numéro ISBN.")
            return
        }
        guard let info = await store.lookupBookByISBNAsync(clean) else {
            store.showToast("Aucun livre trouvé pour l'ISBN \(clean). Vous pouvez remplir les champs manuellement.")
            return
        }
        isbnCode = info.isbn
        selectedCategory = .books
        selectedSubcategory = info.subcategory
        title = info.title
        subtitle = info.publisher.isEmpty ? info.author : "\(info.author) • \(info.publisher)"
        authorOrArtist = info.author
        publisherOrBrand = info.publisher
        releaseYear = info.releaseYear
        if !info.summary.isEmpty {
            descriptionText = info.summary
        }
        priceString = String(format: "%.2f", info.suggestedPrice)
        retailPriceString = String(format: "%.2f", info.originalRetailPrice)
        if !info.coverUrl.isEmpty && !uploadedPhotoUrls.contains(info.coverUrl) {
            uploadedPhotoUrls.insert(info.coverUrl, at: 0)
        }
        store.showToast("Livre reconnu via ISBN \(info.isbn) !")
    }

    private func handleMultiPhotosSelection(_ items: [PhotosPickerItem]) async {
        isUploadingMedia = true
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                #if canImport(UIKit)
                let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data
                #else
                let compressed = data
                #endif
                if let remoteUrl = await LivriaMarketplaceAPIClient.shared.uploadMarketplaceMedia(
                    data: compressed,
                    fileName: "listing_\(Int.random(in: 1000...9999)).jpg",
                    mimeType: "image/jpeg"
                ) {
                    uploadedPhotoUrls.append(remoteUrl)
                } else {
                    uploadedPhotoUrls.append("data:image/jpeg;base64,\(compressed.base64EncodedString())")
                }
            }
        }
        multiPhotoItems.removeAll()
        isUploadingMedia = false
        store.showToast("Photos importées dans votre annonce !")
    }

    private func uploadSingleCroppedListingPhoto(_ jpegData: Data) async {
        isUploadingMedia = true
        if let remoteUrl = await LivriaMarketplaceAPIClient.shared.uploadMarketplaceMedia(
            data: jpegData,
            fileName: "cropped_listing_\(Int.random(in: 1000...9999)).jpg",
            mimeType: "image/jpeg"
        ) {
            uploadedPhotoUrls.insert(remoteUrl, at: 0)
        } else {
            uploadedPhotoUrls.insert("data:image/jpeg;base64,\(jpegData.base64EncodedString())", at: 0)
        }
        isUploadingMedia = false
        store.showToast("Photo recadrée ajoutée en couverture !")
    }

    private func submitListing() async {
        guard store.isAuthenticated else {
            store.showToast("Connectez-vous avec votre compte Viple Live ID pour publier une annonce.")
            store.isShowingAuthSheet = true
            return
        }

        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalTitle.isEmpty else {
            store.showToast("Veuillez saisir le titre de votre annonce à l'étape 3.")
            currentStep = 3
            return
        }

        guard !uploadedPhotoUrls.isEmpty else {
            store.showToast("Veuillez importer au moins une photo de votre article à l'étape 2.")
            currentStep = 2
            return
        }

        let finalDesc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? finalTitle
            : descriptionText

        _ = await store.publishOrUpdateListing(
            existingId: existingListing?.id,
            title: finalTitle,
            subtitle: subtitle,
            description: finalDesc,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            condition: selectedCondition,
            price: numericPrice,
            originalRetailPrice: numericRetailPrice,
            photos: uploadedPhotoUrls,
            isbn: selectedCategory == .books ? isbnCode : nil,
            authorOrArtist: authorOrArtist,
            publisherOrBrand: publisherOrBrand,
            releaseYear: releaseYear,
            clothingSize: selectedCategory == .clothing ? clothingSize : nil,
            allowsOffers: allowsOffers
        )

        if existingListing != nil {
            store.editingListing = nil
            dismiss()
        } else {
            // Réinitialise et retourne sur l'explorateur
            store.clearListingDraft()
            currentStep = 1
            title = ""
            subtitle = ""
            descriptionText = ""
            uploadedPhotoUrls = []
            store.selectedTab = .explore
        }
    }
}
