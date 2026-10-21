import SwiftUI
import PhotosUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Onglet 3 : Messagerie Instantanée Riche (Photos, Vocaux, GIFs, Livres Boutique, Liens)

public struct MessagesView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @State private var memberSearchQuery: String = ""
    @State private var activeRecipient: ConversationRecipientTarget? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Barre de recherche d'un lecteur pour démarrer une discussion
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(LivriaSocialPalette.accent)
                            TextField("Chercher un membre par pseudo ou @handle...", text: $memberSearchQuery)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.white)
                                .onChange(of: memberSearchQuery) { _, newValue in
                                    Task {
                                        await social.searchMembers(query: newValue)
                                    }
                                }
                            if !memberSearchQuery.isEmpty {
                                Button {
                                    memberSearchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(LivriaSocialPalette.textMuted)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )

                        if !memberSearchQuery.isEmpty && !social.searchedMembers.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(social.searchedMembers) { member in
                                    Button {
                                        activeRecipient = ConversationRecipientTarget(
                                            id: member.id,
                                            displayName: member.displayName,
                                            handle: member.handle,
                                            avatarUrl: member.avatarUrl,
                                            accentColor: member.accentColor
                                        )
                                    } label: {
                                        HStack(spacing: 10) {
                                            SocialAvatarRingView(
                                                name: member.displayName,
                                                avatarUrl: member.avatarUrl,
                                                accentHex: member.accentColor,
                                                size: 38
                                            )
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(member.displayName)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(.white)
                                                Text("\(member.handle) • Niv. \(member.level)")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                                            }
                                            Spacer()
                                            Label("Écrire", systemImage: "paperplane.fill")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Capsule().fill(LivriaSocialPalette.primary))
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.05))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .socialCard()

                    // Membres actifs pour lancer rapidement un message privé
                    if !social.topMembers.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DÉMARRER UNE DISCUSSION RAPIDE")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LivriaSocialPalette.textMuted)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(social.topMembers.filter { $0.id != social.currentUser?.id }) { member in
                                        Button {
                                            activeRecipient = ConversationRecipientTarget(
                                                id: member.id,
                                                displayName: member.displayName,
                                                handle: member.handle,
                                                avatarUrl: member.avatarUrl,
                                                accentColor: member.accentColor
                                            )
                                        } label: {
                                            VStack(spacing: 6) {
                                                SocialAvatarRingView(
                                                    name: member.displayName,
                                                    avatarUrl: member.avatarUrl,
                                                    accentHex: member.accentColor,
                                                    size: 52
                                                )
                                                Text(member.displayName)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 72)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .socialCard()
                    }

                    // Liste des conversations actives de l'utilisateur
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("VOS CONVERSATIONS PRIVÉES")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                            Spacer()
                            Text("\(social.conversations.count) fil(s)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LivriaSocialPalette.accent)
                        }

                        if social.conversations.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(LivriaSocialPalette.primary)
                                Text("Aucune conversation ouverte")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("Sélectionnez un lecteur ci-dessus ou recherchez un membre pour échanger des messages, photos, notes vocales, GIFs ou livres Livria Store.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(social.conversations) { conv in
                                Button {
                                    activeRecipient = ConversationRecipientTarget(
                                        id: conv.userId,
                                        displayName: conv.displayName,
                                        handle: conv.handle,
                                        avatarUrl: conv.avatarUrl,
                                        accentColor: conv.accentColor
                                    )
                                } label: {
                                    HStack(spacing: 12) {
                                        SocialAvatarRingView(
                                            name: conv.displayName,
                                            avatarUrl: conv.avatarUrl,
                                            accentHex: conv.accentColor,
                                            size: 48
                                        )

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(conv.displayName)
                                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                                    .foregroundStyle(.white)
                                                Text(conv.handle)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(LivriaSocialPalette.textMuted)
                                                Spacer()
                                                if conv.unreadCount > 0 {
                                                    Text("\(conv.unreadCount)")
                                                        .font(.system(size: 11, weight: .black))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 2)
                                                        .background(Capsule().fill(LivriaSocialPalette.secondary))
                                                }
                                            }

                                            Text(conv.lastMessagePreview)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.82))
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .socialCard()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .socialCustomBackground(
                type: social.currentUser?.pageBackgroundType,
                value: social.currentUser?.pageBackgroundValue
            )
            .navigationTitle("Messagerie Riche")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await social.refreshBootstrap()
            }
            .navigationDestination(item: $activeRecipient) { target in
                ConversationThreadView(
                    otherUserId: target.id,
                    otherDisplayName: target.displayName,
                    otherHandle: target.handle,
                    otherAvatarUrl: target.avatarUrl,
                    otherAccentColor: target.accentColor
                )
            }
        }
    }
}

