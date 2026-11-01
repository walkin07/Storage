import AppIntents
import Foundation
import UIKit

/// 단축어에서 "스크린샷 찍기" 다음에 붙여 쓰는 액션.
/// 링크는 앱 화면을 띄우지 않고 바로 연다. 글이나 Wi-Fi 정보 같은 QR은 앱을 앞으로 불러 내용을 보여 준다.
/// 앱은 다른 앱의 화면을 캡처할 수 없어서, 캡처는 단축어의 "스크린샷 찍기"가 한다.
/// 그 동작이 빠졌으면 사진 선택 창을 띄우는 대신 무엇을 넣어야 하는지 알려 준다.
struct OpenQRFromImageIntent: AppIntent {
    static let title: LocalizedStringResource = "이미지 속 QR 열기"
    static let description = IntentDescription(
        "이미지(스크린샷)에서 QR 코드를 찾아 링크를 바로 엽니다. 링크가 아니면 앱에서 내용을 보여줍니다."
    )
    /// 평소에는 뒤에서 조용히 실행하고, 링크가 아닌 QR일 때만 앱을 앞으로 불러온다.
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(
        title: "이미지",
        supportedContentTypes: [.image],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var image: IntentFile?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$image)에서 QR 열기")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & OpensIntent {
        guard let image else {
            throw QRIntentError.missingScreenshot
        }
        let payloads: [String]
        do {
            payloads = try QRDecoder.decode(image.data)
        } catch {
            throw QRIntentError.unreadableImage
        }

        guard let payload = payloads.first else {
            throw QRIntentError.notFound
        }

        let destination = QRPayload.destination(for: payload)
        if let text = QRPayload.text(from: destination) {
            // 링크가 아닌 QR(글, Wi-Fi 정보, 튜토리얼의 시험용 QR).
            // ‘URL 열기’로 앱 주소(screenqr://)를 넘기면 아무 일도 일어나지 않아서, 이 동작이 실행 중인
            // 앱 안에서 바로 화면에 넘긴다. 앱이 뒤에 있으면(다른 앱을 보던 중이면) 앞으로 불러온다.
            let inBackground = await MainActor.run { () -> Bool in
                QRInbox.shared.deliver(text)
                return UIApplication.shared.applicationState == .background
            }
            if inBackground, systemContext.currentMode.canContinueInForeground {
                try? await continueInForeground(alwaysConfirm: false)
            }
        }

        // 링크는 Safari 등으로 바로 열린다. (링크가 아닐 때의 앱 주소는 열리지 않아도 위에서 이미 전했다.)
        return .result(
            value: payload,
            opensIntent: OpenURLIntent(destination)
        )
    }
}

enum QRIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notFound
    case unreadableImage
    case missingScreenshot

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound: "화면에서 QR 코드를 찾지 못했어요."
        case .unreadableImage: "이미지를 읽을 수 없어요."
        case .missingScreenshot: "단축어 맨 위에 ‘스크린샷 찍기’ 동작을 넣어 주세요. 단축어 편집 화면 아래 ‘동작 검색’에서 ‘스크린샷’을 검색하면 나와요."
        }
    }
}
