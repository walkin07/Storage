import SwiftUI
import UIKit

struct ScannedText: Identifiable {
    let id = UUID()
    let text: String
}

/// 단축어를 실행할 방법
enum Trigger: String, CaseIterable, Identifiable {
    case backTap, actionButton, controlCenter, safari

    var id: Self { self }

    var title: String {
        switch self {
        case .backTap: "뒷면 탭"
        case .actionButton: "동작 버튼"
        case .controlCenter: "제어 센터"
        case .safari: "Safari"
        }
    }

    var symbol: String {
        switch self {
        case .backTap: "hand.tap"
        case .actionButton: "button.horizontal.top.press"
        case .controlCenter: "switch.2"
        case .safari: "safari"
        }
    }

    var steps: [String] {
        switch self {
        case .backTap:
            ["설정 → 손쉬운 사용 → 터치 → 뒷면 탭", "이중 탭 → 단축어 ‘QR 열기’ 선택", "이제 뒷면을 두 번 톡톡"]
        case .actionButton:
            ["설정 → 동작 버튼 → 단축어", "내 단축어에서 ‘QR 열기’ 선택 (앱의 ‘이미지 속 QR 열기’를 고르면 사진 선택이 떠요)", "iPhone 15 Pro 이상에서 쓸 수 있어요"]
        case .controlCenter:
            ["제어 센터를 열고 빈 곳을 길게 누르기", "컨트롤 추가 → 단축어 → ‘QR 열기’ 선택", "제어 센터에서 한 번 누르기"]
        case .safari:
            ["설정 → 앱 → Safari → 확장 프로그램", "Screen QR Scanner 켜기", "주소창의 메뉴 → Screen QR Scanner (단축어 없이 동작)"]
        }
    }
}

/// 위쪽 전환: 화면 속 QR 읽기 설정 / 링크로 QR 만들기
enum AppMode: String, CaseIterable, Identifiable {
    case scan, make

    var id: Self { self }

    var title: String {
        switch self {
        case .scan: "QR 읽기"
        case .make: "QR 만들기"
        }
    }

    var symbol: String {
        switch self {
        case .scan: "qrcode.viewfinder"
        case .make: "qrcode"
        }
    }
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var mode: AppMode = .scan
    @State private var trigger: Trigger = .backTap
    @State private var scanned: ScannedText?
    @State private var tapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                modePicker
                switch mode {
                case .scan:
                    PhotoScanCard(onOpen: openPayload)
                    shortcutCard
                    triggerCard
                    Text("스크린샷은 저장되지 않고, QR은 기기 안에서만 읽어요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                case .make:
                    QRMakerView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sensoryFeedback(.selection, trigger: trigger)
        .sensoryFeedback(.selection, trigger: mode)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .sensoryFeedback(.success, trigger: scanned?.id)
        .onOpenURL { url in
            if let text = QRPayload.text(from: url) {
                scanned = ScannedText(text: text)
            }
        }
        .sheet(item: $scanned) { item in
            ScannedTextView(text: item.text)
        }
    }

    /// 찾은 QR 내용을 연다: 링크는 바로 열고, 글이나 Wi-Fi 정보는 내용을 보여 준다.
    private func openPayload(_ payload: String) {
        let url = QRPayload.destination(for: payload)
        if let text = QRPayload.text(from: url) {
            scanned = ScannedText(text: text)
        } else {
            openURL(url)
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 40, weight: .medium))
                .frame(width: 88, height: 88)
                .glassEffect(.regular.interactive(), in: .circle)
            VStack(spacing: 6) {
                Text("Screen QR Scanner")
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("화면 속 QR을 버튼 한 번으로 열고, 링크로 QR을 만들어요")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var modePicker: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(AppMode.allCases) { item in
                    Button {
                        withAnimation(.snappy) { mode = item }
                    } label: {
                        Label(item.title, systemImage: item.symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(item == mode ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        item == mode ? .regular.tint(.black).interactive() : .regular.interactive(),
                        in: .capsule
                    )
                }
            }
        }
    }

    private var shortcutCard: some View {
        Card(number: 1, title: "단축어 만들기") {
            VStack(alignment: .leading, spacing: 10) {
                ActionRow(symbol: "camera.viewfinder", text: "스크린샷 찍기")
                ActionRow(symbol: "qrcode", text: "이미지 속 QR 열기")
            }
            Text("이 순서로 넣고 이름을 ‘QR 열기’로 저장하세요. 두 번째 줄이 ‘스크린샷에서 QR 열기’로 이어져 있어야 버튼 한 번에 열려요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("버튼을 누를 때 진동도 느끼고 싶으면 맨 위에 ‘진동’ 동작을 하나 더 넣으세요 (검색창에 ‘진동’).")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                tapCount += 1
                if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
            } label: {
                Text("단축어 앱 열기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.black)
            .controlSize(.large)
        }
    }

    private var triggerCard: some View {
        Card(number: 2, title: "실행 방법 고르기") {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Trigger.allCases) { item in
                        TriggerChip(trigger: item, isSelected: item == trigger) {
                            withAnimation(.snappy) { trigger = item }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(trigger.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.footnote.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(step)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(trigger)
            .transition(.opacity)
        }
    }
}

private struct Card<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black, in: .circle)
                Text(title)
                    .font(.title3.weight(.semibold))
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

private struct ActionRow: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 14))
    }
}

private struct TriggerChip: View {
    let trigger: Trigger
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: trigger.symbol)
                    .font(.system(size: 18, weight: .medium))
                Text(trigger.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.black).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 18)
        )
    }
}

/// 링크가 아닌 QR(Wi-Fi 정보, 일반 텍스트 등)의 내용을 보여준다.
struct ScannedTextView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var closeTick = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("QR 내용")
                .font(.headline)
            ScrollView {
                Text(text)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
            HStack(spacing: 12) {
                Button("닫기") {
                    closeTick += 1
                    dismiss()
                }
                .buttonStyle(.glass)
                Button(copied ? "복사됨" : "복사") {
                    UIPasteboard.general.string = text
                    copied = true
                }
                .buttonStyle(.glassProminent)
                .tint(.black)
            }
            .controlSize(.large)
        }
        .padding(24)
        .background(Color.white.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .sensoryFeedback(.success, trigger: copied)
        .sensoryFeedback(.impact(weight: .light), trigger: closeTick)
    }
}
