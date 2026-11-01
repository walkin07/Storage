import SwiftUI

@main
struct ScreenQRApp: App {
    init() {
        // UI 테스트: 처음 설치한 것처럼 튜토리얼부터 시작한다.
        if ProcessInfo.processInfo.arguments.contains("UITEST_RESET") {
            UserDefaults.standard.removeObject(forKey: TutorialKeys.done)
            UserDefaults.standard.removeObject(forKey: TutorialKeys.page)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
