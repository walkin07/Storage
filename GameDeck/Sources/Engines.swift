import SwiftUI
import UIKit

enum EngineGroup: String, CaseIterable, Identifiable {
    case nintendoSwitch, pc, tool

    var id: Self { self }

    var title: String {
        switch self {
        case .nintendoSwitch: "스위치 게임"
        case .pc: "스팀 · PC 게임"
        case .tool: "도구 (JIT · 설치 · 실행)"
        }
    }
}

struct EngineInfo {
    let name: String
    /// 한 줄 설명
    let role: String
    let group: EngineGroup
    let symbol: String
    /// 설치 여부를 canOpenURL로 확인할 스킴 (Info.plist의 LSApplicationQueriesSchemes에도 있어야 한다)
    let probeScheme: String?
    /// 앱을 여는 URL
    let openURL: URL?
    /// 받는 곳
    let homepage: URL
    let notes: [String]
}

/// 게임을 실제로 돌리는 앱과, 그 앱을 띄우는 데 쓰는 도구들
enum EngineID: String, Codable, CaseIterable, Identifiable {
    case melonx, nxnative, madeira, ideck, playport, steamLink, liveContainer, stikDebug, localDevVPN, shortcuts

    var id: Self { self }

    var info: EngineInfo {
        switch self {
        case .melonx:
            EngineInfo(
                name: "MeloNX",
                role: "스위치 에뮬레이터 · 게임 목록을 게임덱으로 바로 가져올 수 있어요",
                group: .nintendoSwitch,
                symbol: "gamecontroller",
                probeScheme: "melonx",
                openURL: URL(string: "melonx://"),
                homepage: URL(string: "https://melonx.org")!,
                notes: [
                    "JIT가 필요해요 (iOS 26은 StikDebug)",
                    "본인 스위치에서 뽑은 prod.keys · 펌웨어 · 게임 파일이 필요해요",
                    "메모리 한도 늘리기(Increased Memory Limit)를 켜서 설치하세요",
                    "iPhone 15 Pro 이상 권장",
                ]
            )
        case .nxnative:
            EngineInfo(
                name: "nxnative",
                role: "스위치 게임을 아이폰 앱으로 변환 · 에뮬레이터 없이 칩에서 바로 실행",
                group: .nintendoSwitch,
                symbol: "cpu",
                probeScheme: nil,
                openURL: nil,
                homepage: URL(string: "https://github.com/seedds/nxnative")!,
                notes: [
                    "게임마다 Mac에서 IPA로 변환해야 해요 (macOS 26.6 · Xcode 27.2)",
                    "JIT가 필요 없어요",
                    "iPhone 15 Pro(A17 Pro) 이상 · iOS 26 이상",
                    "만든 게임 앱은 단축어 · StikDebug · LiveContainer로 게임덱에서 실행해요",
                ]
            )
        case .madeira:
            EngineInfo(
                name: "Madeira",
                role: "윈도우 PC 게임과 스팀을 아이폰에서 직접 실행",
                group: .pc,
                symbol: "macwindow",
                probeScheme: "madeira",
                openURL: URL(string: "madeira://"),
                homepage: URL(string: "https://github.com/willfaust/madeira")!,
                notes: [
                    "JIT가 필요해요 (앱 안의 도우미 또는 StikDebug)",
                    "iOS 26 이상 · 최신 Pro 아이폰 권장 · 연구 단계",
                    "게임 상세 화면의 바로가기 링크를 게임덱에 넣으면 그 게임이 바로 실행돼요",
                ]
            )
        case .ideck:
            EngineInfo(
                name: "iDeck",
                role: "스팀 빅 픽처 화면 그대로 · Madeira 기반",
                group: .pc,
                symbol: "rectangle.on.rectangle",
                probeScheme: "madeira-steamui",
                openURL: URL(string: "madeira-steamui://"),
                homepage: URL(string: "https://github.com/kuscholar/iDeck")!,
                notes: [
                    "JIT가 필요해요",
                    "iOS 26 이상 · 실험 단계",
                ]
            )
        case .playport:
            EngineInfo(
                name: "Playport",
                role: "스팀 · GOG · 에픽 게임을 아이폰에서 직접 실행",
                group: .pc,
                symbol: "arrow.down.app",
                probeScheme: "playport",
                openURL: URL(string: "playport://"),
                homepage: URL(string: "https://github.com/playportdev/playport")!,
                notes: [
                    "JIT가 필요해요 (LocalDevVPN + 한 번 페어링)",
                    "iOS 26 이상 · 초기 개발 단계",
                ]
            )
        case .steamLink:
            EngineInfo(
                name: "Steam Link",
                role: "PC에서 스팀 게임을 스트리밍 · 가장 안정적",
                group: .pc,
                symbol: "dot.radiowaves.left.and.right",
                probeScheme: nil,
                openURL: nil,
                homepage: URL(string: "https://apps.apple.com/app/id1246969117")!,
                notes: [
                    "App Store 무료 앱 · JIT와 사이드로드가 필요 없어요",
                    "같은 Wi-Fi의 PC에서 Steam이 켜져 있어야 해요",
                    "단축어 앱에서 ‘앱 열기 → Steam Link’ 단축어를 만들어 두면 게임덱에서 바로 열려요",
                ]
            )
        case .liveContainer:
            EngineInfo(
                name: "LiveContainer",
                role: "여러 앱을 한 앱 안에 설치 · 무료 Apple ID의 앱 3개 제한을 피해요",
                group: .tool,
                symbol: "shippingbox",
                probeScheme: "livecontainer",
                openURL: URL(string: "livecontainer://livecontainer-launch?bundle-name=ui"),
                homepage: URL(string: "https://github.com/LiveContainer/LiveContainer")!,
                notes: [
                    "nxnative 게임 IPA를 안에 넣어 두고 게임덱에서 바로 실행할 수 있어요",
                    "안에 넣은 앱의 폴더 이름은 보통 ‘번들 ID.app’이에요",
                ]
            )
        case .stikDebug:
            EngineInfo(
                name: "StikDebug",
                role: "JIT 켜기 · 번들 ID로 앱 실행",
                group: .tool,
                symbol: "bolt",
                probeScheme: "stikjit",
                openURL: URL(string: "stikjit://"),
                homepage: URL(string: "https://github.com/StikDebug/StikDebug")!,
                notes: [
                    "처음 한 번 PC에서 페어링 파일을 만들어 넣어야 해요",
                    "LocalDevVPN을 켠 상태에서 동작해요",
                ]
            )
        case .localDevVPN:
            EngineInfo(
                name: "LocalDevVPN",
                role: "JIT용 로컬 VPN (App Store)",
                group: .tool,
                symbol: "network",
                probeScheme: "localdevvpn",
                openURL: URL(string: "localdevvpn://"),
                homepage: URL(string: "https://apps.apple.com/app/id6755608044")!,
                notes: [
                    "StikDebug · Playport가 이 아이폰과 통신할 때 켜 둬요",
                ]
            )
        case .shortcuts:
            EngineInfo(
                name: "단축어",
                role: "어떤 앱이든 여는 다리 · nxnative 게임이나 Steam Link에 써요",
                group: .tool,
                symbol: "square.2.layers.3d",
                probeScheme: "shortcuts",
                openURL: URL(string: "shortcuts://"),
                homepage: URL(string: "https://apps.apple.com/app/id915249334")!,
                notes: [
                    "‘앱 열기’ 동작 하나로 단축어를 만들고, 그 이름을 게임덱에 적으면 돼요",
                ]
            )
        }
    }
}

/// 엔진 앱이 설치되어 있는지 확인한다.
@MainActor
final class EngineMonitor: ObservableObject {
    enum Status {
        case installed, missing, unknown
    }

    @Published private(set) var installed: Set<EngineID> = []

    func refresh() {
        var found = Set<EngineID>()
        for engine in EngineID.allCases {
            guard let scheme = engine.info.probeScheme, let url = URL(string: "\(scheme)://") else { continue }
            if UIApplication.shared.canOpenURL(url) { found.insert(engine) }
        }
        installed = found
    }

    func status(of engine: EngineID) -> Status {
        guard engine.info.probeScheme != nil else { return .unknown }
        return installed.contains(engine) ? .installed : .missing
    }
}
