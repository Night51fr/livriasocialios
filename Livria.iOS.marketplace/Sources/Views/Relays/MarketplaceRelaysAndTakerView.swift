import SwiftUI
import MapKit

// MARK: - Onglet Points Relais UPS & Programme « Devenir Viple Taker » (Point Relais Particulier — 1,00 € / colis)

public struct MarketplaceRelaysAndTakerView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel

    @State private var postalCode: String = "54000"
    @State private var city: String = "Nancy"
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.6921, longitude: 6.1844),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    takerRecruitmentCard
                    liveRelayMapAndSearchCard
                    relayPointsListSection
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Points Relais & Viple Taker")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await store.fetchTakerApplicationStatus()
            }
        }
    }

    // MARK: - Carte « Devenir Viple Taker (1,00 € / colis) » + Statut de Demande en Temps Réel

    private var takerRecruitmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MarketplacePalette.heroGradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: "house.and.flag.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Devenir Viple Taker")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        Text("1,00 € / colis")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(MarketplacePalette.green.opacity(0.15)))
                            .foregroundStyle(MarketplacePalette.green)
                    }
                    Text("Point Relais Particulier Livria Store & Marketplace : gagnez autant que les commerces relais (1,00 € par colis remis) !")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(MarketplacePalette.primary)
                }
                Spacer()
            }

            Text("Réceptionnez les colis Livria livrés par Viple Delivery (service interne) ou par UPS (une étiquette Viple Delivery y est aussi apposée pour scanner le code-barres depuis l'application « Looby Taker »), puis programmez avec l'acheteur quand lui remettre son colis.")
                .font(.system(size: 12))
                .foregroundStyle(MarketplacePalette.inkMuted)
                .lineSpacing(2)

            if let app = store.takerApplication {
                HStack(spacing: 10) {
                    Circle()
                        .fill(statusColor(app.status))
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status de votre demande : \(app.status)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)
                        if let req = app.requestedAdditionalInfo, !req.isEmpty {
                            Text("Élément demandé par Viple : \(req)")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primarySoft.opacity(0.6)))
            }

            Button {
                store.isShowingTakerApplicationSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: store.takerApplication != nil ? "doc.text.magnifyingglass" : "paperplane.fill")
                    Text(store.takerApplication != nil ? "Voir le statut / Gérer ma demande Viple Taker" : "Remplir le formulaire pour devenir Viple Taker")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(MarketplacePalette.heroGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .marketplaceCard()
    }

    // MARK: - Carte Interactive Apple Maps (Viple Taker Validés & UPS Access Point)

    private var liveRelayMapAndSearchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Carte des Points Relais Validés")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Spacer()
                Text("Livraison 0,00 €")
                    .font(.system(size: 11, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(MarketplacePalette.green.opacity(0.15)))
                    .foregroundStyle(MarketplacePalette.green)
            }

            Map(position: $cameraPosition) {
                ForEach(store.relayPoints) { relay in
                    Annotation(
                        relay.name,
                        coordinate: CLLocationCoordinate2D(latitude: relay.latitude, longitude: relay.longitude)
                    ) {
                        Button {
                            store.selectedRelayPoint = relay
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: relay.isParticulierTaker ? "house.and.flag.fill" : "shippingbox.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(7)
                                    .background(Circle().fill(relay.isParticulierTaker ? MarketplacePalette.primary : MarketplacePalette.upsBrown))
                                    .foregroundStyle(relay.isParticulierTaker ? .white : MarketplacePalette.upsGold)
                                Text(relay.isParticulierTaker ? "Viple Taker" : "UPS")
                                    .font(.system(size: 9, weight: .black))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.white))
                                    .foregroundStyle(MarketplacePalette.ink)
                            }
                        }
                    }
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(spacing: 8) {
                TextField("Code postal", text: $postalCode)
                    .frame(width: 95)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.background))
                TextField("Ville", text: $city)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.background))
                Button {
                    Task {
                        await store.searchRelays(postalCode: postalCode, city: city)
                        if let first = store.relayPoints.first {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                                )
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                        Text("Chercher")
                    }
                    .font(.system(size: 12.5, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.primary))
                    .foregroundStyle(.white)
                }
            }
        }
        .marketplaceCard()
    }

    private var relayPointsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points Relais Viple Taker & UPS disponibles (\(store.relayPoints.count))")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)

            ForEach(store.relayPoints) { relay in
                let isSelected = store.selectedRelayPoint?.id == relay.id
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(relay.isParticulierTaker ? MarketplacePalette.primary : MarketplacePalette.upsBrown)
                                .frame(width: 44, height: 44)
                            Image(systemName: relay.isParticulierTaker ? "house.and.flag.fill" : "shippingbox.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(relay.isParticulierTaker ? .white : MarketplacePalette.upsGold)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(relay.name)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(MarketplacePalette.ink)
                                if relay.isParticulierTaker {
                                    Text("Viple Taker Validé • 1€/colis")
                                        .font(.system(size: 9.5, weight: .black))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(MarketplacePalette.primarySoft))
                                        .foregroundStyle(MarketplacePalette.primary)
                                }
                            }
                            Text("\(relay.address), \(relay.postalCode) \(relay.city)")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                            Text("Horaires : \(relay.openingHours) • À \(String(format: "%.1f km", relay.distanceKm))")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(MarketplacePalette.primary)
                        }
                        Spacer()
                    }

                    Button {
                        store.selectedRelayPoint = relay
                        store.showToast("Point relais « \(relay.name) » sélectionné par défaut !")
                    } label: {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "mappin.and.ellipse")
                            Text(isSelected ? "Point relais sélectionné par défaut" : "Choisir ce point relais (0,00 €)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? MarketplacePalette.primary : MarketplacePalette.primarySoft)
                        )
                        .foregroundStyle(isSelected ? .white : MarketplacePalette.primary)
                    }
                }
                .marketplaceCard(padding: 14)
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        let lower = status.lowercased()
        if lower.contains("valid") { return MarketplacePalette.green }
        if lower.contains("refus") { return .red }
        if lower.contains("attente") { return .orange }
        return MarketplacePalette.primary
    }
}

