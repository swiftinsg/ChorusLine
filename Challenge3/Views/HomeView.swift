// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/HomeView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Main menu and navigation hub. Creates the shared StudioState, lists
//          the four lessons, the sandbox and saved songs, and plays the opening
//          and completion record animations.
//
// HOW IT WORKS:
//   • body — a NavigationStack with integer path routes: 0 StructureView,
//     1 ChordLessonView, 2 DrumLessonView, 3 MelodyView, 4 SandboxView and
//     5 SongLibraryView. GeometryReader adapts card size/spacing on short
//     screens; completed modules show a RecordPlayerBadge. `onChange(of:
//     state.completionEvent)` runs the staged celebration and clears the event
//     after 3.2 s.
//   • openModule(_:) — ignores taps during animations, tells StudioState the
//     module began, plays the intro animation with a haptic, then after 0.95 s
//     pushes the matching route and fades the overlay out.
// -----------------------------------------------------------------------------

// Import SwiftUI so the file can use View, NavigationStack, Color, and other SwiftUI types.
import SwiftUI
// Check at compile time whether UIKit is available before using iOS-only APIs.
#if canImport(UIKit)
// Import UIKit on iOS so haptic feedback can be triggered through UIFeedbackGenerator.
import UIKit
// End of the UIKit-only import block.
#endif

