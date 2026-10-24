import SwiftUI

#if canImport(UIKit)
@main
struct LivriaMarketplaceApp: App {
    @StateObject private var store = LivriaMarketplaceViewModel()

    var body: some Scene {
        WindowGroup {
            MarketplaceMainTabView()
                .environmentObject(store)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    store.handleIncomingDeepLink(url)
                }
        }
    }
}
#endif
