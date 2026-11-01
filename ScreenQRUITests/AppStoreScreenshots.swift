import XCTest

/// 앱 스토어용 화면을 6.9형 iPhone 시뮬레이터에서 원본 크기(1320×2868)로 찍는다.
/// 문구와 기기 틀은 AppStore/compose.py가 입힌다. (appstore.yml 워크플로가 실행하고, 평소 UI 테스트에서는 건너뛴다)
final class AppStoreScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureScreens() {
        // 1. 첫 화면: 버튼 한 번으로 화면 속 QR 열기
        shoot("31-welcome", ["UITEST", "UITEST_RESET"]) { app in
            app.buttons["tutorial.primary"].waitForExistence(timeout: 20)
        }
        // 2. 실행 방법 고르기 + 시험용 QR 성공
        shoot("32-run", ["UITEST", "UITEST_RESET", "UITEST_INBOX", "-tutorial.page", "4"]) { app in
            app.staticTexts["잘 동작해요!"].waitForExistence(timeout: 20)
        }
        // 3. 튜토리얼 단계 (단축어 완성 모습)
        shoot("33-steps", ["UITEST", "UITEST_RESET", "-tutorial.page", "3"]) { app in
            app.staticTexts["‘이미지 속 QR 열기’ 넣기"].waitForExistence(timeout: 20)
        }
        // 4. 기본 화면(사진에서 QR 열기) + 글 QR을 열었을 때의 내용 시트
        shoot("34-photo", ["UITEST", "-tutorial.done", "YES", "-uitest.inboxText", "카페 와이파이 비밀번호: coffee1234"]) { app in
            app.staticTexts["QR 내용"].waitForExistence(timeout: 20)
        }
        // 5. QR 만들기
        shoot("35-make", ["UITEST", "-tutorial.done", "YES", "-uitest.mode", "make", "-uitest.makeInput", "https://example.com"]) { app in
            app.images["QR 코드"].waitForExistence(timeout: 20)
        }
        // 6. Safari 확장 프로그램
        shoot("36-safari", ["UITEST", "UITEST_RESET", "-tutorial.page", "5"]) { app in
            app.staticTexts["Safari에서는 단축어 없이도 돼요"].waitForExistence(timeout: 20)
        }
    }

    @MainActor
    private func shoot(_ name: String, _ arguments: [String], ready: (XCUIApplication) -> Bool) {
        let app = XCUIApplication()
        // 시스템이 그리는 버튼(붙여넣기 등)도 한국어로
        app.launchArguments = arguments + ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(ready(app), "\(name) 화면이 떠야 함")
        sleep(2)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
    }
}
