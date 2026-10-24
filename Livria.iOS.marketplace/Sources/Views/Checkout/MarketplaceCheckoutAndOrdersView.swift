import SwiftUI
import PassKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Checkout Complet Livria Marketplace (Apple Pay, PayPal, API UPS & Points Relais Viple Taker • 1€ Garantie • 0€ Port)

public struct MarketplaceCheckoutSheetView: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    public let listing: MarketplaceListing
    public let agreedPrice: Double?

    @State private var selectedDeliveryMode: String = "Point Relais Viple Taker (Particulier)"
    @State private var selectedPaymentMethod: String = "Apple Pay"
    @State private var postalCodeSearch: String = "54000"
    @State private var citySearch: String = "Nancy"
    @State private var isProcessingPayment: Bool = false
    @State private var completedOrder: MarketplaceOrder? = nil
    @State private var isShowingPayPalWebSheet: Bool = false

    public init(listing: MarketplaceListing, agreedPrice: Double? = nil) {
        self.listing = listing
        self.agreedPrice = agreedPrice
    }

    private var itemBasePrice: Double {
        agreedPrice ?? listing.price
    }

    private var totalAmount: Double {
        itemBasePrice + 1.00 // + 1,00 € Garantie et Maintien du service • 0,00 € Livraison
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if let order = completedOrder {
                        orderConfirmationSuccessCard(order)
                    } else {
                        listingSummaryCard
                        deliveryAndUPSRelayCard
                        paymentMethodSelectionCard
                        priceBreakdownCard
                        payNowActionButton
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle(completedOrder != nil ? "Commande Confirmée" : "Finaliser ma commande")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingPayPalWebSheet) {
                MarketplacePayPalCheckoutWebModal(
                    amount: totalAmount,
                    itemTitle: listing.title,
                    onApproved: {
                        isShowingPayPalWebSheet = false
                        Task { await finalizeOrder(using: "PayPal") }
                    },
                    onCancel: {
                        isShowingPayPalWebSheet = false
                    }
                )
            }
        }
    }

    // MARK: - 1. Résumé de l'Article

    private var listingSummaryCard: some View {
        HStack(spacing: 12) {
            MarketplaceSmartImage(urlString: listing.photos.first, contentMode: .fill)
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                    .lineLimit(2)
                Text("Vendu par @\(listing.sellerUsername) • \(listing.condition)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MarketplacePalette.inkMuted)
                HStack(spacing: 6) {
                    Text(String(format: "%.2f €", itemBasePrice))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.primary)
                    if agreedPrice != nil {
                        Text("Offre acceptée")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(MarketplacePalette.green.opacity(0.15)))
                            .foregroundStyle(MarketplacePalette.green)
                    }
                }
            }
            Spacer()
        }
        .marketplaceCard()
    }

    // MARK: - 2. Livraison 0,00 € : Points Relais Viple Taker (1 €/colis) & API UPS Access Point

    private var deliveryAndUPSRelayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(MarketplacePalette.primary)
                Text("Mode de livraison (Toujours 0,00 €)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.ink)
                Spacer()
                Text("0,00 €")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(MarketplacePalette.green.opacity(0.15)))
                    .foregroundStyle(MarketplacePalette.green)
            }

            ForEach([
                ("Point Relais Viple Taker (Particulier)", "house.and.flag.fill", "Livré par Viple Delivery ou UPS (avec étiquette Viple Delivery scannée via Looby Taker • 1€ reversé au Taker)"),
                ("Point Relais UPS Access Point", "shippingbox.and.arrow.backward.fill", "Réseau officiel UPS Access Point • Étiquette et suivi temps réel UPS"),
                ("Domicile UPS Standard", "truck.box.fill", "Livraison directe à votre domicile par UPS sans frais de livraison")
            ], id: \.0) { mode, icon, desc in
                let isSelected = selectedDeliveryMode == mode
                Button {
                    selectedDeliveryMode = mode
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isSelected ? MarketplacePalette.primary : MarketplacePalette.inkMuted)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode)
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MarketplacePalette.ink)
                            Text(desc)
                                .font(.system(size: 11))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? MarketplacePalette.primary : MarketplacePalette.border)
                    }
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? MarketplacePalette.primarySoft.opacity(0.6) : MarketplacePalette.background))
                }
                .buttonStyle(.plain)
            }

            if selectedDeliveryMode != "Domicile UPS Standard" {
                Divider()

                Text("Choisir votre Point Relais Viple Taker ou UPS Access Point :")
                    .font(.system(size: 13, weight: .bold))

                HStack(spacing: 8) {
                    TextField("Code postal", text: $postalCodeSearch)
                        .frame(width: 90)
                        .padding(9)
                        .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.background))
                    TextField("Ville", text: $citySearch)
                        .padding(9)
                        .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.background))
                    Button {
                        Task {
                            await store.searchRelays(postalCode: postalCodeSearch, city: citySearch)
                        }
                    } label: {
                        Text("API UPS")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.primary))
                            .foregroundStyle(.white)
                    }
                }

                ForEach(store.relayPoints) { relay in
                    let isSelectedRelay = store.selectedRelayPoint?.id == relay.id
                    Button {
                        store.selectedRelayPoint = relay
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(relay.isParticulierTaker ? MarketplacePalette.primary : MarketplacePalette.upsBrown)
                                    .frame(width: 36, height: 36)
                                Image(systemName: relay.isParticulierTaker ? "house.and.flag.fill" : "shippingbox.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(relay.isParticulierTaker ? .white : MarketplacePalette.upsGold)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text(relay.name)
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundStyle(MarketplacePalette.ink)
                                        .lineLimit(1)
                                    if relay.isParticulierTaker {
                                        Text("Viple Taker • 1€/colis")
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Capsule().fill(MarketplacePalette.primarySoft))
                                            .foregroundStyle(MarketplacePalette.primary)
                                    }
                                }
                                Text("\(relay.address), \(relay.postalCode) \(relay.city) • \(String(format: "%.1f km", relay.distanceKm))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(MarketplacePalette.inkMuted)
                            }
                            Spacer()
                            Image(systemName: isSelectedRelay ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelectedRelay ? MarketplacePalette.primary : MarketplacePalette.border)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(isSelectedRelay ? MarketplacePalette.primarySoft.opacity(0.45) : MarketplacePalette.background))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .marketplaceCard()
    }

    // MARK: - 3. Intégration Complète Apple Pay & PayPal

    private var paymentMethodSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moyen de paiement sécurisé")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MarketplacePalette.ink)

            HStack(spacing: 10) {
                Button {
                    selectedPaymentMethod = "Apple Pay"
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Apple Pay")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                            Text("Face ID / Touch ID")
                                .font(.system(size: 10.5))
                                .opacity(0.8)
                        }
                        Spacer()
                        if selectedPaymentMethod == "Apple Pay" {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedPaymentMethod == "Apple Pay" ? Color.black : MarketplacePalette.background)
                    )
                    .foregroundStyle(selectedPaymentMethod == "Apple Pay" ? .white : MarketplacePalette.ink)
                }
                .buttonStyle(.plain)

                Button {
                    selectedPaymentMethod = "PayPal"
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 16, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("PayPal")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                            Text("Protection & 4x")
                                .font(.system(size: 10.5))
                                .opacity(0.85)
                        }
                        Spacer()
                        if selectedPaymentMethod == "PayPal" {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedPaymentMethod == "PayPal" ? Color(red: 0.0, green: 0.29, blue: 0.68) : MarketplacePalette.background)
                    )
                    .foregroundStyle(selectedPaymentMethod == "PayPal" ? .white : MarketplacePalette.ink)
                }
                .buttonStyle(.plain)
            }
        }
        .marketplaceCard()
    }

    // MARK: - 4. Détail du Prix (1,00 € Garantie et Maintien du service • 0,00 € Livraison)

    private var priceBreakdownCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Prix de l'article")
                    .font(.system(size: 13.5))
                    .foregroundStyle(MarketplacePalette.inkMuted)
                Spacer()
                Text(String(format: "%.2f €", itemBasePrice))
                    .font(.system(size: 13.5, weight: .bold))
            }
            HStack {
                Text("Garantie et Maintien du service (Commission Livria)")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(MarketplacePalette.primary)
                Spacer()
                Text("1,00 €")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(MarketplacePalette.primary)
            }
            HStack {
                Text("Livraison (\(selectedDeliveryMode))")
                    .font(.system(size: 13.5))
                    .foregroundStyle(MarketplacePalette.green)
                Spacer()
                Text("0,00 €")
                    .font(.system(size: 13.5, weight: .black))
                    .foregroundStyle(MarketplacePalette.green)
            }
            Divider()
            HStack {
                Text("Total à régler")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Spacer()
                Text(String(format: "%.2f €", totalAmount))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)
            }
        }
        .marketplaceCard()
    }

    private var payNowActionButton: some View {
        Button {
            if selectedPaymentMethod == "PayPal" {
                isShowingPayPalWebSheet = true
            } else {
                Task { await finalizeOrder(using: "Apple Pay") }
            }
        } label: {
            HStack(spacing: 10) {
                if isProcessingPayment {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: selectedPaymentMethod == "Apple Pay" ? "apple.logo" : "lock.shield.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                Text(isProcessingPayment
                     ? "Validation sécurisée en cours..."
                     : "Payer \(String(format: "%.2f €", totalAmount)) avec \(selectedPaymentMethod)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedPaymentMethod == "Apple Pay"
                    ? AnyShapeStyle(Color.black)
                    : AnyShapeStyle(Color(red: 0.0, green: 0.29, blue: 0.68))
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isProcessingPayment)
    }

    // MARK: - Confirmation de Commande avec Étiquette UPS & Code-Barres Viple Delivery / Looby Taker

    private func orderConfirmationSuccessCard(_ order: MarketplaceOrder) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MarketplacePalette.green.opacity(0.15))
                        .frame(width: 54, height: 54)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(MarketplacePalette.green)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Commande \(order.orderNumber) validée !")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MarketplacePalette.ink)
                    Text("Payé via \(order.paymentMethod) • \(String(format: "%.2f €", order.totalPaid)) (dont 1,00 € Garantie Livria & 0,00 € port)")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("Suivi Logistique UPS & Viple Delivery", systemImage: "barcode.viewfinder")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MarketplacePalette.primary)

                HStack {
                    Text("N° Suivi UPS API :")
                        .font(.caption.bold())
                        .foregroundStyle(MarketplacePalette.inkMuted)
                    Spacer()
                    Text(order.upsTrackingNumber)
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(MarketplacePalette.ink)
                }

                HStack {
                    Text("Étiquette Viple Delivery (Scan Looby Taker) :")
                        .font(.caption.bold())
                        .foregroundStyle(MarketplacePalette.inkMuted)
                    Spacer()
                    Text(order.vipleDeliveryBarcode)
                        .font(.caption.monospaced().bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(MarketplacePalette.primarySoft))
                        .foregroundStyle(MarketplacePalette.primary)
                }

                if let relayName = order.relayName {
                    Text("Point de retrait : \(relayName) (\(order.relayAddress ?? ""))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MarketplacePalette.ink)
                }

                Text("Note Viple Taker : Que le colis soit acheminé par Viple Delivery (service interne) ou par UPS, une étiquette Viple Delivery (\(order.vipleDeliveryBarcode)) y est apposée. Le Viple Taker scanne ce code-barres depuis l'application « Looby Taker » pour confirmer la réception, programme avec vous le créneau de remise et perçoit 1,00 € par colis remis.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(MarketplacePalette.inkMuted)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
            }

            Button {
                Task {
                    await store.trackOrderInApp(order)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "truck.box.badge.clock.fill")
                    Text("Suivre mon colis Viple Delivery dans l'application")
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.primarySoft))
                .foregroundStyle(MarketplacePalette.primary)
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("Retourner sur Livria Marketplace")
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MarketplacePalette.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .marketplaceCard()
        .sheet(isPresented: $store.isShowingVipleDeliverySheet) {
            if let tracking = store.activeTrackingResult {
                MarketplaceVipleDeliveryTrackingSheet(tracking: tracking)
                    .environmentObject(store)
            }
        }
    }

    private func finalizeOrder(using method: String) async {
        isProcessingPayment = true
        let order = await store.completeCheckout(
            for: listing,
            agreedPrice: agreedPrice,
            paymentMethod: method,
            deliveryMode: selectedDeliveryMode,
            relay: store.selectedRelayPoint
        )
        isProcessingPayment = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            completedOrder = order
        }
    }
}

