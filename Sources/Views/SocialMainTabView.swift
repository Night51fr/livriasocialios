import SwiftUI
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Navigation Principale « Livria Social » (Écran de Chargement + CGU au 1er lancement + Connexion Viple Live ID obligatoire)

public struct SocialMainTabView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            if social.mobileAppMaintenanceEnabled {
                LivriaSocialMaintenanceView()
                    .environmentObject(social)
                    .transition(.opacity)
            } else if social.isInitialBootstrapping {
                LivriaSocialLoadingSplashView()
                    .environmentObject(social)
                    .transition(.opacity)
            } else if social.isServerUnreachable && social.posts.isEmpty {
                LivriaSocialServerOutageView()
                    .environmentObject(social)
                    .transition(.opacity)
            } else if !social.hasAcceptedTermsOfUse {
                LivriaSocialLegalTermsView(isFirstLaunchGate: true)
                    .environmentObject(social)
                    .transition(.opacity)
            } else if !social.isAuthenticated || social.currentUser == nil {
                SocialMandatoryAuthView()
                    .environmentObject(social)
                    .transition(.opacity)
            } else {
                authenticatedTabExperience
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $social.isShowingTermsReviewSheet) {
            LivriaSocialLegalTermsView(isFirstLaunchGate: false)
                .environmentObject(social)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await social.refreshMaintenanceStatus()
                }
            }
        }
        .onOpenURL { url in
            social.handleIncomingURL(url)
        }
    }

    private var authenticatedTabExperience: some View {
        ZStack(alignment: .top) {
            TabView(selection: $social.selectedTab) {
                FeedView()
                    .tabItem {
                        Label("Fil d'actu", systemImage: "sparkles")
                    }
                    .tag(0)

                BookListsView()
                    .tabItem {
                        Label("Listes (€)", systemImage: "books.vertical.fill")
                    }
                    .tag(1)

                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .badge(social.unreadMessagesCount)
                    .tag(2)

                SocialGamesHubView()
                    .tabItem {
                        Label("Jeux XP", systemImage: "gamecontroller.fill")
                    }
                    .tag(3)

                SocialProfileView()
                    .tabItem {
                        Label("Mon Profil", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            .tint(LivriaSocialPalette.coral)
            .onChange(of: social.selectedTab) { _, _ in
                Task {
                    await social.refreshMaintenanceStatus()
                }
            }

            if let toast = social.activeToastMessage {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(LivriaSocialPalette.gold)
                    Text(toast)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(LivriaSocialPalette.ink.opacity(0.94))
                        .overlay(Capsule().stroke(LivriaSocialPalette.gold.opacity(0.45), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.30), radius: 10, x: 0, y: 4)
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(99)
            }
        }
        .sheet(isPresented: $social.isShowingAuthSheet) {
            SocialAuthSheetView()
                .environmentObject(social)
        }
        .sheet(isPresented: $social.isShowingCreatePostSheet) {
            CreatePostSheetView()
                .environmentObject(social)
        }
        .sheet(isPresented: $social.isShowingCreateListSheet) {
            CreateBookListSheetView()
                .environmentObject(social)
        }
        .sheet(item: $social.deepLinkedMemberProfile) { member in
            NavigationStack {
                MemberPublicProfileView(memberId: member.id, initialSummary: member)
                    .environmentObject(social)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") {
                                social.deepLinkedMemberProfile = nil
                            }
                            .foregroundStyle(.white)
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Écran de Chargement Livria Social (Logo « Livria » sur fond transparent + Texte + Icône de chargement animée)

public struct LivriaSocialLoadingSplashView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @State private var isSpinning: Bool = false
    @State private var isPulsing: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            VStack(spacing: 26) {
                Spacer()

                // 1. Logo « Livria » au-dessus (fond transparent)
                Group {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(named: "LivriaLogoTransparent") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 82)
                    } else if let horizontalImg = UIImage(named: "LivriaSocialLogoHorizontal") {
                        Image(uiImage: horizontalImg)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 62)
                    } else {
                        fallbackLogoText
                    }
                    #else
                    fallbackLogoText
                    #endif
                }
                .scaleEffect(isPulsing ? 1.03 : 0.97)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isPulsing)

                // 2. Texte d'accroche au centre
                Text("Mais quelle pépite, va t'on encore me partager !?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)

                // 3. Icône de chargement animée en dessous de tout ça
                ZStack {
                    Circle()
                        .stroke(LivriaSocialPalette.primary.opacity(0.22), lineWidth: 4.5)
                        .frame(width: 54, height: 54)

                    Circle()
                        .trim(from: 0.08, to: 0.78)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    LivriaSocialPalette.primary,
                                    LivriaSocialPalette.coral,
                                    LivriaSocialPalette.gold,
                                    LivriaSocialPalette.primary
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                        )
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isSpinning)

                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [LivriaSocialPalette.primary, LivriaSocialPalette.coral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPulsing ? 1.12 : 0.90)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
                }
                .padding(.top, 6)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .socialCustomBackground(
            bgType: social.currentUser?.pageBackgroundType ?? "preset",
            bgValue: social.currentUser?.pageBackgroundValue ?? "aurora"
        )
        .onAppear {
            isSpinning = true
            isPulsing = true
        }
    }

    private var fallbackLogoText: some View {
        Text("Livria")
            .font(.system(size: 56, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        LivriaSocialPalette.primary,
                        LivriaSocialPalette.coral
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

// MARK: - Écran « Maintenance en cours » (Synchronisé en direct avec /admin sur Livria Store)

public struct LivriaSocialMaintenanceView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    public init() {}

    public var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Text("Maintenance en cours")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.11, green: 0.10, blue: 0.18))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .task {
            while !Task.isCancelled && social.mobileAppMaintenanceEnabled {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                await social.refreshMaintenanceStatus()
            }
        }
    }
}

