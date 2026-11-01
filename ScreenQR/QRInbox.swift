import Combine
import Foundation

/// 단축어 동작(이미지 속 QR 열기)이 읽은 ‘링크가 아닌 QR’ 내용을 앱 화면에 넘겨준다.
///
/// 단축어의 ‘URL 열기’(OpenURLIntent)는 앱 자체 주소(screenqr://)를 열지 못하고 아무 일도 일어나지 않는다.
/// 이 동작은 앱 안에서 실행되므로, URL을 거치지 않고 같은 앱 안에서 바로 화면에 전한다.
/// 화면이 아직 없을 때(단축어가 앱을 뒤에서 켰을 때) 넣어 둔 내용도, 화면이 생기면 받아 간다.
@MainActor
final class QRInbox: ObservableObject {
    static let shared = QRInbox()

    @Published private(set) var pending: ScannedText?

    func deliver(_ text: String) {
        pending = ScannedText(text: text)
    }

    /// 화면이 받아 간 내용을 지운다 (그사이 새로 온 내용은 남겨 둔다).
    func clear(_ id: UUID) {
        if pending?.id == id { pending = nil }
    }
}
