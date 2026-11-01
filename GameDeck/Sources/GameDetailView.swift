import SwiftUI
import UIKit

/// 게임 정보: 큰 표지, 플레이, 실행 방법, 즐겨찾기, 바로가기 링크, 편집, 삭제
struct GameDetailView: View {
    let gameID: UUID
    let onPlay: (Game) -> Void

    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var confirmDelete = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Group {
                if let game = library.game(withID: gameID) {
                    details(game)
                } else {
                    ContentUnavailableView("게임을 찾을 수 없어요", systemImage: "questionmark.square.dashed")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("편집") { editing = true }
                        .disabled(library.game(withID: gameID) == nil)
                }
            }
            .navigationDestination(isPresented: $editing) {
                if let game = library.game(withID: gameID) {
                    GameEditor(draft: GameDraft(game: game), editingID: game.id) { editing = false }
                }
            }
        }
    }

    private func details(_ game: Game) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                CoverView(game: game, maxPixel: 900)
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    .frame(maxWidth: 210)
                    .clipShape(.rect(cornerRadius: 20))
                    .shadow(color: game.platform.tint.opacity(0.45), radius: 24, y: 8)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        PlatformBadge(platform: game.platform)
                        if let runner = game.runner {
                            Text(runner.info.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(game.title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(game.playedSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button {
                    onPlay(game)
                } label: {
                    Label("플레이", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(game.platform.tint)
                .controlSize(.large)
                launchCard(game)
                actions(game)
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog("‘\(game.title)’을(를) 목록에서 지울까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                library.remove(game.id)
                dismiss()
            }
        } message: {
            Text("게임 앱과 파일은 그대로예요. 게임덱 목록에서만 빠져요.")
        }
    }

    private func launchCard(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(game.launch.summary, systemImage: "arrow.up.forward.app")
                .font(.headline)
            if let value = game.launch.value, !value.isEmpty {
                Text(value)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
            Text(Self.tip(for: game.launch))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func actions(_ game: Game) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    library.toggleFavorite(game.id)
                } label: {
                    Label(game.favorite ? "즐겨찾기 해제" : "즐겨찾기", systemImage: game.favorite ? "star.slash" : "star")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    UIPasteboard.general.string = DeckLink.playURL(for: game.id)
                    copied = true
                } label: {
                    Label(copied ? "복사됨" : "바로가기 링크", systemImage: copied ? "checkmark" : "link")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.glass)
            Text("바로가기 링크를 단축어의 ‘URL 열기’에 넣으면 뒷면 탭이나 홈 화면 아이콘으로 이 게임을 바로 켤 수 있어요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("목록에서 삭제", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
        .controlSize(.large)
        .sensoryFeedback(.success, trigger: copied)
    }

    static func tip(for launch: LaunchMethod) -> String {
        switch launch {
        case .melonx:
            "MeloNX가 열리고 이 게임이 바로 시작돼요. JIT가 꺼져 있으면 MeloNX가 StikDebug로 JIT를 켠 뒤 이어서 시작해요."
        case .madeira:
            "Madeira가 열리고 JIT를 켠 뒤 이 게임을 시작해요."
        case .liveContainer:
            "LiveContainer가 안에 넣어 둔 이 앱을 실행해요."
        case .stikDebug:
            "StikDebug가 이 번들 ID의 앱을 실행해요. LocalDevVPN이 켜져 있어야 하고, StikDebug에서 실행을 한 번 허용해야 할 수 있어요."
        case .shortcut:
            "단축어 앱이 이 이름의 단축어를 실행해요. 단축어에는 ‘앱 열기’ 동작으로 게임 앱을 넣어 두세요."
        case .openEngine(let engine):
            "\(engine.info.name)이(가) 열려요. 게임은 그 앱 안에서 고르세요."
        case .url:
            "이 링크를 받을 수 있는 앱이 열려요."
        }
    }
}
