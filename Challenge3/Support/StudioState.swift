import Combine
import Foundation

// MARK: - Shared progress

/// Progress shared across all lesson modules.
final class StudioState: ObservableObject {
    @Published var completed: Set<Int> = Set(UserDefaults.standard.array(forKey: "completedModules") as? [Int] ?? []) {
        didSet { UserDefaults.standard.set(Array(completed), forKey: "completedModules") }
    }
    @Published var completionEvent: Int? = nil
    @Published var selectedProgression = 0
    @Published var selectedBeat = 0
    /// Whether the current lesson slideshow should show the spin-to-advance hint.
    @Published var showModuleSpinHint = false

    func finish(_ module: Int, animate: Bool = true) {
        if animate { completionEvent = module }
        completed.insert(module)
    }

    /// Shows the swipe hint only for the first lesson module opened on first app use.
    func beginModule(_ index: Int) {
        let key = "didShowModuleSwipeHint"
        if (0...3).contains(index) && !UserDefaults.standard.bool(forKey: key) {
            showModuleSpinHint = true
            UserDefaults.standard.set(true, forKey: key)
        } else {
            showModuleSpinHint = false
        }
    }
}
