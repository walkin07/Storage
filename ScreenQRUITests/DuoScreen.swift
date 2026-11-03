import XCTest

/// 아이폰 듀오는 화면이 둘이다 (XCUIScreen.main은 늘 바깥 화면).
/// CI가 접거나 펼친 상태를 TEST_RUNNER_DUO_STATE=flat/closed로 알려 주면(테스트에서는 DUO_STATE)
/// 크기로 구분해서, 펼쳤으면 큰 안쪽 화면을, 접었으면 작은 바깥 화면을 찍는다.
enum DuoScreen {
    /// "flat"(펼침) · "closed"(접음). 아이폰 듀오가 아니면 nil.
    static var state: String? { ProcessInfo.processInfo.environment["DUO_STATE"] }

    /// 지금 켜진 화면을 찍는다. 화면이 하나뿐인 기기는 기본 화면.
    @MainActor static func screenshot() -> XCUIScreenshot {
        let screens = XCUIScreen.screens
        guard screens.count > 1 else { return XCUIScreen.main.screenshot() }
        let shots = screens.map { $0.screenshot() }.sorted { area($0) < area($1) }
        return (state == "flat" ? shots.last : shots.first) ?? XCUIScreen.main.screenshot()
    }

    private static func area(_ shot: XCUIScreenshot) -> CGFloat {
        shot.image.size.width * shot.image.size.height
    }
}
