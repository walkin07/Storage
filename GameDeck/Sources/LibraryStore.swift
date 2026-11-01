import Foundation

/// 게임 목록. Application Support/GameDeck/library.json에 저장하고, 표지는 Covers 폴더에 둔다.
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var games: [Game] = []

    private let folder: URL
    private let coversFolder: URL
    private var fileURL: URL { folder.appendingPathComponent("library.json") }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        folder = base.appendingPathComponent("GameDeck", isDirectory: true)
        coversFolder = folder.appendingPathComponent("Covers", isDirectory: true)
        try? FileManager.default.createDirectory(at: coversFolder, withIntermediateDirectories: true)
        load()
        #if DEBUG
        applyDemoArgument()
        #endif
    }

    func game(withID id: UUID) -> Game? {
        games.first { $0.id == id }
    }

    func sorted(by order: SortOrder) -> [Game] {
        switch order {
        case .recent:
            return games.sorted { a, b in
                switch (a.lastPlayed, b.lastPlayed) {
                case let (x?, y?): return x > y
                case (.some, nil): return true
                case (nil, .some): return false
                case (nil, nil): return a.addedAt > b.addedAt
                }
            }
        case .name:
            return games.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
    }

    /// 마지막으로 플레이한 게임
    var mostRecent: Game? {
        games.filter { $0.lastPlayed != nil }.max { ($0.lastPlayed ?? .distantPast) < ($1.lastPlayed ?? .distantPast) }
    }

    // MARK: - 바꾸기

    func add(_ game: Game) {
        games.append(game)
        save()
    }

    func update(_ game: Game) {
        guard let index = index(of: game.id) else { return }
        games[index] = game
        save()
    }

    func remove(_ id: UUID) {
        guard let index = index(of: id) else { return }
        deleteCoverFile(games[index].coverFile)
        games.remove(at: index)
        save()
    }

    func removeAll() {
        games.forEach { deleteCoverFile($0.coverFile) }
        games = []
        save()
    }

    func markPlayed(_ id: UUID) {
        guard let index = index(of: id) else { return }
        games[index].lastPlayed = .now
        games[index].playCount += 1
        save()
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = index(of: id) else { return }
        games[index].favorite.toggle()
        save()
    }

    func setArtwork(_ id: UUID, covers: [URL], hero: URL?) {
        guard let index = index(of: id) else { return }
        games[index].artURLs = covers
        games[index].heroURL = hero
        save()
    }

    // MARK: - 표지

    /// 이 게임의 표지 후보: 직접 고른 표지가 먼저, 그다음 인터넷 이미지
    func artCandidates(for game: Game) -> [URL] {
        var list: [URL] = []
        if let file = game.coverFile { list.append(coversFolder.appendingPathComponent(file)) }
        list.append(contentsOf: game.artURLs)
        return list
    }

    /// 표지 이미지를 저장한다. 파일 이름을 매번 바꿔 이미지 캐시가 예전 표지를 보여 주지 않게 한다.
    @discardableResult
    func setCover(_ data: Data, for id: UUID) -> Bool {
        guard let index = index(of: id), let name = writeCover(data, id: id) else { return false }
        deleteCoverFile(games[index].coverFile)
        games[index].coverFile = name
        save()
        return true
    }

    func clearCover(for id: UUID) {
        guard let index = index(of: id) else { return }
        deleteCoverFile(games[index].coverFile)
        games[index].coverFile = nil
        save()
    }

    // MARK: - 가져오기

    /// MeloNX가 보내 준 목록을 넣는다. 이미 있는 게임은 표지만 채운다.
    func importMeloNX(_ entries: [MeloNXBridge.Entry]) -> (added: Int, updated: Int) {
        var added = 0
        var updated = 0
        for entry in entries {
            // MeloNX는 타이틀 ID나 게임 이름 어느 쪽으로도 게임을 찾는다.
            let key = entry.titleId.isEmpty ? entry.titleName : entry.titleId
            if let index = games.firstIndex(where: { $0.launch == .melonx(titleID: key) }) {
                if games[index].coverFile == nil, let icon = entry.iconData, let name = writeCover(icon, id: games[index].id) {
                    games[index].coverFile = name
                }
                updated += 1
            } else {
                var game = Game(
                    title: entry.titleName,
                    platform: .nintendoSwitch,
                    runner: .melonx,
                    launch: .melonx(titleID: key),
                    titleID: Self.normalizedTitleID(key)
                )
                if let icon = entry.iconData { game.coverFile = writeCover(icon, id: game.id) }
                games.append(game)
                added += 1
            }
        }
        save()
        return (added, updated)
    }

    /// 스팀 라이브러리를 넣는다. 이미 있는 스팀 게임(같은 App ID)은 건너뛴다.
    func importSteam(_ owned: [SteamAPI.OwnedGame], art: [Int: SteamAPI.Art], runner: EngineID, launch: LaunchMethod) -> Int {
        let existing = Set(games.compactMap(\.steamAppID))
        var added = 0
        for item in owned where !existing.contains(item.appID) {
            let artwork = art[item.appID] ?? SteamAPI.fallbackArt(appID: item.appID)
            games.append(Game(
                title: item.name,
                platform: .steam,
                runner: runner,
                launch: launch,
                steamAppID: item.appID,
                artURLs: artwork.covers,
                heroURL: artwork.hero,
                lastPlayed: item.lastPlayed
            ))
            added += 1
        }
        save()
        return added
    }

    /// 16자리 16진수면 대문자로, 아니면 nil
    nonisolated static func normalizedTitleID(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard value.count == 16, value.allSatisfy(\.isHexDigit) else { return nil }
        return value
    }

    // MARK: - 파일

    private func index(of id: UUID) -> Int? {
        games.firstIndex { $0.id == id }
    }

    private func writeCover(_ data: Data, id: UUID) -> String? {
        let name = "\(id.uuidString)-\(Int(Date().timeIntervalSince1970 * 1000)).img"
        do {
            try data.write(to: coversFolder.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    private func deleteCoverFile(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: coversFolder.appendingPathComponent(name))
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            games = try JSONDecoder().decode([Lossy<Game>].self, from: data).compactMap(\.value)
        } catch {
            // 읽을 수 없는 파일은 지우지 않고 옆에 남겨 둔다.
            let backup = folder.appendingPathComponent("library-unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: fileURL, to: backup)
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(games)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("GameDeck: 라이브러리를 저장하지 못했어요: \(error)")
        }
    }
}

#if DEBUG
// UI 테스트와 스크린샷용 예시 목록 (-gamedeck-demo library | empty). 릴리스 빌드(배포용 IPA)에는 들어가지 않고, 저장하지도 않는다.
extension LibraryStore {
    fileprivate func applyDemoArgument() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-gamedeck-demo"), index + 1 < arguments.count else { return }
        switch arguments[index + 1] {
        case "empty":
            games = []
        case "library":
            games = Self.demoGames()
        default:
            break
        }
    }

    private static func demoGames() -> [Game] {
        let now = Date()
        func steam(_ appID: Int, _ title: String, runner: EngineID, launch: LaunchMethod, hoursAgo: Double? = nil, favorite: Bool = false) -> Game {
            let art = SteamAPI.fallbackArt(appID: appID)
            return Game(
                title: title, platform: .steam, runner: runner, launch: launch, steamAppID: appID,
                artURLs: art.covers, heroURL: art.hero, favorite: favorite,
                lastPlayed: hoursAgo.map { now.addingTimeInterval(-$0 * 3600) }, playCount: hoursAgo == nil ? 0 : 3
            )
        }
        func nx(_ titleID: String, _ title: String, launch: LaunchMethod, runner: EngineID, hoursAgo: Double? = nil) -> Game {
            Game(
                title: title, platform: .nintendoSwitch, runner: runner, launch: launch, titleID: titleID,
                lastPlayed: hoursAgo.map { now.addingTimeInterval(-$0 * 3600) }, playCount: hoursAgo == nil ? 0 : 5
            )
        }
        return [
            steam(620, "Portal 2", runner: .madeira, launch: .madeira(exe: #"C:\Program Files (x86)\Steam\steamapps\common\Portal 2\portal2.exe"#), hoursAgo: 1, favorite: true),
            nx("0100152000022000", "Mario Kart 8 Deluxe", launch: .melonx(titleID: "0100152000022000"), runner: .melonx, hoursAgo: 5),
            steam(413150, "Stardew Valley", runner: .steamLink, launch: .shortcut(name: "Steam Link"), hoursAgo: 30),
            nx("0100F2C0115B6000", "The Legend of Zelda: Tears of the Kingdom", launch: .shortcut(name: "젤다 왕눈"), runner: .nxnative, hoursAgo: 50),
            steam(1145360, "Hades", runner: .ideck, launch: .openEngine(.ideck)),
            steam(367520, "Hollow Knight", runner: .playport, launch: .openEngine(.playport)),
            nx("01006F8002326000", "Animal Crossing: New Horizons", launch: .stikDebug(bundleID: "org.nxnative.01006f8002326000"), runner: .nxnative),
            steam(1245620, "ELDEN RING", runner: .steamLink, launch: .shortcut(name: "Steam Link")),
            Game(title: "다른 에뮬레이터 게임", platform: .other, runner: nil, launch: .url("someapp://play")),
        ]
    }
}
#endif
