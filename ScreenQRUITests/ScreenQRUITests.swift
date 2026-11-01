import XCTest

/// 시뮬레이터에서 첫 실행 튜토리얼을 끝까지 넘겨 보고, 페이지마다 스크린샷을 남긴다 (CI가 로그로 꺼내 본다).
final class ScreenQRUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testFirstLaunchTutorial() {
        let app = XCUIApplication()
        // UITEST: 반복 애니메이션을 멈춘다 · UITEST_RESET: 처음 설치한 상태로 시작
        app.launchArguments = ["UITEST", "UITEST_RESET"]
        app.launch()

        let primary = app.buttons["tutorial.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 20), "처음 실행하면 튜토리얼이 먼저 나와야 함")
        XCTAssertFalse(app.buttons["home.tutorial"].exists, "튜토리얼 뒤의 기본 화면은 가려져 있어야 함")
        sleep(1)
        snap("01-welcome")

        primary.tap()
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tutorial.openShortcuts"].exists)
        sleep(1)
        snap("02-step-open")

        primary.tap()
        XCTAssertTrue(app.staticTexts["‘스크린샷 찍기’ 넣기"].waitForExistence(timeout: 5))
        sleep(1)
        snap("03-step-screenshot")

        primary.tap()
        XCTAssertTrue(app.staticTexts["‘이미지 속 QR 열기’ 넣기"].waitForExistence(timeout: 5))
        sleep(1)
        snap("04-step-qr")

        // 이전으로 한 단계 돌아갔다가 다시 앞으로
        app.buttons["tutorial.back"].tap()
        XCTAssertTrue(app.staticTexts["‘스크린샷 찍기’ 넣기"].waitForExistence(timeout: 5))
        sleep(1)
        primary.tap()
        XCTAssertTrue(app.staticTexts["‘이미지 속 QR 열기’ 넣기"].waitForExistence(timeout: 5))
        sleep(1)
        primary.tap()
        XCTAssertTrue(app.staticTexts["단축어 완성!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["실행 방법 고르기"].exists)
        sleep(2)
        snap("05-finish")

        let actionButton = app.buttons["trigger.actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        actionButton.tap()
        XCTAssertTrue(app.staticTexts["설정 → 동작 버튼"].waitForExistence(timeout: 5))
        sleep(1)
        snap("06-finish-action-button")

        // 단축어가 시험용 QR을 읽은 것처럼 앱을 연다.
        var components = URLComponents()
        components.scheme = "screenqr"
        components.host = "show"
        components.queryItems = [URLQueryItem(name: "text", value: "Screen QR Scanner 테스트 성공!")]
        if let url = components.url {
            app.open(url)
        }
        XCTAssertTrue(app.staticTexts["잘 동작해요!"].waitForExistence(timeout: 10), "시험용 QR을 읽으면 성공 표시")
        app.swipeUp()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Safari 확장 프로그램"].exists)
        snap("07-finish-tested")

        primary.tap() // 완료
        let reopen = app.buttons["home.tutorial"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 5), "완료하면 기본 화면")
        sleep(1)
        XCTAssertTrue(reopen.isHittable)
        XCTAssertFalse(primary.exists, "완료하면 튜토리얼이 닫혀야 함")
        snap("08-home")

        reopen.tap()
        XCTAssertTrue(primary.waitForExistence(timeout: 5), "버튼으로 튜토리얼을 다시 열 수 있어야 함")
        XCTAssertFalse(app.staticTexts["새 단축어 열기"].exists, "다시 열면 첫 페이지부터")
        sleep(1)
        snap("09-reopened")

        app.buttons["tutorial.later"].tap()
        XCTAssertTrue(reopen.waitForExistence(timeout: 5), "나중에를 누르면 기본 화면")

        // 끝낸 뒤에 다시 켜면 튜토리얼 없이 기본 화면
        app.terminate()
        app.launchArguments = ["UITEST"]
        app.launch()
        XCTAssertTrue(app.buttons["home.tutorial"].waitForExistence(timeout: 20), "끝낸 뒤에는 기본 화면부터")
        XCTAssertFalse(app.buttons["tutorial.primary"].exists, "끝낸 뒤에는 튜토리얼이 다시 뜨지 않아야 함")
    }

    @MainActor
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
