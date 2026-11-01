import PhotosUI
import SwiftUI
import UIKit

/// 편집 화면에서 고르는 실행 방법
enum LaunchKind: String, CaseIterable, Identifiable, Hashable {
    case melonx, nxShortcut, nxStikDebug, nxLiveContainer, madeira, ideck, playport, steamLink, customURL

    var id: Self { self }

    var title: String {
        switch self {
        case .melonx: "MeloNX (스위치 에뮬레이터)"
        case .nxShortcut: "nxnative 게임 앱 · 단축어로"
        case .nxStikDebug: "nxnative 게임 앱 · StikDebug로"
        case .nxLiveContainer: "nxnative 게임 앱 · LiveContainer 안"
        case .madeira: "Madeira (PC 게임)"
        case .ideck: "iDeck 열기"
        case .playport: "Playport 열기"
        case .steamLink: "Steam Link (PC 스트리밍)"
        case .customURL: "직접 입력한 링크"
        }
    }

    var runner: EngineID? {
        switch self {
        case .melonx: .melonx
        case .nxShortcut, .nxStikDebug, .nxLiveContainer: .nxnative
        case .madeira: .madeira
        case .ideck: .ideck
        case .playport: .playport
        case .steamLink: .steamLink
        case .customURL: nil
        }
    }

    /// 값을 넣는 칸의 이름. nil이면 칸이 없다.
    var fieldLabel: String? {
        switch self {
        case .melonx: "타이틀 ID 또는 MeloNX의 게임 이름"
        case .nxShortcut: "단축어 이름"
        case .nxStikDebug: "번들 ID"
        case .nxLiveContainer: "LiveContainer 안의 앱 폴더 이름"
        case .madeira: "Madeira 바로가기 링크 (비우면 Madeira만 열기)"
        case .ideck, .playport: nil
        case .steamLink: "Steam Link를 여는 단축어 이름"
        case .customURL: "링크 (예: someapp://…)"
        }
    }

    var help: String {
        switch self {
        case .melonx:
            "MeloNX에서 가져오기를 쓰면 자동으로 채워져요. 직접 넣을 땐 MeloNX 목록에 보이는 게임 이름을 그대로 적어도 돼요."
        case .nxShortcut:
            "단축어 앱 → + → ‘앱 열기’ 동작 → 게임 앱 고르기 → 위 이름으로 저장. 어떻게 설치했든 동작해서 가장 쉬워요."
        case .nxStikDebug:
            "StikDebug가 이 번들 ID의 앱을 바로 실행해요 (LocalDevVPN 켜기). nxnative의 기본값은 org.nxnative.<타이틀 ID 소문자>이고, AltStore · SideStore로 설치하면 뒤에 팀 ID가 붙어요."
        case .nxLiveContainer:
            "LiveContainer에 IPA를 넣었다면 보통 ‘번들 ID.app’이에요 (예: org.nxnative.<타이틀 ID 소문자>.app)."
        case .madeira:
            "Madeira의 게임 상세 화면에서 바로가기 링크를 복사해 붙여넣으면 이 게임이 바로 시작돼요."
        case .ideck:
            "iDeck이 열리고, 게임은 스팀 빅 픽처 화면에서 고르면 돼요."
        case .playport:
            "Playport가 열리고, 게임은 Playport 라이브러리에서 고르면 돼요."
        case .steamLink:
            "단축어 앱에서 ‘앱 열기 → Steam Link’ 단축어를 만들고 그 이름을 적으세요. 같은 Wi-Fi의 PC에서 Steam이 켜져 있어야 해요."
        case .customURL:
            "다른 에뮬레이터나 앱이 지원하는 URL 스킴 링크를 넣으세요."
        }
    }

    var usesShortcut: Bool { self == .nxShortcut || self == .steamLink }
    var acceptsPaste: Bool { self == .madeira || self == .customURL }
}

/// 편집 중인 게임
struct GameDraft: Hashable {
    var title = ""
    var platform: Platform = .nintendoSwitch
    var kind: LaunchKind = .nxShortcut
    var value = ""
    var titleID = ""
    var steamAppID = ""
    var artURLs: [URL] = []
    var heroURL: URL?

    init() {}

    init(game: Game) {
        title = game.title
        platform = game.platform
        titleID = game.titleID ?? ""
        steamAppID = game.steamAppID.map(String.init) ?? ""
        artURLs = game.artURLs
        heroURL = game.heroURL
        switch game.launch {
        case .melonx(let id):
            kind = .melonx
            value = id
        case .madeira(let exe):
            kind = .madeira
            value = exe
        case .liveContainer(let name):
            kind = .nxLiveContainer
            value = name
        case .stikDebug(let bundleID):
            kind = .nxStikDebug
            value = bundleID
        case .shortcut(let name):
            kind = game.runner == .steamLink ? .steamLink : .nxShortcut
            value = name
        case .openEngine(.madeira):
            kind = .madeira
        case .openEngine(.ideck):
            kind = .ideck
        case .openEngine(.playport):
            kind = .playport
        case .openEngine(let engine):
            kind = .customURL
            value = engine.info.openURL?.absoluteString ?? ""
        case .url(let text):
            kind = .customURL
            value = text
        }
    }

