import CoreImage.CIFilterBuiltins
import Photos
import SwiftUI
import UIKit

/// 링크나 글로 QR 코드 이미지를 만든다.
enum QRGenerator {
    /// 주소처럼 보이는데 스킴이 없으면 https://를 붙인다 ("naver.com" → "https://naver.com").
    static func content(for input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.range(of: #"^[A-Za-z][A-Za-z0-9+.-]*:"#, options: .regularExpression) != nil {
            return trimmed
        }
        if trimmed.range(of: #"^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(:\d+)?(/\S*)?$"#, options: .regularExpression) != nil {
            return "https://" + trimmed
        }
        return trimmed
    }

    /// 사방에 흰 여백(4칸)을 두른 약 1024px QR 이미지. 내용이 비었거나 너무 길면 nil.
    static func image(for content: String) -> UIImage? {
        guard !content.isEmpty, let data = content.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let code = CIContext().createCGImage(output, from: output.extent)
        else { return nil }

        let modules = output.extent.width
        let margin: CGFloat = 4
        let moduleSize = max(4, (1024 / (modules + margin * 2)).rounded(.down))
        let side = (modules + margin * 2) * moduleSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            // 칸 경계가 흐려지지 않게 확대할 때 보간하지 않는다.
            context.cgContext.interpolationQuality = .none
            UIImage(cgImage: code).draw(in: CGRect(
                x: margin * moduleSize,
                y: margin * moduleSize,
                width: modules * moduleSize,
                height: modules * moduleSize
            ))
        }
    }
}

/// 링크를 넣으면 바로 QR 코드를 보여 주고, 공유 · 사진 저장 · 복사를 할 수 있다.
struct QRMakerView: View {
    @State private var input = ""
    @State private var message: String?
    @State private var doneTick = 0
    @FocusState private var focused: Bool

    var body: some View {
        let content = QRGenerator.content(for: input)
        let image = QRGenerator.image(for: content)
        VStack(spacing: 20) {
            inputCard
            if content.isEmpty {
                placeholder
            } else if let image {
                result(image: image, content: content)
            } else {
                Text("내용이 너무 길어서 QR 코드로 만들 수 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .sensoryFeedback(.success, trigger: doneTick)
        .onChange(of: input) { _, _ in message = nil }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("링크나 글")
                .font(.headline)
            TextField("https://example.com", text: $input)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .onSubmit { focused = false }
                .padding(14)
                .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 14))
            HStack(spacing: 10) {
                PasteButton(payloadType: String.self) { strings in
                    if let first = strings.first { input = first }
                }
                .buttonBorderShape(.capsule)
                .labelStyle(.titleAndIcon)
                .tint(.black)
                if !input.isEmpty {
                    Button {
                        input = ""
                    } label: {
                        Label("지우기", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "qrcode")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
            Text("링크를 넣으면 QR 코드가 바로 만들어져요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func result(image: UIImage, content: String) -> some View {
        VStack(spacing: 18) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .accessibilityLabel("QR 코드")
            Text(content)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            HStack(spacing: 10) {
                ShareLink(item: Image(uiImage: image), preview: SharePreview("QR 코드", image: Image(uiImage: image))) {
                    Label("공유", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.black)
                Button {
                    Task { await save(image) }
                } label: {
                    Label("저장", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                Button {
                    UIPasteboard.general.image = image
                    message = "QR 이미지를 복사했어요"
                    doneTick += 1
                } label: {
                    Label("복사", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private func save(_ image: UIImage) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            message = "사진 저장을 허용해야 저장할 수 있어요. 설정 → 앱에서 바꿀 수 있어요."
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            message = "사진 앱에 저장했어요"
            doneTick += 1
        } catch {
            message = "저장하지 못했어요: \(error.localizedDescription)"
        }
    }
}
