import Foundation
import SafariServices

/// popup.js가 보낸 이미지에서 QR을 찾아 돌려준다. 인식은 앱과 같은 QRDecoder(Vision)를 쓴다.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey] as? [String: Any] ?? [:]
        let dataURLs = message["dataURLs"] as? [String] ?? []
        let urls = (message["urls"] as? [String] ?? []).compactMap(URL.init(string:))

        Task {
            var images = dataURLs.compactMap(Self.data(fromDataURL:))
            for url in urls.prefix(20) {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    images.append(data)
                }
            }

            var seen = Set<String>()
            var results: [[String: Any]] = []
            for image in images {
                for payload in (try? QRDecoder.decode(image)) ?? [] where seen.insert(payload).inserted {
                    let destination = QRPayload.destination(for: payload)
                    results.append([
                        "payload": payload,
                        "url": destination.absoluteString,
                        "isLink": QRPayload.text(from: destination) == nil,
                    ])
                }
            }

            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["results": results]]
            context.completeRequest(returningItems: [response], completionHandler: nil)
        }
    }

    private static func data(fromDataURL string: String) -> Data? {
        guard let comma = string.firstIndex(of: ","),
              string[..<comma].hasSuffix(";base64") else { return nil }
        return Data(base64Encoded: String(string[string.index(after: comma)...]))
    }
}
