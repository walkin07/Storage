import UIKit
import XCTest

/// 아이폰 · 아이패드 · 아이폰 듀오에서 화면 배치를 확인하려고 주요 화면을 한 장씩 찍는다 (CI가 로그로 꺼내 본다).
/// 아이패드는 앱을 켠 채로 세로 → 가로로 돌려 가며 찍고(돌렸을 때 배치가 바로 바뀌는지도 본다),
/// 아이폰 듀오는 CI가 접은 상태 · 펼친 상태로 각각 한 번씩 돌린다 (TEST_RUNNER_DUO_STATE=closed/flat → DUO_STATE).
/// 화면마다 테스트를 나눠서, 시뮬레이터가 한 번 멈칫해도 다른 화면은 그대로 찍힌다.
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

    @MainActor func test01Welcome() {
        capture(70, "welcome", ["UITEST", "UITEST_RESET"], .button("tutorial.skip"))
    }

    @MainActor func test02StepOpen() {
        capture(71, "step-open", ["UITEST", "UITEST_RESET", "-tutorial.page", "1"], .text("새 단축어 열기"))
    }

    @MainActor func test03StepScreenshot() {
        capture(72, "step-screenshot", ["UITEST", "UITEST_RESET", "-tutorial.page", "2"], .text("‘스크린샷 찍기’ 넣기"))
    }

    @MainActor func test04StepQR() {
        capture(73, "step-qr", ["UITEST", "UITEST_RESET", "-tutorial.page", "3"], .text("‘이미지 속 QR 열기’ 넣기"))
    }

    @MainActor func test05Finish() {
        capture(74, "finish", ["UITEST", "UITEST_RESET", "-tutorial.page", "4"], .text("실행 방법 고르기"))
    }

    @MainActor func test06Safari() {
        capture(75, "safari", ["UITEST", "UITEST_RESET", "-tutorial.page", "5"], .text("Safari에서는 단축어 없이도 돼요"))
    }

    @MainActor func test07Home() {
        capture(76, "home", ["UITEST", "-tutorial.done", "YES"], .button("home.tutorial"))
    }

    @MainActor func test08Make() {
        capture(
            77, "make",
            ["UITEST", "-tutorial.done", "YES", "-uitest.mode", "make", "-uitest.makeInput", "https://example.com"],
            .image("QR 코드")
        )
    }

    @MainActor func test09Sheet() {
        capture(
            78, "sheet",
            ["UITEST", "-tutorial.done", "YES", "-uitest.inboxText", "카페 와이파이 비밀번호: coffee1234"],
            .text("QR 내용")
        )
    }

    /// 앱을 켜고 화면이 뜨면 찍는다. 아이패드는 세로로 찍은 뒤 가로로 돌려 한 장 더 찍는다.
    @MainActor
    private func capture(_ number: Int, _ name: String, _ arguments: [String], _ wait: Wait) {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let device: String
        switch DuoScreen.state {
        case "flat": device = "duo-inner"
        case "closed": device = "duo-cover"
        default: device = isPad ? "ipad" : "iphone"
        }
        // 아이폰은 세로로만 쓰고, 펼친 아이폰 듀오는 방향과 상관없이 화면에 맞춘다.
        let orientations: [(UIDeviceOrientation, String)] = isPad
            ? [(.portrait, "-portrait"), (.landscapeLeft, "-landscape")]
            : [(.portrait, "")]

        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = arguments + ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        let element: XCUIElement
        switch wait {
        case .button(let id): element = app.buttons[id]
        case .text(let label): element = app.staticTexts[label]
        case .image(let label): element = app.images[label]
        }
        XCTAssertTrue(element.waitForExistence(timeout: 30), "\(device) \(name) 화면이 떠야 함")

        for (orientation, suffix) in orientations {
            XCUIDevice.shared.orientation = orientation
            sleep(2)
            XCTAssertTrue(element.exists, "\(device) \(name)\(suffix): 돌린 뒤에도 같은 화면이어야 함")
            let attachment = XCTAttachment(screenshot: DuoScreen.screenshot())
            // CI가 이름의 ‘숫자-영문’ 부분으로 파일 이름을 만든다 (예: 70-ipad-welcome-portrait).
            attachment.name = "\(number)-\(device)-\(name)\(suffix)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        XCUIDevice.shared.orientation = .portrait
    }
}
