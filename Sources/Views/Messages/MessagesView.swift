import SwiftUI

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

// MARK: - Fil de Discussion Riche (Photos, Vocaux, GIFs, Livres Boutique & Liens)

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
    @State private var voiceDurationSec: Int = 12
    @State private var isLoadingThread: Bool = true

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
                            Text("Vous pouvez envoyer du texte, une photo, une note vocale, un GIF animé, un lien ou une fiche livre Livria Store.")
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

                if selectedAttachmentType == "image" || selectedAttachmentType == "gif" || selectedAttachmentType == "link" {
                    TextField(
                        selectedAttachmentType == "link" ? "URL du lien (https://...)" : "URL de l'image ou du GIF (https://...)",
                        text: $attachmentUrl
                    )
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 12))
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                    .foregroundStyle(.white)
                } else if selectedAttachmentType == "voice" {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(LivriaSocialPalette.secondary)
                        Text("Note vocale prête (\(voiceDurationSec)s)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Stepper("", value: $voiceDurationSec, in: 3...60, step: 3)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 10)
                } else if selectedAttachmentType == "book" {
                    Picker("Livre Livria Store", selection: $selectedBookId) {
                        Text("Choisir un livre du catalogue...").tag(0)
                        ForEach(social.booksCatalog) { book in
                            Text("\(book.title) (\(String(format: "%.2f €", book.priceTtc)))").tag(book.id)
                        }
                    }
                    .tint(LivriaSocialPalette.gold)
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
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(LivriaSocialPalette.brandGradient)
                    }
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

    private func reloadMessages() async {
        isLoadingThread = true
        messages = await social.loadConversationThread(otherUserId: otherUserId)
        isLoadingThread = false
    }

    private func sendMessageNow() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || selectedAttachmentType != "none" else { return }

        let ok = await social.sendRichMessage(
            recipientId: otherUserId,
            body: trimmed,
            attachmentType: selectedAttachmentType,
            attachmentUrl: attachmentUrl,
            attachmentTitle: attachmentTitle,
            bookId: selectedBookId > 0 ? selectedBookId : nil,
            voiceDurationSec: selectedAttachmentType == "voice" ? voiceDurationSec : 0
        )
        if ok {
            messageText = ""
            attachmentUrl = ""
            attachmentTitle = ""
            selectedAttachmentType = "none"
            selectedBookId = 0
            await reloadMessages()
        }
    }
}

private struct RichMessageBubbleView: View {
    let message: SocialRichMessageItem

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
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LivriaSocialPalette.gold)
                        Text("Note vocale • \(max(1, message.voiceDurationSec)) sec")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.25)))
                } else if (message.attachmentType == "image" || message.attachmentType == "gif"),
                          let url = URL(string: message.attachmentUrl), !message.attachmentUrl.isEmpty {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 220, maxHeight: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        if let url = URL(string: message.attachmentUrl) {
                            Link(destination: url) {
                                Image(systemName: "cart.fill.badge.plus")
                                    .foregroundStyle(LivriaSocialPalette.gold)
                            }
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25)))
                } else if message.attachmentType == "link", let url = URL(string: message.attachmentUrl) {
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
