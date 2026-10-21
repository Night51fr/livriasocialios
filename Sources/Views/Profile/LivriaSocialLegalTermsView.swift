import SwiftUI

// MARK: - Conditions Générales d'Utilisation Complètes Livria, Livria Social & Viple Live ID (Premier lancement & Consultation)

public struct LivriaSocialLegalTermsView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel
    @Environment(\.dismiss) private var dismiss

    public let isFirstLaunchGate: Bool
    @State private var hasCheckedConsent: Bool = false

    public init(isFirstLaunchGate: Bool = true) {
        self.isFirstLaunchGate = isFirstLaunchGate
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LivriaSocialPalette.heroGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            headerBanner

                            ForEach(Self.legalArticles) { article in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: article.icon)
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundStyle(LivriaSocialPalette.gold)
                                        Text(article.title)
                                            .font(.system(size: 15, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                    }

                                    Text(article.body)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.86))
                                        .lineSpacing(3)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .socialCard()
                            }
                        }
                        .padding(16)
                    }

                    bottomConsentBar
                }
            }
            .navigationTitle("Conditions Générales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstLaunchGate {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            dismiss()
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .interactiveDismissDisabled(isFirstLaunchGate)
        }
        .preferredColorScheme(.dark)
    }

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                LivriaSocialBrandLogoView(compact: false)
                Spacer()
                Text("Édition 2026")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))
            }

            Text("Conditions Générales d'Utilisation — Livria Social, Livria Store & Compte Viple Live ID")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Veuillez prendre connaissance des présentes Conditions Générales d'Utilisation régissant l'accès au réseau social littéraire Livria Social, aux services Livria et au compte unifié Viple Live ID.")
                .font(.system(size: 12.5))
                .foregroundStyle(LivriaSocialPalette.textMuted)
        }
        .padding(16)
        .socialCard()
    }

    private var bottomConsentBar: some View {
        VStack(spacing: 12) {
            if isFirstLaunchGate {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        hasCheckedConsent.toggle()
                    }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: hasCheckedConsent ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(hasCheckedConsent ? LivriaSocialPalette.gold : .white.opacity(0.65))

                        Text("Je certifie avoir lu et j'accepte sans réserve les Conditions Générales d'Utilisation de Livria, Livria Social et du compte Viple Live ID.")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    social.acceptTermsOfUse()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Accepter et continuer sur Livria Social")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(hasCheckedConsent ? LivriaSocialPalette.ink : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            hasCheckedConsent
                                ? AnyShapeStyle(LivriaSocialPalette.goldGradient)
                                : AnyShapeStyle(Color.white.opacity(0.10))
                        )
                    )
                }
                .disabled(!hasCheckedConsent)
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(LivriaSocialPalette.emerald)
                    Text("Conditions Générales acceptées sur cet appareil.")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Fermer") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(LivriaSocialPalette.gold)
                }
            }
        }
        .padding(16)
        .background(
            LivriaSocialPalette.ink.opacity(0.96)
                .overlay(Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1), alignment: .top)
        )
    }

    public struct LegalArticle: Identifiable, Sendable {
        public let id: Int
        public let icon: String
        public let title: String
        public let body: String
    }

    public static let legalArticles: [LegalArticle] = [
        LegalArticle(
            id: 1,
            icon: "doc.text.fill",
            title: "1. Objet et champ d'application",
            body: "Les présentes Conditions Générales d'Utilisation (CGU) définissent les modalités d'accès et d'utilisation de l'application mobile « Livria Social », de l'écosystème « Livria Store » et du compte d'authentification unifié « Viple Live ID » édités par Viple. L'utilisation de l'application implique l'acceptation pleine et entière des présentes conditions."
        ),
        LegalArticle(
            id: 2,
            icon: "person.badge.key.fill",
            title: "2. Compte Viple Live ID obligatoire",
            body: "L'accès aux fonctionnalités de Livria Social (fil d'actualité, publications, commentaires, listes de lecture, messagerie privée, personnalisation de profil et jeux quotidiens) nécessite obligatoirement la connexion à un compte personnel Viple Live ID valide. Chaque utilisateur est personnellement responsable de la confidentialité de son identifiant et de son mot de passe Viple Live ID."
        ),
        LegalArticle(
            id: 3,
            icon: "bubble.left.and.exclamationmark.bubble.right.fill",
            title: "3. Charte communautaire et publications",
            body: "Livria Social est un espace d'échange culturel et littéraire bienveillant. Les utilisateurs s'engagent à ne publier aucun contenu illicite, diffamatoire, injurieux, haineux, discriminatoire ou portant atteinte aux droits d'autrui ou à la propriété intellectuelle. Viple se réserve le droit de modérer, masquer ou supprimer toute publication contraire aux présentes règles et de suspendre le compte concerné."
        ),
        LegalArticle(
            id: 4,
            icon: "books.vertical.fill",
            title: "4. Listes de lecture rémunérées et cagnotte Livria",
            body: "Les membres peuvent créer et partager des listes de recommandation de livres. Lorsqu'un achat ferme et définitif est réalisé sur Livria Store via une liste éligible (hors annulation ou remboursement), une commission comprise entre 0,50 € et 1,00 € peut être créditée sur la cagnotte Livria du créateur. Toute tentative d'auto-achat abusif ou de fraude entraîne l'annulation des gains."
        ),
        LegalArticle(
            id: 5,
            icon: "gamecontroller.fill",
            title: "5. Règles des Jeux XP, Bonus Quotidien et Roue de la Fortune",
            body: "L'espace Jeux permet de gagner des points d'expérience (XP), des points de fidélité et des bonus de cagnotte. Le Bonus Quotidien de lecture est strictement limité à une (1) réclamation par jour calendaire et par compte Viple Live ID. De même, la Roue de la Fortune est strictement limitée à un (1) lancer gratuit par jour calendaire et par compte. Toute tentative de contournement technique entraîne la réinitialisation des récompenses."
        ),
        LegalArticle(
            id: 6,
            icon: "lock.shield.fill",
            title: "6. Protection des données personnelles (RGPD)",
            body: "Conformément au Règlement Général sur la Protection des Données (RGPD) et à la loi Informatique et Libertés, les informations rattachées à votre compte Viple Live ID et à votre profil Livria Social sont traitées uniquement pour assurer le fonctionnement de nos services, la synchronisation de votre bibliothèque et la sécurité de vos échanges. Vous disposez à tout moment d'un droit d'accès, de rectification, de portabilité et de suppression de vos données depuis votre espace client Viple ou sur simple demande au support."
        ),
        LegalArticle(
            id: 7,
            icon: "c.circle.fill",
            title: "7. Propriété intellectuelle et disponibilité",
            body: "L'ensemble des marques, logos (Viple, Viple Live ID, Livria, Livria Social, Looby+), interfaces, textes et éléments graphiques demeurent la propriété exclusive de Viple et de ses partenaires éditeurs. Les présentes CGU sont soumises au droit français."
        )
    ]
}
