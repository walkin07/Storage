import SwiftUI
import UIKit

enum TutorialKeys {
    /// 튜토리얼을 끝냈거나 ‘나중에’를 눌렀는지
    static let done = "tutorial.done"
    /// 보던 페이지 (단축어 앱에 다녀오는 사이 앱이 종료돼도 이어서 보도록)
    static let page = "tutorial.page"
}

enum TutorialMotion {
    /// UI 테스트에서는 반복 애니메이션을 멈춰 화면을 고정한다.
    static let frozen = ProcessInfo.processInfo.arguments.contains("UITEST")
}

/// 단축어를 실행할 방법
enum Trigger: String, CaseIterable, Identifiable {
    case backTap, actionButton, controlCenter

    var id: Self { self }

    var title: String {
        switch self {
        case .backTap: "뒷면 탭"
        case .actionButton: "동작 버튼"
        case .controlCenter: "제어 센터"
        }
    }

    var symbol: String {
        switch self {
        case .backTap: "hand.tap"
        case .actionButton: "button.horizontal.top.press"
        case .controlCenter: "switch.2"
        }
    }

    var steps: [String] {
        switch self {
        case .backTap:
            [
                "설정 → 손쉬운 사용 → 터치 → 뒷면 탭",
                "‘이중 탭’을 누르고, 아래쪽 단축어 목록에서 방금 만든 단축어를 골라요",
                "아이폰 뒷면을 두 번 톡톡 치면 실행돼요",
            ]
        case .actionButton:
            [
                "설정 → 동작 버튼",
                "옆으로 넘겨 ‘단축어’를 고르고, 방금 만든 단축어를 선택해요",
                "동작 버튼을 길게 누르면 실행돼요 (iPhone 15 Pro · 16 이후 모델)",
            ]
        case .controlCenter:
            [
                "제어 센터를 열고 왼쪽 위 ＋를 눌러요",
                "‘컨트롤 추가’에서 ‘단축어’를 넣고, 방금 만든 단축어를 골라요",
                "제어 센터에서 한 번 누르면 실행돼요",
            ]
        }
    }
}

/// 튜토리얼 페이지 순서
enum TutorialPage: Int, CaseIterable, Identifiable {
    case welcome, open, screenshot, qr, finish

    var id: Self { self }

    /// 단축어 만들기 단계 수
    static let stepCount = 3

    /// 단축어를 만드는 단계 번호 (소개·마지막 페이지는 nil)
    var stepNumber: Int? {
        switch self {
        case .open: 1
        case .screenshot: 2
        case .qr: 3
        case .welcome, .finish: nil
        }
    }

    var title: String {
        switch self {
        case .welcome: "버튼 한 번으로\n화면 속 QR 열기"
        case .open: "새 단축어 열기"
        case .screenshot: "‘스크린샷 찍기’ 넣기"
        case .qr: "‘이미지 속 QR 열기’ 넣기"
        case .finish: "단축어 완성!"
        }
    }

    var lines: [Text] {
        switch self {
        case .open:
            [
                Text("아래 ‘단축어 앱 열기’를 누르면 빈 단축어가 열려요"),
                Text("열렸으면 왼쪽 위 ‘\(Image(systemName: "arrowtriangle.left.fill"))\u{00A0}Screen\u{00A0}QR\u{00A0}Scanner’\u{2060}를 눌러 여기로 돌아와요"),
            ]
        case .screenshot:
            [
                Text("단축어 앱 아래쪽 ‘동작 검색’을 눌러요"),
                Text("‘스크린샷’을 입력하고 ‘스크린샷 찍기’를 눌러요"),
            ]
        case .qr:
            [
                Text("다시 ‘QR’을 입력하고 ‘이미지\u{00A0}속\u{00A0}QR\u{00A0}열기’\u{2060}를 눌러요"),
                Text("‘스크린샷에서\u{00A0}QR\u{00A0}열기’\u{2060}로 이어졌는지 확인해요"),
                Text("오른쪽 위 완료(\(Image(systemName: "checkmark")))를 누르면 끝!"),
            ]
        case .welcome, .finish:
            []
        }
    }
}