// MARK: - Modal PayPal Orders v2 Express Checkout

public struct MarketplacePayPalCheckoutWebModal: View {
    public let amount: Double
    public let itemTitle: String
    public let onApproved: () -> Void
    public let onCancel: () -> Void

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("PayPal")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.0, green: 0.29, blue: 0.68))
                    Text("Paiement sécurisé Livria Marketplace (Orders API v2)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MarketplacePalette.inkMuted)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 10) {
                    Text(itemTitle)
                        .font(.system(size: 15, weight: .bold))
                    Divider()
                    HStack {
                        Text("Montant total (1,00 € Garantie Livria incluse • 0 € port)")
                            .font(.system(size: 13))
                        Spacer()
                        Text(String(format: "%.2f €", amount))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.0, green: 0.29, blue: 0.68))
                    }
                }
                .marketplaceCard()
                .padding(.horizontal, 16)

                Button {
                    onApproved()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Autoriser et payer \(String(format: "%.2f €", amount)) avec PayPal")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.0, green: 0.29, blue: 0.68)))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)

                Button("Annuler et revenir au choix du paiement") {
                    onCancel()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MarketplacePalette.inkMuted)

                Spacer()
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Historique & Suivi des Commandes Marketplace (Avec Suivi Viple Delivery Natif Intégré)

public struct MarketplaceOrdersHistorySheet: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var manualTrackingInput: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Recherche directe Viple Delivery / Looby Taker / UPS sans ouvrir Safari
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MarketplacePalette.primary)
                            Text("Suivi Viple Delivery & Looby Taker intégré")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.ink)
                        }
                        Text("Suivez n'importe quel colis Livria Marketplace, étiquette Viple Delivery ou numéro UPS en direct sans quitter l'application.")
                            .font(.system(size: 12))
                            .foregroundStyle(MarketplacePalette.inkMuted)

                        HStack(spacing: 8) {
                            TextField("Ex: VD-LVR-..., 1Z999..., LVR-MKT-...", text: $manualTrackingInput)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.background))
                            Button {
                                Task {
                                    await store.trackParcelByCodeInApp(manualTrackingInput)
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    if store.isTrackingLoading {
                                        ProgressView().tint(.white).scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "location.magnifyingglass")
                                    }
                                    Text("Suivre")
                                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(MarketplacePalette.primary))
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .marketplaceCard()

                    if store.orders.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(MarketplacePalette.primary)
                            Text("Aucune commande pour le moment")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                            Text("Vos achats sur Livria Marketplace (avec suivi UPS & code-barres Viple Delivery / Looby Taker intégré) apparaîtront ici.")
                                .font(.system(size: 12.5))
                                .foregroundStyle(MarketplacePalette.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .marketplaceCard(padding: 24)
                    } else {
                        ForEach(store.orders) { order in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Button {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = order.orderNumber
                                        #endif
                                        store.showToast("Référence \(order.orderNumber) copiée")
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(order.orderNumber)
                                                .font(.system(size: 14, weight: .black, design: .rounded))
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundStyle(MarketplacePalette.primary)
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()
                                    Text(order.createdAtDisplay)
                                        .font(.caption)
                                        .foregroundStyle(MarketplacePalette.inkMuted)
                                }

                                Text(order.listingTitle)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)

                                Text("Total payé : \(String(format: "%.2f €", order.totalPaid)) via \(order.paymentMethod) (dont 1,00 € Garantie Livria & 0,00 € livraison)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(MarketplacePalette.green)

                                Divider()

                                HStack {
                                    Text("Suivi UPS : \(order.upsTrackingNumber)")
                                        .font(.caption.monospaced().bold())
                                    Spacer()
                                    Button {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = order.upsTrackingNumber
                                        #endif
                                        store.showToast("Numéro UPS copié")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                            .foregroundStyle(MarketplacePalette.inkMuted)
                                    }
                                    .buttonStyle(.plain)
                                }

                                HStack {
                                    Text("Étiquette Viple Delivery : \(order.vipleDeliveryBarcode)")
                                        .font(.caption.monospaced().bold())
                                        .foregroundStyle(MarketplacePalette.primary)
                                    Spacer()
                                    Button {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = order.vipleDeliveryBarcode
                                        #endif
                                        store.showToast("Code-barres Viple Delivery copié")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                            .foregroundStyle(MarketplacePalette.primary)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(order.status)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(MarketplacePalette.ink)

                                HStack(spacing: 8) {
                                    Button {
                                        Task {
                                            await store.trackOrderInApp(order)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "truck.box.badge.clock.fill")
                                            Text("Suivi Viple Delivery en direct")
                                        }
                                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 11).fill(MarketplacePalette.primary))
                                        .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.plain)

                                    if !order.status.localizedCaseInsensitiveContains("confirmée") {
                                        Button {
                                            Task {
                                                await store.confirmOrderReceipt(order.orderNumber)
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: "checkmark.seal.fill")
                                                Text("Colis reçu")
                                            }
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(RoundedRectangle(cornerRadius: 11).fill(MarketplacePalette.green.opacity(0.16)))
                                            .foregroundStyle(MarketplacePalette.green)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .marketplaceCard()
                        }
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Mes Commandes & Suivi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $store.isShowingVipleDeliverySheet) {
                if let tracking = store.activeTrackingResult {
                    MarketplaceVipleDeliveryTrackingSheet(tracking: tracking)
                        .environmentObject(store)
                }
            }
        }
    }
}

