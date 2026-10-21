import SwiftUI

@main
public struct LivriaSocialApp: App {
    @StateObject private var social = LivriaSocialViewModel()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            SocialMainTabView()
                .environmentObject(social)
        }
    }
}
