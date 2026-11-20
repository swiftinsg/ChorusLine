import SwiftUI

/// A one-octave piano keyboard. Pressing a key reports its MIDI note so the
/// caller can respond (for example, to transpose a chord progression).
struct PianoKeyboard: View {
    let onNote: (Int) -> Void

    private struct KeySpec: Identifiable {
        let id: Int
        let name: String?
        let whiteOffset: Int
    }

    private let whiteKeys: [KeySpec] = [
        .init(id: 60, name: "C", whiteOffset: 0), .init(id: 62, name: "D", whiteOffset: 1),
        .init(id: 64, name: "E", whiteOffset: 2), .init(id: 65, name: "F", whiteOffset: 3),
        .init(id: 67, name: "G", whiteOffset: 4), .init(id: 69, name: "A", whiteOffset: 5),
        .init(id: 71, name: "B", whiteOffset: 6)
    ]
    // whiteOffset is the number of white keys to the left of the black key.
    private let blackKeys: [KeySpec] = [
        .init(id: 61, name: nil, whiteOffset: 1), .init(id: 63, name: nil, whiteOffset: 2),
        .init(id: 66, name: nil, whiteOffset: 4), .init(id: 68, name: nil, whiteOffset: 5),
        .init(id: 70, name: nil, whiteOffset: 6)
    ]

    var body: some View {
        GeometryReader { proxy in
            let whiteWidth = proxy.size.width / CGFloat(whiteKeys.count)
            let blackWidth = whiteWidth * 0.62
            let blackHeight = proxy.size.height * 0.62

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(whiteKeys) { key in
                        PianoKeyView(isBlack: false, label: key.name) { onNote(key.id) }
                            .frame(width: whiteWidth, height: proxy.size.height)
                    }
                }
                ForEach(blackKeys) { key in
                    PianoKeyView(isBlack: true, label: nil) { onNote(key.id) }
                        .frame(width: blackWidth, height: blackHeight)
                        .offset(x: CGFloat(key.whiteOffset) * whiteWidth - blackWidth / 2)
                }
            }
        }
    }
}

private struct PianoKeyView: View {
    let isBlack: Bool
    let label: String?
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button {
            action()
            pressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { pressed = false }
        } label: {
            RoundedRectangle(cornerRadius: isBlack ? 3 : 4)
                .fill(fillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: isBlack ? 3 : 4)
                        .stroke(Color.black.opacity(isBlack ? 0.9 : 0.25), lineWidth: 1)
                }
                .overlay(alignment: .bottom) {
                    if let label {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.black.opacity(0.45))
                            .padding(.bottom, 7)
                    }
                }
                .shadow(color: .black.opacity(isBlack ? 0.4 : 0.08), radius: isBlack ? 2 : 1, y: isBlack ? 2 : 1)
        }
        .buttonStyle(.plain)
    }

    private var fillColor: Color {
        if pressed { return isBlack ? Palette.accent : Color(white: 0.78) }
        return isBlack ? Color(white: 0.06) : .white
    }
}
