import SwiftUI

// MARK: - Navigation Principale « Livria Social » avec Barre d'Onglets Design & Logo "Mon Profil" Garanti

public struct SocialMainTabView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    public init() {}

    public var body: some View {
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
        .preferredColorScheme(.dark)
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