// MARK: - Page Complète « Devenir Viple Taker » (Formulaire -> /admin Livria + Suivi des 5 Statuts + Bouton Annuler)

public struct MarketplaceVipleTakerApplicationSheet: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var streetAddress: String = ""
    @State private var postalCode: String = ""
    @State private var city: String = ""
    @State private var availabilityHours: String = "Lun-Sam 09h00 - 20h00 (Sur RDV avec l'acheteur)"
    @State private var storageCapacityParcels: Int = 15
    @State private var housingType: String = "Maison / Appartement avec pièce dédiée"
    @State private var motivation: String = "Je souhaite devenir point relais particulier Viple Taker dans mon quartier pour réceptionner les colis Livria (Viple Delivery & UPS) et les remettre aux lecteurs."
    @State private var acceptsCharter: Bool = true
    @State private var additionalReplyText: String = ""
    @State private var showingCancelConfirmation: Bool = false
    @State private var isShowingLoobyTakerScanner: Bool = false
    @State private var lastScannedParcelCode: String? = nil

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerExplanationCard

                    if let app = store.takerApplication {
                        applicationStatusTrackingCard(app)
                    } else {
                        applicationFormCard
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Devenir Viple Taker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                prefillFromUser()
                Task { await store.fetchTakerApplicationStatus() }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $isShowingLoobyTakerScanner) {
                MarketplaceBarcodeScannerSheet(
                    title: "Scan Étiquette Viple Delivery (Looby Taker)",
                    subtitle: "Scannez le code-barres Viple Delivery apposé sur le colis Livria ou UPS pour confirmer sa réception (1,00 € / colis)"
                ) { code in
                    lastScannedParcelCode = code
                    store.showToast("Colis \(code) réceptionné ! Programmez le RDV avec l'acheteur (+1,00 €)")
                }
            }
            #endif
            .alert("Annuler votre demande Viple Taker ?", isPresented: $showingCancelConfirmation) {
                Button("Conserver ma demande", role: .cancel) {}
                Button("Oui, annuler ma demande", role: .destructive) {
                    Task {
                        await store.cancelTakerApplication()
                    }
                }
            } message: {
                Text("Vous pourrez soumettre une nouvelle demande à tout moment depuis Livria Store ou Livria Marketplace.")
            }
        }
    }

    // MARK: - Fonctionnement Complet Viple Taker (1,00 € / colis • Viple Delivery & UPS • Looby Taker)

    private var headerExplanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(MarketplacePalette.heroGradient)
                        .frame(width: 50, height: 50)
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Programme Viple Taker (Point Relais Particulier)")
                        .font(.system(size: 16.5, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text("1,00 € par colis remis • Autant que les commerces points relais classiques !")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(MarketplacePalette.green)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("1. Réceptionnez les colis Livria livrés par Viple Delivery (service interne) ou par UPS.", systemImage: "truck.box.fill")
                Label("2. Une étiquette Viple Delivery est apposée sur chaque colis : scannez son code-barres depuis l'application « Looby Taker » pour confirmer la réception.", systemImage: "barcode.viewfinder")
                Label("3. Programmez directement avec l'acheteur le créneau de remise de son colis.", systemImage: "calendar.badge.clock")
                Label("4. Vous percevez 1,00 € par colis délivré, exactement comme les commerces points relais Viple Taker classiques.", systemImage: "eurosign.circle.fill")
            }
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(MarketplacePalette.ink)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
        }
        .marketplaceCard()
    }

    // MARK: - Suivi en Temps Réel du « Status de votre demande » + Éléments Supplémentaires + Bouton Annuler

    private func applicationStatusTrackingCard(_ app: MarketplaceVipleTakerApplication) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status de votre demande")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                    Text(app.status)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(statusTextColor(app.status))
                }
                Spacer()
                Text("Code : \(app.loobyTakerCode)")
                    .font(.system(size: 11.5, weight: .black, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(MarketplacePalette.primarySoft))
                    .foregroundStyle(MarketplacePalette.primary)
            }

            // Timeline visuelle des 5 statuts possibles gérés depuis /admin de Livria
            VStack(alignment: .leading, spacing: 10) {
                ForEach([
                    ("Envoyée", "Votre formulaire a été transmis à l'espace /admin de Livria."),
                    ("Vu par Viple, en cours de traitement", "L'équipe Viple étudie votre adresse et vos disponibilités."),
                    ("En attente d'éléments supplémentaires", "Viple a besoin d'une précision ou d'un justificatif complémentaire."),
                    ("Validé", "Votre point relais Viple Taker est actif et affiché dans Livria Store & Marketplace !"),
                    ("Refusé", "Votre demande n'a pas pu être retenue pour ce secteur.")
                ], id: \.0) { stepStatus, desc in
                    let isCurrent = app.status.caseInsensitiveCompare(stepStatus) == .orderedSame
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle.dotted")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isCurrent ? statusTextColor(stepStatus) : MarketplacePalette.inkMuted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stepStatus)
                                .font(.system(size: 13.5, weight: isCurrent ? .black : .semibold, design: .rounded))
                                .foregroundStyle(isCurrent ? MarketplacePalette.ink : MarketplacePalette.inkMuted)
                            Text(desc)
                                .font(.system(size: 11.5))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCurrent ? MarketplacePalette.primarySoft.opacity(0.6) : MarketplacePalette.background)
                    )
                }
            }

            // Si "En attente d'éléments supplémentaires" : affiche ce que Viple demande + champ de réponse
            if app.status.localizedCaseInsensitiveContains("attente") || !(app.requestedAdditionalInfo ?? "").isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.Bubble.fill")
                            .foregroundStyle(.orange)
                        Text("Éléments supplémentaires demandés par Viple (/admin) :")
                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                            .foregroundStyle(.orange)
                    }

                    Text(app.requestedAdditionalInfo?.isEmpty == false
                         ? app.requestedAdditionalInfo!
                         : "Merci de préciser vos horaires exacts de présence et le lieu sécurisé où seront stockés les colis Livria.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MarketplacePalette.ink)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.12)))

                    TextField("Votre réponse / éléments complémentaires pour Viple...", text: $additionalReplyText, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(MarketplacePalette.border, lineWidth: 1))

                    Button {
                        Task {
                            _ = await store.submitTakerApplication(
                                fullName: app.fullName,
                                email: app.email,
                                phone: app.phone,
                                streetAddress: app.streetAddress,
                                postalCode: app.postalCode,
                                city: app.city,
                                availabilityHours: app.availabilityHours,
                                storageCapacityParcels: app.storageCapacityParcels,
                                housingType: app.housingType,
                                motivation: app.motivation,
                                acceptsCharter: true,
                                additionalReply: additionalReplyText
                            )
                            additionalReplyText = ""
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Envoyer les éléments supplémentaires à Viple")
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primary))
                        .foregroundStyle(.white)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.background))
            }

            // Si Validé : Outil de scan d'étiquette Viple Delivery ("Looby Taker") + Gains 1,00 €/colis
            if app.status.localizedCaseInsensitiveContains("valid") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(MarketplacePalette.green)
                        Text("Espace Viple Taker Actif • Synchronisé avec Looby Taker")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.green)
                    }

                    Text("Votre point relais particulier est affiché dans la page Points Relais de Livria Store et Livria Marketplace. Rémunération : 1,00 € par colis remis.")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplacePalette.ink)

                    if let scanned = lastScannedParcelCode {
                        Text("Dernier colis scanné : \(scanned) • Créneau de remise prêt à programmer avec l'acheteur (+1,00 €)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MarketplacePalette.primary)
                    }

                    Button {
                        isShowingLoobyTakerScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Scanner l'étiquette Viple Delivery d'un colis (Looby Taker)")
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MarketplacePalette.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.green.opacity(0.10)))
            }

            // Bouton pour actualiser le statut ou annuler sa demande si besoin
            HStack(spacing: 10) {
                Button {
                    Task {
                        await store.fetchTakerApplicationStatus()
                        store.showToast("Statut synchronisé avec /admin Livria")
                    }
                } label: {
                    Label("Actualiser le statut", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }

                Button(role: .destructive) {
                    showingCancelConfirmation = true
                } label: {
                    Label("Annuler ma demande", systemImage: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.14)))
                        .foregroundStyle(.red)
                }
            }
        }
        .marketplaceCard()
    }

    // MARK: - Formulaire de Candidature « Devenir Viple Taker » (Envoyé dans /admin de Livria)

    private var applicationFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Formulaire d'inscription Viple Taker")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)

            Group {
                TextField("Nom et Prénom complet *", text: $fullName)
                TextField("Email Viple Live ID *", text: $email)
                    .keyboardType(.emailAddress)
                TextField("Téléphone mobile (pour prise de RDV acheteur) *", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Adresse postale du Point Relais Particulier *", text: $streetAddress)

                HStack(spacing: 10) {
                    TextField("Code postal *", text: $postalCode)
                        .frame(width: 110)
                    TextField("Ville *", text: $city)
                }

                TextField("Créneaux de disponibilité (ex: Lun-Sam 09h-20h) *", text: $availabilityHours)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))

            Stepper("Capacité d'accueil : \(storageCapacityParcels) colis simultanés", value: $storageCapacityParcels, in: 5...100, step: 5)
                .font(.system(size: 13.5, weight: .bold))

            VStack(alignment: .leading, spacing: 5) {
                Text("Type de logement & espace de stockage")
                    .font(.system(size: 12.5, weight: .bold))
                TextField("Maison, appartement, bureau...", text: $housingType)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Présentation & Motivation")
                    .font(.system(size: 12.5, weight: .bold))
                TextField("Pourquoi souhaitez-vous devenir Viple Taker ?", text: $motivation, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }

            Toggle(isOn: $acceptsCharter) {
                Text("J'accepte la charte Viple Taker : réceptionner les colis Viple Delivery et UPS, scanner l'étiquette Viple Delivery depuis l'application Looby Taker, et programmer la remise avec l'acheteur (1,00 € reversé par colis donné).")
                    .font(.system(size: 12))
                    .foregroundStyle(MarketplacePalette.ink)
            }
            .tint(MarketplacePalette.primary)

            Button {
                Task {
                    _ = await store.submitTakerApplication(
                        fullName: fullName.isEmpty ? "Membre Viple Taker" : fullName,
                        email: email.isEmpty ? "contact@viple.fr" : email,
                        phone: phone.isEmpty ? "06 12 34 56 78" : phone,
                        streetAddress: streetAddress.isEmpty ? "14 Place Stanislas" : streetAddress,
                        postalCode: postalCode.isEmpty ? "54000" : postalCode,
                        city: city.isEmpty ? "Nancy" : city,
                        availabilityHours: availabilityHours,
                        storageCapacityParcels: storageCapacityParcels,
                        housingType: housingType,
                        motivation: motivation,
                        acceptsCharter: acceptsCharter
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Envoyer ma demande à Viple (/admin Livria)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(MarketplacePalette.heroGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!acceptsCharter)
        }
        .marketplaceCard()
    }

    private func prefillFromUser() {
        guard let u = store.currentUser else { return }
        if fullName.isEmpty { fullName = "\(u.firstName) \(u.lastName)".trimmingCharacters(in: .whitespaces) }
        if fullName.isEmpty { fullName = u.displayName }
        if email.isEmpty { email = u.email }
        if phone.isEmpty { phone = u.phone }
        if streetAddress.isEmpty { streetAddress = u.address }
        if postalCode.isEmpty { postalCode = u.postalCode }
        if city.isEmpty { city = u.city }
    }

    private func statusTextColor(_ status: String) -> Color {
        let lower = status.lowercased()
        if lower.contains("valid") { return MarketplacePalette.green }
        if lower.contains("refus") { return .red }
        if lower.contains("attente") { return .orange }
        return MarketplacePalette.primary
    }
}
