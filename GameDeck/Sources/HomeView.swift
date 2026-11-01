import SwiftUI

enum HomeSheet: Identifiable, Equatable {
    case detail(UUID)
    case add
    case engines
    case settings

    var id: String {
        switch self {
        case .detail(let id): "detail-\(id.uuidString)"
        case .add: "add"
        case .engines: "engines"
        case .settings: "settings"
        }
    }
}

struct LaunchProblem: Identifiable {
    let id = UUID()
    let engine: EngineID?
}

/// 홈 화면. 가로는 스위치·스팀덱처럼 큰 정보 + 가로 선반, 세로는 정보 + 격자.
struct HomeView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var engines: EngineMonitor
    @EnvironmentObject private var pad: ControllerHub
    @EnvironmentObject private var toasts: ToastCenter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @AppStorage("cardSize") private var cardSize: CardSize = .medium
    @AppStorage("sortOrder") private var sortOrder: SortOrder = .recent
    @AppStorage("haptics") private var haptics = true

    @State private var filter: LibraryFilter = .all
    @State private var focusedID: UUID?
    @State private var sheet: HomeSheet?
    @State private var problem: LaunchProblem?
    @State private var launchTick = 0
    @State private var isLandscape = true
    @State private var gridColumns = 3

    private var visibleGames: [Game] {
        library.sorted(by: sortOrder).filter(filter.matches)
    }

    private func currentGame(in list: [Game]) -> Game? {
        list.first { $0.id == focusedID } ?? list.first
    }

    var body: some View {
        let list = visibleGames
        let current = currentGame(in: list)
        screen(list: list, current: current)
            .overlay(alignment: .bottom) { toastOverlay }
            .statusBarHidden(isLandscape)
            .persistentSystemOverlays(.hidden)
            .preferredColorScheme(.dark)
            .sensoryFeedback(.selection, trigger: focusedID) { _, _ in haptics }
            .sensoryFeedback(.impact(weight: .medium), trigger: launchTick) { _, _ in haptics }
            .sheet(item: $sheet, content: sheetView)
            .alert("실행하지 못했어요", isPresented: problemBinding, presenting: problem, actions: problemActions, message: problemMessage)
            .onReceive(pad.inputs, perform: handle)
            .onOpenURL(perform: handleURL)
            .onChange(of: filter) { _, _ in
                focusedID = visibleGames.first?.id
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active { engines.refresh() }
            }
    }

    // MARK: - 화면

    private func screen(list: [Game], current: Game?) -> some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            let columns = Self.columns(width: geo.size.width, minimum: cardSize.gridMinimum)
            let shelf = Self.shelfCardWidth(height: geo.size.height, preferred: cardSize.shelfWidth, hints: pad.controllerName != nil)
            ZStack {
                DeckBackdrop(game: current)
                VStack(spacing: 0) {
                    topBar(landscape: landscape)
                    content(list: list, current: current, landscape: landscape, columns: columns, shelfWidth: shelf)
                    if pad.controllerName != nil {
                        ButtonHintBar()
                            .padding(.horizontal, landscape ? 28 : 18)
                            .padding(.bottom, 6)
                    }
                }
            }
            .onChange(of: geo.size, initial: true) { _, size in
                isLandscape = size.width > size.height
                gridColumns = Self.columns(width: size.width, minimum: cardSize.gridMinimum)
            }
            .onChange(of: cardSize) { _, size in
                gridColumns = Self.columns(width: geo.size.width, minimum: size.gridMinimum)
            }
        }
    }

    @ViewBuilder
    private func topBar(landscape: Bool) -> some View {
        Group {
            if landscape {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        logo
                        filterChips
                        Spacer(minLength: 8)
                        StatusCluster(controllerName: pad.controllerName)
                        toolButtons
                    }
                    HStack(spacing: 14) {
                        logo
                        filterChips
                        Spacer(minLength: 8)
                        toolButtons
                    }
                    stackedTopBar
                }
            } else {
                stackedTopBar
            }
        }
        .padding(.horizontal, landscape ? 28 : 18)
        .padding(.top, landscape ? 10 : 6)
    }

    private var stackedTopBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                logo
                Spacer(minLength: 8)
                toolButtons
            }
            ScrollView(.horizontal, showsIndicators: false) { filterChips }
                .scrollClipDisabled()
        }
    }

    private var logo: some View {
        Text("GameDeck")
            .font(.title3.weight(.heavy))
            .fontWidth(.expanded)
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
    }

    private var toolButtons: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                RoundIconButton(symbol: "plus", label: "게임 추가") { sheet = .add }
                RoundIconButton(symbol: "puzzlepiece.extension", label: "엔진 준비 상태") { sheet = .engines }
                RoundIconButton(symbol: "gearshape", label: "설정") { sheet = .settings }
            }
        }
    }

    private var filterChips: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(LibraryFilter.allCases) { item in
                    Button {
                        withAnimation(.snappy) { filter = item }
                    } label: {
                        Text(item.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(item == filter ? Color.black : Color.white)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(item == filter ? .regular.tint(.white).interactive() : .regular.interactive(), in: .capsule)
                }
            }
        }
    }

    @ViewBuilder
    private func content(list: [Game], current: Game?, landscape: Bool, columns: Int, shelfWidth: CGFloat) -> some View {
        if library.games.isEmpty {
            EmptyLibraryView(
                onImportMeloNX: importFromMeloNX,
                onAdd: { sheet = .add },
                onEngines: { sheet = .engines }
            )
        } else if list.isEmpty {
            ContentUnavailableView {
                Label("이 목록에 게임이 없어요", systemImage: filter.symbol)
            } description: {
                Text("위의 탭이나 L·R 버튼으로 다른 목록을 보세요.")
            }
            .frame(maxHeight: .infinity)
        } else if landscape {
            shelfLayout(list: list, current: current, cardWidth: shelfWidth)
        } else {
            gridLayout(list: list, current: current, columns: columns)
        }
    }

    private func shelfLayout(list: [Game], current: Game?, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 0)
            if let current {
                HeroPanel(
                    game: current,
                    wide: true,
                    titleSize: cardWidth > 170 ? 38 : 28,
                    onPlay: { play(current) },
                    onOptions: { sheet = .detail(current.id) }
                )
                .padding(.horizontal, 28)
            }
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .bottom, spacing: cardWidth > 120 ? 18 : 14) {
                        ForEach(list) { game in
                            card(game, focused: game.id == current?.id, width: cardWidth, showsTitle: false)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                }
                .scrollClipDisabled()
                .onChange(of: focusedID) { _, id in scroll(proxy, to: id) }
            }
        }
        .padding(.bottom, 4)
    }

    private func gridLayout(list: [Game], current: Game?, columns: Int) -> some View {
        VStack(spacing: 0) {
            if let current {
                HeroPanel(game: current, wide: false, onPlay: { play(current) }, onOptions: { sheet = .detail(current.id) })
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns), spacing: 20) {
                        ForEach(list) { game in
                            card(game, focused: game.id == current?.id, width: nil)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
                .onChange(of: focusedID) { _, id in scroll(proxy, to: id) }
            }
        }
    }

    private func card(_ game: Game, focused: Bool, width: CGFloat?, showsTitle: Bool = true) -> some View {
        GameCard(game: game, isFocused: focused, width: width, showsTitle: showsTitle)
            .id(game.id)
            .onTapGesture { tap(game) }
            .contextMenu { menuItems(for: game) }
    }

    @ViewBuilder
    private func menuItems(for game: Game) -> some View {
        Button { play(game) } label: { Label("플레이", systemImage: "play.fill") }
        Button { sheet = .detail(game.id) } label: { Label("정보 · 편집", systemImage: "info.circle") }
        Button { library.toggleFavorite(game.id) } label: {
            Label(game.favorite ? "즐겨찾기 해제" : "즐겨찾기", systemImage: game.favorite ? "star.slash" : "star")
        }
        Button(role: .destructive) { library.remove(game.id) } label: { Label("삭제", systemImage: "trash") }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast = toasts.current {
            ToastView(toast: toast)
                .padding(.bottom, isLandscape ? 14 : 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .id(toast.id)
        }
    }

    @ViewBuilder
    private func sheetView(_ item: HomeSheet) -> some View {
        Group {
            switch item {
            case .detail(let id):
                GameDetailView(gameID: id) { game in
                    sheet = nil
                    play(game)
                }
            case .add:
                AddGameView()
            case .engines:
                EnginesView()
            case .settings:
                SettingsView()
            }
        }
        .environmentObject(library)
        .environmentObject(engines)
        .environmentObject(toasts)
        .preferredColorScheme(.dark)
    }

    // MARK: - 실행

    private func tap(_ game: Game) {
        if focusedID == game.id {
            play(game)
        } else {
            withAnimation(.snappy) { focusedID = game.id }
        }
    }

    private func play(_ game: Game) {
        focusedID = game.id
        Task {
            if await Launcher.open(game.launch) {
                library.markPlayed(game.id)
                launchTick += 1
                if case .stikDebug = game.launch {
                    toasts.show("StikDebug에서 실행을 허용하세요", symbol: "bolt.fill")
                }
            } else {
                problem = LaunchProblem(engine: game.launch.requiredEngine)
            }
        }
    }

    private func importFromMeloNX() {
        Task {
            if await Launcher.open(MeloNXBridge.requestURL) == false {
                problem = LaunchProblem(engine: .melonx)
            }
        }
    }

    private var problemBinding: Binding<Bool> {
        Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })
    }

    @ViewBuilder
    private func problemActions(_ info: LaunchProblem) -> some View {
        if let engine = info.engine {
            Button("\(engine.info.name) 받는 곳") { openURL(engine.info.homepage) }
            Button("엔진 준비 상태") { sheet = .engines }
        }
        Button("닫기", role: .cancel) {}
    }

    private func problemMessage(_ info: LaunchProblem) -> Text {
        guard let engine = info.engine else {
            return Text("이 링크를 열 수 있는 앱이 없어요. 주소를 확인하세요.")
        }
        return Text("\(engine.info.name) 앱이 없거나 이 링크를 받지 못했어요. 앱이 설치되어 있는지 확인하세요.")
    }

    // MARK: - 게임패드

    private func handle(_ input: PadInput) {
        if let open = sheet {
            switch input {
            case .b:
                sheet = nil
            case .a:
                if case .detail(let id) = open, let game = library.game(withID: id) {
                    sheet = nil
                    play(game)
                }
            default:
                break
            }
            return
        }
        if problem != nil {
            if input == .a || input == .b { problem = nil }
            return
        }
        let list = visibleGames
        switch input {
        case .left: move(by: -1, in: list)
        case .right: move(by: 1, in: list)
        case .up: if !isLandscape { move(by: -gridColumns, in: list) }
        case .down: if !isLandscape { move(by: gridColumns, in: list) }
        case .a: if let game = currentGame(in: list) { play(game) }
        case .x: if let game = currentGame(in: list) { sheet = .detail(game.id) }
        case .y: sheet = .add
        case .l: withAnimation(.snappy) { filter = filter.shifted(by: -1) }
        case .r: withAnimation(.snappy) { filter = filter.shifted(by: 1) }
        case .menu: sheet = .settings
        case .options: sheet = .engines
        case .b: break
        }
    }

    private func move(by step: Int, in list: [Game]) {
        guard !list.isEmpty else { return }
        let index = list.firstIndex { $0.id == focusedID } ?? 0
        let next = min(max(index + step, 0), list.count - 1)
        focusedID = list[next].id
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: UUID?) {
        guard let id else { return }
        withAnimation(.snappy) { proxy.scrollTo(id, anchor: .center) }
    }

    private static func columns(width: CGFloat, minimum: CGFloat) -> Int {
        max(2, Int((width - 36 + 14) / (minimum + 14)))
    }

    /// 가로 화면 선반의 카드 너비: 위쪽 막대 · 게임 정보 · 버튼 안내를 빼고 남은 높이에 2:3 표지가 들어가게 한다.
    /// 아이패드처럼 높이가 넉넉하면 설정한 크기보다 조금 크게.
    private static func shelfCardWidth(height: CGFloat, preferred: CGFloat, hints: Bool) -> CGFloat {
        let reserved: CGFloat = 52 + 74 + 10 + 24 + 16 + (hints ? 30 : 0)
        let fitting = (height - reserved) / 1.5 / 1.06
        let largest = height > 600 ? preferred * 1.35 : preferred
        return max(72, min(largest, fitting))
    }

    // MARK: - 링크

    private func handleURL(_ url: URL) {
        if let entries = MeloNXBridge.entries(from: url) {
            if sheet == .add { sheet = nil }
            guard !entries.isEmpty else {
                toasts.show("MeloNX에서 게임 목록을 받지 못했어요. MeloNX를 한 번 연 뒤 다시 시도하세요.", symbol: "exclamationmark.triangle.fill")
                return
            }
            let result = library.importMeloNX(entries)
            filter = .nintendoSwitch
            let extra = result.updated > 0 ? " (\(result.updated)개는 이미 있었어요)" : ""
            toasts.show("스위치 게임 \(result.added)개를 가져왔어요\(extra)", symbol: "gamecontroller.fill")
            return
        }
        switch DeckLink(url) {
        case .play(let id)?:
            if let game = library.game(withID: id) { play(game) }
        case .resume?:
            if let game = library.mostRecent { play(game) }
        case nil:
            break
        }
    }
}

/// 게임이 하나도 없을 때
struct EmptyLibraryView: View {
    let onImportMeloNX: () -> Void
    let onAdd: () -> Void
    let onEngines: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .frame(width: 96, height: 96)
                    .glassEffect(.regular, in: .circle)
                Text("게임덱에 오신 걸 환영해요")
                    .font(.title2.bold())
                Text("스위치·스팀 게임을 한 화면에 모아 두고 컨트롤러로 바로 실행해요. 게임은 MeloNX · nxnative · Madeira 같은 엔진 앱이 돌리고, 게임덱은 그 앱들을 이어 줍니다.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: 540)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { buttons }
                    VStack(spacing: 10) { buttons }
                }
                .controlSize(.large)
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var buttons: some View {
        Button(action: onImportMeloNX) {
            Label("MeloNX에서 가져오기", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.glassProminent)
        .tint(Platform.nintendoSwitch.tint)
        Button(action: onAdd) {
            Label("게임 추가", systemImage: "plus")
        }
        .buttonStyle(.glass)
        Button(action: onEngines) {
            Label("엔진 준비 상태", systemImage: "puzzlepiece.extension")
        }
        .buttonStyle(.glass)
    }
}
