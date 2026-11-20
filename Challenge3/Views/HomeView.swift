import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The main menu listing the four lesson modules and the sandbox.
struct HomeView: View {
    @StateObject private var state = StudioState()
    @State private var finishingModule: Int? = nil
    @State private var completionStage = 0
    @State private var openingModule: Int? = nil
    @State private var openingStage = 0
    @State private var path: [Int] = []
    private let titles = ["Song Structure", "Chord Progression", "Drum Beats", "Melody"]
    private let colors: [Color] = Array(repeating: Palette.accent, count: 4)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ScrollView {
                    let compact = proxy.size.height < 700
                    let wide = horizontalSizeClass == .regular || proxy.size.width > 700
                    let vinylSize = max(56, min(wide ? 140 : 116, min(proxy.size.width, proxy.size.height) * 0.16))
                    let columns = Array(repeating: GridItem(.flexible(), spacing: compact ? 10 : 14), count: wide ? 4 : 2)

                    VStack(spacing: compact ? 12 : 18) {
                    Text("CHORUS LINE")
                        .font(.system(size: compact ? 30 : 36, weight: .bold))
                        .tracking(1)
                        .padding(.top, compact ? 6 : 14)
                    LazyVGrid(columns: columns, spacing: compact ? 12 : 16) {
                        ForEach(0..<4) { index in
                            Button { openModule(index) } label: {
                                VStack(spacing: compact ? 5 : 8) {
                                    if state.completed.contains(index) {
                                        RecordPlayerBadge(color: colors[index], size: vinylSize)
                                    } else {
                                        Vinyl(color: colors[index], size: vinylSize, showsGlow: false)
                                    }
                                    Text(titles[index]).font(.system(size: compact ? 13 : 15, weight: .bold))
                                    if state.completed.contains(index) {
                                        Text("COMPLETED ✓")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    }
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
                                RecordPlayerBadge(color: Palette.gold, size: vinylSize * 0.8, accent: Palette.gold)
                            } else {
                                Vinyl(color: Palette.gold, size: vinylSize * 0.8, showsGlow: false)
                            }
                            Text("Sandbox")
                                .font(.system(size: compact ? 20 : 23, weight: .bold))
                            Spacer(minLength: 0)
                        }
                        .padding(compact ? 14 : 18)
                        .frame(maxWidth: .infinity)
                        .background(Palette.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.gold.opacity(0.35)))
                    }.buttonStyle(.plain)
                    Button { openModule(5) } label: {
                        HStack(spacing: compact ? 12 : 16) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: compact ? 18 : 20, weight: .semibold))
                                .foregroundStyle(Palette.accent)
                            Text("Saved Songs")
                                .font(.system(size: compact ? 17 : 19, weight: .bold))
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(compact ? 12 : 14)
                        .frame(maxWidth: .infinity)
                        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                    Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }
            .background(Palette.background.ignoresSafeArea()).foregroundStyle(Palette.cream)
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .navigationDestination(for: Int.self) { index in
                Group {
                    switch index {
                    case 0: StructureView()
                    case 1: ChordLessonView()
                    case 2: DrumLessonView()
                    case 3: MelodyView()
                    case 4: SandboxView()
                    case 5: SongLibraryView()
                    default: SandboxView()
                    }
                }.environmentObject(state)
            }
        }
        .tint(Palette.accent)
        .overlay {
            if let module = openingModule {
                OpeningRecordAnimation(
                    color: module == 4 ? Palette.gold : (colors.indices.contains(module) ? colors[module] : Palette.accent),
                    stage: openingStage,
                    accent: module == 4 ? Palette.gold : Palette.accent
                )
                .transition(.opacity).allowsHitTesting(true)
            }
            if let module = finishingModule {
                RecordPlayerCompletion(
                    color: module == 4 ? Palette.gold : (colors.indices.contains(module) ? colors[module] : Palette.accent),
                    stage: completionStage,
                    accent: module == 4 ? Palette.gold : Palette.accent
                )
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
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                #endif
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
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        withAnimation(.easeInOut(duration: 0.85)) { openingStage = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            path.append(index)
            withAnimation(.easeOut(duration: 0.25)) { openingModule = nil }
        }
    }
}
