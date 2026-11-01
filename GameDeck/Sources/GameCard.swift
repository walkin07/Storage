import SwiftUI

/// 라이브러리의 게임 카드 (2:3 표지 + 이름). 선택되면 커지고 테두리가 빛난다.
struct GameCard: View {
    let game: Game
    let isFocused: Bool
    /// nil이면 격자 칸의 너비를 따른다.
    let width: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
            Text(game.title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.white.opacity(isFocused ? 1 : 0.72))
        }
        .frame(width: width)
        .scaleEffect(isFocused ? 1.06 : 1, anchor: .bottom)
        .animation(.snappy(duration: 0.22), value: isFocused)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var cover: some View {
        CoverView(game: game)
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .frame(width: width)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(alignment: .topLeading) {
                PlatformBadge(platform: game.platform, compact: true)
                    .padding(6)
            }
            .overlay(alignment: .topTrailing) {
                if game.favorite {
                    Image(systemName: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow)
                        .padding(7)
                        .background(.black.opacity(0.45), in: .circle)
                        .padding(5)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isFocused ? Color.white : Color.white.opacity(0.08), lineWidth: isFocused ? 3 : 1)
            }
            .shadow(
                color: isFocused ? game.platform.tint.opacity(0.65) : .black.opacity(0.45),
                radius: isFocused ? 18 : 6,
                y: 4
            )
    }
}

/// 선택한 게임의 큰 정보와 플레이 버튼
struct HeroPanel: View {
    let game: Game
    let compact: Bool
    let onPlay: () -> Void
    let onOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack(spacing: 8) {
                PlatformBadge(platform: game.platform)
                if let runner = game.runner {
                    Text(runner.info.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                if game.favorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            Text(game.title)
                .font(compact ? .title2.weight(.bold) : .system(size: 34, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(game.playedSummary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 10) {
                Button(action: onPlay) {
                    Label("플레이", systemImage: "play.fill")
                        .font(.headline)
                        .frame(minWidth: compact ? 96 : 128)
                }
                .buttonStyle(.glassProminent)
                .tint(game.platform.tint)
                Button(action: onOptions) {
                    Label("옵션", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .font(.headline)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
            .padding(.top, compact ? 2 : 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 화면 전체 배경: 선택한 게임의 넓은 이미지(스팀) 또는 표지를 흐리게
struct DeckBackdrop: View {
    let game: Game?

    @EnvironmentObject private var library: LibraryStore
    @State private var image: UIImage?
    @State private var isWide = false

    var body: some View {
        ZStack {
            DeckStyle.background
            if let image {
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .blur(radius: isWide ? 8 : 48)
                    .opacity(isWide ? 0.6 : 0.5)
                    .transition(.opacity)
            }
            LinearGradient(
                colors: [.black.opacity(0.2), .black.opacity(0.55), .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: image)
        .task(id: game?.id) {
            // 게임패드로 빠르게 넘길 때는 마지막 게임만 불러온다.
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
            guard let game else {
                image = nil
                return
            }
            if let hero = game.heroURL, let wide = await ArtworkLoader.shared.image(from: [hero], maxPixel: 1400) {
                guard !Task.isCancelled else { return }
                isWide = true
                image = wide
                return
            }
            let cover = await ArtworkLoader.shared.image(from: library.artCandidates(for: game), maxPixel: 320)
            guard !Task.isCancelled else { return }
            isWide = false
            image = cover
        }
    }
}