private struct ConversationRecipientTarget: Identifiable, Hashable, Sendable {
    let id: Int
    let displayName: String
    let handle: String
    let avatarUrl: String
    let accentColor: String
}

// MARK: - Fil de Discussion Riche (Galerie Photo iPhone, Enregistreur Vocal Réel, API GIFs, Livres Boutique & Liens)

public struct ConversationThreadView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    public let otherUserId: Int
    public let otherDisplayName: String
    public let otherHandle: String
    public let otherAvatarUrl: String
    public let otherAccentColor: String

    @State private var messages: [SocialRichMessageItem] = []
    @State private var messageText: String = ""
    @State private var selectedAttachmentType: String = "none" // none, image, voice, gif, book, link
    @State private var attachmentUrl: String = ""
    @State private var attachmentTitle: String = ""
    @State private var selectedBookId: Int = 0
    @State private var isLoadingThread: Bool = true
    @State private var isSendingOrUploading: Bool = false

    // Sélection Photo depuis la Photothèque de l'iPhone (PhotosUI)
    @State private var selectedPhotoPickerItem: PhotosPickerItem? = nil
    @State private var selectedPhotoLocalData: Data? = nil
    @State private var isUploadingPhoto: Bool = false

    // Recherche & Sélection de GIFs animés via API
    @State private var gifSearchQuery: String = ""
    @State private var gifResults: [SocialGifItem] = []
    @State private var selectedGifItem: SocialGifItem? = nil
    @State private var isLoadingGifs: Bool = false

    // Enregistreur vocal réel (AVAudioRecorder)
    @StateObject private var voiceRecorder = SocialVoiceRecorderManager()

    private let gifQuickTags: [(label: String, query: String)] = [
        ("🔥 Tendances", ""),
        ("📚 Lecture", "reading book"),
        ("😂 Rire", "laughing"),
        ("👏 Bravo", "applause bravo"),
        ("❤️ Love", "love heart"),
        ("😮 Wow", "mind blown")
    ]

    public init(
        otherUserId: Int,
        otherDisplayName: String,
        otherHandle: String,
        otherAvatarUrl: String = "",
        otherAccentColor: String = "#8b5cf6"
    ) {
        self.otherUserId = otherUserId
        self.otherDisplayName = otherDisplayName
        self.otherHandle = otherHandle
        self.otherAvatarUrl = otherAvatarUrl
        self.otherAccentColor = otherAccentColor
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    if isLoadingThread {
                        ProgressView("Chargement des messages...")
                            .tint(LivriaSocialPalette.primary)
                            .padding(.top, 32)
                    } else if messages.isEmpty {
                        VStack(spacing: 10) {
                            SocialAvatarRingView(
                                name: otherDisplayName,
                                avatarUrl: otherAvatarUrl,
                                accentHex: otherAccentColor,
                                size: 64
                            )
                            Text("Démarrez la discussion avec \(otherDisplayName)")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Envoyez du texte, une photo de votre galerie iPhone, un vrai message vocal, un GIF animé ou une fiche livre Livria Store.")
                                .font(.system(size: 12))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 36)
                    } else {
                        ForEach(messages) { msg in
                            RichMessageBubbleView(message: msg)
                        }
                    }
                }
                .padding(16)
            }

            // Barre d'outils d'attachement riche
            VStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        attachmentTypeChip("Texte", code: "none", icon: "text.bubble.fill")
                        attachmentTypeChip("Photo", code: "image", icon: "photo.fill")
                        attachmentTypeChip("Note vocale", code: "voice", icon: "waveform")
                        attachmentTypeChip("GIF", code: "gif", icon: "sparkles.tv.fill")
                        attachmentTypeChip("Livre Store", code: "book", icon: "book.closed.fill")
                        attachmentTypeChip("Lien web", code: "link", icon: "link")
                    }
                }

                // 1. PHOTO DEPUIS LA GALERIE DE L'IPHONE (PhotosPicker)
                if selectedAttachmentType == "image" {
                    photoGalleryAttachmentPanel
                }
                // 2. SÉLECTEUR DE GIFs ANIMÉS VIA API (sans demander d'URL)
                else if selectedAttachmentType == "gif" {
                    gifPickerAttachmentPanel
                }
                // 3. ENREGISTREUR DE MESSAGE VOCAL RÉEL (AVAudioRecorder)
                else if selectedAttachmentType == "voice" {
                    voiceRecorderAttachmentPanel
                }
                // 4. LIVRE DU CATALOGUE LIVRIA STORE
                else if selectedAttachmentType == "book" {
                    Picker("Livre Livria Store", selection: $selectedBookId) {
                        Text("Choisir un livre du catalogue...").tag(0)
                        ForEach(social.booksCatalog) { book in
                            Text("\(book.title) (\(String(format: "%.2f €", book.priceTtc)))").tag(book.id)
                        }
                    }
                    .tint(LivriaSocialPalette.gold)
                }
                // 5. LIEN WEB
                else if selectedAttachmentType == "link" {
                    TextField("URL du lien à partager (https://...)", text: $attachmentUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 12))
                        .padding(9)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 10) {
                    TextField("Votre message à \(otherDisplayName)...", text: $messageText)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                        .foregroundStyle(.white)

                    Button {
                        Task { await sendMessageNow() }
                    } label: {
                        if isSendingOrUploading {
                            ProgressView()
                                .tint(LivriaSocialPalette.gold)
                                .frame(width: 34, height: 34)
                        } else {
                            Image(systemName: "paperplane.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(LivriaSocialPalette.brandGradient)
                        }
                    }
                    .disabled(isSendingOrUploading || isUploadingPhoto)
                }
            }
            .padding(12)
            .background(LivriaSocialPalette.cardSurface.opacity(0.96))
        }
        .socialCustomBackground(
            type: social.currentUser?.pageBackgroundType,
            value: social.currentUser?.pageBackgroundValue
        )
        .navigationTitle(otherDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reloadMessages()
        }
        .onChange(of: selectedAttachmentType) { _, newValue in
            if newValue == "gif" && gifResults.isEmpty {
                Task { await performGifSearch(query: "") }
            }
            if newValue != "voice" && voiceRecorder.isRecording {
                voiceRecorder.stopRecording()
            }
        }
        .onChange(of: selectedPhotoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await handlePickedPhoto(item: newItem)
            }
        }
        .onDisappear {
            voiceRecorder.cleanupAll()
        }
    }

    // MARK: - Sous-vues d'attachement (Galerie Photo, API GIFs, Enregistreur Vocal)

    private var photoGalleryAttachmentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedPhotoPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 15, weight: .bold))
                        Text(selectedPhotoLocalData == nil ? "Choisir dans la galerie de l'iPhone" : "Changer de photo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LivriaSocialPalette.brandGradient)
                    )
                }
                .buttonStyle(.plain)

                if isUploadingPhoto {
                    HStack(spacing: 6) {
                        ProgressView()
                            .tint(LivriaSocialPalette.gold)
                        Text("Importation...")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }
                } else if !attachmentUrl.isEmpty {
                    Label("Prête à envoyer", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LivriaSocialPalette.mint)
                }

                Spacer()
            }

            if let data = selectedPhotoLocalData {
                HStack(spacing: 12) {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    }
                    #endif

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photo sélectionnée depuis votre iPhone")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            Button {
                                Task { await sendMessageNow() }
                            } label: {
                                Label("Envoyer la photo", systemImage: "paperplane.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(LivriaSocialPalette.mint))
                                    .foregroundStyle(.black)
                            }
                            .buttonStyle(.plain)
                            .disabled(isUploadingPhoto || isSendingOrUploading)

                            Button(role: .destructive) {
                                selectedPhotoPickerItem = nil
                                selectedPhotoLocalData = nil
                                attachmentUrl = ""
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(7)
                                    .background(Circle().fill(Color.red.opacity(0.22)))
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private var gifPickerAttachmentPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Barre de recherche GIF API
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LivriaSocialPalette.accent)
                TextField("Rechercher un GIF (ex: lecture, bravo, rire, chat)...", text: $gifSearchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white)
                    .onSubmit {
                        Task { await performGifSearch(query: gifSearchQuery) }
                    }
                if !gifSearchQuery.isEmpty {
                    Button {
                        gifSearchQuery = ""
                        Task { await performGifSearch(query: "") }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }
                }
                Button {
                    Task { await performGifSearch(query: gifSearchQuery) }
                } label: {
                    Text("Chercher")
                        .font(.system(size: 11.5, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(LivriaSocialPalette.primary))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

            // Catégories rapides de GIFs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(gifQuickTags, id: \.label) { tag in
                        Button {
                            gifSearchQuery = tag.query
                            Task { await performGifSearch(query: tag.query) }
                        } label: {
                            Text(tag.label)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Grille de résultats GIFs
            if isLoadingGifs {
                HStack {
                    Spacer()
                    ProgressView("Chargement des GIFs...")
                        .tint(LivriaSocialPalette.gold)
                        .font(.system(size: 12))
                    Spacer()
                }
                .padding(.vertical, 14)
            } else if gifResults.isEmpty {
                Text("Aucun GIF trouvé pour cette recherche.")
                    .font(.system(size: 12))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(gifResults) { gif in
                            let isSelected = selectedGifItem?.id == gif.id
                            Button {
                                selectedGifItem = gif
                                attachmentUrl = gif.gifUrl
                                attachmentTitle = gif.title
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    AsyncImage(url: URL(string: gif.previewUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        default:
                                            ZStack {
                                                Color.white.opacity(0.08)
                                                ProgressView()
                                                    .tint(.white)
                                            }
                                        }
                                    }
                                    .frame(width: 112, height: 86)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? LivriaSocialPalette.gold : Color.white.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
                                    )

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(LivriaSocialPalette.gold)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                            .padding(5)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 92)
            }

            if let chosen = selectedGifItem {
                HStack {
                    Image(systemName: "sparkles.tv.fill")
                        .foregroundStyle(LivriaSocialPalette.gold)
                    Text("GIF sélectionné : \(chosen.title.isEmpty ? "GIF animé" : chosen.title)")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        Task { await sendMessageNow() }
                    } label: {
                        Label("Envoyer ce GIF", systemImage: "paperplane.fill")
                            .font(.system(size: 11.5, weight: .black))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(LivriaSocialPalette.gold))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private var voiceRecorderAttachmentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let err = voiceRecorder.errorMessage {
                Text(err)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(LivriaSocialPalette.coral)
            }

            if voiceRecorder.isRecording {
                // Enregistrement vocal en cours
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)

                    Text("Enregistrement... \(voiceRecorder.formattedElapsed)")
                        .font(.system(size: 13.5, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)

                    // Visualiseur d'onde sonore en direct
                    HStack(spacing: 3) {
                        ForEach(0..<voiceRecorder.meterLevels.count, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LivriaSocialPalette.coral)
                                .frame(width: 3.5, height: max(6, CGFloat(voiceRecorder.meterLevels[idx]) * 26))
                        }
                    }
                    .frame(height: 28)

                    Spacer()

                    Button {
                        voiceRecorder.cancelRecording()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)

                    Button {
                        voiceRecorder.stopRecording()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "stop.fill")
                            Text("Terminer")
                                .font(.system(size: 12, weight: .black))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.red))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.16)))
            } else if voiceRecorder.recordedFileURL != nil {
                // Note vocale enregistrée prête à être écoutée ou envoyée
                HStack(spacing: 10) {
                    Button {
                        voiceRecorder.togglePreviewPlayback()
                    } label: {
                        Image(systemName: voiceRecorder.isPlayingPreview ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(LivriaSocialPalette.gold)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Message vocal prêt (\(max(1, voiceRecorder.recordedDurationSec)) sec)")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(.white)
                        Text(voiceRecorder.isPlayingPreview ? "Lecture de l'aperçu en cours..." : "Appuyez sur Play pour réécouter")
                            .font(.system(size: 11))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }

                    Spacer()

                    Button {
                        voiceRecorder.startRecording()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Recommencer l'enregistrement")

                    Button {
                        Task { await sendMessageNow() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "paperplane.fill")
                            Text("Envoyer")
                                .font(.system(size: 12, weight: .black))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(LivriaSocialPalette.mint))
                        .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSendingOrUploading)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
            } else {
                // Prêt à démarrer l'enregistrement
                HStack(spacing: 12) {
                    Button {
                        voiceRecorder.startRecording()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 20))
                            Text("Enregistrer un message vocal")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(LivriaSocialPalette.brandGradient)
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Utilise le microphone de votre iPhone")
                        .font(.system(size: 11.5))
                        .foregroundStyle(LivriaSocialPalette.textMuted)

                    Spacer()
                }
            }
        }
    }

    private func attachmentTypeChip(_ label: String, code: String, icon: String) -> some View {
        let active = selectedAttachmentType == code
        return Button {
            withAnimation {
                selectedAttachmentType = code
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(active ? .white : LivriaSocialPalette.textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(active ? AnyShapeStyle(LivriaSocialPalette.brandGradient) : AnyShapeStyle(Color.white.opacity(0.06)))
            )
        }
        .buttonStyle(.plain)
    }

    private func handlePickedPhoto(item: PhotosPickerItem) async {
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }

        do {
            guard let rawData = try await item.loadTransferable(type: Data.self), !rawData.isEmpty else {
                social.showToast("Impossible de lire la photo sélectionnée.")
                return
            }

            var uploadData = rawData
            #if canImport(UIKit)
            if let img = UIImage(data: rawData), let jpeg = img.jpegData(compressionQuality: 0.82) {
                uploadData = jpeg
            }
            #endif

            selectedPhotoLocalData = uploadData
            if let uploadedUrl = await social.uploadPhotoData(uploadData, fileExtension: "jpg") {
                attachmentUrl = uploadedUrl
            }
        } catch {
            social.showToast("Erreur lors du chargement de la photo : \(error.localizedDescription)")
        }
    }

    private func performGifSearch(query: String) async {
        isLoadingGifs = true
        gifResults = await social.searchGifs(query: query)
        isLoadingGifs = false
    }

    private func reloadMessages() async {
        isLoadingThread = true
        messages = await social.loadConversationThread(otherUserId: otherUserId)
        isLoadingThread = false
    }

    private func sendMessageNow() async {
        if isSendingOrUploading { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        isSendingOrUploading = true
        defer { isSendingOrUploading = false }

        var finalAttachmentType = selectedAttachmentType
        var finalAttachmentUrl = attachmentUrl
        var finalAttachmentTitle = attachmentTitle
        var finalVoiceDuration = 0

        if selectedAttachmentType == "image" {
            if finalAttachmentUrl.isEmpty, let photoData = selectedPhotoLocalData {
                if let uploaded = await social.uploadPhotoData(photoData, fileExtension: "jpg") {
                    finalAttachmentUrl = uploaded
                    attachmentUrl = uploaded
                } else {
                    return
                }
            }
            if finalAttachmentUrl.isEmpty && trimmed.isEmpty {
                social.showToast("Veuillez choisir une photo dans votre galerie.")
                return
            }
            if finalAttachmentUrl.isEmpty {
                finalAttachmentType = "none"
            }
        } else if selectedAttachmentType == "gif" {
            if finalAttachmentUrl.isEmpty, let chosen = selectedGifItem {
                finalAttachmentUrl = chosen.gifUrl
                finalAttachmentTitle = chosen.title
            }
            if finalAttachmentUrl.isEmpty && trimmed.isEmpty {
                social.showToast("Veuillez toucher un GIF dans la liste pour l'envoyer.")
                return
            }
            if finalAttachmentUrl.isEmpty {
                finalAttachmentType = "none"
            }
        } else if selectedAttachmentType == "voice" {
            if voiceRecorder.isRecording {
                voiceRecorder.stopRecording()
            }
            guard let voiceURL = voiceRecorder.recordedFileURL,
                  let voiceData = try? Data(contentsOf: voiceURL),
                  !voiceData.isEmpty else {
                social.showToast("Veuillez enregistrer votre message vocal avant d'envoyer.")
                return
            }
            guard let uploadedVoiceUrl = await social.uploadVoiceData(voiceData, fileExtension: "m4a") else {
                return
            }
            finalAttachmentUrl = uploadedVoiceUrl
            finalVoiceDuration = max(1, voiceRecorder.recordedDurationSec)
        } else if selectedAttachmentType == "book" {
            if selectedBookId <= 0 && trimmed.isEmpty {
                social.showToast("Veuillez sélectionner un livre du catalogue.")
                return
            }
        } else if selectedAttachmentType == "none" {
            guard !trimmed.isEmpty else { return }
        }

        let ok = await social.sendRichMessage(
            recipientId: otherUserId,
            body: trimmed,
            attachmentType: finalAttachmentType,
            attachmentUrl: finalAttachmentUrl,
            attachmentTitle: finalAttachmentTitle,
            bookId: selectedBookId > 0 ? selectedBookId : nil,
            voiceDurationSec: finalVoiceDuration
        )
        if ok {
            messageText = ""
            attachmentUrl = ""
            attachmentTitle = ""
            selectedPhotoPickerItem = nil
            selectedPhotoLocalData = nil
            selectedGifItem = nil
            voiceRecorder.cleanupAll()
            selectedAttachmentType = "none"
            selectedBookId = 0
            await reloadMessages()
        }
    }
}

