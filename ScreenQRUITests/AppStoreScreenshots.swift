import XCTest

/// 앱 스토어용 화면을 6.9형 iPhone · 13형 iPad · 아이폰 듀오(접은 바깥 화면) 시뮬레이터에서 원본 크기로 찍는다.
/// 문구와 기기 틀은 AppStore/compose.py가 입힌다. (appstore.yml 워크플로가 실행하고, 평소 UI 테스트에서는 건너뛴다)
/// 화면마다 테스트를 나눠서, 시뮬레이터가 한 번 멈칫해도(앱을 끄지 못함 등) 다른 화면은 그대로 찍히고
/// 실패한 화면만 다시 돌린다 (-retry-tests-on-failure). 화면이 제대로 뜬 경우에만 찍는다.
final class AppStoreScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 1. 첫 화면: 버튼 한 번으로 화면 속 QR 열기
    @MainActor func test31Welcome() {
        shoot("31-welcome", ["UITEST", "UITEST_RESET"]) { app in
            app.buttons["tutorial.primary"].waitForExistence(timeout: 30)
        }
    }

    /// 2. 실행 방법 고르기 + 시험용 QR 성공
    @MainActor func test32Run() {
        shoot("32-run", ["UITEST", "UITEST_RESET", "UITEST_INBOX", "-tutorial.page", "4"]) { app in
            app.staticTexts["잘 동작해요!"].waitForExistence(timeout: 30)
        }
    }

    /// 3. 튜토리얼 단계 (단축어 완성 모습)
    @MainActor func test33Steps() {
        shoot("33-steps", ["UITEST", "UITEST_RESET", "-tutorial.page", "3"]) { app in
            app.staticTexts["‘이미지 속 QR 열기’ 넣기"].waitForExistence(timeout: 30)
        }
    }

    /// 4. 기본 화면(사진에서 QR 열기) + 글 QR을 열었을 때의 내용 시트
    @MainActor func test34Photo() {
        // 접은 아이폰 듀오는 오른쪽 상태 막대만큼 폭이 좁아서, 긴 예시 글이 단어 중간에서 줄이 넘어간다.
        let sample = Self.duoClosed ? "와이파이 비밀번호: coffee1234" : "카페 와이파이 비밀번호: coffee1234"
        shoot("34-photo", ["UITEST", "-tutorial.done", "YES", "-uitest.inboxText", sample]) { app in
            app.staticTexts["QR 내용"].waitForExistence(timeout: 30)
        }
    }

    /// 5. QR 만들기
    @MainActor func test35Make() {
        shoot("35-make", ["UITEST", "-tutorial.done", "YES", "-uitest.mode", "make", "-uitest.makeInput", "https://example.com"]) { app in
            guard app.images["QR 코드"].waitForExistence(timeout: 30) else { return false }
            // 접은 아이폰 듀오(바깥 화면)는 세로가 짧아서 QR과 공유 · 저장 · 복사 버튼이 아래로 잘린다.
            // 화면을 끝까지 올려서 QR 카드가 다 보이게 찍는다.
            if Self.duoClosed {
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
                start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
            }
            return true
        }
    }

    /// 6. Safari 확장 프로그램
    @MainActor func test36Safari() {
        shoot("36-safari", ["UITEST", "UITEST_RESET", "-tutorial.page", "5"]) { app in
            app.staticTexts["Safari에서는 단축어 없이도 돼요"].waitForExistence(timeout: 30)
        }
    }

    /// CI가 아이폰 듀오를 접어 둔 채(바깥 화면) 찍는 중인지
    private static var duoClosed: Bool { DuoScreen.state == "closed" }

    /// 앱을 켜고(앞의 테스트가 띄운 앱은 launch가 알아서 끈다), 화면이 다 뜨면 한 장 찍는다.
    @MainActor
    private func shoot(_ name: String, _ arguments: [String], ready: (XCUIApplication) -> Bool) {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        // 시스템이 그리는 버튼(붙여넣기 등)도 한국어로
        app.launchArguments = arguments + ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        guard ready(app) else {
            XCTFail("\(name) 화면이 떠야 함")
            return
        }
        sleep(2)
        // 아이폰 듀오는 CI가 접어 둔 바깥 화면을 찍는다 (DuoScreen).
        let attachment = XCTAttachment(screenshot: DuoScreen.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
