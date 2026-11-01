import SwiftUI

/// UI 테스트(앱 스토어 스크린샷)에서 처음 상태를 정할 때만 쓰는 값 (예: -uitest.mode make).
/// 배포(Release) 빌드에서는 늘 nil이라 앱 동작에 영향이 없다.
func uiTestDefault(_ key: String) -> String? {
    #if DEBUG
    return UserDefaults.standard.string(forKey: key)
    #else
    return nil
    #endif
}

@main
struct ScreenQRApp: App {
    init() {
        // UI 테스트: 처음 설치한 것처럼 튜토리얼부터 시작한다.
        if ProcessInfo.processInfo.arguments.contains("UITEST_RESET") {
            UserDefaults.standard.removeObject(forKey: TutorialKeys.done)
            UserDefaults.standard.removeObject(forKey: TutorialKeys.page)
            UserDefaults.standard.removeObject(forKey: TutorialKeys.completed)
        }
        // UI 테스트: 단축어 동작이 튜토리얼의 시험용 QR을 읽어 앱에 넘긴 것처럼 시작한다.
        if ProcessInfo.processInfo.arguments.contains("UITEST_INBOX") {
            QRInbox.shared.deliver(TutorialView.testPayload)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
