import UIKit
import XCTest

/// 시뮬레이터에서 첫 실행 튜토리얼을 끝까지 넘겨 보고, 페이지마다 스크린샷을 남긴다 (CI가 로그로 꺼내 본다).
final class ScreenQRUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// 처음 설치 → 끝까지 보고 완료 → 기본 화면 버튼으로 다시 열기 (이때는 ‘나중에’ 대신 X)
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
        XCTAssertFalse(app.buttons["tutorial.close"].exists, "처음 설치 화면에는 X가 없어야 함")
        XCTAssertFalse(app.buttons["home.tutorial"].exists, "튜토리얼 뒤의 기본 화면은 가려져 있어야 함")
        sleep(1)
        snap("01-welcome")

        primary.tap()
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tutorial.skip"].exists, "튜토리얼을 시작하면 건너뛰기 대신 위쪽 ‘나중에’")
        XCTAssertTrue(app.buttons["tutorial.later"].exists, "처음 보는 중에는 ‘나중에’")
        XCTAssertFalse(app.buttons["tutorial.close"].exists)
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

        // 처음 보는 중에 이전으로 돌아가면 처음 설치 화면 그대로 (건너뛰기 있음, X 없음)
        app.buttons["tutorial.back"].tap()
        XCTAssertTrue(app.buttons["tutorial.skip"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tutorial.close"].exists)
        sleep(1)
        primary.tap()
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5))
        sleep(1)

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
        XCTAssertTrue(app.buttons["tutorial.later"].exists, "실행 방법 페이지는 마지막이 아니라 ‘나중에’가 있어야 함")
        snap("05-finish")

        // 아이패드에는 뒷면 탭 · 동작 버튼이 없고, 대신 Apple Pencil · AssistiveTouch가 있다.
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        XCTAssertEqual(app.buttons["trigger.backTap"].exists, !isPad, "뒷면 탭은 아이폰에만")
        XCTAssertEqual(app.buttons["trigger.pencilSqueeze"].exists, isPad, "Apple Pencil은 아이패드에만")
        XCTAssertTrue(app.buttons["trigger.controlCenter"].exists, "제어 센터는 둘 다")
        let otherTrigger = app.buttons[isPad ? "trigger.pencilSqueeze" : "trigger.actionButton"]
        XCTAssertTrue(otherTrigger.waitForExistence(timeout: 5))
        otherTrigger.tap()
        XCTAssertTrue(app.staticTexts[isPad ? "설정 → Apple Pencil → 스퀴즈" : "설정 → 동작 버튼"].waitForExistence(timeout: 5))
        sleep(1)
        snap("06-finish-other-trigger")

        // 단축어 동작이 시험용 QR을 읽어 앱에 넘긴 것처럼 다시 켠다 (앱이 꺼져 있다가 단축어로 켜진 경우와 같다).
        // UITEST_RESET은 빼서 보던 페이지(실행 방법)가 이어지게 한다.
        app.terminate()
        app.launchArguments = ["UITEST", "UITEST_INBOX"]
        app.launch()
        XCTAssertTrue(app.staticTexts["잘 동작해요!"].waitForExistence(timeout: 20), "단축어 동작이 시험용 QR을 넘기면 성공 표시")
        sleep(1)
        snap("07-finish-tested")

        // 마지막 페이지: Safari 확장 프로그램 (따로 한 페이지라 놓치지 않는다)
        primary.tap()
        XCTAssertTrue(app.staticTexts["Safari에서는 단축어 없이도 돼요"].waitForExistence(timeout: 5), "Safari 확장 페이지")
        sleep(1)
        XCTAssertTrue(primary.label.contains("완료"), "마지막 페이지 버튼: \(primary.label)")
        XCTAssertFalse(app.buttons["tutorial.later"].exists, "마지막 페이지에는 아래 ‘완료’만")
        XCTAssertFalse(app.buttons["tutorial.close"].exists)
        snap("08-safari")

        primary.tap() // 완료
        let reopen = app.buttons["home.tutorial"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 5), "완료하면 기본 화면")
        sleep(1)
        XCTAssertTrue(reopen.isHittable)
        XCTAssertFalse(primary.exists, "완료하면 튜토리얼이 닫혀야 함")
        snap("09-home")

        // 끝까지 보고 완료를 누른 뒤 다시 열면: 바로 1단계, 위에는 ‘나중에’ 대신 X
        reopen.tap()
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5), "버튼으로 다시 열면 바로 1단계부터")
        sleep(1)
        XCTAssertTrue(app.buttons["tutorial.close"].exists, "완료한 적이 있으면 X")
        XCTAssertFalse(app.buttons["tutorial.later"].exists, "완료한 적이 있으면 ‘나중에’가 없어야 함")
        XCTAssertFalse(app.buttons["tutorial.skip"].exists)
        snap("10-reopened-completed")

        // 이전으로 처음 화면에 가면: 건너뛰기 없이 위에 X
        app.buttons["tutorial.back"].tap()
        sleep(1)
        XCTAssertTrue(primary.label.contains("튜토리얼 보기"), "처음 화면으로 돌아와야 함: \(primary.label)")
        XCTAssertFalse(app.buttons["tutorial.skip"].exists, "다시 연 튜토리얼의 첫 화면에는 건너뛰기가 없어야 함")
        XCTAssertTrue(app.buttons["tutorial.close"].exists, "다시 연 튜토리얼의 첫 화면에는 X")
        snap("11-reopened-welcome")

        app.buttons["tutorial.close"].tap()
        XCTAssertTrue(reopen.waitForExistence(timeout: 5), "X를 누르면 기본 화면")
        sleep(1)
        XCTAssertFalse(primary.exists)

        // 끝낸 뒤에 다시 켜면 튜토리얼 없이 기본 화면
        app.terminate()
        app.launchArguments = ["UITEST"]
        app.launch()
        XCTAssertTrue(app.buttons["home.tutorial"].waitForExistence(timeout: 20), "끝낸 뒤에는 기본 화면부터")
        XCTAssertFalse(app.buttons["tutorial.primary"].exists, "끝낸 뒤에는 튜토리얼이 다시 뜨지 않아야 함")
    }

    /// 처음 화면에서 건너뛰기 → 기본 화면. 끝까지 보지 않았으니 다시 열면 위에 ‘나중에’, 첫 화면에는 X.
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
        snap("12-skipped-home")

        home.tap()
        XCTAssertTrue(app.staticTexts["새 단축어 열기"].waitForExistence(timeout: 5), "버튼으로 열면 바로 1단계부터")
        sleep(1)
        XCTAssertTrue(app.buttons["tutorial.later"].exists, "끝까지 보지 않았으면 ‘나중에’")
        XCTAssertFalse(app.buttons["tutorial.close"].exists)
        snap("13-skipped-reopened")

        app.buttons["tutorial.back"].tap()
        sleep(1)
        XCTAssertFalse(app.buttons["tutorial.skip"].exists, "다시 연 튜토리얼의 첫 화면에는 건너뛰기가 없어야 함")
        XCTAssertTrue(app.buttons["tutorial.close"].exists, "다시 연 튜토리얼의 첫 화면에는 X")
        snap("14-skipped-reopened-welcome")

        app.buttons["tutorial.close"].tap()
        XCTAssertTrue(home.waitForExistence(timeout: 5), "X를 누르면 기본 화면")

        app.terminate()
        app.launchArguments = ["UITEST"]
        app.launch()
        XCTAssertTrue(app.buttons["home.tutorial"].waitForExistence(timeout: 20), "건너뛴 뒤에는 다시 켜도 기본 화면")
        XCTAssertFalse(app.buttons["tutorial.primary"].exists, "건너뛴 뒤에는 튜토리얼이 다시 뜨지 않아야 함")
    }

    /// 기본 화면의 ‘QR 읽기 / QR 만들기’는 글자가 없는 가장자리를 눌러도 바뀌어야 한다 (아이패드는 버튼이 넓어 빈 곳이 많다).
    @MainActor
    func testModePickerWholeButtonIsTappable() {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST", "-tutorial.done", "YES"]
        app.launch()

        let make = app.buttons["QR 만들기"]
        XCTAssertTrue(make.waitForExistence(timeout: 20), "기본 화면의 QR 만들기 버튼")
        // 가운데 글자에서 먼 왼쪽 가장자리를 누른다.
        make.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["링크나 글"].waitForExistence(timeout: 5), "버튼 가장자리를 눌러도 QR 만들기로 바뀌어야 함")

        let scan = app.buttons["QR 읽기"]
        scan.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["home.tutorial"].waitForExistence(timeout: 5), "버튼 가장자리를 눌러도 QR 읽기로 바뀌어야 함")
    }

    /// 애니메이션을 켠 채로 페이지마다 바로 띄워, 그림이 움직이는 중간 장면을 몇 장 찍는다.
    @MainActor
    func testTutorialAnimations() {
        // (페이지 번호, 이름, 찍을 장 수) — 반복 마지막의 ‘다음’ 안내 장면까지 담기도록 넉넉히 찍는다.
        let pages: [(Int, String, Int)] = [
            (0, "welcome", 4),
            (1, "open", 8),
            (2, "screenshot", 4),
            (3, "qr", 4),
            (5, "safari", 10),
        ]
        let letters = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
        for (index, name, count) in pages {
            let app = XCUIApplication()
            // -tutorial.page N: 그 페이지부터 이어 보는 것처럼 시작
            app.launchArguments = ["UITEST_RESET", "-tutorial.page", "\(index)"]
            app.launch()
            XCTAssertTrue(app.buttons["tutorial.primary"].waitForExistence(timeout: 20), "\(name) 페이지가 떠야 함")
            for frame in letters.prefix(count) {
                usleep(900_000)
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
