import SwiftUI

// MARK: - Navigation Principale « Livria Social » (Bundle ID: store.livria.social • Fil d'actu, Listes, Messages, Jeux XP & Profil)

public struct SocialMainTabView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $social.selectedTab) {
                FeedView()
                    .tabItem {
                        Label("Fil d'actu", systemImage: "sparkles.rectangle.stack.fill")
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
                        Label("Mon Profil", systemImage: "person.crop.circle.badge.sparkles")
                    }
                    .tag(4)
            }
            .tint(LivriaSocialPalette.primary)

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
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
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
    }
}
