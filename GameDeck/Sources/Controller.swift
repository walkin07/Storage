import Combine
import GameController

enum PadInput {
    case up, down, left, right
    case a, b, x, y
    case l, r
    case menu, options
}

/// 게임패드 입력을 화면 조작으로 바꾼다. 방향은 누르고 있으면 반복된다.
/// GameController는 핸들러를 메인 큐에서 부른다.
final class ControllerHub: ObservableObject {
    @Published private(set) var controllerName: String?
    let inputs = PassthroughSubject<PadInput, Never>()

    private var observers: [NSObjectProtocol] = []
    private var held: [String: PadInput] = [:]
    private var repeats: [String: DispatchWorkItem] = [:]

    init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.attach(controller)
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            self?.releaseDirections()
            self?.updateName()
        })
        // 게임을 켜러 다른 앱으로 넘어가면 방향 입력이 끊긴다. 돌아왔을 때 선택이 저절로 움직이지 않게 지운다.
        observers.append(center.addObserver(forName: Notification.Name("UIApplicationWillResignActiveNotification"), object: nil, queue: .main) { [weak self] _ in
            self?.releaseDirections()
        })
        GCController.controllers().forEach { attach($0) }
        updateName()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func attach(_ controller: GCController) {
        controller.handlerQueue = .main
        guard let pad = controller.extendedGamepad else {
            updateName()
            return
        }
        let tag = String(UInt(bitPattern: ObjectIdentifier(controller).hashValue))
        pad.dpad.valueChangedHandler = { [weak self] _, x, y in
            self?.direction(x: x, y: y, source: "dpad-\(tag)", threshold: 0.5)
        }
        pad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.direction(x: x, y: y, source: "stick-\(tag)", threshold: 0.6)
        }
        bind(pad.buttonA, to: .a)
        bind(pad.buttonB, to: .b)
        bind(pad.buttonX, to: .x)
        bind(pad.buttonY, to: .y)
        bind(pad.leftShoulder, to: .l)
        bind(pad.rightShoulder, to: .r)
        bind(pad.buttonMenu, to: .menu)
        if let options = pad.buttonOptions { bind(options, to: .options) }
        updateName()
    }

    private func bind(_ button: GCControllerButtonInput, to input: PadInput) {
        button.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.inputs.send(input) }
        }
    }

    private func updateName() {
        let pads = GCController.controllers().filter { $0.extendedGamepad != nil }
        controllerName = pads.first.map { $0.vendorName ?? "게임패드" }
    }

    private func releaseDirections() {
        repeats.values.forEach { $0.cancel() }
        repeats.removeAll()
        held.removeAll()
    }

    private func direction(x: Float, y: Float, source: String, threshold: Float) {
        var next: PadInput?
        if abs(x) >= abs(y) {
            if x > threshold { next = .right } else if x < -threshold { next = .left }
        } else {
            if y > threshold { next = .up } else if y < -threshold { next = .down }
        }
        guard held[source] != next else { return }
        held[source] = next
        repeats[source]?.cancel()
        repeats[source] = nil
        guard let next else { return }
        inputs.send(next)
        scheduleRepeat(next, source: source, after: 0.4, remaining: 80)
    }

    /// 누르고 있는 동안 반복한다. 손을 뗐다는 신호를 놓쳐도 끝없이 움직이지 않게 횟수에 상한을 둔다.
    private func scheduleRepeat(_ input: PadInput, source: String, after delay: TimeInterval, remaining: Int) {
        guard remaining > 0 else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.held[source] == input else { return }
            self.inputs.send(input)
            self.scheduleRepeat(input, source: source, after: 0.11, remaining: remaining - 1)
        }
        repeats[source] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