    static var nxnative: GameDraft {
        var draft = GameDraft()
        draft.platform = .nintendoSwitch
        draft.kind = .nxShortcut
        return draft
    }

    static var melonx: GameDraft {
        var draft = GameDraft()
        draft.platform = .nintendoSwitch
        draft.kind = .melonx
        return draft
    }

    static var madeiraLink: GameDraft {
        var draft = GameDraft()
        draft.platform = .steam
        draft.kind = .madeira
        return draft
    }

    static var custom: GameDraft {
        var draft = GameDraft()
        draft.platform = .other
        draft.kind = .customURL
        return draft
    }

    static func steam(_ item: SteamAPI.SearchItem, kind: LaunchKind, shortcut: String) -> GameDraft {
        var draft = GameDraft()
        draft.title = item.name
        draft.platform = .steam
        draft.kind = kind
        draft.steamAppID = String(item.id)
        if kind == .steamLink { draft.value = shortcut }
        return draft
    }

    /// 입력값으로 실행 방법을 만든다. 모자라면 nil.
    func launchMethod() -> LaunchMethod? {
        let text = value.trimmed
        switch kind {
        case .melonx:
            return text.isEmpty ? nil : .melonx(titleID: text)
        case .nxShortcut, .steamLink:
            return text.isEmpty ? nil : .shortcut(name: text)
        case .nxStikDebug:
            return text.isEmpty ? nil : .stikDebug(bundleID: text)
        case .nxLiveContainer:
            return text.isEmpty ? nil : .liveContainer(bundleName: text)
        case .madeira:
            if text.isEmpty { return .openEngine(.madeira) }
            return .madeira(exe: Self.madeiraExe(from: text) ?? text)
        case .ideck:
            return .openEngine(.ideck)
        case .playport:
            return .openEngine(.playport)
        case .customURL:
            guard let url = URL(string: text), url.scheme != nil else { return nil }
            return .url(text)
        }
    }

    /// 타이틀 ID나 이름으로 만든 추천 값
    func suggestion(for kind: LaunchKind) -> String? {
        let normalizedID = LibraryStore.normalizedTitleID(self.titleID)
        let name = self.title.trimmed
        switch kind {
        case .nxStikDebug: return normalizedID.map { "org.nxnative.\($0.lowercased())" }
        case .nxLiveContainer: return normalizedID.map { "org.nxnative.\($0.lowercased()).app" }
        case .nxShortcut: return name.isEmpty ? nil : name
        case .melonx: return normalizedID ?? (name.isEmpty ? nil : name)
        default: return nil
        }
    }

    /// madeira://play?exe=… 링크에서 윈도우 경로를 꺼낸다. 링크가 아니면 nil.
    static func madeiraExe(from text: String) -> String? {
        guard text.lowercased().hasPrefix("madeira://") else { return nil }
        if let exe = URLComponents(string: text)?.queryItems?.first(where: { $0.name == "exe" })?.value, !exe.isEmpty {
            return exe
        }
        guard let range = text.range(of: "exe=") else { return nil }
        let raw = String(text[range.upperBound...])
        return raw.removingPercentEncoding ?? raw
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// 게임 추가 · 편집
struct GameEditor: View {
    let editingID: UUID?
    let onDone: () -> Void

    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var toasts: ToastCenter
    @Environment(\.openURL) private var openURL
    @AppStorage("steamLinkShortcut") private var steamLinkShortcut = "Steam Link"

    @State private var draft: GameDraft
    @State private var photo: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var removeCover = false
    @State private var saving = false
    @State private var lastSuggestion = ""

    init(draft: GameDraft, editingID: UUID?, onDone: @escaping () -> Void) {
        _draft = State(initialValue: draft)
        self.editingID = editingID
        self.onDone = onDone
    }

    var body: some View {
        Form {
            gameSection
            launchSection
            if draft.platform == .nintendoSwitch { switchSection }
            if draft.platform == .steam { steamSection }
            coverSection
        }
        .navigationTitle(editingID == nil ? "게임 추가" : "게임 편집")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(editingID == nil ? "추가" : "저장") {
                    Task { await save() }
                }
                .disabled(!canSave || saving)
            }
        }
        .onAppear { applySuggestion(for: draft.kind) }
        .onChange(of: draft.kind) { _, kind in applySuggestion(for: kind) }
        .onChange(of: draft.titleID) { _, _ in applySuggestion(for: draft.kind) }
        .onChange(of: draft.title) { _, _ in applySuggestion(for: draft.kind) }
        .onChange(of: photo) { _, item in loadPhoto(item) }
    }

    private var canSave: Bool {
        !draft.title.trimmed.isEmpty && draft.launchMethod() != nil
    }