/// 처음 설치하면 먼저 나오는 단축어 만들기 튜토리얼.
/// 한 단계씩 보여 주고 ‘다음’으로 넘어가며, 마지막 페이지에서 실행 방법과 Safari 확장을 안내한다.
struct TutorialView: View {
    /// 마지막 페이지의 시험용 QR 내용. 단축어로 읽으면 ContentView가 알려 준다.
    static let testPayload = "Screen QR Scanner 테스트 성공!"
    static let testQR: UIImage? = QRGenerator.image(for: testPayload)

    let testPassed: Bool
    let onClose: () -> Void

    @AppStorage(TutorialKeys.page) private var savedPage = 0
    @State private var page: TutorialPage
    @State private var forward = true
    @State private var lastMove = Date.distantPast
    @State private var trigger: Trigger = .backTap
    /// 이번에 새 단축어를 이미 만들었으면 다시 눌러도 단축어 앱만 연다 (빈 단축어가 여러 개 생기지 않게).
    @State private var createdShortcut = false
    @State private var awaitingReturn = false
    @State private var leftApp = false
    @State private var returnedPages: Set<TutorialPage> = []
    @State private var failedPage: TutorialPage?
    @State private var openTick = 0
    @State private var returnTick = 0
    @State private var errorTick = 0

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter start: 시작할 페이지. nil이면 보던 페이지부터 (처음 설치했으면 ‘튜토리얼 보기 / 건너뛰기’ 화면)
    init(start: TutorialPage?, testPassed: Bool, onClose: @escaping () -> Void) {
        let saved = TutorialPage(rawValue: UserDefaults.standard.integer(forKey: TutorialKeys.page)) ?? .welcome
        _page = State(initialValue: start ?? saved)
        self.testPassed = testPassed
        self.onClose = onClose
    }

    /// 위쪽 점으로 보여 줄 페이지 (첫 화면은 튜토리얼을 볼지 고르는 곳이라 뺀다)
    private static let progressPages = TutorialPage.allCases.filter { $0 != .welcome }

