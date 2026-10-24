import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Messagerie Livria Marketplace (Identique à Livria Social, mais avec EN 1ER L'ANNONCE et EN DESSOUS EN PLUS PETIT LE PSEUDO)

public struct MarketplaceMessagesView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @State private var searchConversationQuery: String = ""
    @State private var selectedConversation: MarketplaceConversationPreview? = nil

    public init() {}

    private var filteredConversations: [MarketplaceConversationPreview] {
        let q = searchConversationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.conversations }
        return store.conversations.filter {
            $0.listingTitle.localizedCaseInsensitiveContains(q) ||
            $0.otherUsername.localizedCaseInsensitiveContains(q) ||
            $0.otherDisplayName.localizedCaseInsensitiveContains(q) ||
            $0.lastMessagePreview.localizedCaseInsensitiveContains(q)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // En-tête Messagerie
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Messagerie & Offres Livria")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundStyle(MarketplacePalette.ink)
                                Text("Échangez des messages, photos, GIFs, notes vocales et offres de prix")
                                    .font(.system(size: 12))
                                    .foregroundStyle(MarketplacePalette.inkMuted)
                            }
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(MarketplacePalette.primary)
                            TextField("Rechercher par annonce ou par @pseudo...", text: $searchConversationQuery)
                                .font(.system(size: 13.5))
                        }
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                    }
                    .marketplaceCard()

                    // Liste des conversations :
                    // En 1er l'ANNONCE (en grand et gras), et juste en dessous en plus petit le PSEUDO !
                    ForEach(filteredConversations) { conv in
                        Button {
                            selectedConversation = conv
                        } label: {
                            MarketplaceConversationRow(conversation: conv)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedConversation) { conv in
                MarketplaceChatThreadView(conversation: conv)
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Ligne de Conversation : 1. L'Annonce en Premier • 2. Juste en Dessous en Plus Petit le Pseudo

public struct MarketplaceConversationRow: View {
    public let conversation: MarketplaceConversationPreview

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Miniature de l'annonce + pastille avatar du membre en bas à droite
            ZStack(alignment: .bottomTrailing) {
                MarketplaceSmartImage(urlString: conversation.listingPhoto, contentMode: .fill)
                    .frame(width: 66, height: 66)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(MarketplacePalette.border, lineWidth: 1)
                    )

                Circle()
                    .fill(MarketplacePalette.primary)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(conversation.otherDisplayName.prefix(1)).uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 1ER ÉLÉMENT EN HAUT : L'ANNONCE (Titre de l'annonce + Prix)
                HStack(alignment: .top, spacing: 6) {
                    Text(conversation.listingTitle)
                        .font(.system(size: 14.5, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                        .lineLimit(1)

                    Spacer()

                    Text(String(format: "%.2f €", conversation.listingPrice))
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }

                // 2ÈME ÉLÉMENT JUSTE EN DESSOUS EN PLUS PETIT : LE PSEUDO (@pseudo)
                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9.5))
                        .foregroundStyle(MarketplacePalette.primary)
                    Text("@\(conversation.otherUsername)")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.primary)
                    Text("• \(conversation.otherDisplayName) (Niv.\(conversation.otherLevel))")
                        .font(.system(size: 11))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.lastMessageAt)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }

                // Dernier message + badge offre éventuelle
                HStack(spacing: 6) {
                    Text(conversation.lastMessagePreview)
                        .font(.system(size: 12.5, weight: conversation.unreadCount > 0 ? .bold : .regular))
                        .foregroundStyle(conversation.unreadCount > 0 ? MarketplacePalette.ink : MarketplacePalette.inkMuted)
                        .lineLimit(1)

                    Spacer()

                    if let offerPrice = conversation.latestOfferPrice {
                        Text(String(format: "Offre %.2f € (%@)", offerPrice, conversation.latestOfferStatus ?? "En attente"))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(MarketplacePalette.goldSoft))
                            .foregroundStyle(Color(red: 0.65, green: 0.42, blue: 0.02))
                    }

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 10.5, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(MarketplacePalette.coral))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .marketplaceCard(padding: 13, cornerRadius: 18)
    }
}

