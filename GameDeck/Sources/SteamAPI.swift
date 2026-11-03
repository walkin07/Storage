import Foundation

/// 스팀 공개 API. 검색과 표지는 키 없이, 내 라이브러리는 Steam Web API 키로 가져온다.
enum SteamAPI {
    struct SearchItem: Identifiable, Hashable {
        let id: Int
        let name: String
        let thumbnail: URL?
    }

    struct OwnedGame: Hashable {
        let appID: Int
        let name: String
        let lastPlayed: Date?
    }

    struct Art: Hashable {
        var covers: [URL]
        var hero: URL?
    }

    enum Failure: LocalizedError {
        case http(Int)
        case unreadable
        case noSteamID
        case privateProfile

        var errorDescription: String? {
            switch self {
            case .http(401), .http(403): "API 키가 맞지 않아요. 키를 다시 확인하세요."
            case .http(let code): "스팀 서버가 응답하지 않아요 (\(code)). 잠시 뒤 다시 시도하세요."
            case .unreadable: "스팀 응답을 읽지 못했어요."
            case .noSteamID: "스팀 ID를 찾지 못했어요. 프로필 주소나 17자리 숫자 ID를 넣어 보세요."
            case .privateProfile: "게임 목록을 볼 수 없어요. 스팀 프로필 → 개인정보 설정에서 ‘게임 세부 정보’를 공개로 바꾸세요."
            }
        }
    }

    static let assetBase = "https://shared.akamai.steamstatic.com/store_item_assets/"

    // MARK: - 검색 (키 필요 없음)

    static func search(_ term: String) async throws -> [SearchItem] {
        let url = link("https://store.steampowered.com/api/storesearch/", [
            ("term", term), ("l", "koreana"), ("cc", "KR"),
        ])
        let json = try await getJSON(url)
        let items = json["items"] as? [[String: Any]] ?? []
        return items.compactMap { item in
            if let type = item["type"] as? String, type != "app" { return nil }
            guard let id = intValue(item["id"]), let name = item["name"] as? String else { return nil }
            let thumbnail = (item["tiny_image"] as? String).flatMap(URL.init(string:))
            return SearchItem(id: id, name: name, thumbnail: thumbnail)
        }
    }

    // MARK: - 내 라이브러리 (Steam Web API 키)

    /// 17자리 ID, 프로필 주소(…/profiles/7656…, …/id/이름), 사용자 지정 이름 중 무엇이든 받는다.
    static func resolveSteamID(_ input: String, key: String) async throws -> String {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count == 17, text.allSatisfy(\.isNumber) { return text }
        if let url = URL(string: text), let host = url.host, host.contains("steamcommunity.com") {
            let parts = url.pathComponents.filter { $0 != "/" }
            if parts.count >= 2, parts[0] == "profiles" { return parts[1] }
            if parts.count >= 2, parts[0] == "id" { return try await resolveVanity(parts[1], key: key) }
            throw Failure.noSteamID
        }
        return try await resolveVanity(text, key: key)
    }

    private static func resolveVanity(_ name: String, key: String) async throws -> String {
        let url = link("https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/", [
            ("key", key), ("vanityurl", name),
        ])
        let json = try await getJSON(url)
        guard let response = json["response"] as? [String: Any],
              intValue(response["success"]) == 1,
              let id = response["steamid"] as? String
        else { throw Failure.noSteamID }
        return id
    }

    static func ownedGames(key: String, steamID: String) async throws -> [OwnedGame] {
        let url = link("https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/", [
            ("key", key), ("steamid", steamID), ("include_appinfo", "1"),
            ("include_played_free_games", "1"), ("format", "json"),
        ])
        let json = try await getJSON(url)
        guard let response = json["response"] as? [String: Any] else { throw Failure.unreadable }
        guard let games = response["games"] as? [[String: Any]] else {
            if intValue(response["game_count"]) == 0 { return [] }
            throw Failure.privateProfile
        }
        return games.compactMap { game in
            guard let appID = intValue(game["appid"]) else { return nil }
            let name = game["name"] as? String ?? "App \(appID)"
            let last = intValue(game["rtime_last_played"]).flatMap { $0 > 0 ? Date(timeIntervalSince1970: TimeInterval($0)) : nil }
            return OwnedGame(appID: appID, name: name, lastPlayed: last)
        }
    }

    // MARK: - 표지 이미지

    /// 예전부터 쓰던 주소. 최근 게임은 주소가 바뀌어 없을 수 있어 artwork(for:)를 먼저 쓴다.
    static func fallbackArt(appID: Int) -> Art {
        let base = "\(assetBase)steam/apps/\(appID)/"
        let covers = ["library_600x900_2x.jpg", "library_600x900.jpg", "header.jpg"].compactMap { URL(string: base + $0) }
        return Art(covers: covers, hero: URL(string: base + "library_hero.jpg"))
    }

    /// 스토어가 알려 주는 정확한 이미지 주소. 실패한 게임은 결과에 없다 (fallbackArt로 대신).
    static func artwork(for appIDs: [Int]) async -> [Int: Art] {
        var result: [Int: Art] = [:]
        var start = 0
        while start < appIDs.count {
            let chunk = Array(appIDs[start..<min(start + 50, appIDs.count)])
            start += 50
            let request: [String: Any] = [
                "ids": chunk.map { ["appid": $0] },
                "context": ["language": "koreana", "country_code": "KR"],
                "data_request": ["include_assets": true],
            ]
            guard let body = try? JSONSerialization.data(withJSONObject: request),
                  let text = String(data: body, encoding: .utf8),
                  let json = try? await getJSON(link("https://api.steampowered.com/IStoreBrowseService/GetItems/v1/", [("input_json", text)])),
                  let items = (json["response"] as? [String: Any])?["store_items"] as? [[String: Any]]
            else { continue }
            for item in items {
                guard let appID = intValue(item["appid"]) ?? intValue(item["id"]),
                      let assets = item["assets"] as? [String: Any],
                      let format = assets["asset_url_format"] as? String
                else { continue }
                let fallback = fallbackArt(appID: appID)
                func asset(_ key: String) -> URL? {
                    guard let file = assets[key] as? String, !file.isEmpty else { return nil }
                    return URL(string: assetBase + format.replacingOccurrences(of: "${FILENAME}", with: file))
                }
                var covers = ["library_capsule_2x", "library_capsule", "header", "main_capsule"].compactMap { asset($0) }
                for url in fallback.covers where !covers.contains(url) { covers.append(url) }
                result[appID] = Art(covers: covers, hero: asset("library_hero") ?? fallback.hero)
            }
        }
        return result
    }

    static func artwork(for appID: Int) async -> Art {
        await artwork(for: [appID])[appID] ?? fallbackArt(appID: appID)
    }

    // MARK: - 공통

    private static func link(_ base: String, _ items: [(String, String)]) -> URL {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        let query = items
            .map { "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")" }
            .joined(separator: "&")
        return URL(string: "\(base)?\(query)")!
    }

    private static func getJSON(_ url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw Failure.http(status) }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw Failure.unreadable }
        return object
    }

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let number as Int: number
        case let text as String: Int(text)
        case let number as NSNumber: number.intValue
        default: nil
        }
    }
}
