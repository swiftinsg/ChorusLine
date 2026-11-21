// Combine provides ObservableObject so SwiftUI can watch this shared state for changes.
import Combine
// Foundation provides UserDefaults so lesson progress survives app restarts.
import Foundation

// MARK: - Shared progress

// One observable store lets every lesson screen read and update the same progress.
/// Progress shared across all lesson modules.
final class StudioState: ObservableObject {
    // @Published refreshes observers; initialize from saved IDs, or an empty set on first launch.
    @Published var completed: Set<Int> = Set(UserDefaults.standard.array(forKey: "completedModules") as? [Int] ?? []) {
        // Persist the new set to UserDefaults so completed lessons stay completed after relaunch.
        didSet { UserDefaults.standard.set(Array(completed), forKey: "completedModules") }
    }
    // Remember which module just finished so a one-time completion animation can be triggered.
    @Published var completionEvent: Int? = nil
    // Keep the chosen progression option in sync across lesson screens.
    @Published var selectedProgression = 0
    // Keep the chosen beat option in sync across rhythm lessons.
    @Published var selectedBeat = 0
    /// Whether the current lesson slideshow should show the spin-to-advance hint.
    // @Published makes the hint appear or disappear immediately when this value changes.
    @Published var showModuleSpinHint = false

    // Record a module as finished, optionally publishing an animation event.
    func finish(_ module: Int, animate: Bool = true) {
        // Publish the event only when animation is requested to avoid unwanted visual effects.
        if animate { completionEvent = module }
        // Add the module ID to the set, which also saves it through didSet above.
        completed.insert(module)
    }

    /// Shows the swipe hint only for the first lesson module opened on first app use.
    // Decide at module entry whether the spin-to-advance hint should be visible.
    func beginModule(_ index: Int) {
        // Reuse a single UserDefaults key so the hint is remembered across launches.
        let key = "didShowModuleSwipeHint"
        // Limit the hint to modules 0-3 and only until it has been shown once.
        if (0...3).contains(index) && !UserDefaults.standard.bool(forKey: key) {
            // Reveal the hint for this first qualifying module.
            showModuleSpinHint = true
            // Flag it as shown so the hint never interrupts later sessions.
            UserDefaults.standard.set(true, forKey: key)
        // Hide the hint for later modules or repeat visits.
        } else {
            showModuleSpinHint = false
        }
    }
}
