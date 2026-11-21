//
//  ContentView.swift
//  Challenge3
//
//  Created by Z MacPro on 14/11/26.
//

// Import SwiftUI for the View protocol and the built-in views used in this starter screen.
import SwiftUI

// Define a simple SwiftUI view kept as the project's template screen and preview sample.
struct ContentView: View {
    // Build the view's body: a vertical stack holding an image and a text label.
    var body: some View {
        // Arrange the child views vertically using SwiftUI's default spacing.
        VStack {
            // Display a globe SF Symbol as the starter image.
            Image(systemName: "globe")
                // Enlarge the symbol so it is easy to see.
                .imageScale(.large)
                // Color the symbol using the app's current tint color.
                .foregroundStyle(.tint)
            // Show the classic greeting text beneath the image.
            Text("Hello, world!")
        }
        // Add default padding so the content is not flush against the screen edges.
        .padding()
    }
}

// Preview this view in Xcode's canvas without launching the whole app.
#Preview {
    // Render ContentView as the preview's content.
    ContentView()
}
