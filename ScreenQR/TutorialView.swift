import SwiftUI
import UIKit

enum TutorialKeys {
    /// 튜토리얼을 끝냈거나 ‘나중에’를 눌렀는지
    static let done = "tutorial.done"
    /// 보던 페이지 (단축어 앱에 다녀오는 사이 앱이 종료돼도 이어서 보도록)
    static let page = "tutorial.page"
    /// 마지막 페이지까지 보고 ‘완료’를 누른 적이 있는지 (다시 열면 ‘나중에’ 대신 X)
    static let completed = "tutorial.completed"
}

/// 튜토리얼을 어떻게 열었는지
enum TutorialEntry: Equatable {
    /// 처음 설치: 첫 화면에 ‘건너뛰기’가 있다.
    case firstRun
    /// 기본 화면의 버튼으로 다시 열었다. completed면 예전에 끝까지 보고 완료를 눌렀다.
    case revisit(completed: Bool)
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
                "단축어 앱에서 그 단축어에 ‘대기’(1초)를 넣고 맨 위로 옮겨요. 제어 센터가 닫힌 뒤에 찍혀요",
                "제어 센터에서 한 번 누르면 실행돼요",
            ]
        }
    }
}

/// 튜토리얼 페이지 순서
enum TutorialPage: Int, CaseIterable, Identifiable {
    case welcome, open, screenshot, qr, finish, safari

    var id: Self { self }

    /// 단축어 만들기 단계 수
    static let stepCount = 3

    /// 단축어를 만드는 단계 번호 (소개·마지막 페이지는 nil)
    var stepNumber: Int? {
        switch self {
        case .open: 1
        case .screenshot: 2
        case .qr: 3
        case .welcome, .finish, .safari: nil
        }
    }

    var title: String {
        switch self {
        case .welcome: "버튼 한 번으로\n화면 속 QR 열기"
        case .open: "새 단축어 열기"
        case .screenshot: "‘스크린샷 찍기’ 넣기"
        case .qr: "‘이미지 속 QR 열기’ 넣기"
        case .finish: "단축어 완성!"
        case .safari: "Safari에서는 단축어 없이도 돼요"
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
                Text("‘스크린샷에서\u{00A0}QR\u{00A0}열기’\u{2060}가 추가되면 끝!"),
            ]
        case .safari:
            [
                Text("설정 → 앱 → Safari → 확장 프로그램"),
                Text("‘Screen\u{00A0}QR\u{00A0}Scanner’\u{2060}를 켜요"),
                Text("Safari 주소창 메뉴에서 ‘Screen\u{00A0}QR\u{00A0}Scanner’\u{2060}를 누르면 보고 있는 페이지의 QR이 열려요"),
            ]
        case .welcome, .finish:
            []
        }
    }

    /// 마지막 페이지 (아래 버튼이 ‘완료’)
    var isLast: Bool { self == TutorialPage.allCases.last }

    /// 그림 반복의 마지막 장면에 나오는 안내
    var nextHint: String {
        switch self {
        case .safari: "설정했다면 아래 ‘완료’를 눌러 주세요"
        default: "다 했다면 아래 ‘다음’을 눌러 주세요"
        }
    }
}

/// 처음 설치하면 먼저 나오는 단축어 만들기 튜토리얼.
/// 한 단계씩 보여 주고 ‘다음’으로 넘어가며, 마지막 페이지에서 실행 방법과 Safari 확장을 안내한다.
struct TutorialView: View {
    /// 실행 방법 페이지의 시험용 QR 내용 (링크가 아닌 글). 단축어 동작이 읽으면 앱 안에서 바로 ContentView에 전해진다.
    static let testPayload = "Screen QR Scanner 시험용 QR"
    static let testQR: UIImage? = QRGenerator.image(for: testPayload)

    let entry: TutorialEntry
    let testPassed: Bool
    /// 닫을 때 부른다. 마지막 페이지에서 ‘완료’를 눌렀으면 true.
    let onClose: (_ completed: Bool) -> Void

