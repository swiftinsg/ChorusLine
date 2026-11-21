import Combine
import Foundation

// MARK: - Shared progress

/// Progress shared across all lesson modules.
/// `StudioState` is created in `HomeView` and injected into child views via `.environmentObject`.
final class StudioState: ObservableObject {
    /// Persisted set of completed module IDs so progress survives app restarts.
    @Published var completed: Set<Int> = Set(UserDefaults.standard.array(forKey: "completedModules") as? [Int] ?? []) {
        didSet { UserDefaults.standard.set(Array(completed), forKey: "completedModules") }
    }
    /// When non-nil, `HomeView` shows the completion overlay for that module, then clears it.
    @Published var completionEvent: Int? = nil
    /// Last selected progression/beat, shared across modules and sandbox as a starting point.
    @Published var selectedProgression = 0
    @Published var selectedBeat = 0
    /// Whether the current lesson slideshow should show the spin-to-advance hint.
    @Published var showModuleSpinHint = false

    /// Marks a module complete. If `animate` is true, triggers the home-screen completion animation.
    func finish(_ module: Int, animate: Bool = true) {
        if animate { completionEvent = module }
        completed.insert(module)
    }

    /// Shows the swipe hint only for the first lesson module opened on first app use.
    /// The one-time flag is stored in UserDefaults so it persists across launches.
    func beginModule(_ index: Int) {
        let key = "didShowModuleSwipeHint"
        // Only lesson modules (0-3) participate in the one-time onboarding hint.
        if (0...3).contains(index) && !UserDefaults.standard.bool(forKey: key) {
            showModuleSpinHint = true
            UserDefaults.standard.set(true, forKey: key)
        } else {
            showModuleSpinHint = false
        }
    }
}
