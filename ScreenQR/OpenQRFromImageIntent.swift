import AppIntents
import Foundation

/// 단축어에서 "스크린샷 찍기" 다음에 붙여 쓰는 액션.
/// 앱 화면을 띄우지 않고 QR을 읽어 링크를 바로 연다.
/// 앱은 다른 앱의 화면을 캡처할 수 없어서, 캡처는 단축어의 "스크린샷 찍기"가 한다.
/// 그 동작이 빠졌으면 사진 선택 창을 띄우는 대신 무엇을 넣어야 하는지 알려 준다.
struct OpenQRFromImageIntent: AppIntent {
    static let title: LocalizedStringResource = "이미지 속 QR 열기"
    static let description = IntentDescription(
        "이미지(스크린샷)에서 QR 코드를 찾아 링크를 바로 엽니다. 링크가 아니면 앱에서 내용을 보여줍니다."
    )

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

        return .result(
            value: payload,
            opensIntent: OpenURLIntent(QRPayload.destination(for: payload))
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