    @AppStorage(TutorialKeys.page) private var savedPage = 0
    @State private var page: TutorialPage
    @State private var forward = true
    @State private var lastMove = Date.distantPast
    @State private var trigger: Trigger = .backTap
    /// 이번에 새 단축어를 이미 만들었으면 다시 눌러도 단축어 앱만 연다 (빈 단축어가 여러 개 생기지 않게).
    @State private var createdShortcut = false
    @State private var awaitingReturn = false
    @State private var leftApp = false
    /// Safari 페이지를 보다가 앱 밖(설정 등)에 나갔는지
    @State private var leftFromSafari = false
    @State private var returnedPages: Set<TutorialPage> = []
    @State private var failedPage: TutorialPage?
    @State private var openTick = 0
    @State private var returnTick = 0
    @State private var errorTick = 0

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter start: 시작할 페이지. nil이면 보던 페이지부터 (처음 설치했으면 ‘튜토리얼 보기 / 건너뛰기’ 화면)
    init(
        start: TutorialPage?,
        entry: TutorialEntry,
        testPassed: Bool,
        onClose: @escaping (_ completed: Bool) -> Void
    ) {
        let saved = TutorialPage(rawValue: UserDefaults.standard.integer(forKey: TutorialKeys.page)) ?? .welcome
        _page = State(initialValue: start ?? saved)
        self.entry = entry
        self.testPassed = testPassed
        self.onClose = onClose
    }

    /// 위쪽 오른쪽 자리에 무엇을 둘지
    private enum TopTrailing {
        case hidden, later, close
    }

    private var topTrailing: TopTrailing {
        // 처음 설치 화면은 아래 ‘건너뛰기’, 다시 열어서 첫 화면으로 돌아왔으면 X
        if page == .welcome { return entry == .firstRun ? .hidden : .close }
        // 마지막 페이지는 아래 ‘완료’로 닫는다.
        if page.isLast { return .hidden }
        // 끝까지 보고 완료를 누른 적이 있으면 ‘나중에’ 대신 X
        if entry == .revisit(completed: true) { return .close }
        return .later
    }