    private var existingGame: Game? {
        editingID.flatMap { library.game(withID: $0) }
    }

    // MARK: - 칸

    private var gameSection: some View {
        Section("게임") {
            TextField("이름", text: $draft.title)
            Picker("플랫폼", selection: $draft.platform) {
                ForEach(Platform.allCases) { platform in
                    Text(platform.title).tag(platform)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var launchSection: some View {
        Section {
            Picker("실행 방법", selection: $draft.kind) {
                ForEach(LaunchKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)
            if let label = draft.kind.fieldLabel {
                TextField(label, text: $draft.value, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if draft.kind.acceptsPaste {
                    Button {
                        if let text = UIPasteboard.general.string { draft.value = text.trimmed }
                    } label: {
                        Label("붙여넣기", systemImage: "doc.on.clipboard")
                    }
                }
                if draft.kind.usesShortcut {
                    Button {
                        if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
                    } label: {
                        Label("단축어 앱에서 만들기", systemImage: "square.2.layers.3d")
                    }
                }
            }
        } header: {
            Text("실행 방법")
        } footer: {
            Text(draft.kind.help)
        }
    }

    private var switchSection: some View {
        Section {
            TextField("타이틀 ID (16자리, 선택)", text: $draft.titleID)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.body.monospaced())
        } header: {
            Text("스위치")
        } footer: {
            Text("게임 파일 이름의 [0100…] 부분이에요. 넣으면 nxnative 게임의 번들 ID와 LiveContainer 폴더 이름을 채워 줘요.")
        }
    }

    private var steamSection: some View {
        Section {
            TextField("스팀 App ID (선택)", text: $draft.steamAppID)
                .keyboardType(.numberPad)
            NavigationLink {
                SteamSearchView(dismissOnPick: true) { item in
                    if draft.title.trimmed.isEmpty { draft.title = item.name }
                    draft.steamAppID = String(item.id)
                    draft.artURLs = []
                    draft.heroURL = nil
                }
            } label: {
                Label("스팀에서 찾아 표지 넣기", systemImage: "magnifyingglass")
            }
        } header: {
            Text("스팀")
        } footer: {
            Text("App ID가 있으면 스팀 표지와 배경 이미지를 받아 와요.")
        }
    }

    private var coverSection: some View {
        Section {
            PhotosPicker(selection: $photo, matching: .images) {
                Label(coverData == nil ? "사진에서 표지 고르기" : "다른 사진 고르기", systemImage: "photo")
            }
            if let coverData, let image = UIImage(data: coverData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(.rect(cornerRadius: 12))
            }
            if coverData == nil, existingGame?.coverFile != nil {
                Toggle("직접 고른 표지 지우기", isOn: $removeCover)
            }
        } header: {
            Text("표지")
        } footer: {
            Text("비워 두면 MeloNX 아이콘이나 스팀 표지를 쓰고, 둘 다 없으면 이름으로 표지를 만들어요.")
        }
    }

    // MARK: - 동작

    private func applySuggestion(for kind: LaunchKind) {
        let suggestion = kind == .steamLink ? steamLinkShortcut : (draft.suggestion(for: kind) ?? "")
        if draft.value.isEmpty || draft.value == lastSuggestion {
            draft.value = suggestion
            lastSuggestion = suggestion
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                coverData = data
                removeCover = false
            }
        }
    }

    private func save() async {
        guard let launch = draft.launchMethod() else { return }
        saving = true
        defer { saving = false }

        let title = draft.title.trimmed
        let titleID = LibraryStore.normalizedTitleID(draft.titleID)
        let appID = Int(draft.steamAppID.trimmed)
        var artURLs = draft.artURLs
        var hero = draft.heroURL
        let previous = existingGame

        if let appID, artURLs.isEmpty || previous?.steamAppID != appID {
            // 스팀 App ID가 새로 생기거나 바뀌면 표지 주소를 받아 온다.
            let art = await SteamAPI.artwork(for: appID)
            artURLs = art.covers
            hero = art.hero
        } else if appID == nil, previous?.steamAppID != nil {
            artURLs = []
            hero = nil
        }

        let id: UUID
        if var game = previous {
            game.title = title
            game.platform = draft.platform
            game.runner = draft.kind.runner
            game.launch = launch
            game.titleID = titleID
            game.steamAppID = appID
            game.artURLs = artURLs
            game.heroURL = hero
            library.update(game)
            id = game.id
        } else {
            let game = Game(
                title: title,
                platform: draft.platform,
                runner: draft.kind.runner,
                launch: launch,
                titleID: titleID,
                steamAppID: appID,
                artURLs: artURLs,
                heroURL: hero
            )
            library.add(game)
            id = game.id
            toasts.show("‘\(title)’을(를) 추가했어요")
        }

        if let coverData {
            library.setCover(coverData, for: id)
        } else if removeCover {
            library.clearCover(for: id)
        }
        onDone()
    }
}