// MARK: - Enregistreur Vocal Réel (AVAudioRecorder + Aperçu AVAudioPlayer)

@MainActor
public final class SocialVoiceRecorderManager: NSObject, ObservableObject {
    @Published public var isRecording: Bool = false
    @Published public var isPlayingPreview: Bool = false
    @Published public var recordedDurationSec: Int = 0
    @Published public var recordedFileURL: URL? = nil
    @Published public var meterLevels: [Float] = [0.2, 0.35, 0.5, 0.25, 0.6, 0.4, 0.3, 0.55, 0.25, 0.4]
    @Published public var errorMessage: String? = nil

    private var audioRecorder: AVAudioRecorder?
    private var previewPlayer: AVAudioPlayer?
    private var meterTimer: Timer?
    private var recordingStartDate: Date?

    public var formattedElapsed: String {
        let mins = recordedDurationSec / 60
        let secs = recordedDurationSec % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public func startRecording() {
        errorMessage = nil
        stopPreviewPlayback()

        #if os(iOS)
        Task {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = await AVAudioApplication.requestRecordPermission()
            } else {
                granted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                        continuation.resume(returning: allowed)
                    }
                }
            }
            guard granted else {
                self.errorMessage = "Autorisez l'accès au microphone dans les Réglages de votre iPhone pour enregistrer un message vocal."
                return
            }
            self.beginRecordingSession()
        }
        #else
        beginRecordingSession()
        #endif
    }

    private func beginRecordingSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            errorMessage = "Impossible d'initialiser la session audio : \(error.localizedDescription)"
            return
        }
        #endif

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("livriasocial_voice_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            guard recorder.record() else {
                errorMessage = "L'enregistrement vocal n'a pas pu démarrer."
                return
            }
            self.audioRecorder = recorder
            self.recordedFileURL = nil
            self.recordedDurationSec = 0
            self.recordingStartDate = Date()
            self.isRecording = true

            meterTimer?.invalidate()
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateMeters()
                }
            }
        } catch {
            errorMessage = "Erreur d'enregistrement : \(error.localizedDescription)"
        }
    }

    private func updateMeters() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        if let start = recordingStartDate {
            recordedDurationSec = max(1, Int(Date().timeIntervalSince(start).rounded()))
        }
        let power = recorder.averagePower(forChannel: 0) // -160 ... 0 dB
        let normalized = max(0.15, min(1.0, (power + 50.0) / 50.0))
        var next = Array(meterLevels.dropFirst())
        next.append(normalized)
        meterLevels = next
    }

    public func stopRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        guard let recorder = audioRecorder else {
            isRecording = false
            return
        }
        let url = recorder.url
        if let start = recordingStartDate {
            recordedDurationSec = max(1, Int(Date().timeIntervalSince(start).rounded()))
        }
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        recordedFileURL = url
    }

    public func cancelRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        if let recorder = audioRecorder {
            let url = recorder.url
            recorder.stop()
            try? FileManager.default.removeItem(at: url)
        }
        audioRecorder = nil
        isRecording = false
        recordedFileURL = nil
        recordedDurationSec = 0
    }

    public func togglePreviewPlayback() {
        if isPlayingPreview {
            stopPreviewPlayback()
            return
        }
        guard let url = recordedFileURL else { return }
        do {
            #if os(iOS)
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            previewPlayer = player
            isPlayingPreview = true

            let duration = max(0.5, player.duration)
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000) + 200_000_000)
                if self?.isPlayingPreview == true {
                    self?.isPlayingPreview = false
                }
            }
        } catch {
            errorMessage = "Impossible de lire l'aperçu vocal."
        }
    }

    public func stopPreviewPlayback() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPlayingPreview = false
    }

    public func cleanupAll() {
        stopPreviewPlayback()
        cancelRecording()
    }
}

