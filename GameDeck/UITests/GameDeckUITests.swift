import XCTest

/// 시뮬레이터에서 앱을 띄워 주요 화면이 열리는지 확인하고 스크린샷을 남긴다 (CI가 로그로 꺼내 본다).
final class GameDeckUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testEmptyLibrary() {
        let app = launch(demo: "empty")
        XCTAssertTrue(app.staticTexts["게임덱에 오신 걸 환영해요"].waitForExistence(timeout: 15))
        snap(app, "01-empty-portrait")
    }

    @MainActor
    func testLibraryScreens() {
        let app = launch(demo: "library")
        XCTAssertTrue(app.staticTexts["Portal 2"].firstMatch.waitForExistence(timeout: 15))
        sleep(4) // 표지 이미지가 내려받아질 시간
        snap(app, "02-home-portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(4)
        snap(app, "03-home-landscape")

        let options = app.buttons["옵션"].firstMatch
        if options.waitForExistence(timeout: 5) {
            options.tap()
            sleep(2)
            snap(app, "04-detail")
            app.buttons["닫기"].firstMatch.tap()
            sleep(1)
        } else {
            XCTFail("옵션 버튼이 없음")
        }

        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        let engines = app.buttons["엔진 준비 상태"].firstMatch
        if engines.waitForExistence(timeout: 5) {
            engines.tap()
            sleep(2)
            snap(app, "05-engines")
            app.buttons["닫기"].firstMatch.tap()
            sleep(1)
        } else {
            XCTFail("엔진 준비 상태 버튼이 없음")
        }

        let add = app.buttons["게임 추가"].firstMatch
        if add.waitForExistence(timeout: 5) {
            add.tap()
            sleep(2)
            snap(app, "06-add")
        } else {
            XCTFail("게임 추가 버튼이 없음")
        }
    }

    @MainActor
    private func launch(demo: String) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-gamedeck-demo", demo]
        app.launch()
        return app
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
