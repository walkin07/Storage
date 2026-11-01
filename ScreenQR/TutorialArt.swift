import SwiftUI
import UIKit

// 튜토리얼에 들어가는 그림들. 실제 앱 화면을 그대로 옮긴 것이 아니라, 무엇을 누르면 되는지 보여 주는 설명용 그림이다.

/// 페이지를 넘기면(작업이 취소되면) false를 돌려준다. 그림 애니메이션 반복을 멈추는 데 쓴다.
func tutorialPause(_ milliseconds: Int) async -> Bool {
    do {
        try await Task.sleep(for: .milliseconds(milliseconds))
        return true
    } catch {
        return false
    }
}

// MARK: - 단축어 편집 화면 그림

/// 그림 속 단축어 동작
enum MockAction: Equatable {
    case screenshot, qr

    var symbol: String {
        switch self {
        case .screenshot: "camera.viewfinder"
        case .qr: "qrcode.viewfinder"
        }
    }

    var color: Color {
        switch self {
        case .screenshot: Color(red: 0.24, green: 0.5, blue: 0.98)
        case .qr: .black
        }
    }
}

/// 그림 속 단축어 편집 화면의 한 장면
struct MockScene: Equatable {
    /// false면 단축어 앱으로 가기 전, 이 앱 화면
    var inShortcuts = true
    /// 단축어에 들어간 동작 수 (0~2)
    var blocks = 0
    /// 검색창에 입력한 글자
    var query = ""
    /// 검색창을 누른 상태 (커서가 깜박인다)
    var searching = false
    /// 검색 결과로 보이는 동작
    var result: MockAction?
    /// 오른쪽 위 완료(✓)를 누른 상태
    var doneLit = false
    // 손가락 표시: 값이 바뀔 때마다 그 자리를 한 번 누른다.
    var tapOpen = 0
    var tapBack = 0
    var tapSearch = 0
    var tapResult = 0
    var tapDone = 0

    /// 누른 횟수는 그대로 두고 화면만 처음으로 되돌린다 (횟수가 바뀌면 손가락이 한 번 더 나오기 때문).
    mutating func reset(blocks: Int) {
        inShortcuts = true
        self.blocks = blocks
        query = ""
        searching = false
        result = nil
        doneLit = false
    }

    /// 반복 애니메이션의 첫 장면
    static func start(for page: TutorialPage) -> MockScene {
        switch page {
        case .open: MockScene(inShortcuts: false)
        case .qr: MockScene(blocks: 1)
        default: MockScene()
        }
    }

    /// 움직임 줄이기를 켰을 때(또는 UI 테스트) 보여 줄 한 장면
    static func still(for page: TutorialPage) -> MockScene {
        switch page {
        case .screenshot: MockScene(query: "스크린샷", searching: true, result: .screenshot)
        case .qr: MockScene(blocks: 2, doneLit: true)
        default: MockScene()
        }
    }
}

/// 아이폰 화면 모양 안에 단축어 편집 화면을 단순하게 그린다.
struct ShortcutMock: View {
    let scene: MockScene
    var showsBackLink = false
    var still = false

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            ZStack {
                if scene.inShortcuts {
                    editor
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                } else {
                    launcher
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .frame(maxWidth: 300)
        .background(Color(white: 0.965))
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
        .environment(\.dynamicTypeSize, .large)
        .accessibilityHidden(true)
    }

    /// 다이내믹 아일랜드와, 다른 앱에서 돌아오는 ‘◀ Screen QR Scanner’
    private var statusBar: some View {
        ZStack {
            Capsule()
                .fill(.black)
                .frame(width: 50, height: 17)
            HStack {
                if scene.inShortcuts && showsBackLink {
                    HStack(spacing: 2) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: 7))
                        Text("Screen QR Scanner")
                            .font(.system(size: 9.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.blue)
                    .overlay { TapIndicator(tick: scene.tapBack) }
                    .transition(.opacity)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 20)
        .padding(.bottom, 12)
    }

    /// 단축어 앱으로 가기 전: 이 앱의 ‘단축어 앱 열기’ 버튼
    private var launcher: some View {
        VStack(spacing: 12) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 26, weight: .medium))
                .frame(width: 58, height: 58)
                .background(.white, in: .rect(cornerRadius: 15, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            Text("Screen QR Scanner")
                .font(.system(size: 13, weight: .semibold))
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.forward.app")
                Text("단축어 앱 열기")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.black, in: .capsule)
            .overlay { TapIndicator(tick: scene.tapOpen) }
            .padding(.top, 4)
        }
    }