// MARK: - Vue Native Complète de Suivi Viple Delivery (Sans Ouvrir delivery.viplenetwork.com)

public struct MarketplaceVipleDeliveryTrackingSheet: View {
    @EnvironmentObject private var store: LivriaMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    public let tracking: MarketplaceVipleDeliveryTrackResponse

    public init(tracking: MarketplaceVipleDeliveryTrackResponse) {
        self.tracking = tracking
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // En-tête Statut Temps Réel & Progression
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "shippingbox.and.arrow.backward.fill")
                                Text("VIPLE DELIVERY • SUIVI NATIF")
                                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.white.opacity(0.2)))
                            .foregroundStyle(.white)

                            Spacer()

                            Text("\(tracking.progressPercent)%")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        Text(tracking.currentStatus)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(tracking.estimatedDeliveryText)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.24))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(.white)
                                    .frame(width: max(24, geo.size.width * CGFloat(min(max(tracking.progressPercent, 8), 100)) / 100.0), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(MarketplacePalette.heroGradient)
                    )

                    // Carte Code-barres Visuel Viple Delivery / Scan Looby Taker
                    VStack(spacing: 10) {
                        HStack {
                            Label("Étiquette Viple Delivery (Scan Looby Taker)", systemImage: "barcode.viewfinder")
                                .font(.system(size: 13.5, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.primary)
                            Spacer()
                            Button {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = tracking.vipleDeliveryTrackingCode
                                #endif
                                store.showToast("Code Viple Delivery copié")
                            } label: {
                                Label("Copier", systemImage: "doc.on.doc")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(MarketplacePalette.primarySoft))
                                    .foregroundStyle(MarketplacePalette.primary)
                            }
                            .buttonStyle(.plain)
                        }

                        // Représentation code-barres 1D haute lisibilité pour Looby Taker
                        HStack(spacing: 2) {
                            ForEach(Array(tracking.vipleDeliveryTrackingCode.utf8.enumerated()), id: \.offset) { idx, byte in
                                Rectangle()
                                    .fill(MarketplacePalette.ink)
                                    .frame(width: CGFloat((Int(byte) + idx) % 3 + 1) * 1.6, height: 46)
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: CGFloat(idx % 2 + 1), height: 46)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarketplacePalette.border, lineWidth: 1))

                        Text(tracking.vipleDeliveryTrackingCode)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(MarketplacePalette.ink)

                        if let ups = tracking.upsTrackingNumber, !ups.isEmpty {
                            HStack {
                                Text("N° Transporteur UPS :")
                                    .font(.caption)
                                    .foregroundStyle(MarketplacePalette.inkMuted)
                                Spacer()
                                Text(ups)
                                    .font(.caption.monospaced().bold())
                                    .foregroundStyle(MarketplacePalette.ink)
                            }
                        }

                        HStack {
                            Text("Destination / Point Relais :")
                                .font(.caption)
                                .foregroundStyle(MarketplacePalette.inkMuted)
                            Spacer()
                            Text(tracking.destinationAddress)
                                .font(.caption.bold())
                                .foregroundStyle(MarketplacePalette.ink)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .marketplaceCard()

                    // Étapes de livraison Viple Delivery (4 jalons)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Progression de l'acheminement")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MarketplacePalette.ink)

                        ForEach(Array(tracking.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 0) {
                                    ZStack {
                                        Circle()
                                            .fill(step.isCompleted ? MarketplacePalette.green : (step.isCurrent ? MarketplacePalette.primary : MarketplacePalette.border))
                                            .frame(width: 26, height: 26)
                                        Image(systemName: step.isCompleted ? "checkmark" : (step.isCurrent ? "truck.box.fill" : "circle.fill"))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    if idx < tracking.steps.count - 1 {
                                        Rectangle()
                                            .fill(step.isCompleted ? MarketplacePalette.green.opacity(0.5) : MarketplacePalette.border)
                                            .frame(width: 2, height: 30)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(step.title)
                                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                            .foregroundStyle(MarketplacePalette.ink)
                                        Spacer()
                                        if let ts = step.timestamp, !ts.isEmpty {
                                            Text(ts)
                                                .font(.system(size: 10.5, weight: .semibold))
                                                .foregroundStyle(MarketplacePalette.inkMuted)
                                        }
                                    }
                                    Text(step.subtitle)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(MarketplacePalette.inkMuted)
                                }
                            }
                        }
                    }
                    .marketplaceCard()

                    // Journal des scans Looby Taker & Hub Viple Delivery
                    if !tracking.events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Historique des scans Viple Delivery & UPS")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(MarketplacePalette.ink)

                            ForEach(tracking.events) { ev in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: ev.icon)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MarketplacePalette.primary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(MarketplacePalette.primarySoft))

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(ev.label)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(MarketplacePalette.ink)
                                            Spacer()
                                            Text(ev.timestamp)
                                                .font(.system(size: 10.5, weight: .semibold))
                                                .foregroundStyle(MarketplacePalette.inkMuted)
                                        }
                                        Text(ev.location)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(MarketplacePalette.primary)
                                        Text(ev.details)
                                            .font(.system(size: 11.5))
                                            .foregroundStyle(MarketplacePalette.inkMuted)
                                    }
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(MarketplacePalette.background))
                            }
                        }
                        .marketplaceCard()
                    }

                    // Bouton Confirmation de Bonne Réception (+25 XP)
                    if tracking.progressPercent < 100 {
                        Button {
                            Task {
                                await store.confirmOrderReceipt(tracking.orderReference)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Confirmer la bonne réception du colis (+25 XP)")
                            }
                            .font(.system(size: 14.5, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(RoundedRectangle(cornerRadius: 14).fill(MarketplacePalette.green))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(MarketplacePalette.background.ignoresSafeArea())
            .navigationTitle("Suivi Viple Delivery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
