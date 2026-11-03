import SwiftUI
import UIKit

extension Platform {
    var tint: Color {
        switch self {
        case .nintendoSwitch: Color(red: 0.94, green: 0.20, blue: 0.22)
        case .steam: Color(red: 0.16, green: 0.60, blue: 1.0)
        case .other: Color(red: 0.62, green: 0.44, blue: 1.0)
        }
    }
}

enum DeckStyle {
    static let background = LinearGradient(
        colors: [Color(red: 0.05, green: 0.06, blue: 0.11), Color(red: 0.08, green: 0.09, blue: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct PlatformBadge: View {
    let platform: Platform
    var compact = false

    var body: some View {
        Label(platform.title, systemImage: platform.symbol)
            .labelStyle(.titleAndIcon)
            .font(compact ? .caption2.weight(.bold) : .caption.weight(.bold))
            .padding(.horizontal, compact ? 6 : 9)
            .padding(.vertical, compact ? 3 : 5)
            .background(platform.tint.gradient, in: .capsule)
            .foregroundStyle(.white)
    }
}

/// 위쪽 오른편의 둥근 아이콘 버튼
struct RoundIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}

/// 연결된 게임패드, 시계, 배터리
struct StatusCluster: View {
    let controllerName: String?

    var body: some View {
        HStack(spacing: 12) {
            if let controllerName {
                Image(systemName: "gamecontroller.fill")
                    .accessibilityLabel("\(controllerName) 연결됨")
            }
            TimelineView(.periodic(from: .now, by: 20)) { context in
                HStack(spacing: 10) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .monospacedDigit()
                    BatteryIcon()
                }
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white.opacity(0.85))
    }
}

private struct BatteryIcon: View {
    var body: some View {
        let device = UIDevice.current
        let level = device.batteryLevel
        let charging = device.batteryState == .charging || device.batteryState == .full
        Image(systemName: Self.symbol(level: level, charging: charging))
            .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true }
    }

    private static func symbol(level: Float, charging: Bool) -> String {
        if charging { return "battery.100percent.bolt" }
        guard level >= 0 else { return "battery.100percent" }
        switch level {
        case ..<0.13: return "battery.0percent"
        case ..<0.38: return "battery.25percent"
        case ..<0.63: return "battery.50percent"
        case ..<0.88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

/// 게임패드가 연결됐을 때 아래에 보이는 버튼 안내
struct ButtonHintBar: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            hints(full: true)
            hints(full: false)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.8))
    }

    private func hints(full: Bool) -> some View {
        HStack(spacing: full ? 18 : 12) {
            Hint(key: "A", text: "플레이")
            Hint(key: "X", text: "옵션")
            Hint(key: "Y", text: full ? "게임 추가" : "추가")
            Hint(key: "L R", text: full ? "목록 바꾸기" : "목록")
            Hint(key: "≡", text: "설정")
            Spacer(minLength: 0)
        }
    }

    private struct Hint: View {
        let key: String
        let text: String

        var body: some View {
            HStack(spacing: 6) {
                Text(key)
                    .font(.caption2.weight(.heavy))
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(.white.opacity(0.18), in: .capsule)
                Text(text)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}

/// 잠깐 떴다 사라지는 알림
@MainActor
final class ToastCenter: ObservableObject {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let symbol: String
    }

    @Published private(set) var current: Toast?

    func show(_ text: String, symbol: String = "checkmark.circle.fill") {
        let toast = Toast(text: text, symbol: symbol)
        withAnimation(.snappy) { current = toast }
        Task {
            try? await Task.sleep(for: .seconds(3.2))
            if current?.id == toast.id {
                withAnimation(.easeOut) { current = nil }
            }
        }
    }
}

struct ToastView: View {
    let toast: ToastCenter.Toast

    var body: some View {
        Label(toast.text, systemImage: toast.symbol)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .capsule)
            .padding(.horizontal, 20)
    }
}
