import SwiftUI

@main
/// App entry point. The app starts at `HomeView`, which owns navigation and shared state.
struct Challenge3App: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