// MARK: - Fil de Discussion Complet (Même Espace que Livria Social : Texte, Photos iPhone, GIFs Giphy, Vocal .m4a & Offres)

public struct MarketplaceChatThreadView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    public let conversation: MarketplaceConversationPreview

    @State private var messageText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isShowingGifPicker: Bool = false
    @State private var isShowingQuickOfferModal: Bool = false
    @State private var quickOfferString: String = ""

    private var linkedListing: MarketplaceListing {
        store.listings.first(where: { $0.id == conversation.listingId }) ?? MarketplaceListing(
            id: conversation.listingId,
            title: conversation.listingTitle,
            subtitle: "Annonce Livria Marketplace",
            description: "Article en vente sur Livria Marketplace.",
            category: conversation.listingCategory,
            subcategory: "Livres",
            condition: "Comme neuf",
            price: conversation.listingPrice,
            photos: [conversation.listingPhoto],
            sellerUsername: conversation.otherUsername,
            sellerDisplayName: conversation.otherDisplayName
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Bandeau d'Annonce épinglé en haut de la conversation avec les 4 boutons icônes !
            pinnedListingBanner

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(store.activeThreadMessages) { msg in
                            MarketplaceMessageBubbleView(
                                message: msg,
                                listing: linkedListing
                            )
                            .environmentObject(store)
                            .id(msg.id)
                        }
                    }
                    .padding(14)
                }
                .onChange(of: store.activeThreadMessages.count) { _, _ in
                    if let lastId = store.activeThreadMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            composerBar
        }
        .background(MarketplacePalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // En 1er l'annonce, et juste en dessous en plus petit le pseudo !
                VStack(spacing: 1) {
                    Text(conversation.listingTitle)
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                        .lineLimit(1)
                    Text("@\(conversation.otherUsername) • \(conversation.otherDisplayName)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(MarketplacePalette.primary)
                        .lineLimit(1)
                }
            }
        }
        .task {
            await store.loadMessages(for: conversation)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    #if canImport(UIKit)
                    let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data
                    #else
                    let jpeg = data
                    #endif
                    let url = await LivriaMarketplaceAPIClient.shared.uploadMarketplaceMedia(
                        data: jpeg,
                        fileName: "chat_photo_\(Int.random(in: 1000...9999)).jpg",
                        mimeType: "image/jpeg"
                    ) ?? "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
                    await store.sendMessage(
                        in: conversation,
                        text: "Photo envoyée",
                        imageUrl: url
                    )
                    selectedPhotoItem = nil
                }
            }
        }
        .sheet(isPresented: $isShowingGifPicker) {
            MarketplaceGifPickerSheet { chosenGif in
                Task {
                    await store.sendMessage(
                        in: conversation,
                        text: chosenGif.title,
                        gifUrl: chosenGif.url
                    )
                }
            }
        }
    }

    // MARK: - Bandeau d'Annonce Épinglé avec les 4 Boutons sous Forme de Petites Icônes

    private var pinnedListingBanner: some View {
        HStack(spacing: 10) {
            MarketplaceSmartImage(urlString: linkedListing.photos.first, contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(linkedListing.title)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                    .lineLimit(1)
                Text("@\(conversation.otherUsername) • \(String(format: "%.2f € (+1€ Livria • 0€ port)", linkedListing.price))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MarketplacePalette.primary)
                    .lineLimit(1)
            }

            Spacer()

            // Les 4 Petites Icônes d'Action : Caddie, Faire une offre, Favoris, Partager
            HStack(spacing: 6) {
                Button {
                    store.activeCheckoutAgreedPrice = conversation.latestOfferStatus == "Acceptée" ? conversation.latestOfferPrice : nil
                    store.activeCheckoutListing = linkedListing
                } label: {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(MarketplacePalette.primary))
                        .foregroundStyle(.white)
                }

                Button {
                    store.activeOfferListing = linkedListing
                } label: {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12.5, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }

                Button {
                    store.toggleFavorite(for: linkedListing)
                } label: {
                    Image(systemName: linkedListing.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 12.5, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(MarketplacePalette.background))
                        .foregroundStyle(linkedListing.isFavorited ? MarketplacePalette.coral : MarketplacePalette.ink)
                }

                Button {
                    store.activeShareListing = linkedListing
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(MarketplacePalette.background))
                        .foregroundStyle(MarketplacePalette.ink)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white)
        .overlay(Rectangle().fill(MarketplacePalette.border).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Barre de Saisie Riche (Photo Galerie, GIF Giphy, Message Vocal .m4a, Offre & Texte)

    private var composerBar: some View {
        VStack(spacing: 8) {
            if store.isRecordingVoiceNote {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("Enregistrement vocal en cours... \(store.recordingSeconds)s")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Annuler") {
                        store.cancelVoiceRecording()
                    }
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(MarketplacePalette.inkMuted)

                    Button {
                        Task {
                            await store.stopAndSendVoiceRecording(in: conversation)
                        }
                    } label: {
                        Label("Envoyer", systemImage: "arrow.up.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(MarketplacePalette.primary))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
                .padding(.horizontal, 12)
            }

            HStack(spacing: 8) {
                // Upload Photo depuis l'iPhone
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }

                // Sélecteur GIF Giphy
                Button {
                    isShowingGifPicker = true
                } label: {
                    Text("GIF")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }

                // Faire une offre rapide
                Button {
                    store.activeOfferListing = linkedListing
                } label: {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(MarketplacePalette.goldSoft))
                        .foregroundStyle(Color(red: 0.65, green: 0.42, blue: 0.02))
                }

                // Champ Texte
                TextField("Écrire un message à @\(conversation.otherUsername)...", text: $messageText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(MarketplacePalette.background))
                    .overlay(Capsule().stroke(MarketplacePalette.border, lineWidth: 1))

                // Enregistrement Vocal ou Envoi Texte
                if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        if store.isRecordingVoiceNote {
                            Task { await store.stopAndSendVoiceRecording(in: conversation) }
                        } else {
                            store.startVoiceRecording()
                        }
                    } label: {
                        Image(systemName: store.isRecordingVoiceNote ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(store.isRecordingVoiceNote ? Color.red : MarketplacePalette.primarySoft))
                            .foregroundStyle(store.isRecordingVoiceNote ? .white : MarketplacePalette.primary)
                    }
                } else {
                    Button {
                        let txt = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        messageText = ""
                        Task {
                            await store.sendMessage(in: conversation, text: txt)
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(MarketplacePalette.heroGradient))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Rectangle().fill(MarketplacePalette.border).frame(height: 1), alignment: .top)
        }
    }
}

// MARK: - Bulle de Message (Texte, Photo, GIF Animé, Note Vocale .m4a, ou Carte d'Offre de Prix)

public struct MarketplaceMessageBubbleView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    public let message: MarketplaceDirectMessage
    public let listing: MarketplaceListing

    public var body: some View {
        HStack {
            if message.isFromMe { Spacer(minLength: 45) }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 6) {
                // Carte spéciale si le message contient une Offre de Prix
                if let offerAmount = message.offerAmount {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(MarketplacePalette.primary)
                            Text("OFFRE DE PRIX LIVRIA MARKETPLACE")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.primary)
                            Spacer()
                            Text(message.offerStatus ?? "En attente")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(MarketplacePalette.primarySoft))
                                .foregroundStyle(MarketplacePalette.primary)
                        }

                        Text(String(format: "%.2f €", offerAmount))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        Text("+ 1,00 € Garantie et Maintien du service • 0,00 € Livraison")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MarketplacePalette.green)

                        if !message.text.isEmpty {
                            Text(message.text)
                                .font(.system(size: 12.5))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                        }

                        HStack(spacing: 8) {
                            if (message.offerStatus ?? "En attente") == "En attente" {
                                Button {
                                    Task {
                                        await store.respondToOffer(messageId: message.id, offerId: message.offerId, accept: true)
                                    }
                                } label: {
                                    Text("Accepter")
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(MarketplacePalette.green))
                                        .foregroundStyle(.white)
                                }

                                Button {
                                    Task {
                                        await store.respondToOffer(messageId: message.id, offerId: message.offerId, accept: false)
                                    }
                                } label: {
                                    Text("Décliner")
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(Color.red.opacity(0.14)))
                                        .foregroundStyle(.red)
                                }
                            }

                            Button {
                                store.activeCheckoutAgreedPrice = offerAmount
                                store.activeCheckoutListing = listing
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "cart.badge.plus")
                                    Text("Acheter à \(String(format: "%.2f €", offerAmount))")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(MarketplacePalette.primary))
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(MarketplacePalette.primary, lineWidth: 1.5))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        if let imgUrl = message.imageUrl, !imgUrl.isEmpty {
                            MarketplaceSmartImage(urlString: imgUrl, contentMode: .fill)
                                .frame(width: 210, height: 155)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if let gifUrl = message.gifUrl, !gifUrl.isEmpty {
                            MarketplaceSmartImage(urlString: gifUrl, contentMode: .fill)
                                .frame(width: 200, height: 145)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if let audioUrl = message.audioUrl, !audioUrl.isEmpty {
                            Button {
                                store.togglePlayAudio(url: audioUrl)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: store.currentlyPlayingAudioUrl == audioUrl ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 22))
                                    Text("Message vocal (\(message.audioDurationSeconds ?? 3)s)")
                                        .font(.system(size: 13, weight: .bold))
                                    Image(systemName: "waveform")
                                }
                            }
                        } else if !message.text.isEmpty {
                            Text(message.text)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.isFromMe ? AnyShapeStyle(MarketplacePalette.heroGradient) : AnyShapeStyle(Color.white))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(message.isFromMe ? Color.clear : MarketplacePalette.border, lineWidth: 1)
                    )
                    .foregroundStyle(message.isFromMe ? .white : MarketplacePalette.ink)
                }

                Text(message.sentAtDisplay)
                    .font(.system(size: 10))
                    .foregroundStyle(MarketplacePalette.inkMuted)
            }

            if !message.isFromMe { Spacer(minLength: 45) }
        }
    }
}

