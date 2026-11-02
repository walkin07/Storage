import UIKit
import XCTest

/// 아이폰 · 아이패드 · 아이폰 듀오에서 화면 배치를 확인하려고 주요 화면을 한 장씩 찍는다 (CI가 로그로 꺼내 본다).
/// 아이패드는 세로와 가로로 찍고, 아이폰 듀오는 CI가 접은 상태 · 펼친 상태로 각각 한 번씩 돌린다
/// (TEST_RUNNER_DUO_STATE=closed/flat → 이 테스트에서는 DUO_STATE).
final class LayoutScreens: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// 화면이 다 떴는지 확인할 요소
    private enum Wait {
        case button(String)
        case text(String)
        case image(String)
    }

    @MainActor
    func testCaptureLayouts() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let duoState = ProcessInfo.processInfo.environment["DUO_STATE"]
        let device: String
        switch duoState {
        case "flat": device = "duo-inner"
        case "closed": device = "duo-cover"
        default: device = isPad ? "ipad" : "iphone"
        }
        // 아이패드는 세로 · 가로 둘 다 본다. 아이폰은 세로만 쓰고, 펼친 아이폰 듀오는 방향과 상관없이 화면에 맞춘다.
        let orientations: [(UIDeviceOrientation, String)] = isPad
            ? [(.portrait, "-portrait"), (.landscapeLeft, "-landscape")]
            : [(.portrait, "")]

        // (이름, 실행 인자, 다 떴는지 확인할 요소)
        let screens: [(String, [String], Wait)] = [
            ("welcome", ["UITEST", "UITEST_RESET"], .button("tutorial.skip")),
            ("step-open", ["UITEST", "UITEST_RESET", "-tutorial.page", "1"], .text("새 단축어 열기")),
            ("step-screenshot", ["UITEST", "UITEST_RESET", "-tutorial.page", "2"], .text("‘스크린샷 찍기’ 넣기")),
            ("step-qr", ["UITEST", "UITEST_RESET", "-tutorial.page", "3"], .text("‘이미지 속 QR 열기’ 넣기")),
            ("finish", ["UITEST", "UITEST_RESET", "-tutorial.page", "4"], .text("실행 방법 고르기")),
            ("safari", ["UITEST", "UITEST_RESET", "-tutorial.page", "5"], .text("Safari에서는 단축어 없이도 돼요")),
            ("home", ["UITEST", "-tutorial.done", "YES"], .button("home.tutorial")),
            ("make", ["UITEST", "-tutorial.done", "YES", "-uitest.mode", "make", "-uitest.makeInput", "https://example.com"], .image("QR 코드")),
            ("sheet", ["UITEST", "-tutorial.done", "YES", "-uitest.inboxText", "카페 와이파이 비밀번호: coffee1234"], .text("QR 내용")),
        ]

        for (orientation, suffix) in orientations {
            XCUIDevice.shared.orientation = orientation
            for (index, screen) in screens.enumerated() {
                let (name, arguments, wait) = screen
                let app = XCUIApplication()
                app.launchArguments = arguments + ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
                app.launch()
                let element: XCUIElement
                switch wait {
                case .button(let id): element = app.buttons[id]
                case .text(let label): element = app.staticTexts[label]
                case .image(let label): element = app.images[label]
                }
                XCTAssertTrue(element.waitForExistence(timeout: 20), "\(device) \(name)\(suffix) 화면이 떠야 함")
                sleep(2)
                let attachment = XCTAttachment(screenshot: Self.screenshot(inner: duoState == "flat"))
                // CI가 이름의 ‘숫자-영문’ 부분으로 파일 이름을 만든다 (예: 70-ipad-welcome-portrait).
                attachment.name = "\(70 + index)-\(device)-\(name)\(suffix)"
                attachment.lifetime = .keepAlways
                add(attachment)
                app.terminate()
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }

    /// 지금 켜진 화면을 찍는다. 아이폰 듀오는 화면이 둘이라(XCUIScreen.main은 늘 바깥 화면)
    /// 크기로 구분해서, 펼쳤으면 큰 안쪽 화면을, 접었으면 작은 바깥 화면을 고른다.
    @MainActor
    private static func screenshot(inner: Bool) -> XCUIScreenshot {
        let screens = XCUIScreen.screens
        guard screens.count > 1 else { return XCUIScreen.main.screenshot() }
        let shots = screens.map { $0.screenshot() }.sorted {
            $0.image.size.width * $0.image.size.height < $1.image.size.width * $1.image.size.height
        }
        return (inner ? shots.last : shots.first) ?? XCUIScreen.main.screenshot()
    }
}
