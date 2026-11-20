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
    func finish(_ module: Int) { completionEvent = module; completed.insert(module) }
}
