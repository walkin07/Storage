import SwiftUI

enum AddRoute: Hashable {
    case editor(GameDraft)
    case steamSearch
    case steamImport
}

/// 게임을 넣는 곳: MeloNX 가져오기, nxnative, 스팀 검색 · 라이브러리, Madeira 링크, 직접 추가
struct AddGameView: View {
    @EnvironmentObject private var engines: EngineMonitor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("steamDefaultLaunch") private var steamDefault: SteamLaunchDefault = .steamLink
    @AppStorage("steamLinkShortcut") private var steamLinkShortcut = "Steam Link"
    @State private var path: [AddRoute] = []
    @State private var meloNXMissing = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    SourceRow(
                        symbol: "square.and.arrow.down",
                        tint: Platform.nintendoSwitch.tint,
                        title: "MeloNX에서 가져오기",
                        subtitle: "MeloNX에 넣어 둔 스위치 게임을 아이콘과 함께 한 번에",
                        status: engines.status(of: .melonx)
                    ) { importFromMeloNX() }
                    SourceRow(
                        symbol: "cpu",
                        tint: Platform.nintendoSwitch.tint,
                        title: "nxnative 게임 추가",
                        subtitle: "Mac에서 만든 게임 앱을 단축어 · StikDebug · LiveContainer로 실행"
                    ) { path.append(.editor(.nxnative)) }
                    SourceRow(
                        symbol: "gamecontroller",
                        tint: Platform.nintendoSwitch.tint,
                        title: "MeloNX 게임 하나만 추가",
                        subtitle: "타이틀 ID나 게임 이름으로"
                    ) { path.append(.editor(.melonx)) }
                } header: {
                    Text("스위치")
                }

                Section {
                    SourceRow(
                        symbol: "magnifyingglass",
                        tint: Platform.steam.tint,
                        title: "스팀에서 게임 찾기",
                        subtitle: "이름으로 찾아 표지와 함께 추가"
                    ) { path.append(.steamSearch) }
                    SourceRow(
                        symbol: "person.crop.square",
                        tint: Platform.steam.tint,
                        title: "내 스팀 라이브러리 가져오기",
                        subtitle: "Steam Web API 키로 가진 게임을 모두"
                    ) { path.append(.steamImport) }
                    SourceRow(
                        symbol: "link",
                        tint: Platform.steam.tint,
                        title: "Madeira 게임 링크로 추가",
                        subtitle: "Madeira 게임 상세에서 복사한 madeira://play 링크",
                        status: engines.status(of: .madeira)
                    ) { path.append(.editor(.madeiraLink)) }
                } header: {
                    Text("스팀 · PC")
                }

                Section {
                    SourceRow(
                        symbol: "plus.app",
                        tint: Platform.other.tint,
                        title: "직접 추가",
                        subtitle: "다른 에뮬레이터나 앱의 링크, 단축어"
                    ) { path.append(.editor(.custom)) }
                } header: {
                    Text("기타")
                }
            }
            .navigationTitle("게임 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .navigationDestination(for: AddRoute.self) { route in
                destination(route)
            }
            .alert("MeloNX를 열 수 없어요", isPresented: $meloNXMissing) {
                Button("MeloNX 받는 곳") { openURL(EngineID.melonx.info.homepage) }
                Button("닫기", role: .cancel) {}
            } message: {
                Text("MeloNX를 설치하고 게임을 넣은 뒤 다시 시도하세요.")
            }
            .onAppear { engines.refresh() }
        }
    }

    @ViewBuilder
    private func destination(_ route: AddRoute) -> some View {
        switch route {
        case .editor(let draft):
            GameEditor(draft: draft, editingID: nil) { dismiss() }
        case .steamSearch:
            SteamSearchView(dismissOnPick: false) { item in
                path.append(.editor(.steam(item, kind: steamDefault.launchKind, shortcut: steamLinkShortcut)))
            }
        case .steamImport:
            SteamImportView { dismiss() }
        }
    }

    private func importFromMeloNX() {
        Task {
            if await Launcher.open(MeloNXBridge.requestURL) == false {
                meloNXMissing = true
            }
        }
    }
}

