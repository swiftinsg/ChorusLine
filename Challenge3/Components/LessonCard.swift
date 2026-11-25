// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/LessonCard.swift
// -----------------------------------------------------------------------------
// PURPOSE: Reusable panel rendering one lesson slide: an accent-coloured heading
//          and body copy on a rounded, subtly outlined card.
//
// HOW IT WORKS:
//   • body — leading-aligned VStack of the bold title and flexible-height
//     description, padded and placed on a rounded Palette.panel background with
//     a faint stroke overlay.
// -----------------------------------------------------------------------------

// Import SwiftUI for Text, VStack, and the layout and styling modifiers used below.
import SwiftUI

// A card groups a heading with its explanation so lessons read as distinct sections.
/// A panel containing a lesson heading and its explanation.
/// Used by `LessonSlideshow` to present each lesson slide's content consistently.
struct LessonCard: View {
    // Heading text for this lesson card.
    let title: String
    // Body copy explaining the lesson topic.
    let description: String
    // Accent color for the card title, matching the module's theme.
    var accent: Color = Palette.accent
    // Compose the card's internal layout and surface styling.
    var body: some View {
        // Stack heading and description vertically with leading alignment and 12-point gaps.
        VStack(alignment: .leading, spacing: 12) {
            // Render the title prominently in bold and color it with the module accent.
            Text(title).font(.title2.bold()).foregroundStyle(accent)
            // Render the explanation in body type using the theme's foreground color.
            Text(description).font(.body).foregroundStyle(Palette.cream)
                // Wrap horizontally but keep the full height so text is never truncated.
                .fixedSize(horizontal: false, vertical: true)
        }
        // Make the stack fill the available width and align content to the leading edge.
        .frame(maxWidth: .infinity, alignment: .leading)
        // Add inner spacing so text does not touch the card edges.
        .padding(22)
        // Draw a rounded panel behind the content using the adaptive panel color.
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
        // Add a subtle border to define the card edge against the background.
        .overlay {
            // Create a rounded rectangle matching the card's corner radius.
            RoundedRectangle(cornerRadius: 20)
                // Stroke it with a barely visible foreground color for a delicate outline.
                .stroke(Palette.cream.opacity(0.08), lineWidth: 1)
        }
    }
}
