import SwiftUI
import UIKit

/// The main menu listing the four lesson modules and the sandbox.
struct HomeView: View {
    @StateObject private var state = StudioState()
    @State private var finishingModule: Int? = nil
    @State private var completionStage = 0
    @State private var openingModule: Int? = nil
    @State private var openingStage = 0
    @State private var path: [Int] = []
    private let titles = ["Song Structure", "Chord Progression", "Drum Beats", "Melody"]
    private let subtitles = ["Learn how songs are built", "Play chords on a piano", "Explore popular rhythms", "Find your own sound"]
    private let colors: [Color] = [.purple, .cyan, .orange, .mint]
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                let compact = proxy.size.height < 640
                let vinylSize = max(56, min(116, (proxy.size.height - 380) / 3))

                VStack(spacing: compact ? 12 : 18) {
                    Text("CHORUS LINE")
                        .font(.system(size: compact ? 30 : 36, weight: .bold))
                        .tracking(1)
                        .padding(.top, compact ? 6 : 14)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: compact ? 10 : 14), GridItem(.flexible(), spacing: compact ? 10 : 14)], spacing: compact ? 12 : 16) {
                        ForEach(0..<4) { index in
                            Button { openModule(index) } label: {
                                VStack(spacing: compact ? 5 : 8) {
                                    if state.completed.contains(index) {
                                        RecordPlayerBadge(color: colors[index], size: vinylSize)
                                    } else {
                                        Vinyl(color: colors[index], size: vinylSize)
                                    }
                                    Text(titles[index]).font(.system(size: compact ? 13 : 15, weight: .bold))
                                    Text(state.completed.contains(index) ? "COMPLETED ✓" : subtitles[index])
                                        .font(.caption2).foregroundStyle(state.completed.contains(index) ? .green : .gray)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .frame(height: 26, alignment: .top)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, compact ? 10 : 14)
                                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
                            }.buttonStyle(.plain)
                        }
                    }
                    Button { openModule(4) } label: {
                        HStack(spacing: compact ? 18 : 24) {
                            if state.completed.contains(4) {
                                RecordPlayerBadge(color: Palette.gold, size: vinylSize * 0.8)
                            } else {
                                Vinyl(color: Palette.gold, size: vinylSize * 0.8)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Sandbox")
                                    .font(.system(size: compact ? 20 : 23, weight: .bold))
                                Text("Mix chords and drum beats into your song")
                                    .font(.system(size: compact ? 12 : 13))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(compact ? 14 : 18)
                        .frame(maxWidth: .infinity)
                        .background(Palette.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.gold.opacity(0.35)))
                    }.buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
            }
            .background(Palette.background).foregroundStyle(Palette.cream)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { index in
                Group {
                    switch index {
                    case 0: StructureView()
                    case 1: ChordLessonView()
                    case 2: DrumLessonView()
                    case 3: MelodyView()
                    default: SandboxView()
                    }
                }.environmentObject(state)
            }
        }
        .tint(Palette.gold)
        .overlay {
            if let module = openingModule {
                OpeningRecordAnimation(color: module == 4 ? Palette.gold : colors[module], stage: openingStage)
                    .transition(.opacity).allowsHitTesting(true)
            }
            if let module = finishingModule {
                RecordPlayerCompletion(color: module == 4 ? Palette.gold : colors[module], stage: completionStage)
                    .transition(.opacity).allowsHitTesting(true)
            }
        }
        .onChange(of: state.completionEvent) { _, module in
            guard let module else { return }
            finishingModule = module
            completionStage = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.65)) { completionStage = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) { completionStage = 2 }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation(.easeOut(duration: 0.35)) { finishingModule = nil }
                state.completionEvent = nil
            }
        }
    }
    private func openModule(_ index: Int) {
        guard openingModule == nil && finishingModule == nil else { return }
        openingModule = index
        openingStage = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.85)) { openingStage = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            path.append(index)
            withAnimation(.easeOut(duration: 0.25)) { openingModule = nil }
        }
    }
}