    private var editor: some View {
        VStack(spacing: 10) {
            HStack {
                Text("새 단축어")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(scene.doneLit ? Color.white : Color.blue)
                    .frame(width: 30, height: 30)
                    .background(scene.doneLit ? Color.blue : Color.white, in: .circle)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                    .overlay { TapIndicator(tick: scene.tapDone) }
            }
            VStack(spacing: 8) {
                if scene.blocks >= 1 {
                    MockActionBlock(action: .screenshot)
                        .transition(Self.blockTransition)
                }
                if scene.blocks >= 2 {
                    MockActionBlock(action: .qr)
                        .transition(Self.blockTransition)
                }
                if scene.blocks == 0 {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(height: 44)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.25))
                        }
                        .transition(.opacity)
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                if let result = scene.result {
                    MockResultRow(action: result, tap: scene.tapResult)
                        .transition(.offset(y: 16).combined(with: .opacity))
                }
                MockSearchField(query: scene.query, searching: scene.searching, tap: scene.tapSearch, still: still)
            }
        }
    }

    private static let blockTransition: AnyTransition = .offset(y: 24)
        .combined(with: .opacity)
        .combined(with: .scale(scale: 0.94))
}

struct MockActionIcon: View {
    let action: MockAction

    var body: some View {
        Image(systemName: action.symbol)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(action.color, in: .rect(cornerRadius: 6, style: .continuous))
    }
}

/// 단축어에 들어간 동작 한 줄
struct MockActionBlock: View {
    let action: MockAction

    var body: some View {
        HStack(spacing: 8) {
            MockActionIcon(action: action)
            switch action {
            case .screenshot:
                Text("스크린샷 찍기")
                    .font(.system(size: 13, weight: .semibold))
            case .qr:
                // 앞 동작의 결과(스크린샷)가 자동으로 이어진 모습
                HStack(spacing: 3) {
                    Text("스크린샷")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12), in: .rect(cornerRadius: 6, style: .continuous))
                    Text("에서 QR 열기")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.white, in: .rect(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

/// 동작 검색 결과 한 줄
struct MockResultRow: View {
    let action: MockAction
    let tap: Int

    var body: some View {
        HStack(spacing: 10) {
            MockActionIcon(action: action)
            VStack(alignment: .leading, spacing: 1) {
                Text(action == .screenshot ? "스크린샷 찍기" : "이미지 속 QR 열기")
                    .font(.system(size: 13, weight: .semibold))
                if action == .qr {
                    Text("Screen QR Scanner")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white, in: .rect(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        .overlay { TapIndicator(tick: tap) }
    }
}

/// 아래쪽 ‘동작 검색’ 창
struct MockSearchField: View {
    let query: String
    let searching: Bool
    let tap: Int
    let still: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            ZStack(alignment: .leading) {
                if query.isEmpty {
                    Text("동작 검색")
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 1) {
                    Text(query)
                    if searching {
                        MockCaret(still: still)
                    }
                }
            }
            .font(.system(size: 13))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(.white, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(searching ? Color.blue.opacity(0.45) : Color.black.opacity(0.06), lineWidth: 1)
        }
        .overlay { TapIndicator(tick: tap) }
    }
}

/// 깜박이는 입력 커서
struct MockCaret: View {
    let still: Bool

    var body: some View {
        if still {
            bar
        } else {
            PhaseAnimator([true, false]) { visible in
                bar.opacity(visible ? 1 : 0)
            } animation: { _ in
                .easeInOut(duration: 0.45)
            }
        }
    }

    private var bar: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.blue)
            .frame(width: 2, height: 15)
    }
}

/// 손가락으로 한 번 누르는 모습. tick이 바뀔 때마다 나타나 눌렀다가 사라진다.
struct TapIndicator: View {
    let tick: Int

    var body: some View {
        Circle()
            .fill(Color.black.opacity(0.22))
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
            }
            .frame(width: 30, height: 30)
            .keyframeAnimator(initialValue: TapPose(), trigger: tick) { content, pose in
                content
                    .scaleEffect(pose.scale)
                    .opacity(pose.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.12)
                    LinearKeyframe(1, duration: 0.3)
                    LinearKeyframe(0, duration: 0.22)
                }
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.0, duration: 0.12)
                    CubicKeyframe(0.75, duration: 0.14)
                    SpringKeyframe(1.0, duration: 0.16)
                    CubicKeyframe(1.3, duration: 0.22)
                }
            }
            .allowsHitTesting(false)
    }
}

struct TapPose {
    var scale: CGFloat = 1.3
    var opacity: Double = 0
}

// MARK: - 첫 페이지 그림: 뒷면 톡톡 → QR 인식 → 링크 열림

struct WelcomeHero: View {
    let still: Bool

