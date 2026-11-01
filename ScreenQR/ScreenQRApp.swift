import SwiftUI

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