    private var still: Bool { reduceMotion || TutorialMotion.frozen }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack {
                pageContent(page)
                    .id(page)
                    .transition(.tutorialPage(forward: forward, reduceMotion: reduceMotion))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
        .background {
            LinearGradient(
                colors: [Color(white: 0.95), .white],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()
        }
        .onChange(of: page) { _, new in
            savedPage = new.rawValue
        }
        .onChange(of: scenePhase) { _, phase in
            handle(phase)
        }
        // 다음은 부드럽게 톡, 이전은 더 약하게, 마지막 페이지에 오면 완성 진동
        .sensoryFeedback(trigger: page) { old, new -> SensoryFeedback? in
            if new == .finish { return SensoryFeedback.success }
            return SensoryFeedback.impact(flexibility: .soft, intensity: new.rawValue > old.rawValue ? 0.8 : 0.5)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: openTick)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.55), trigger: returnTick)
        .sensoryFeedback(.error, trigger: errorTick)
        .sensoryFeedback(.selection, trigger: trigger)
        .sensoryFeedback(.success, trigger: testPassed) { old, new in !old && new }
    }

    // MARK: 위·아래 막대

    private var topBar: some View {
        // 숨길 때는 아예 만들지 않는다 (보이지 않는 버튼이 VoiceOver에 잡히지 않게). 자리는 그대로 둬서 가운데 점이 흔들리지 않는다.
        let hidesLater = page == .welcome || page == .finish
        return HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if page != .welcome {
                    Button(action: back) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("이전")
                    .accessibilityIdentifier("tutorial.back")
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(width: 84, height: 44, alignment: .leading)

            Spacer(minLength: 0)
            if page != .welcome {
                progressDots
                    .transition(.opacity)
            }
            Spacer(minLength: 0)

            // 첫 화면에는 아래에 ‘건너뛰기’가 있고, 마지막 페이지에는 ‘완료’가 있어서 숨긴다.
            ZStack(alignment: .trailing) {
                if !hidesLater {
                    Button(action: onClose) {
                        Text("나중에")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("tutorial.later")
                    .transition(.opacity)
                }
            }
            .frame(width: 84, height: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .animation(.smooth(duration: 0.3), value: page)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(Self.progressPages) { item in
                Capsule()
                    .fill(item.rawValue <= page.rawValue ? Color.black : Color.black.opacity(0.12))
                    .frame(width: item == page ? 24 : 8, height: 8)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: page)
        .accessibilityElement()
        .accessibilityLabel("\(Self.progressPages.count)쪽 중 \(max(page.rawValue, 1))쪽")
    }

    private var bottomBar: some View {
        VStack(spacing: 4) {
            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Text(primaryTitle)
                        .contentTransition(.interpolate)
                    Image(systemName: page == .finish ? "checkmark" : "arrow.right")
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: returnTick)
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.glassProminent)
            .tint(.black)
            .controlSize(.large)
            .accessibilityIdentifier("tutorial.primary")

            // 처음 화면: 튜토리얼을 볼지 건너뛸지 고른다.
            if page == .welcome {
                Button(action: onClose) {
                    Text("건너뛰기")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tutorial.skip")
                .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, page == .welcome ? 4 : 12)
        .animation(.smooth(duration: 0.3), value: page)
    }

    private var primaryTitle: String {
        switch page {
        case .welcome: "단축어 만들기 튜토리얼 보기"
        case .finish: "완료"
        default: "다음"
        }
    }

    // MARK: 페이지

    private func pageContent(_ item: TutorialPage) -> some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 620
            ScrollView {
                Group {
                    switch item {
                    case .welcome:
                        WelcomePage(still: still, compact: compact)
                    case .open, .screenshot, .qr:
                        StepPage(
                            page: item,
                            still: still,
                            compact: compact,
                            returned: returnedPages.contains(item),
                            failedToOpen: failedPage == item,
                            onOpenShortcuts: openShortcuts
                        )
                    case .finish:
                        FinishPage(trigger: $trigger, testPassed: testPassed, still: still)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(
                    maxWidth: .infinity,
                    minHeight: proxy.size.height,
                    alignment: item == .welcome ? .center : .top
                )
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }

    // MARK: 동작

    private func primaryAction() {
        if page == .finish {
            onClose()
        } else if let next = TutorialPage(rawValue: page.rawValue + 1) {
            go(to: next)
        }
    }

    private func back() {
        if let previous = TutorialPage(rawValue: page.rawValue - 1) {
            go(to: previous)
        }
    }

    private func go(to target: TutorialPage) {
        // 두 번 빠르게 눌러 한 단계를 건너뛰지 않게
        let now = Date()
        guard target != page, now.timeIntervalSince(lastMove) > 0.3 else { return }
        lastMove = now
        forward = target.rawValue > page.rawValue
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(duration: 0.5, bounce: 0.12)) {
            page = target
        }
    }

    private func openShortcuts() {
        let creating = page == .open && !createdShortcut
        guard let url = URL(string: creating ? "shortcuts://create-shortcut" : "shortcuts://") else { return }
        let current = page
        openTick += 1
        failedPage = nil
        awaitingReturn = true
        leftApp = false
        openURL(url) { accepted in
            if accepted {
                if creating { createdShortcut = true }
            } else {
                awaitingReturn = false
                withAnimation(.smooth) { failedPage = current }
                errorTick += 1
            }
        }
    }

    /// 단축어 앱에 다녀오면 ‘다음’ 버튼을 살짝 튕기고 안내를 띄운다.
    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .background:
            if awaitingReturn { leftApp = true }
        case .active:
            guard awaitingReturn, leftApp else { return }
            awaitingReturn = false
            leftApp = false
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                _ = returnedPages.insert(page)
            }
            returnTick += 1
        default:
            break
        }
    }
}