// MARK: - Sélecteur de GIFs Animés Giphy

public struct MarketplaceGifPickerSheet: View {
    public let onSelectGif: (MarketplaceGifItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = "lecture"
    @State private var gifs: [MarketplaceGifItem] = []

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    TextField("Rechercher un GIF (lecture, bravo, colis)...", text: $query)
                        .onSubmit {
                            Task { await loadGifs() }
                        }
                    Button("Chercher") {
                        Task { await loadGifs() }
                    }
                    .font(.caption.bold())
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .padding(.horizontal, 16)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(gifs) { gif in
                            Button {
                                onSelectGif(gif)
                                dismiss()
                            } label: {
                                VStack(spacing: 4) {
                                    MarketplaceSmartImage(urlString: gif.url, contentMode: .fill)
                                        .frame(height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(gif.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(MarketplacePalette.ink)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Choisir un GIF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                await loadGifs()
            }
        }
    }

    private func loadGifs() async {
        let found = await LivriaMarketplaceAPIClient.shared.searchGifs(query: query)
        if !found.isEmpty {
            gifs = found
        } else {
            gifs = [
                MarketplaceGifItem(id: "g1", title: "Lecture passionnée 📚", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbW14eHZyZ2R0/NFA61GS9qKZ68/giphy.gif"),
                MarketplaceGifItem(id: "g2", title: "Affaire conclue 🤝", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/l0MYt5jPR6QX5pnqM/giphy.gif"),
                MarketplaceGifItem(id: "g3", title: "Colis en route 📦", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/3o7abKhOpu0NwenH3O/giphy.gif"),
                MarketplaceGifItem(id: "g4", title: "Coup de cœur ✨", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjEx/26u4cqiYI30juCOGY/giphy.gif")
            ]
        }
    }
}
