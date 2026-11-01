import SwiftUI

@main
struct GameDeckApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var engines = EngineMonitor()
    @StateObject private var controllers = ControllerHub()
    @StateObject private var toasts = ToastCenter()

    init() {
        // 스팀 표지를 넉넉히 보관해서 다시 열 때 바로 보이게 한다.
        URLCache.shared = URLCache(memoryCapacity: 32 * 1024 * 1024, diskCapacity: 300 * 1024 * 1024, directory: nil)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(library)
                .environmentObject(engines)
                .environmentObject(controllers)
                .environmentObject(toasts)
        }
    }
}