// MARK: - 소개

private struct WelcomePage: View {
    let still: Bool
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 22 : 30) {
            WelcomeHero(still: still)
                .scaleEffect(compact ? 0.8 : 1)
                .frame(height: compact ? 256 : 320)
            VStack(spacing: 12) {
                Text(TutorialPage.welcome.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("단축어를 하나 만들어 두면, 어떤 앱에서든 화면에 보이는 QR을 바로 열 수 있어요.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Label("아이폰에서는 앱이 다른 앱 화면을 찍을 수 없어서, 화면 캡처는 단축어가 맡아요.", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 18, style: .continuous))
        }
    }
}

// MARK: - 단축어 만들기 단계

private struct StepPage: View {
    let page: TutorialPage
    let still: Bool
    let compact: Bool
    let returned: Bool
    let failedToOpen: Bool
    let onOpenShortcuts: () -> Void

    @State private var scene: MockScene
    /// 그림이 지금 보여 주는 설명 줄 (nil이면 모두 보통 글씨)
    @State private var activeLine: Int?

    init(
        page: TutorialPage,
        still: Bool,
        compact: Bool,
        returned: Bool,
        failedToOpen: Bool,
        onOpenShortcuts: @escaping () -> Void
    ) {
        self.page = page
        self.still = still
        self.compact = compact
        self.returned = returned
        self.failedToOpen = failedToOpen
        self.onOpenShortcuts = onOpenShortcuts
        _scene = State(initialValue: still ? MockScene.still(for: page) : MockScene.start(for: page))
        _activeLine = State(initialValue: still ? nil : 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 18 : 24) {
            ShortcutMock(scene: scene, showsBackLink: page == .open, still: still)
                .frame(height: compact ? 236 : 290)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(page.stepNumber ?? 1) / \(TutorialPage.stepCount) 단계")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(page.title)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(page.lines.enumerated()), id: \.offset) { index, line in
                    TutorialStepRow(number: index + 1, text: line, style: style(for: index))
                }
            }
            ShortcutsLaunchRow(
                isNew: page == .open,
                attention: page == .open && !returned && !still,
                action: onOpenShortcuts
            )
            if failedToOpen {
                VStack(alignment: .leading, spacing: 8) {
                    Label("단축어 앱을 열 수 없어요. 지웠다면 App Store에서 다시 받아 주세요.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let url = URL(string: "https://apps.apple.com/app/id915249334") {
                        Link("App Store에서 ‘단축어’ 받기", destination: url)
                            .font(.footnote.weight(.semibold))
                    }
                }
                .transition(.opacity)
            }
            if returned {
                Label {
                    Text(page == .qr ? "완료까지 눌렀다면 아래 ‘다음’을 눌러 주세요" : "다 했다면 아래 ‘다음’을 눌러 주세요")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.1), in: .capsule)
                .transition(.scale(scale: 0.9, anchor: .topLeading).combined(with: .opacity))
            }
        }
        .task { await play() }
    }

    private func style(for index: Int) -> StepRowStyle {
        guard let activeLine else { return .plain }
        return index == activeLine ? .active : .dimmed
    }

    // MARK: 그림 애니메이션 (페이지를 넘기면 멈춘다)

    private func play() async {
        guard !still else { return }
        switch page {
        case .open: await playOpen()
        case .screenshot: await playScreenshot()
        case .qr: await playQR()
        case .welcome, .finish: break
        }
    }

    /// 이 앱에서 ‘단축어 앱 열기’ → 새 단축어 → 왼쪽 위로 돌아오기
    private func playOpen() async {
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.3)) { activeLine = 0 }
            guard await tutorialPause(900) else { return }
            scene.tapOpen += 1
            guard await tutorialPause(380) else { return }
            withAnimation(.spring(duration: 0.55, bounce: 0.18)) { scene.inShortcuts = true }
            guard await tutorialPause(1500) else { return }
            withAnimation(.smooth(duration: 0.3)) { activeLine = 1 }
            guard await tutorialPause(600) else { return }
            scene.tapBack += 1
            guard await tutorialPause(380) else { return }
            withAnimation(.smooth(duration: 0.45)) { scene.inShortcuts = false }
            guard await tutorialPause(700) else { return }
        }
    }

    /// 동작 검색 → ‘스크린샷’ 입력 → ‘스크린샷 찍기’ 추가
    private func playScreenshot() async {
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.35)) {
                scene.reset(blocks: 0)
                activeLine = 0
            }
            guard await tutorialPause(900) else { return }
            scene.tapSearch += 1
            guard await tutorialPause(250) else { return }
            withAnimation(.smooth(duration: 0.2)) { scene.searching = true }
            guard await tutorialPause(500) else { return }
            withAnimation(.smooth(duration: 0.3)) { activeLine = 1 }
            for typed in ["스", "스크", "스크린", "스크린샷"] {
                scene.query = typed
                guard await tutorialPause(170) else { return }
            }
            guard await tutorialPause(200) else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) { scene.result = .screenshot }
            guard await tutorialPause(800) else { return }
            scene.tapResult += 1
            guard await tutorialPause(380) else { return }
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                scene.result = nil
                scene.query = ""
                scene.searching = false
                scene.blocks = 1
            }
            guard await tutorialPause(2200) else { return }
        }
    }

    /// ‘QR’ 입력 → ‘이미지 속 QR 열기’ 추가(스크린샷이 이어짐) → 완료
    private func playQR() async {
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.35)) {
                scene.reset(blocks: 1)
                activeLine = 0
            }
            guard await tutorialPause(900) else { return }
            scene.tapSearch += 1
            guard await tutorialPause(250) else { return }
            withAnimation(.smooth(duration: 0.2)) { scene.searching = true }
            guard await tutorialPause(450) else { return }
            for typed in ["Q", "QR"] {
                scene.query = typed
                guard await tutorialPause(200) else { return }
            }
            guard await tutorialPause(200) else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) { scene.result = .qr }
            guard await tutorialPause(800) else { return }
            scene.tapResult += 1
            guard await tutorialPause(380) else { return }
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                scene.result = nil
                scene.query = ""
                scene.searching = false
                scene.blocks = 2
                activeLine = 1
            }
            guard await tutorialPause(1600) else { return }
            withAnimation(.smooth(duration: 0.3)) { activeLine = 2 }
            guard await tutorialPause(450) else { return }
            scene.tapDone += 1
            guard await tutorialPause(200) else { return }
            withAnimation(.smooth(duration: 0.25)) { scene.doneLit = true }
            guard await tutorialPause(1500) else { return }
        }
    }
}

