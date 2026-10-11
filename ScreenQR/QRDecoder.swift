import Foundation
import Vision

enum QRDecoder {
    /// 이미지에서 찾은 코드 내용을 큰 것부터 순서대로 돌려준다.
    static func decode(_ imageData: Data) throws -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr, .microQR, .aztec, .dataMatrix]

        let handler = VNImageRequestHandler(data: imageData, options: [:])
        try handler.perform([request])

        let observations = (request.results ?? []).sorted {
            area($0.boundingBox) > area($1.boundingBox)
        }

        var seen = Set<String>()
        return observations
            .compactMap(\.payloadStringValue)
            .filter { seen.insert($0).inserted }
    }

    private static func area(_ rect: CGRect) -> CGFloat {
        rect.width * rect.height
    }
}

enum QRPayload {
    /// 바로 열어도 되는 스킴. 그 외(Wi-Fi, 일반 텍스트 등)는 앱에서 내용을 보여준다.
    private static let directSchemes: Set<String> = [
        "http", "https", "mailto", "tel", "sms", "facetime", "facetime-audio", "maps", "itms-apps",
    ]

    static func destination(for payload: String) -> URL {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed),
           let scheme = url.scheme?.lowercased(),
           directSchemes.contains(scheme) {
            return url
        }

        // "example.com/abc" 처럼 스킴 없이 들어있는 주소
        if trimmed.range(of: #"^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(/\S*)?$"#, options: .regularExpression) != nil,
           let url = URL(string: "https://" + trimmed) {
            return url
        }

        return textURL(for: trimmed)
    }

    static func textURL(for text: String) -> URL {
        var components = URLComponents()
        components.scheme = "screenqr"
        components.host = "show"
        components.queryItems = [URLQueryItem(name: "text", value: text)]
        return components.url!
    }

    static func text(from url: URL) -> String? {
        guard url.scheme == "screenqr", url.host == "show" else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "text" }?.value
    }
}
