import SwiftUI
import UIKit

struct ScannedText: Identifiable {
    let id = UUID()
    let text: String
}

/// 위쪽 전환: 화면 속 QR 읽기 / 링크로 QR 만들기
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
    @AppStorage(TutorialKeys.done) private var tutorialDone = false
    @AppStorage(TutorialKeys.page) private var tutorialPage = 0
    /// 처음 설치했으면 튜토리얼부터 보여 준다 (첫 화면부터 바로 보이도록 시작 값으로 정한다).
    @State private var showTutorial = !UserDefaults.standard.bool(forKey: TutorialKeys.done)
    /// 튜토리얼을 시작할 페이지. nil이면 보던 페이지부터 (처음 설치했으면 ‘튜토리얼 보기 / 건너뛰기’ 화면).
    /// 기본 화면의 버튼으로 열면 이미 보기로 고른 것이라 바로 1단계부터 연다.
    @State private var tutorialStart: TutorialPage?
    @State private var tutorialTestPassed = false
    @State private var mode: AppMode = .scan
    @State private var scanned: ScannedText?

    var body: some View {
        ZStack {
            home
                .scaleEffect(showTutorial ? 0.94 : 1)
                .opacity(showTutorial ? 0 : 1)
                .allowsHitTesting(!showTutorial)
                .accessibilityHidden(showTutorial)
            if showTutorial {
                TutorialView(start: tutorialStart, testPassed: tutorialTestPassed, onClose: closeTutorial)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .opacity.combined(with: .scale(scale: 1.04))
                    ))
                    .zIndex(1)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sensoryFeedback(.selection, trigger: mode)
        .sensoryFeedback(.success, trigger: scanned?.id)
        // 튜토리얼을 열 때는 가볍게, 닫고 기본 화면으로 갈 때는 조금 더 묵직하게
        .sensoryFeedback(trigger: showTutorial) { _, shown -> SensoryFeedback? in
            shown ? SensoryFeedback.impact(weight: .light) : SensoryFeedback.impact(weight: .medium)
        }
        .onOpenURL { url in
            guard let text = QRPayload.text(from: url) else { return }
            if showTutorial && text == TutorialView.testPayload {
                // 튜토리얼 마지막 페이지의 시험용 QR을 단축어로 읽었다.
                tutorialTestPassed = true
            } else {
                scanned = ScannedText(text: text)
            }
        }
        .sheet(item: $scanned) { item in
            ScannedTextView(text: item.text)
        }
    }

    private var home: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                modePicker
                switch mode {
                case .scan:
                    VStack(spacing: 16) {
                        PhotoScanCard(onOpen: openPayload)
                        tutorialButton
                    }
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
    }

    private func openTutorial() {
        tutorialStart = .open
        tutorialTestPassed = false
        withAnimation(.spring(duration: 0.55, bounce: 0.1)) { showTutorial = true }
    }

    private func closeTutorial() {
        tutorialDone = true
        tutorialPage = 0
        withAnimation(.smooth(duration: 0.5)) { showTutorial = false }
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
            Text("Screen QR Scanner")
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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

    /// 튜토리얼을 다시 보는 버튼
    private var tutorialButton: some View {
        Button(action: openTutorial) {
            HStack(spacing: 14) {
                ShortcutsGlyph(size: 44)
                Text("단축어 만들기 튜토리얼")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .accessibilityIdentifier("home.tutorial")
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