// MARK: - Écran Serveur Indisponible / Timeout 20s / Erreur 503 (« Oups, le serveur a le moral dans les chaussette, il revient bientot »)

public struct LivriaSocialServerOutageView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @State private var isRetrying: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 22) {
                #if canImport(UIKit)
                if let uiImage = UIImage(named: "LivriaLogoTransparent") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 68)
                } else if let horizontalImg = UIImage(named: "LivriaSocialLogoHorizontal") {
                    Image(uiImage: horizontalImg)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 54)
                }
                #endif

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [LivriaSocialPalette.primary, LivriaSocialPalette.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Oups, le serveur a le moral dans les chaussette, il revient bientot")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.11, green: 0.10, blue: 0.18))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button {
                    isRetrying = true
                    Task {
                        await social.refreshMaintenanceStatus()
                        await social.refreshBootstrap()
                        isRetrying = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRetrying {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Réessayer")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [LivriaSocialPalette.primary, LivriaSocialPalette.coral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(isRetrying)
            }
        }
    }
}

// MARK: - Écran de Connexion Viple Live ID Obligatoire pour Livria Social (avec Sign in with Apple & @viplemail.fr)

public struct SocialMandatoryAuthView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var isRegisterMode: Bool = false
    @State private var email: String = ""
    @State private var displayName: String = ""
    @State private var password: String = ""

    // Finalisation d'inscription Sign in with Apple (Nom, Prénom, Pseudo, Adresse @viplemail.fr obligatoire OU association d'un compte Viple existant)
    @State private var appleFirstName: String = ""
    @State private var appleLastName: String = ""
    @State private var appleDisplayName: String = ""
    @State private var appleViplemailUser: String = ""
    @State private var appleLinkExistingMode: Bool = false
    @State private var appleExistingEmail: String = ""
    @State private var appleExistingPassword: String = ""

    public init() {}

    public var body: some View {
        ZStack {
            LivriaSocialPalette.heroGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        LivriaSocialBrandLogoView(compact: false)
                            .padding(.top, 20)

                        Text("Bienvenue sur Livria Social")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Connectez-vous avec votre compte Viple Live ID pour accéder au réseau social littéraire, partager vos lectures, créer vos listes rémunérées et échanger avec la communauté.")
                            .font(.system(size: 13.5))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }

                    if social.pendingAppleOnboardingUserId != nil {
                        applePostSignupOnboardingCard
                    } else {
                        // Sélecteur Connexion / Créer un compte
                        HStack(spacing: 8) {
                            Button {
                                withAnimation {
                                    isRegisterMode = false
                                    social.authErrorMessage = nil
                                }
                            } label: {
                                Text("Se connecter")
                                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(
                                        Capsule().fill(
                                            !isRegisterMode
                                                ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                                : AnyShapeStyle(Color.white.opacity(0.08))
                                        )
                                    )
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation {
                                    isRegisterMode = true
                                    social.authErrorMessage = nil
                                }
                            } label: {
                                Text("Créer un compte")
                                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(
                                        Capsule().fill(
                                            isRegisterMode
                                                ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                                : AnyShapeStyle(Color.white.opacity(0.08))
                                        )
                                    )
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .background(Capsule().fill(Color.white.opacity(0.06)))

                        // Bouton Sign in with Apple
                        VStack(spacing: 10) {
                            SignInWithAppleButton(.continue) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                handleAppleSignInResult(result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Text("Connexion ou inscription rapide avec votre compte Apple associé à Viple Live ID.")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(LivriaSocialPalette.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .socialCard()

                        // Formulaire Viple Live ID
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("COMPTE VIPLE LIVE ID OBLIGATOIRE", systemImage: "lock.shield.fill")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(LivriaSocialPalette.gold)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Identifiant ou e-mail Viple Live ID")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                TextField("Ex: prenom.nom@viplemail.fr", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))
                                    .foregroundStyle(.white)
                            }

                            if isRegisterMode {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Votre pseudo ou prénom de lecteur")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                    TextField("Ex: Clara Lectures", text: $displayName)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))
                                        .foregroundStyle(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(isRegisterMode ? "Mot de passe" : "Mot de passe (laissez vide si inscrit avec Apple sans mot de passe)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                SecureField("Votre mot de passe Viple Live ID", text: $password)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))
                                    .foregroundStyle(.white)
                            }

                            if let notice = social.applePasswordSetupNotice, !notice.isEmpty {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "icloud.fill")
                                        .font(.title3)
                                        .foregroundStyle(LivriaSocialPalette.gold)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Vérifiez votre boîte mail iCloud")
                                            .font(.system(size: 13, weight: .black))
                                            .foregroundStyle(.white)
                                        Text(notice)
                                            .font(.system(size: 12))
                                            .foregroundStyle(LivriaSocialPalette.textMuted)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LivriaSocialPalette.gold.opacity(0.45), lineWidth: 1))
                            }

                            if let err = social.authErrorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(err)
                                }
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundStyle(Color(hex: "#FCA5A5"))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.18)))
                            }

                            Button {
                                Task {
                                    if isRegisterMode {
                                        await social.registerAccount(email: email, displayName: displayName, password: password)
                                    } else {
                                        await social.signIn(email: email, password: password)
                                    }
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    if social.isLoading {
                                        ProgressView()
                                            .tint(LivriaSocialPalette.ink)
                                    } else {
                                        Image(systemName: "person.badge.key.fill")
                                        Text(isRegisterMode ? "Créer mon compte Viple Live ID" : "Se connecter à Livria Social")
                                            .font(.system(size: 15, weight: .black, design: .rounded))
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(LivriaSocialPalette.ink)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                            }
                            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (isRegisterMode && password.isEmpty) || social.isLoading)
                            .padding(.top, 4)
                        }
                        .padding(18)
                        .socialCard()
                    }

                    Button {
                        social.isShowingTermsReviewSheet = true
                    } label: {
                        Label("Revoir les Conditions Générales d'Utilisation (Livria & Viple Live ID)", systemImage: "doc.text.magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                            .underline()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
            }
        }
        .onChange(of: social.pendingAppleOnboardingUserId) { _, newValue in
            if newValue != nil {
                appleFirstName = social.pendingAppleFirstName
                appleLastName = social.pendingAppleLastName
                let suggested = "\(social.pendingAppleFirstName) \(social.pendingAppleLastName)".trimmingCharacters(in: .whitespaces)
                appleDisplayName = suggested
                if appleViplemailUser.isEmpty, !suggested.isEmpty {
                    appleViplemailUser = suggested
                        .folding(options: .diacriticInsensitive, locale: .current)
                        .lowercased()
                        .replacingOccurrences(of: " ", with: ".")
                        .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" }
                }
            }
        }
    }

    private var applePostSignupOnboardingCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.title2)
                    .foregroundStyle(LivriaSocialPalette.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(appleLinkExistingMode ? "Associer mon compte Viple Live ID" : "Finalisez votre compte Viple Live ID")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(appleLinkExistingMode
                         ? "Liez votre compte Viple Live ID existant à votre compte Apple"
                         : "Inscription Sign in with Apple • Adresse @viplemail.fr obligatoire")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LivriaSocialPalette.gold)
                }
                Spacer()
                Button {
                    withAnimation {
                        social.pendingAppleOnboardingUserId = nil
                        appleLinkExistingMode = false
                        social.authErrorMessage = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                }
            }

            // Sélecteur : Nouveau profil @viplemail.fr OU "J'ai déjà un compte Viple Live ID"
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        appleLinkExistingMode = false
                        social.authErrorMessage = nil
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.badge.plus")
                        Text("Nouveau profil")
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            !appleLinkExistingMode
                                ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                : AnyShapeStyle(Color.white.opacity(0.08))
                        )
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation {
                        appleLinkExistingMode = true
                        social.authErrorMessage = nil
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "link.badge.plus")
                        Text("J'ai déjà un compte Viple Live ID")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            appleLinkExistingMode
                                ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                : AnyShapeStyle(Color.white.opacity(0.08))
                        )
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(5)
            .background(Capsule().fill(Color.white.opacity(0.06)))

            if appleLinkExistingMode {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(LivriaSocialPalette.gold)
                    Text("Vous possédez déjà un compte Viple Live ID ? Renseignez vos identifiants ci-dessous pour associer définitivement votre compte Viple Live ID à votre compte Apple. Vos prochaines connexions avec Apple ouvriront directement votre compte.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Identifiant ou e-mail Viple Live ID")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                    TextField("Ex: prenom.nom@viplemail.fr", text: $appleExistingEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Mot de passe Viple Live ID")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                    SecureField("Votre mot de passe Viple Live ID", text: $appleExistingPassword)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                        .foregroundStyle(.white)
                }

                if let err = social.authErrorMessage {
                    Text(err)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color(hex: "#FCA5A5"))
                }

                Button {
                    Task {
                        await social.linkAppleToExistingAccount(
                            email: appleExistingEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                            password: appleExistingPassword
                        )
                    }
                } label: {
                    HStack {
                        Spacer()
                        if social.isLoading {
                            ProgressView().tint(LivriaSocialPalette.ink)
                        } else {
                            Image(systemName: "link.circle.fill")
                            Text("Associer mon compte Viple Live ID à Apple")
                                .font(.system(size: 14.5, weight: .black, design: .rounded))
                        }
                        Spacer()
                    }
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                }
                .disabled(
                    appleExistingEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    appleExistingPassword.isEmpty ||
                    social.isLoading
                )

                Button {
                    withAnimation {
                        appleLinkExistingMode = false
                        social.authErrorMessage = nil
                    }
                } label: {
                    Text("Je n'ai pas encore de compte, créer mon identifiant @viplemail.fr")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LivriaSocialPalette.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "laptopcomputer.and.iphone")
                            .foregroundStyle(LivriaSocialPalette.gold)
                        Text("Pourquoi choisir une adresse @viplemail.fr ? Cet identifiant Viple Live ID vous permet de vous connecter depuis un autre appareil non Apple (ordinateur, web, Android), tandis que sur vos appareils Apple votre compte Viple Live ID reste associé à votre compte Apple.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }

                    Divider().background(Color.white.opacity(0.18))

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "icloud.and.arrow.down.fill")
                            .foregroundStyle(LivriaSocialPalette.coral)
                        Text("Pour rendre votre expérience plus simple et plus rapide, aucun mot de passe ne vous est demandé maintenant. Le jour où vous voudrez vous connecter avec votre adresse @viplemail.fr depuis un autre appareil sans avoir encore de mot de passe, entrez simplement votre adresse @viplemail.fr sans mot de passe : un e-mail sera automatiquement envoyé sur votre boîte mail iCloud avec un lien pour créer votre mot de passe.")
                            .font(.system(size: 12))
                            .foregroundStyle(LivriaSocialPalette.textMuted)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Prénom")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                        TextField("Votre prénom", text: $appleFirstName)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Nom")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                        TextField("Votre nom", text: $appleLastName)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Pseudo")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                    TextField("Votre pseudo sur Livria Social", text: $appleDisplayName)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Quel nom d'adresse @viplemail.fr souhaitez-vous ? (obligatoire)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        TextField("prenom.nom", text: $appleViplemailUser)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                            .foregroundStyle(.white)
                        Text("@viplemail.fr")
                            .font(.system(size: 13.5, weight: .black, design: .monospaced))
                            .foregroundStyle(LivriaSocialPalette.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(LivriaSocialPalette.goldGradient))
                    }
                }

                if let err = social.authErrorMessage {
                    Text(err)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color(hex: "#FCA5A5"))
                }

                Button {
                    Task {
                        await social.completeAppleOnboarding(
                            firstName: appleFirstName.trimmingCharacters(in: .whitespaces),
                            lastName: appleLastName.trimmingCharacters(in: .whitespaces),
                            displayName: appleDisplayName.trimmingCharacters(in: .whitespaces),
                            viplemailUser: appleViplemailUser.trimmingCharacters(in: .whitespaces)
                        )
                    }
                } label: {
                    HStack {
                        Spacer()
                        if social.isLoading {
                            ProgressView().tint(LivriaSocialPalette.ink)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Valider mon identifiant @viplemail.fr")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        Spacer()
                    }
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                }
                .disabled(
                    appleFirstName.trimmingCharacters(in: .whitespaces).isEmpty ||
                    appleLastName.trimmingCharacters(in: .whitespaces).isEmpty ||
                    appleDisplayName.trimmingCharacters(in: .whitespaces).isEmpty ||
                    appleViplemailUser.trimmingCharacters(in: .whitespaces).isEmpty ||
                    social.isLoading
                )

                Button {
                    withAnimation {
                        appleLinkExistingMode = true
                        social.authErrorMessage = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.key.fill")
                        Text("J'ai déjà un compte Viple Live ID")
                    }
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }
            }
        }
        .padding(18)
        .socialCard()
    }

    private func handleAppleSignInResult(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let appleUserId = cred.user
            let email = cred.email
            let givenName = cred.fullName?.givenName
            let familyName = cred.fullName?.familyName
            var tokenString: String? = nil
            if let tokenData = cred.identityToken {
                tokenString = String(data: tokenData, encoding: .utf8)
            }
            Task {
                await social.handleSignInWithApple(
                    appleUserId: appleUserId,
                    email: email,
                    firstName: givenName,
                    lastName: familyName,
                    identityToken: tokenString
                )
            }
        case .failure:
            break
        }
    }
}
