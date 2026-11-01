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

        // 처음 화면: ‘단축어 만들기 튜토리얼 보기’와 ‘건너뛰기’ 중에서 고른다.
        let primary = app.buttons["tutorial.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 20), "처음 실행하면 튜토리얼 보기 버튼이 먼저 나와야 함")
        XCTAssertTrue(primary.label.contains("튜토리얼 보기"), "첫 버튼 이름: \(primary.label)")
        XCTAssertTrue(app.buttons["tutorial.skip"].exists, "처음 화면에 건너뛰기 버튼")
        XCTAssertFalse(app.buttons["tutorial.later"].exists, "처음 화면에는 위쪽 ‘나중에’가 없어야 함")
        XCTAssertFalse(app.buttons["home.tutorial"].exists, "튜토리얼 뒤의 기본 화면은 가려져 있어야 함")
        sleep(1)
        snap("01-welcome")

        primary.tap()
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tutorial.skip"].exists, "튜토리얼을 시작하면 건너뛰기 대신 위쪽 ‘나중에’")
        XCTAssertTrue(app.buttons["tutorial.later"].exists)
        let openShortcuts = app.buttons["tutorial.openShortcuts"]
        XCTAssertTrue(openShortcuts.exists)
        sleep(1)
        snap("02-step-open")

        // 단축어 앱에 다녀오면 ‘다음’ 안내가 뜬다. (시뮬레이터에 단축어 앱이 없으면 App Store 안내가 뜬다.)
        openShortcuts.tap()
        sleep(3)
        app.activate()
        let returnedHint = app.staticTexts["다 했다면 아래 ‘다음’을 눌러 주세요"]
        let missingNote = app.staticTexts["단축어 앱을 열 수 없어요. 지웠다면 App Store에서 다시 받아 주세요."]
        XCTAssertTrue(
            returnedHint.waitForExistence(timeout: 8) || missingNote.exists,
            "단축어 앱에 다녀오면(또는 열 수 없으면) 안내가 떠야 함"
        )
        sleep(1)
        snap("02-step-open-returned")

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
        // XCUIApplication.open은 앱을 다시 켜므로, 처음 상태로 되돌리는 UITEST_RESET은 빼서 보던 페이지가 이어지게 한다.
        // (앱이 꺼져 있을 때 단축어가 실행된 경우와 같다.)
        app.launchArguments = ["UITEST"]
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
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5), "버튼으로 다시 열면 바로 1단계부터")
        XCTAssertFalse(app.buttons["tutorial.skip"].exists)
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

    /// 처음 화면에서 건너뛰기를 고르면 기본 화면으로 가고, 다시 켜도 튜토리얼이 뜨지 않는다.
    @MainActor
    func testSkipOnFirstLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST", "UITEST_RESET"]
        app.launch()

        let skip = app.buttons["tutorial.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 20), "처음 화면에 건너뛰기 버튼")
        skip.tap()
        let home = app.buttons["home.tutorial"]
        XCTAssertTrue(home.waitForExistence(timeout: 5), "건너뛰기를 누르면 기본 화면")
        sleep(1)
        XCTAssertTrue(home.isHittable)
        snap("10-skipped-home")

        app.terminate()
        app.launchArguments = ["UITEST"]
        app.launch()
        XCTAssertTrue(app.buttons["home.tutorial"].waitForExistence(timeout: 20), "건너뛴 뒤에는 다시 켜도 기본 화면")
        XCTAssertFalse(app.buttons["tutorial.primary"].exists, "건너뛴 뒤에는 튜토리얼이 다시 뜨지 않아야 함")
    }

    /// 애니메이션을 켠 채로 페이지마다 바로 띄워, 그림이 움직이는 중간 장면을 몇 장 찍는다.
    @MainActor
    func testTutorialAnimations() {
        let pages = ["welcome", "open", "screenshot", "qr"]
        for (index, name) in pages.enumerated() {
            let app = XCUIApplication()
            // -tutorial.page N: 그 페이지부터 이어 보는 것처럼 시작
            app.launchArguments = ["UITEST_RESET", "-tutorial.page", "\(index)"]
            app.launch()
            XCTAssertTrue(app.buttons["tutorial.primary"].waitForExistence(timeout: 20), "\(name) 페이지가 떠야 함")
            for frame in ["a", "b", "c", "d"] {
                usleep(800_000)
                snap("2\(index)-\(name)-\(frame)")
            }
            app.terminate()
        }
    }

    @MainActor
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