    /// 처음 설치했을 때의 첫 화면에만 ‘건너뛰기’가 있다.
    private var showsSkip: Bool { page == .welcome && entry == .firstRun }

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
        // 위쪽 막대(뒤로·X)와 그 아래 내용이 같은 색으로 이어지도록 한 가지 흰색 (기본 화면과도 같다)
        .background(Color.white.ignoresSafeArea())
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
        HStack(spacing: 0) {
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

            ZStack(alignment: .trailing) {
                switch topTrailing {
                case .hidden:
                    EmptyView()
                case .later:
                    Button {
                        onClose(false)
                    } label: {
                        Text("나중에")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("tutorial.later")
                    .transition(.opacity)
                case .close:
                    Button {
                        onClose(false)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("닫기")
                    .accessibilityIdentifier("tutorial.close")
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
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
                    Image(systemName: page.isLast ? "checkmark" : "arrow.right")
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

            // 처음 설치 화면: 튜토리얼을 볼지 건너뛸지 고른다.
            if showsSkip {
                Button {
                    onClose(false)
                } label: {
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
        .padding(.bottom, showsSkip ? 4 : 12)
        .animation(.smooth(duration: 0.3), value: page)
    }

    private var primaryTitle: String {
        if page == .welcome { return "단축어 만들기 튜토리얼 보기" }
        return page.isLast ? "완료" : "다음"
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
                    case .safari:
                        SafariPage(still: still, compact: compact, returned: returnedPages.contains(.safari))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .frame(
                    maxWidth: .infinity,
                    minHeight: proxy.size.height,
                    alignment: item == .welcome ? .center : .top
                )
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            // 위쪽 막대·아래 버튼과의 경계에서 내용(그림자 포함)이 뚝 잘리지 않고 자연스럽게 사라지게
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                }
            }
        }
    }

    // MARK: 동작

    private func primaryAction() {
        if page.isLast {
            onClose(true)
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

    /// 단축어 앱에 다녀오면(Safari 페이지는 설정 등 앱 밖에 다녀오면) ‘다음’ 버튼을 살짝 튕기고 안내를 띄운다.
    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .background:
            if awaitingReturn { leftApp = true }
            if page == .safari { leftFromSafari = true }
        case .active:
            if leftFromSafari {
                leftFromSafari = false
                if page == .safari {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        _ = returnedPages.insert(.safari)
                    }
                    returnTick += 1
                }
            }
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
    /// 그림 반복의 마지막 장면: ‘다 했다면 아래 다음을 눌러 주세요’
    @State private var showHint: Bool

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
        _showHint = State(initialValue: still && returned)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 18 : 24) {
            ShortcutMock(scene: scene, showsBackLink: page == .open, still: still)
                .frame(height: compact ? 236 : 290)
                .overlay {
                    if showHint {
                        NextHintCard(text: page.nextHint, still: still)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            // 반복 중에 잠깐 나오는 장면은 그림의 일부라 VoiceOver에는 단축어 앱에 다녀온 뒤에만 알린다.
                            .accessibilityHidden(!returned)
                    }
                }
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
        }
        // 단축어 앱에서 돌아오면(returned) 처음부터 다시: 안내 장면부터 보여 준다.
        .task(id: returned) { await play() }
    }

    private func style(for index: Int) -> StepRowStyle {
        // ‘다음’ 안내가 나오는 동안은 어느 줄도 가리키지 않는다 (번호 아이콘 모두 꺼짐).
        if showHint && !still { return .dimmed }
        guard let activeLine else { return .plain }
        return index == activeLine ? .active : .dimmed
    }

    // MARK: 그림 애니메이션 (페이지를 넘기면 멈춘다)

    private func play() async {
        if still {
            // 움직임 줄이기: 단축어 앱에 다녀왔을 때만 안내를 그대로 띄워 둔다.
            withAnimation(.smooth(duration: 0.3)) { showHint = returned }
            return
        }
        if returned {
            guard await showNextHint(thenReset: resetToStart) else { return }
        }
        switch page {
        case .open: await playOpen()
        case .screenshot: await playScreenshot()
        case .qr: await playQR()
        case .welcome, .finish, .safari: break
        }
    }

    /// 반복의 첫 장면으로 (누른 횟수는 그대로)
    private func resetToStart() {
        switch page {
        case .open: scene.inShortcuts = false
        case .screenshot: scene.reset(blocks: 0)
        case .qr: scene.reset(blocks: 1)
        case .welcome, .finish, .safari: break
        }
        activeLine = 0
    }

    /// 한 바퀴의 끝. 단축어 앱에 다녀온 뒤에는 ‘다음’ 안내를 보여 주고, 그 전에는 첫 장면으로 되돌린다.
    /// 첫 장면으로 돌아가는 그림과 1번 아이콘은 같은 애니메이션 안에서 같은 순간에 바뀐다.
    private func finishLoop() async -> Bool {
        if returned {
            return await showNextHint(thenReset: resetToStart)
        }
        withAnimation(.smooth(duration: 0.4)) { resetToStart() }
        return await tutorialPause(800)
    }

    /// 마지막 장면: ‘다음’ 안내를 띄우고, 안내가 덮고 있는 동안 그림을 첫 장면으로 되돌린 뒤 걷어 낸다.
    private func showNextHint(thenReset reset: () -> Void) async -> Bool {
        withAnimation(.spring(duration: 0.45, bounce: 0.2)) { showHint = true }
        guard await tutorialPause(1300) else { return false }
        reset()
        guard await tutorialPause(1300) else { return false }
        withAnimation(.smooth(duration: 0.35)) { showHint = false }
        return await tutorialPause(450)
    }

    /// 이 앱에서 ‘단축어 앱 열기’ → 새 단축어 → 왼쪽 위로 돌아오기 (→ 다녀온 뒤에는 안내)
    private func playOpen() async {
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.3)) { activeLine = 0 }
            guard await tutorialPause(1000) else { return }
            scene.tapOpen += 1
            guard await tutorialPause(400) else { return }
            withAnimation(.spring(duration: 0.55, bounce: 0.18)) { scene.inShortcuts = true }
            guard await tutorialPause(1300) else { return }
            // 2번 설명: 새 단축어 화면에서 왼쪽 위 ◀를 누르기까지 충분히 보여 준다.
            withAnimation(.smooth(duration: 0.3)) { activeLine = 1 }
            guard await tutorialPause(1700) else { return }
            scene.tapBack += 1
            guard await tutorialPause(700) else { return }
            // ◀로 이 앱에 돌아온 화면이 곧 첫 장면이라, 돌아오는 순간 1번 아이콘도 함께 켜진다.
            guard await finishLoop() else { return }
        }
    }

    /// 동작 검색 → ‘스크린샷’ 입력 → ‘스크린샷 찍기’ 추가 (→ 다녀온 뒤에는 안내)
    private func playScreenshot() async {
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.3)) { activeLine = 0 }
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
            guard await tutorialPause(1600) else { return }
            guard await finishLoop() else { return }
        }
    }

    /// ‘QR’ 입력 → ‘이미지 속 QR 열기’ 추가(스크린샷이 이어짐)되면 끝 (→ 다녀온 뒤에는 안내)
    private func playQR() async {
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.3)) { activeLine = 0 }
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
            // ‘스크린샷에서 QR 열기’가 들어간 모습을 충분히 보여 준 뒤 다시 시작 (단축어는 자동으로 저장된다)
            guard await tutorialPause(2400) else { return }
            guard await finishLoop() else { return }
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