    @State private var tapA = 0
    @State private var tapB = 0
    @State private var framed: Bool
    @State private var scanning = false
    @State private var scan: CGFloat = 0
    @State private var opened: Bool

    init(still: Bool) {
        self.still = still
        _framed = State(initialValue: still)
        _opened = State(initialValue: still)
    }

    var body: some View {
        ZStack {
            PhoneRipple(tick: tapA)
            PhoneRipple(tick: tapB)
            phone
        }
        .frame(width: 220, height: 320)
        .accessibilityHidden(true)
        .task { await play() }
    }

    private var phone: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.white)
            VStack(spacing: 10) {
                Capsule().fill(Color.black.opacity(0.08)).frame(width: 90, height: 8)
                Capsule().fill(Color.black.opacity(0.05)).frame(width: 62, height: 8)
                qr.padding(.vertical, 14)
                Capsule().fill(Color.black.opacity(0.05)).frame(width: 96, height: 8)
                Capsule().fill(Color.black.opacity(0.05)).frame(width: 70, height: 8)
            }
            .frame(maxHeight: .infinity)
            Capsule()
                .fill(.black)
                .frame(width: 46, height: 14)
                .padding(.top, 12)
            if opened {
                banner
                    .padding(.top, 34)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 150, height: 300)
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(.black, lineWidth: 6)
        }
        .shadow(color: .black.opacity(0.14), radius: 28, y: 16)
    }

    private var qr: some View {
        ZStack {
            if let image = TutorialView.testQR {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
            ViewfinderCorners()
                .stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .padding(-8)
                .scaleEffect(framed ? 1 : 1.25)
                .opacity(framed ? 1 : 0)
            if scanning {
                LinearGradient(
                    colors: [Color.blue.opacity(0), Color.blue.opacity(0.6), Color.blue.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                .offset(y: (scan - 0.5) * 80)
                .transition(.opacity)
            }
        }
        .frame(width: 84, height: 84)
    }

    private var banner: some View {
        HStack(spacing: 5) {
            Image(systemName: "safari.fill")
                .foregroundStyle(.blue)
            Text("링크를 열었어요")
                .foregroundStyle(.primary)
        }
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white, in: .capsule)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private func play() async {
        guard !still else { return }
        while !Task.isCancelled {
            guard await tutorialPause(800) else { return }
            tapA += 1
            guard await tutorialPause(220) else { return }
            tapB += 1
            guard await tutorialPause(420) else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.35)) { framed = true }
            guard await tutorialPause(250) else { return }
            scanning = true
            withAnimation(.easeInOut(duration: 0.9)) { scan = 1 }
            guard await tutorialPause(950) else { return }
            withAnimation(.easeOut(duration: 0.2)) { scanning = false }
            withAnimation(.spring(duration: 0.55, bounce: 0.3)) { opened = true }
            guard await tutorialPause(1900) else { return }
            withAnimation(.smooth(duration: 0.45)) {
                opened = false
                framed = false
            }
            scan = 0
            guard await tutorialPause(400) else { return }
        }
    }
}

