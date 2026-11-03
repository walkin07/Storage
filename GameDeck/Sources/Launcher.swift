import UIKit

@MainActor
enum Launcher {
    /// 실행 URL을 연다. 그 URL을 받을 앱이 없으면 false.
    static func open(_ method: LaunchMethod) async -> Bool {
        guard let url = method.url else { return false }
        return await UIApplication.shared.open(url)
    }

    static func open(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url)
    }
}

/// MeloNX의 외부 런처용 링크.
/// melonx://gameInfo?scheme=gamedeck 를 열면 MeloNX가 게임 목록(이름, 타이틀 ID, 아이콘)을
/// gamedeck://melonx?games=<base64url JSON> 으로 돌려준다. 실행은 melonx://game?id=<타이틀 ID>.
enum MeloNXBridge {
    static var requestURL: URL {
        URL(string: "melonx://gameInfo?scheme=\(DeckLink.scheme)")!
    }

    struct Entry: Decodable {
        let titleName: String
        let titleId: String
        let developer: String?
        let version: String?
        let iconData: Data?
    }

    /// MeloNX가 돌려준 링크면 게임 목록(비어 있을 수 있음)을, 다른 링크면 nil을 돌려준다.
    static func entries(from url: URL) -> [Entry]? {
        guard url.scheme?.lowercased() == DeckLink.scheme, url.host?.lowercased() == "melonx" else { return nil }
        guard
            let text = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "games" })?.value,
            let data = base64URLDecoded(text),
            let list = try? JSONDecoder().decode([Lossy<Entry>].self, from: data)
        else { return [] }
        return list.compactMap(\.value).filter { !$0.titleId.isEmpty || !$0.titleName.isEmpty }
    }

    static func base64URLDecoded(_ text: String) -> Data? {
        var base64 = text
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        return Data(base64Encoded: base64)
    }
}