struct SourceRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let subtitle: String
    var status: EngineMonitor.Status?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if let status {
                    StatusPill(status: status)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

struct StatusPill: View {
    let status: EngineMonitor.Status

    var body: some View {
        Group {
            switch status {
            case .installed:
                Label("설치됨", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .missing:
                Label("없음", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            case .unknown:
                Label("확인 불가", systemImage: "questionmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption.weight(.semibold))
        .labelStyle(.titleAndIcon)
    }
}

/// 스팀 스토어 검색 (키 필요 없음)
struct SteamSearchView: View {
    var dismissOnPick = true
    let onPick: (SteamAPI.SearchItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [SteamAPI.SearchItem] = []
    @State private var loading = false
    @State private var failure: String?

    var body: some View {
        List {
            if let failure {
                Text(failure)
                    .foregroundStyle(.red)
            }
            ForEach(results) { item in
                Button {
                    onPick(item)
                    if dismissOnPick { dismiss() }
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: item.thumbnail) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.secondary.opacity(0.15)
                        }
                        .frame(width: 96, height: 36)
                        .clipShape(.rect(cornerRadius: 6))
                        Text(item.name)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .overlay { statusOverlay }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "스팀 게임 이름")
        .task(id: query) { await search() }
        .navigationTitle("스팀에서 찾기")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if loading {
            ProgressView()
        } else if results.isEmpty, failure == nil {
            if query.trimmed.isEmpty {
                ContentUnavailableView("게임 이름을 입력하세요", systemImage: "magnifyingglass", description: Text("영어 이름으로 찾으면 더 잘 나와요."))
            } else {
                ContentUnavailableView.search(text: query)
            }
        }
    }

    private func search() async {
        let term = query.trimmed
        guard !term.isEmpty else {
            results = []
            failure = nil
            loading = false
            return
        }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        loading = true
        let outcome: Result<[SteamAPI.SearchItem], Error>
        do {
            outcome = .success(try await SteamAPI.search(term))
        } catch {
            outcome = .failure(error)
        }
        guard !Task.isCancelled else { return }
        loading = false
        switch outcome {
        case .success(let found):
            results = found
            failure = nil
        case .failure(let error):
            results = []
            failure = "검색하지 못했어요. \(error.localizedDescription)"
        }
    }
}

/// Steam Web API로 가진 게임을 모두 가져온다.
struct SteamImportView: View {
    let onDone: () -> Void

    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var toasts: ToastCenter
    @AppStorage("steamID") private var steamID = ""
    @AppStorage("steamDefaultLaunch") private var steamDefault: SteamLaunchDefault = .steamLink
    @AppStorage("steamLinkShortcut") private var steamLinkShortcut = "Steam Link"
    @State private var apiKey = Keychain.get(Keychain.steamAPIKey) ?? ""
    @State private var working = false
    @State private var failure: String?

    var body: some View {
        Form {
            Section {
                Text("가진 게임 목록을 받으려면 Steam Web API 키가 필요해요. 키는 이 아이폰의 키체인에만 저장돼요.")
                if let url = URL(string: "https://steamcommunity.com/dev/apikey") {
                    Link(destination: url) {
                        Label("API 키 받기 (도메인 칸은 아무거나, 예: localhost)", systemImage: "key")
                    }
                }
            }
            Section("계정") {
                SecureField("Steam Web API 키", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("스팀 ID 또는 프로필 주소", text: $steamID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
            Section {
                Picker("실행 방법", selection: $steamDefault) {
                    ForEach(SteamLaunchDefault.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            } header: {
                Text("가져온 게임을 여는 방법")
            } footer: {
                Text(steamDefault.help)
            }
            Section {
                Button {
                    Task { await run() }
                } label: {
                    HStack {
                        Text(working ? "가져오는 중…" : "가져오기")
                        Spacer()
                        if working { ProgressView() }
                    }
                }
                .disabled(working || apiKey.trimmed.isEmpty || steamID.trimmed.isEmpty)
            } footer: {
                if let failure {
                    Text(failure).foregroundStyle(.red)
                } else {
                    Text("스팀 프로필의 ‘게임 세부 정보’가 비공개면 목록을 받을 수 없어요.")
                }
            }
        }
        .navigationTitle("스팀 라이브러리")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run() async {
        let key = apiKey.trimmed
        working = true
        failure = nil
        defer { working = false }
        Keychain.set(key, for: Keychain.steamAPIKey)
        do {
            let id = try await SteamAPI.resolveSteamID(steamID, key: key)
            let owned = try await SteamAPI.ownedGames(key: key, steamID: id)
            guard !owned.isEmpty else {
                failure = "이 계정에서 게임을 찾지 못했어요."
                return
            }
            let art = await SteamAPI.artwork(for: owned.map(\.appID))
            let method = steamDefault.method(shortcutName: steamLinkShortcut)
            let added = library.importSteam(owned, art: art, runner: method.runner, launch: method.launch)
            toasts.show(added > 0 ? "스팀 게임 \(added)개를 가져왔어요" : "새로 가져올 스팀 게임이 없어요", symbol: Platform.steam.symbol)
            onDone()
        } catch {
            failure = error.localizedDescription
        }
    }
}
