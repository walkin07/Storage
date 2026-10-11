import SwiftUI
import UIKit

struct ScannedText: Identifiable {
    let id = UUID()
    let text: String
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var scanned: ScannedText?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("아이폰 뒷면을 두 번 톡톡 치면 지금 화면에 있는 QR 링크가 바로 열려요. 아래 순서대로 한 번만 설정하면 됩니다.")
                }

                Section("1. 단축어 만들기") {
                    step(1, "단축어 앱 → 오른쪽 위 + 버튼")
                    step(2, "액션 추가: \"스크린샷 찍기\"")
                    step(3, "액션 추가: \"이미지 속 QR 열기\" (화면 QR)")
                    step(4, "이름을 \"화면 QR\"로 저장")
                    Button("단축어 앱 열기") {
                        if let url = URL(string: "shortcuts://") { openURL(url) }
                    }
                }

                Section("2. 버튼에 연결 (하나 고르기)") {
                    Label("설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 이중 탭 → 화면 QR", systemImage: "hand.tap")
                    Label("설정 → 동작 버튼 → 단축어 → 화면 QR", systemImage: "button.horizontal.top.press")
                    Label("제어 센터 편집 → 컨트롤 추가 → 단축어 → 화면 QR", systemImage: "switch.2")
                }

                Section {
                    Text("처음 실행할 때 단축어가 스크린샷 공유 권한을 물어보면 \"항상 허용\"을 눌러 주세요. 스크린샷은 사진첩에 저장되지 않습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("화면 QR")
        }
        .onOpenURL { url in
            if let text = QRPayload.text(from: url) {
                scanned = ScannedText(text: text)
            }
        }
        .sheet(item: $scanned) { item in
            ScannedTextView(text: item.text)
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        Label(text, systemImage: "\(number).circle")
    }
}

/// 링크가 아닌 QR(Wi-Fi 정보, 일반 텍스트 등)의 내용을 보여준다.
struct ScannedTextView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("QR 내용")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(copied ? "복사됨" : "복사") {
                        UIPasteboard.general.string = text
                        copied = true
                    }
                }
            }
        }
    }
}