/// 휴대폰 둘레로 퍼지는 물결 (뒷면을 톡 친 느낌)
struct PhoneRipple: View {
    let tick: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 38, style: .continuous)
            .stroke(Color.black.opacity(0.2), lineWidth: 2)
            .frame(width: 150, height: 300)
            .keyframeAnimator(initialValue: RipplePose(), trigger: tick) { content, pose in
                content
                    .scaleEffect(pose.scale)
                    .opacity(pose.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    MoveKeyframe(1.0)
                    CubicKeyframe(1.2, duration: 0.7)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(1.0)
                    CubicKeyframe(0, duration: 0.7)
                }
            }
            .allowsHitTesting(false)
    }
}

struct RipplePose {
    var scale: CGFloat = 1
    var opacity: Double = 0
}

/// 앱 아이콘처럼 네 귀퉁이만 있는 뷰파인더
struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = min(rect.width, rect.height) * 0.22
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        return path
    }
}

// MARK: - 마지막 페이지의 체크 표시

/// 검은 원이 튀어나오고 체크가 그려진다.
struct DrawnCheck: View {
    let still: Bool

    @State private var shown: Bool
    @State private var drawn: CGFloat

    init(still: Bool) {
        self.still = still
        _shown = State(initialValue: still)
        _drawn = State(initialValue: still ? 1 : 0)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .scaleEffect(shown ? 1 : 0.5)
                .opacity(shown ? 1 : 0)
            CheckShape()
                .trim(from: 0, to: drawn)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .frame(width: 30, height: 24)
        }
        .frame(width: 76, height: 76)
        .accessibilityHidden(true)
        .onAppear {
            guard !still else { return }
            withAnimation(.spring(duration: 0.5, bounce: 0.45)) { shown = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) { drawn = 1 }
        }
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: - 공용 조각

/// 단축어 앱을 떠올리게 하는 아이콘
struct ShortcutsGlyph: View {
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: "square.stack.3d.up.fill")
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.36, blue: 0.5), Color(red: 0.36, green: 0.42, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: .rect(cornerRadius: size * 0.27, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

enum StepRowStyle: Equatable {
    /// 보통
    case plain
    /// 지금 그림이 보여 주는 줄
    case active
    /// 그림이 다른 줄을 보여 주는 동안
    case dimmed
}

/// 번호가 붙은 설명 한 줄
struct TutorialStepRow: View {
    let number: Int
    let text: Text
    var style: StepRowStyle = .plain

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.footnote.weight(.bold).monospacedDigit())
                .foregroundStyle(numberColor)
                .frame(width: 24, height: 24)
                .background(style == .active ? Color.black : Color.black.opacity(0.07), in: .circle)
            text
                .font(.callout)
                .foregroundStyle(style == .dimmed ? Color.secondary : Color.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.smooth(duration: 0.3), value: style)
    }

    private var numberColor: Color {
        switch style {
        case .active: .white
        case .plain: .primary
        case .dimmed: .secondary
        }
    }
}

/// 실행 방법 하나 (뒷면 탭 · 동작 버튼 · 제어 센터)
struct TriggerChip: View {
    let trigger: Trigger
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: trigger.symbol)
                    .font(.system(size: 18, weight: .medium))
                    .symbolEffect(.bounce, value: isSelected)
                Text(trigger.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 62)
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.black).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 18)
        )
        .accessibilityLabel(trigger.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("trigger.\(trigger.rawValue)")
    }
}
