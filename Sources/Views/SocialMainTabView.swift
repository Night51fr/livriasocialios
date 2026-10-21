import SwiftUI

// MARK: - Navigation Principale « Livria Social » (CGU au 1er lancement + Connexion Viple Live ID obligatoire)

public struct SocialMainTabView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    public init() {}

    public var body: some View {
        Group {
            if !social.hasAcceptedTermsOfUse {
                LivriaSocialLegalTermsView(isFirstLaunchGate: true)
                    .environmentObject(social)
            } else if !social.isAuthenticated || social.currentUser == nil {
                SocialMandatoryAuthView()
                    .environmentObject(social)
            } else {
                authenticatedTabExperience
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $social.isShowingTermsReviewSheet) {
            LivriaSocialLegalTermsView(isFirstLaunchGate: false)
                .environmentObject(social)
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

// MARK: - Écran de Connexion Viple Live ID Obligatoire pour Livria Social

public struct SocialMandatoryAuthView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var isRegisterMode: Bool = false
    @State private var email: String = ""
    @State private var displayName: String = ""
    @State private var password: String = ""

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
                            Text("Mot de passe")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                            SecureField("Votre mot de passe Viple Live ID", text: $password)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))
                                .foregroundStyle(.white)
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
                        .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || social.isLoading)
                        .padding(.top, 4)
                    }
                    .padding(18)
                    .socialCard()

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
    }
}
