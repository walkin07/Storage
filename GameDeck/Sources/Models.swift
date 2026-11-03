import Foundation

/// 게임이 원래 어느 기기용인지. 필터와 배지에 쓴다.
enum Platform: String, Codable, CaseIterable, Identifiable {
    case nintendoSwitch = "switch"
    case steam
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .nintendoSwitch: "스위치"
        case .steam: "스팀"
        case .other: "기타"
        }
    }

    var symbol: String {
        switch self {
        case .nintendoSwitch: "gamecontroller.fill"
        case .steam: "desktopcomputer"
        case .other: "square.grid.2x2.fill"
        }
    }
}

/// 게임을 여는 방법. 게임덱은 게임을 직접 돌리지 않고, 설치된 엔진 앱을 URL로 연다.
enum LaunchMethod: Codable, Hashable {
    /// MeloNX: melonx://game?id=<타이틀 ID 또는 게임 이름>
    case melonx(titleID: String)
    /// Madeira: madeira://play?exe=<윈도우 경로>
    case madeira(exe: String)
    /// LiveContainer 안의 앱: livecontainer://livecontainer-launch?bundle-name=<앱 폴더 이름>
    case liveContainer(bundleName: String)
    /// StikDebug가 앱을 실행: stikjit://launch-app?bundle-id=<번들 ID>
    case stikDebug(bundleID: String)
    /// 단축어 실행: shortcuts://run-shortcut?name=<이름>
    case shortcut(name: String)
    /// 게임별 링크가 없는 엔진 앱을 연다 (iDeck, Playport 등)
    case openEngine(EngineID)
    /// 그 밖의 URL
    case url(String)
}

extension LaunchMethod {
    /// 이 방법으로 열 때 꼭 있어야 하는 앱
    var requiredEngine: EngineID? {
        switch self {
        case .melonx: .melonx
        case .madeira: .madeira
        case .liveContainer: .liveContainer
        case .stikDebug: .stikDebug
        case .shortcut: .shortcuts
        case .openEngine(let engine): engine
        case .url: nil
        }
    }

    var url: URL? {
        switch self {
        case .melonx(let id): Self.link("melonx", "game", ["id": id])
        case .madeira(let exe): Self.link("madeira", "play", ["exe": exe])
        case .liveContainer(let name): Self.link("livecontainer", "livecontainer-launch", ["bundle-name": name])
        case .stikDebug(let bundleID): Self.link("stikjit", "launch-app", ["bundle-id": bundleID])
        case .shortcut(let name): Self.link("shortcuts", "run-shortcut", ["name": name])
        case .openEngine(let engine): engine.info.openURL
        case .url(let text): URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    /// 화면에 보여 줄 한 줄 설명
    var summary: String {
        switch self {
        case .melonx: "MeloNX에서 바로 실행"
        case .madeira: "Madeira에서 바로 실행"
        case .liveContainer: "LiveContainer에서 실행"
        case .stikDebug: "StikDebug가 앱을 실행"
        case .shortcut(let name): "단축어 ‘\(name)’ 실행"
        case .openEngine(let engine): "\(engine.info.name) 열기"
        case .url: "링크 열기"
        }
    }

    /// 실행에 쓰는 값 (타이틀 ID, 경로, 번들 ID 등)
    var value: String? {
        switch self {
        case .melonx(let id): id
        case .madeira(let exe): exe
        case .liveContainer(let name): name
        case .stikDebug(let bundleID): bundleID
        case .shortcut(let name): name
        case .openEngine: nil
        case .url(let text): text
        }
    }

    /// 받는 쪽이 URLComponents로 다시 풀 수 있게, 영문·숫자와 -._~ 말고는 모두 퍼센트 인코딩한다.
    private static func link(_ scheme: String, _ host: String, _ items: KeyValuePairs<String, String>) -> URL? {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.percentEncodedQueryItems = items.map {
            URLQueryItem(name: $0.key, value: $0.value.addingPercentEncoding(withAllowedCharacters: allowed))
        }
        return components.url
    }
}

struct Game: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var platform: Platform
    /// 실제로 게임을 돌리는 엔진 (표시용)
    var runner: EngineID?
    var launch: LaunchMethod
    /// 스위치 타이틀 ID (16자리 16진수)
    var titleID: String?
    var steamAppID: Int?
    /// 직접 고르거나 MeloNX에서 받은 표지 (Covers 폴더 안의 파일 이름)
    var coverFile: String?
    /// 인터넷 표지 후보. 앞에서부터 차례로 시도한다.
    var artURLs: [URL]
    /// 배경에 쓰는 넓은 이미지
    var heroURL: URL?
    var favorite: Bool
    var addedAt: Date
    var lastPlayed: Date?
    var playCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        platform: Platform,
        runner: EngineID?,
        launch: LaunchMethod,
        titleID: String? = nil,
        steamAppID: Int? = nil,
        coverFile: String? = nil,
        artURLs: [URL] = [],
        heroURL: URL? = nil,
        favorite: Bool = false,
        addedAt: Date = .now,
        lastPlayed: Date? = nil,
        playCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.platform = platform
        self.runner = runner
        self.launch = launch
        self.titleID = titleID
        self.steamAppID = steamAppID
        self.coverFile = coverFile
        self.artURLs = artURLs
        self.heroURL = heroURL
        self.favorite = favorite
        self.addedAt = addedAt
        self.lastPlayed = lastPlayed
        self.playCount = playCount
    }