// MARK: - 단축어 완성: 실행 방법 고르기 (+ 시험용 QR)

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
}

// MARK: - 마지막 페이지: Safari 확장 프로그램

/// Safari에서는 단축어 없이 확장 프로그램으로 연다. 놓치지 않게 따로 한 페이지로 보여 준다.
private struct SafariPage: View {
    let still: Bool
    let compact: Bool
    /// 이 페이지를 보다가 앱 밖(설정 등)에 다녀왔는지. 그때부터 그림 끝에 ‘완료’ 안내가 나온다.
    let returned: Bool

    @State private var scene: SafariScene
    /// 그림이 지금 보여 주는 설명 줄 (nil이면 모두 보통 글씨)
    @State private var activeLine: Int?
    /// 그림 반복의 마지막 장면: ‘설정했다면 아래 완료를 눌러 주세요’
    @State private var showHint: Bool

    init(still: Bool, compact: Bool, returned: Bool) {
        self.still = still
        self.compact = compact
        self.returned = returned
        _scene = State(initialValue: still ? SafariScene.still : SafariScene())
        _activeLine = State(initialValue: still ? nil : 0)
        _showHint = State(initialValue: still && returned)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 18 : 24) {
            SafariMock(scene: scene)
                .frame(height: compact ? 236 : 290)
                .overlay {
                    if showHint {
                        NextHintCard(text: TutorialPage.safari.nextHint, still: still)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            .accessibilityHidden(!returned)
                    }
                }
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 6) {
                Text("Safari 확장 프로그램")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(TutorialPage.safari.title)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(TutorialPage.safari.lines.enumerated()), id: \.offset) { index, line in
                    TutorialStepRow(number: index + 1, text: line, style: style(for: index))
                }
            }
            Label("Safari 확장은 Safari에서만 동작해요. 다른 앱에서는 방금 만든 단축어를 쓰세요.", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 18, style: .continuous))
        }
        // 앱 밖에 다녀오면(returned) 처음부터 다시: 안내 장면부터 보여 준다.
        .task(id: returned) { await play() }
    }

    private func style(for index: Int) -> StepRowStyle {
        // ‘완료’ 안내가 나오는 동안은 어느 줄도 가리키지 않는다.
        if showHint && !still { return .dimmed }
        guard let activeLine else { return .plain }
        return index == activeLine ? .active : .dimmed
    }

    /// 첫 장면(설정 화면)으로 (누른 횟수는 그대로)
    private func resetToStart() {
        scene.reset()
        activeLine = 0
    }

    /// 한 바퀴의 끝. 앱 밖에 다녀온 뒤에는 ‘완료’ 안내를 보여 주고(덮고 있는 동안 첫 장면으로), 그 전에는 바로 첫 장면으로.
    private func finishLoop() async -> Bool {
        if returned {
            withAnimation(.spring(duration: 0.45, bounce: 0.2)) { showHint = true }
            guard await tutorialPause(1300) else { return false }
            resetToStart()
            guard await tutorialPause(1300) else { return false }
            withAnimation(.smooth(duration: 0.35)) { showHint = false }
            return await tutorialPause(450)
        }
        // 첫 장면(설정 화면)으로 돌아가는 그림과 1번 아이콘이 같은 순간에 바뀐다.
        withAnimation(.smooth(duration: 0.4)) { resetToStart() }
        return await tutorialPause(800)
    }

    /// 설정에서 켜기 → Safari 주소창 메뉴 → ‘Screen QR Scanner’ → 페이지 속 QR이 열림 (→ 다녀온 뒤에는 안내)
    private func play() async {
        if still {
            withAnimation(.smooth(duration: 0.3)) { showHint = returned }
            return
        }
        if returned {
            // 앱에 돌아오자마자 안내부터
            withAnimation(.spring(duration: 0.45, bounce: 0.2)) { showHint = true }
            guard await tutorialPause(1300) else { return }
            resetToStart()
            guard await tutorialPause(1300) else { return }
            withAnimation(.smooth(duration: 0.35)) { showHint = false }
            guard await tutorialPause(450) else { return }
        }
        while !Task.isCancelled {
            withAnimation(.smooth(duration: 0.3)) { activeLine = 0 }
            guard await tutorialPause(1100) else { return }
            withAnimation(.smooth(duration: 0.3)) { activeLine = 1 }
            guard await tutorialPause(450) else { return }
            scene.tapToggle += 1
            guard await tutorialPause(220) else { return }
            withAnimation(.spring(duration: 0.35, bounce: 0.25)) { scene.enabled = true }
            guard await tutorialPause(1100) else { return }
            withAnimation(.spring(duration: 0.55, bounce: 0.15)) {
                scene.inSafari = true
                activeLine = 2
            }
            guard await tutorialPause(1000) else { return }
            scene.tapMenu += 1
            guard await tutorialPause(300) else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) { scene.menuOpen = true }
            guard await tutorialPause(900) else { return }
            scene.tapExtension += 1
            guard await tutorialPause(320) else { return }
            withAnimation(.smooth(duration: 0.25)) { scene.menuOpen = false }
            withAnimation(.spring(duration: 0.4, bounce: 0.35).delay(0.15)) { scene.framed = true }
            guard await tutorialPause(800) else { return }
            withAnimation(.spring(duration: 0.55, bounce: 0.3)) { scene.opened = true }
            guard await tutorialPause(1600) else { return }
            guard await finishLoop() else { return }
        }
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
                    ? "단축어가 이 QR을 읽었어요. 이제 어떤 앱에서든 화면 속 QR을 바로 열 수 있어요."
                    : "이 화면에서 방금 설정한 방법(뒷면 톡톡 등)으로 단축어를 실행해 보세요. 단축어가 이 QR을 읽으면 여기가 ‘잘 동작해요!’로 바뀌어요. 처음 한 번은 ‘항상 허용’을 눌러 주세요.")
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
