import PhotosUI
import SwiftUI

/// 앱 안에서 사진을 골라 그 속의 QR을 바로 연다. QR이 여러 개면 고르게 한다.
struct PhotoScanCard: View {
    /// 찾은 QR 내용을 연다 (링크는 열고, 글은 보여 준다).
    let onOpen: (String) -> Void

    @State private var item: PhotosPickerItem?
    @State private var working = false
    @State private var message: String?
    @State private var choices: [String] = []
    @State private var showChoices = false
    @State private var successTick = 0
    @State private var errorTick = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black, in: .circle)
                Text("사진에서 QR 열기")
                    .font(.title3.weight(.semibold))
            }
            Text("저장해 둔 스크린샷이나 QR 사진을 고르면 바로 열어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PhotosPicker(selection: $item, matching: .images) {
                Label(working ? "읽는 중…" : "사진 고르기", systemImage: "photo")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.black)
            .controlSize(.large)
            .disabled(working)
            if let message {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            Task { await scan(picked) }
        }
        .confirmationDialog("QR 코드가 여러 개 있어요", isPresented: $showChoices, titleVisibility: .visible) {
            ForEach(choices, id: \.self) { payload in
                Button(Self.label(for: payload)) { onOpen(payload) }
            }
            Button("취소", role: .cancel) {}
        }
        .sensoryFeedback(.impact(weight: .light), trigger: item) { _, picked in picked != nil }
        .sensoryFeedback(.success, trigger: successTick)
        .sensoryFeedback(.error, trigger: errorTick)
    }

    private func scan(_ picked: PhotosPickerItem) async {
        working = true
        message = nil
        defer {
            working = false
            item = nil // 같은 사진을 다시 고를 수 있게
        }
        guard let data = try? await picked.loadTransferable(type: Data.self) else {
            message = "사진을 불러오지 못했어요."
            errorTick += 1
            return
        }
        let payloads = await Task.detached(priority: .userInitiated) {
            (try? QRDecoder.decode(data)) ?? []
        }.value
        switch payloads.count {
        case 0:
            message = "이 사진에서 QR 코드를 찾지 못했어요."
            errorTick += 1
        case 1:
            successTick += 1
            onOpen(payloads[0])
        default:
            successTick += 1
            choices = payloads
            showChoices = true
        }
    }

    private static func label(for payload: String) -> String {
        payload.count > 60 ? String(payload.prefix(57)) + "…" : payload
    }
}