    /// 나중에 필드가 늘어도 예전 라이브러리 파일을 읽을 수 있게, 없는 값은 기본값으로 채운다.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        platform = (try? c.decode(Platform.self, forKey: .platform)) ?? .other
        runner = try? c.decodeIfPresent(EngineID.self, forKey: .runner)
        launch = try c.decode(LaunchMethod.self, forKey: .launch)
        titleID = try c.decodeIfPresent(String.self, forKey: .titleID)
        steamAppID = try c.decodeIfPresent(Int.self, forKey: .steamAppID)
        coverFile = try c.decodeIfPresent(String.self, forKey: .coverFile)
        artURLs = try c.decodeIfPresent([URL].self, forKey: .artURLs) ?? []
        heroURL = try c.decodeIfPresent(URL.self, forKey: .heroURL)
        favorite = try c.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        addedAt = try c.decodeIfPresent(Date.self, forKey: .addedAt) ?? .now
        lastPlayed = try c.decodeIfPresent(Date.self, forKey: .lastPlayed)
        playCount = try c.decodeIfPresent(Int.self, forKey: .playCount) ?? 0
    }

    var playedSummary: String {
        guard let lastPlayed else { return "아직 플레이하지 않았어요" }
        let when = lastPlayed.formatted(.relative(presentation: .named))
        return playCount > 0 ? "최근 플레이 \(when) · \(playCount)회" : "최근 플레이 \(when)"
    }
}

/// 디코딩에 실패한 항목만 건너뛰고 나머지는 살린다.
struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, nintendoSwitch, steam, other, favorites

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "전체"
        case .nintendoSwitch: "스위치"
        case .steam: "스팀"
        case .other: "기타"
        case .favorites: "즐겨찾기"
        }
    }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .nintendoSwitch: Platform.nintendoSwitch.symbol
        case .steam: Platform.steam.symbol
        case .other: Platform.other.symbol
        case .favorites: "star"
        }
    }

    func matches(_ game: Game) -> Bool {
        switch self {
        case .all: true
        case .nintendoSwitch: game.platform == .nintendoSwitch
        case .steam: game.platform == .steam
        case .other: game.platform == .other
        case .favorites: game.favorite
        }
    }

    func shifted(by step: Int) -> LibraryFilter {
        let cases = Self.allCases
        let index = cases.firstIndex(of: self) ?? 0
        return cases[(index + step % cases.count + cases.count) % cases.count]
    }
}

enum CardSize: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: Self { self }

    var title: String {
        switch self {
        case .small: "작게"
        case .medium: "보통"
        case .large: "크게"
        }
    }

    /// 가로 화면 선반의 카드 너비
    var shelfWidth: CGFloat {
        switch self {
        case .small: 118
        case .medium: 148
        case .large: 182
        }
    }

    /// 세로 화면 격자의 최소 카드 너비
    var gridMinimum: CGFloat {
        switch self {
        case .small: 96
        case .medium: 122
        case .large: 156
        }
    }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case recent, name

    var id: Self { self }

    var title: String {
        switch self {
        case .recent: "최근 플레이순"
        case .name: "이름순"
        }
    }
}

/// 스팀에서 찾거나 가져온 게임을 기본으로 어떻게 열지
enum SteamLaunchDefault: String, CaseIterable, Identifiable {
    case steamLink, madeira, ideck, playport

    var id: Self { self }

    var title: String {
        switch self {
        case .steamLink: "Steam Link (PC에서 스트리밍)"
        case .madeira: "Madeira (아이폰에서 직접)"
        case .ideck: "iDeck (아이폰에서 직접)"
        case .playport: "Playport (아이폰에서 직접)"
        }
    }

    var help: String {
        switch self {
        case .steamLink: "같은 Wi-Fi의 PC에서 Steam이 켜져 있어야 해요. 단축어 앱에서 ‘앱 열기 → Steam Link’ 단축어를 만들어 두세요."
        case .madeira: "Madeira가 열려요. 게임마다 Madeira의 바로가기 링크를 넣으면 그 게임이 바로 실행돼요."
        case .ideck: "iDeck이 열리고, 게임은 스팀 빅 픽처 화면에서 고르면 돼요."
        case .playport: "Playport가 열리고, 게임은 Playport 라이브러리에서 고르면 돼요."
        }
    }

    var launchKind: LaunchKind {
        switch self {
        case .steamLink: .steamLink
        case .madeira: .madeira
        case .ideck: .ideck
        case .playport: .playport
        }
    }

    func method(shortcutName: String) -> (runner: EngineID, launch: LaunchMethod) {
        switch self {
        case .steamLink: return (EngineID.steamLink, LaunchMethod.shortcut(name: shortcutName))
        case .madeira: return (EngineID.madeira, LaunchMethod.openEngine(.madeira))
        case .ideck: return (EngineID.ideck, LaunchMethod.openEngine(.ideck))
        case .playport: return (EngineID.playport, LaunchMethod.openEngine(.playport))
        }
    }
}

/// 게임덱 자신의 링크: gamedeck://play?id=<게임 ID>, gamedeck://resume (마지막 게임 이어하기)
enum DeckLink {
    static let scheme = "gamedeck"

    case play(UUID)
    case resume

    init?(_ url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }
        switch url.host?.lowercased() {
        case "play":
            let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value
            guard let id = value.flatMap(UUID.init(uuidString:)) else { return nil }
            self = .play(id)
        case "resume":
            self = .resume
        default:
            return nil
        }
    }

    static func playURL(for id: UUID) -> String {
        "\(scheme)://play?id=\(id.uuidString)"
    }
}
