// -----------------------------------------------------------------------------
// FILE SUMMARY — Challenge3App.swift
// -----------------------------------------------------------------------------
// PURPOSE: App entry point. The @main attribute tells the system where to start;
//          the app launches the HomeView as its first screen.
//
// HOW IT WORKS:
//   • body — declares one WindowGroup scene, letting the system manage the app
//     window while SwiftUI renders HomeView inside it.
// -----------------------------------------------------------------------------

// Import SwiftUI to get the App and Scene protocols used to launch the interface.
import SwiftUI
#if canImport(UIKit)
import UIKit

/// App delegate used to control supported interface orientations per-screen.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Default orientations: portrait on iPhone, all on iPad.
    static let defaultOrientationLock: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    /// The currently allowed orientations; views update this to request rotation.
    static var orientationLock: UIInterfaceOrientationMask = defaultOrientationLock

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}
#endif

// Mark the following type as the app's entry point so the system knows where to start.
@main
// Declare the SwiftUI App object that configures the app's scene and initial screen.
struct Challenge3App: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    // Define the app's scenes; a single window hosts the entire user interface.
    var body: some Scene {
        // Create a WindowGroup so the system can manage the app's window lifecycle.
        WindowGroup {
            // Show the home screen as the first view users see when the app launches.
            HomeView()
        }
    }
}
