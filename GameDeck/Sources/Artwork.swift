import SwiftUI
import ImageIO

/// 표지 이미지를 줄여서 읽고 메모리에 보관한다. 후보 주소를 앞에서부터 시도한다.
actor ArtworkLoader {
    static let shared = ArtworkLoader()

    private let cache = NSCache<NSString, UIImage>()
    /// 없는 것으로 확인된 주소 (404 등). 같은 실행 동안 다시 요청하지 않는다.
    private var missing: Set<URL> = []

    init() {
        cache.countLimit = 400
    }

    func image(from candidates: [URL], maxPixel: CGFloat) async -> UIImage? {
        for url in candidates {
            let key = "\(url.absoluteString)#\(Int(maxPixel))" as NSString
            if let cached = cache.object(forKey: key) { return cached }
            if missing.contains(url) { continue }

            if url.isFileURL {
                guard let data = try? Data(contentsOf: url), let image = Self.downsample(data, maxPixel: maxPixel) else {
                    missing.insert(url)
                    continue
                }
                cache.setObject(image, forKey: key)
                return image
            }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard status == 200, let image = Self.downsample(data, maxPixel: maxPixel) else {
                    if status == 200 || (400..<500).contains(status) { missing.insert(url) }
                    continue
                }
                cache.setObject(image, forKey: key)
                return image
            } catch {
                // 오프라인이거나 취소됨: 다음 후보로
                if Task.isCancelled { return nil }
                continue
            }
        }
        return nil
    }

    /// 큰 이미지를 필요한 크기로만 풀어서 스크롤이 끊기지 않게 한다.
    static func downsample(_ data: Data, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// 게임 표지. 세로 표지(스팀)는 꽉 채우고, 정사각형 아이콘(스위치)이나 가로 이미지는 흐린 배경 위 가운데에 둔다.
struct CoverView: View {
    let game: Game
    var maxPixel: CGFloat = 640

    @EnvironmentObject private var library: LibraryStore
    @State private var image: UIImage?

    var body: some View {
        let candidates = library.artCandidates(for: game)
        Color.clear
            .overlay {
                if let image {
                    artwork(image)
                } else {
                    PlaceholderCover(game: game)
                }
            }
            .clipped()
            .task(id: candidates) {
                image = await ArtworkLoader.shared.image(from: candidates, maxPixel: maxPixel)
            }
    }

    @ViewBuilder
    private func artwork(_ image: UIImage) -> some View {
        let ratio = image.size.width / max(image.size.height, 1)
        if ratio < 0.8 {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 22)
                    .overlay(Color.black.opacity(0.3))
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                    .padding(12)
            }
        }
    }
}

/// 표지가 없을 때: 플랫폼 색 그라데이션 위에 게임 이름
struct PlaceholderCover: View {
    let game: Game

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [game.platform.tint.opacity(0.85), game.platform.tint.opacity(0.25), Color.black.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: game.platform.symbol)
                    .font(.system(size: 30, weight: .semibold))
                    .opacity(0.9)
                Text(game.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
            }
            .foregroundStyle(.white)
        }
    }
}