// MARK: - Bulle de Message Riche avec Lecteur Audio Réel (AVPlayer) & Affichage Photo / GIF

private struct RichMessageBubbleView: View {
    let message: SocialRichMessageItem

    private func resolvedMediaURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        let prefix = trimmed.hasPrefix("/") ? "" : "/"
        return URL(string: "https://livriasocial.viplenetwork.com\(prefix)\(trimmed)")
    }

    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 45) }

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 8) {
                if !message.body.isEmpty {
                    Text(message.body)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }

                // Pièce jointe riche
                if message.attachmentType == "voice" {
                    VoiceMessageBubblePlayerView(
                        audioURL: resolvedMediaURL(message.attachmentUrl),
                        durationSec: max(1, message.voiceDurationSec)
                    )
                } else if (message.attachmentType == "image" || message.attachmentType == "gif"),
                          let url = resolvedMediaURL(message.attachmentUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 230, maxHeight: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            HStack(spacing: 6) {
                                Image(systemName: "photo")
                                Text(message.attachmentType == "gif" ? "GIF" : "Photo")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(10)
                        default:
                            ProgressView()
                                .tint(.white)
                                .frame(width: 140, height: 90)
                        }
                    }
                } else if message.attachmentType == "book", !message.attachmentTitle.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(LivriaSocialPalette.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(message.attachmentTitle)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                            Text(message.attachmentMeta)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        if let url = resolvedMediaURL(message.attachmentUrl) {
                            Link(destination: url) {
                                Image(systemName: "cart.fill.badge.plus")
                                    .foregroundStyle(LivriaSocialPalette.gold)
                            }
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25)))
                } else if message.attachmentType == "link", let url = resolvedMediaURL(message.attachmentUrl) {
                    Link(destination: url) {
                        Label(message.attachmentTitle.isEmpty ? message.attachmentUrl : message.attachmentTitle, systemImage: "link.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LivriaSocialPalette.accent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        message.isMine
                            ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                            : AnyShapeStyle(Color.white.opacity(0.09))
                    )
            )

            if !message.isMine { Spacer(minLength: 45) }
        }
    }
}

// MARK: - Lecteur Audio Intégré dans une Bulle de Message Vocal

private struct VoiceMessageBubblePlayerView: View {
    let audioURL: URL?
    let durationSec: Int

    @State private var player: AVPlayer? = nil
    @State private var isPlaying: Bool = false

    var body: some View {
        Button {
            togglePlay()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LivriaSocialPalette.gold)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 3) {
                        ForEach(0..<12, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(isPlaying ? LivriaSocialPalette.gold : Color.white.opacity(0.75))
                                .frame(width: 3, height: CGFloat(8 + ((idx * 7) % 14)))
                        }
                    }
                    Text(isPlaying ? "Lecture en cours... (\(durationSec)s)" : "Note vocale • \(durationSec) sec")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.28)))
        }
        .buttonStyle(.plain)
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }

    private func togglePlay() {
        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }
        guard let url = audioURL else { return }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        let avPlayer = AVPlayer(url: url)
        self.player = avPlayer
        self.isPlaying = true
        avPlayer.play()

        let waitSec = Double(max(1, durationSec))
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(waitSec * 1_000_000_000) + 400_000_000)
            if self.isPlaying {
                self.isPlaying = false
            }
        }
    }
}