/// The main menu listing the four lesson modules and the sandbox.
// Define the root menu view that lists lesson modules, the sandbox, and saved songs.
struct HomeView: View {
    // Create and own the shared studio state; @StateObject keeps it alive for this view's lifetime and publishes changes.
    @StateObject private var state = StudioState()
    // Local @State tracks which module is currently showing its completion animation, if any.
    @State private var finishingModule: Int? = nil
    // @State drives the step of the completion animation so SwiftUI redraws when the stage changes.
    @State private var completionStage = 0
    // @State tracks which module is currently showing its opening-record animation.
    @State private var openingModule: Int? = nil
    // @State drives the opening animation stage, letting separate phases animate independently.
    @State private var openingStage = 0
    // @State holds the NavigationStack's integer route path, where each number maps to a destination view.
    @State private var path: [Int] = []
    // Store the four lesson titles used for the grid buttons' labels.
    private let titles = ["Song Structure", "Chord Progression", "Drum Beats", "Melody"]
    // Give each lesson module its own vinyl color for visual distinction on the home screen.
    private let colors: [Color] = [
        Color(red: 0.95, green: 0.45, blue: 0.45), // coral/red
        Color(red: 0.45, green: 0.75, blue: 0.55), // green
        Color(red: 0.95, green: 0.65, blue: 0.30), // orange
        Color(red: 0.70, green: 0.55, blue: 0.95)  // purple
    ]
    // Build the view hierarchy; SwiftUI calls this whenever observed state changes.
    var body: some View {
        // Wrap the menu in a stack driven by $path so appending an integer pushes the matching lesson view.
        NavigationStack(path: $path) {
            // Read the available size so the layout can shrink on short screens.
            GeometryReader { proxy in
                // Treat screens shorter than 640 points as compact and use tighter spacing and smaller text.
                let compact = proxy.size.height < 640
                // Clamp the record artwork between 56 and 116 points based on leftover vertical space.
                let vinylSize = max(56, min(116, (proxy.size.height - 380) / 3))

                // Stack the title, lesson grid, and bottom buttons vertically with size-dependent spacing.
                VStack(spacing: compact ? 12 : 18) {
                    // Display the app title at the top of the menu.
                    Text("CHORUS LINE")
                        // Scale the title down on compact screens while keeping it bold.
                        .font(.system(size: compact ? 30 : 36, weight: .bold))
                        // Add slight letter spacing for a stylized music-app heading.
                        .tracking(1)
                        // Add extra top space on taller screens to balance the layout.
                        .padding(.top, compact ? 6 : 14)
                    // Lay out the four lesson buttons in two flexible columns, spaced according to screen height.
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: compact ? 10 : 14), GridItem(.flexible(), spacing: compact ? 10 : 14)], spacing: compact ? 12 : 16) {
                        // Generate one button per lesson index (0 through 3) instead of writing four near-identical views.
                        ForEach(0..<4) { index in
                            // Tapping a lesson button starts its opening animation before navigating to that lesson.
                            Button { openModule(index) } label: {
                                // Stack each lesson's artwork, title, and optional completion label vertically.
                                VStack(spacing: compact ? 5 : 8) {
                                    // Check shared state to decide whether this lesson is already finished.
                                    if state.completed.contains(index) {
                                        // Show a record-player badge for completed lessons to signal achievement.
                                        RecordPlayerBadge(color: colors[index], size: vinylSize)
                                    } else {
                                        // Show the plain artwork for lessons that have not been completed yet.
                                        Vinyl(color: colors[index], size: vinylSize, showsGlow: false)
                                    }
                                    // Show the lesson name from the titles array with bold, size-adaptive typography.
                                    Text(titles[index]).font(.system(size: compact ? 13 : 15, weight: .bold))
                                    // Check completion again to decide whether to display a confirmation label.
                                    if state.completed.contains(index) {
                                        // Display a green check-mark label so users can see which lessons are done.
                                        Text("COMPLETED ✓")
                                            // Use small caption typography so the label does not dominate the card.
                                            .font(.caption2)
                                            // Color the label green to reinforce the success meaning.
                                            .foregroundStyle(.green)
                                    }
                                }
                                // Let the card fill its grid column so taps register across the whole area.
                                .frame(maxWidth: .infinity)
                                // Add vertical padding to give each card a comfortable tap target.
                                .padding(.vertical, compact ? 10 : 14)
                                // Place the card content on a rounded panel background for visual grouping.
                                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
                            // Remove the default button chrome so the custom card design is undisturbed.
                            }.buttonStyle(.plain)
                        }
                    }
                    // Tapping the sandbox button starts its intro animation and navigates to path index 4.
                    Button { openModule(4) } label: {
                        // Arrange the sandbox artwork and title side by side with adaptive spacing.
                        HStack(spacing: compact ? 18 : 24) {
                            // Check whether the sandbox has been completed to choose its badge artwork.
                            if state.completed.contains(4) {
                                // Show a gold record-player badge for a completed sandbox.
                                RecordPlayerBadge(color: Palette.gold, size: vinylSize * 0.8, accent: Palette.gold)
                            } else {
                                // Otherwise fall back to the incomplete artwork.
                                Vinyl(color: Palette.gold, size: vinylSize * 0.8, showsGlow: false)
                            }
                            // Label the sandbox button so users know it is the free-play area.
                            Text("Sandbox")
                                // Make the sandbox label bold and slightly smaller on compact screens.
                                .font(.system(size: compact ? 20 : 23, weight: .bold))
                            // Push later content to the trailing edge of the row.
                            Spacer(minLength: 0)
                        }
                        // Pad the sandbox card more generously on taller screens.
                        .padding(compact ? 14 : 18)
                        // Make the sandbox button stretch across the full width.
                        .frame(maxWidth: .infinity)
                        // Fill the sandbox card with a faint gold tint to distinguish it from lessons.
                        .background(Palette.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                        // Outline the card with a translucent gold border for emphasis.
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.gold.opacity(0.35)))
                    // Keep the sandbox card's custom look instead of the system button style.
                    }.buttonStyle(.plain)
                    // Tapping saved songs navigates to index 5, which is the SongLibraryView route.
                    Button { openModule(5) } label: {
                        // Lay out the saved-songs icon, label, spacer, and chevron in a row.
                        HStack(spacing: compact ? 12 : 16) {
                            // Show a musical-list symbol to make the saved-songs row recognizable.
                            Image(systemName: "music.note.list")
                                // Scale the icon and give it a semibold weight for legibility.
                                .font(.system(size: compact ? 18 : 20, weight: .semibold))
                                // Tint the icon with the app's accent color.
                                .foregroundStyle(Palette.accent)
                            // Name the destination so users know where the row leads.
                            Text("Saved Songs")
                                // Size the saved-songs label according to the available height.
                                .font(.system(size: compact ? 17 : 19, weight: .bold))
                            // Push the chevron to the trailing edge of the row.
                            Spacer(minLength: 0)
                            // Add a standard disclosure chevron to signal that the row navigates forward.
                            Image(systemName: "chevron.right")
                                // Keep the chevron small but visible.
                                .font(.caption.bold())
                                // Dim the chevron so it does not compete with the row title.
                                .foregroundStyle(Palette.muted)
                        }
                        // Add compact-aware padding around the saved-songs row.
                        .padding(compact ? 12 : 14)
                        // Make the row span the full width for a larger tap area.
                        .frame(maxWidth: .infinity)
                        // Put the row on a rounded panel matching the lesson cards.
                        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                    // Apply the same custom button treatment as the other menu cards.
                    }.buttonStyle(.plain)
                    // Absorb leftover vertical space so the menu content sits near the top.
                    Spacer(minLength: 0)
                }
                // Inset the whole menu from the screen edges.
                .padding(.horizontal, 18)
            }
            // Apply the app background and default cream text color to the menu.
            .background(Palette.background).foregroundStyle(Palette.cream)
            // Only apply the toolbar setting when compiling for iOS.
            #if os(iOS)
            // Hide the system navigation bar because the menu draws its own title.
            .toolbar(.hidden, for: .navigationBar)
            // End of the iOS-only toolbar block.
            #endif
            // Map each integer path value pushed onto $path to its corresponding destination view.
            .navigationDestination(for: Int.self) { index in
                // Group the switch result so the shared environmentObject modifier applies to every case.
                Group {
                    // Choose the destination view based on the integer stored in the navigation path.
                    switch index {
                    // Route integer path value 0 to the song structure lesson screen.
                    case 0: StructureView()
                    // Route integer path value 1 to the chord progression lesson screen.
                    case 1: ChordLessonView()
                    // Route integer path value 2 to the drum beats lesson screen.
                    case 2: DrumLessonView()
                    // Route integer path value 3 to the melody lesson screen.
                    case 3: MelodyView()
                    // Route integer path value 4 to the free-play sandbox screen.
                    case 4: SandboxView()
                    // Route integer path value 5 to the saved-songs library screen.
                    case 5: SongLibraryView()
                    // Fall back to the sandbox for any unrecognized path value.
                    default: SandboxView()
                    }
                // Inject the shared StudioState into every destination so lessons can read and finish modules.
                }.environmentObject(state)
            }
        }
        // Color system controls and navigation accents with the app's accent color.
        .tint(Palette.accent)
        // Layer transition animations above the menu without changing its layout.
        .overlay {
            // Show the opening animation only while an opening module is set.
            if let module = openingModule {
                // Draw the animated record that plays before a module opens.
                OpeningRecordAnimation(
                    // Use gold for the sandbox, the lesson color for valid indexes, and the accent color as a safe fallback.
                    color: module == 4 ? Palette.gold : (colors.indices.contains(module) ? colors[module] : Palette.accent),
                    // Pass the current opening stage so the animation can advance through its phases.
                    stage: openingStage,
                    // Use gold accents for the sandbox and the normal accent for lessons.
                    accent: module == 4 ? Palette.gold : Palette.accent
                )
                // Fade the overlay in and out while letting it receive taps during the animation.
                .transition(.opacity).allowsHitTesting(true)
            }
            // Show the completion animation only while a finishing module is set.
            if let module = finishingModule {
                // Draw the record-player celebration shown after a module is finished.
                RecordPlayerCompletion(
                    // Choose the animation color the same way as the opening animation, with a safe fallback.
                    color: module == 4 ? Palette.gold : (colors.indices.contains(module) ? colors[module] : Palette.accent),
                    // Pass the completion stage so the celebration can advance from fade-in to spin to dismissal.
                    stage: completionStage,
                    // Give the sandbox a gold accent and lessons the standard accent.
                    accent: module == 4 ? Palette.gold : Palette.accent
                )
                // Fade the celebration in and out while allowing interaction.
                .transition(.opacity).allowsHitTesting(true)
            }
        }
        // React when a lesson publishes a completion event through the shared state.
        .onChange(of: state.completionEvent) { _, module in
            // Ignore nil events so only real module completions start the celebration.
            guard let module else { return }
            // Store the completed module so the overlay can render its celebration.
            finishingModule = module
            // Reset the animation to its initial stage before scheduling later stages.
            completionStage = 0
            // Schedule the first animation phase shortly after the event arrives.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                // Animate into stage 1 so the record begins its celebratory transition.
                withAnimation(.easeOut(duration: 0.65)) { completionStage = 1 }
            }
            // Schedule the main celebration phase after a short build-up.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                // Spring into the final stage for a playful record-player flourish.
                withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) { completionStage = 2 }
                // Restrict haptic feedback to iOS where UIKit is available.
                #if os(iOS)
                // Fire a heavy haptic to make the completion feel physical.
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                // End of the iOS-only haptic block.
                #endif
            }
            // Schedule cleanup after the celebration has had time to play.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                // Fade out the overlay by clearing the finishing module.
                withAnimation(.easeOut(duration: 0.35)) { finishingModule = nil }
                // Clear the shared event so a later completion can be observed again.
                state.completionEvent = nil
            }
        }
    }
    // Start the opening animation, mark the module as begun, and push its route after a delay.
    private func openModule(_ index: Int) {
        // Ignore extra taps while an intro or celebration is already playing.
        guard openingModule == nil && finishingModule == nil else { return }
        // Record in shared state that the user entered this module so progress can be tracked.
        state.beginModule(index)
        // Set the module for the opening overlay so it knows which color and style to use.
        openingModule = index
        // Reset the opening animation to its first stage before animating forward.
        openingStage = 0
        // Only trigger haptics on iOS.
        #if os(iOS)
        // Give a light tap response so the button press feels responsive.
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // End of the iOS-only haptic block.
        #endif
        // Animate the record into its open state before navigating.
        withAnimation(.easeInOut(duration: 0.85)) { openingStage = 1 }
        // Wait for the opening animation to finish before switching screens.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            // Append the module index to the NavigationStack path to push the matching destination.
            path.append(index)
            // Fade out the opening overlay once the new view is on screen.
            withAnimation(.easeOut(duration: 0.25)) { openingModule = nil }
        }
    }
}