/// 단축어 앱을 여는 줄. 첫 단계에서는 새 단축어를 만들고, 그다음부터는 단축어 앱으로 돌아간다.
private struct ShortcutsLaunchRow: View {
    let isNew: Bool
    /// 아직 누르지 않았으면 테두리가 퍼지며 눈길을 끈다.
    let attention: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ShortcutsGlyph(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isNew ? "단축어 앱 열기" : "단축어 앱으로 이동")
                        .font(.headline)
                    Text(isNew ? "빈 단축어가 새로 만들어져요" : "만들던 단축어로 돌아가요")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.forward")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
        .background {
            if attention {
                AttentionRing(cornerRadius: 22)
            }
        }
        .accessibilityIdentifier("tutorial.openShortcuts")
    }
}

/// 버튼 둘레로 천천히 퍼지는 테두리
private struct AttentionRing: View {
    let cornerRadius: CGFloat

    var body: some View {
        PhaseAnimator([false, true]) { expanded in
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(expanded ? 0 : 0.3), lineWidth: 2)
                .padding(expanded ? -10 : -1)
        } animation: { expanded -> Animation? in
            expanded ? Animation.easeOut(duration: 1.3) : Animation.linear(duration: 0.01).delay(0.5)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 마지막 페이지: 실행 방법 고르기 + Safari 확장

private struct FinishPage: View {
    @Binding var trigger: Trigger
    let testPassed: Bool
    let still: Bool

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                DrawnCheck(still: still)
                Text(TutorialPage.finish.title)
                    .font(.largeTitle.bold())
                Text("이제 단축어를 실행할 방법을 골라 설정해 주세요.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
            triggerCard
            safariCard
        }
    }

    private var triggerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("실행 방법 고르기")
                    .font(.title3.weight(.semibold))
                Text("원하는 방법을 골라 설정하세요. 여러 개 해도 돼요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Trigger.allCases) { item in
                        TriggerChip(trigger: item, isSelected: item == trigger) {
                            withAnimation(.snappy) { trigger = item }
                        }
                    }
                }
            }
            // 바뀌는 동안 예전 설명과 새 설명이 위아래로 쌓이지 않게 겹쳐서 바꾼다.
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(trigger.steps.enumerated()), id: \.offset) { index, step in
                        TutorialStepRow(number: index + 1, text: Text(step))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(trigger)
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
            Divider()
            TestRow(passed: testPassed)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var safariCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "safari")
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 46, height: 46)
                    .glassEffect(.regular, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safari 확장 프로그램")
                        .font(.title3.weight(.semibold))
                    Text("Safari에서는 단축어 없이도 돼요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                TutorialStepRow(number: 1, text: Text("설정 → 앱 → Safari → 확장 프로그램"))
                TutorialStepRow(number: 2, text: Text("‘Screen\u{00A0}QR\u{00A0}Scanner’\u{2060}를 켜요"))
                TutorialStepRow(number: 3, text: Text("Safari 주소창의 메뉴에서 ‘Screen\u{00A0}QR\u{00A0}Scanner’\u{2060}를 누르면 보고 있는 페이지의 QR이 열려요"))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

/// 설정한 방법으로 바로 시험해 보는 QR. 단축어로 읽으면 체크로 바뀐다.
private struct TestRow: View {
    let passed: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                if passed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else if let qr = TutorialView.testQR {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
            }
            .frame(width: 96, height: 96)
            .background(.white, in: .rect(cornerRadius: 16, style: .continuous))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(passed ? "잘 동작해요!" : "바로 시험해 보기")
                    .font(.headline)
                Text(passed
                    ? "이제 어떤 앱에서든 화면 속 QR을 바로 열 수 있어요."
                    : "설정한 방법으로 단축어를 실행해 이 QR이 열리면 성공이에요. 처음 한 번은 ‘항상 허용’을 눌러 주세요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.4), value: passed)
    }
}

// MARK: - 페이지 전환

/// 새 페이지는 넘기는 방향에서 미끄러져 들어오고, 이전 페이지는 제자리에서 흐려지며 사라진다.
/// (사라지는 쪽은 방향을 쓰지 않아서 ‘이전’을 눌러도 엉뚱한 쪽으로 밀려 나가지 않는다.)
private struct PageShift: ViewModifier {
    let x: CGFloat
    let scale: CGFloat
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: x)
            .scaleEffect(scale)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

private extension AnyTransition {
    static func tutorialPage(forward: Bool, reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let rest = PageShift(x: 0, scale: 1, blur: 0, opacity: 1)
        return .asymmetric(
            insertion: .modifier(active: PageShift(x: forward ? 60 : -60, scale: 1, blur: 8, opacity: 0), identity: rest),
            removal: .modifier(active: PageShift(x: 0, scale: 0.95, blur: 8, opacity: 0), identity: rest)
        )
    }
}
