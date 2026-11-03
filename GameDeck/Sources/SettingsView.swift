import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var toasts: ToastCenter
    @Environment(\.dismiss) private var dismiss

    @AppStorage("cardSize") private var cardSize: CardSize = .medium
    @AppStorage("sortOrder") private var sortOrder: SortOrder = .recent
    @AppStorage("haptics") private var haptics = true
    @AppStorage("steamDefaultLaunch") private var steamDefault: SteamLaunchDefault = .steamLink
    @AppStorage("steamLinkShortcut") private var steamLinkShortcut = "Steam Link"

    @State private var hasAPIKey = Keychain.get(Keychain.steamAPIKey) != nil
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("화면") {
                    Picker("카드 크기", selection: $cardSize) {
                        ForEach(CardSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    Picker("정렬", selection: $sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    Toggle("진동", isOn: $haptics)
                }

                Section {
                    Picker("새 스팀 게임 실행 방법", selection: $steamDefault) {
                        ForEach(SteamLaunchDefault.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    TextField("Steam Link 단축어 이름", text: $steamLinkShortcut)
                    if hasAPIKey {
                        Button("저장된 Steam API 키 지우기", role: .destructive) {
                            Keychain.set(nil, for: Keychain.steamAPIKey)
                            hasAPIKey = false
                        }
                    }
                } header: {
                    Text("스팀")
                } footer: {
                    Text(steamDefault.help)
                }

                Section {
                    LabeledContent("게임 수", value: "\(library.games.count)")
                    Button("이어하기 링크 복사 (gamedeck://resume)") {
                        UIPasteboard.general.string = "\(DeckLink.scheme)://resume"
                        toasts.show("링크를 복사했어요")
                    }
                    Button("모든 게임 지우기", role: .destructive) {
                        confirmClear = true
                    }
                } header: {
                    Text("라이브러리")
                } footer: {
                    Text("이어하기 링크를 단축어의 ‘URL 열기’에 넣고 뒷면 탭에 연결하면, 뒷면을 두 번 두드려 마지막 게임을 바로 켤 수 있어요.")
                }

                Section("게임덱") {
                    Text("게임덱은 게임을 직접 돌리지 않아요. 설치된 엔진 앱(MeloNX, nxnative 게임, Madeira, iDeck, Playport, Steam Link)을 열어 주는 런처예요.")
                    Text("게임 파일 · 키 · 펌웨어는 들어 있지 않아요. 본인이 가진 게임만 쓰세요.")
                    LabeledContent("버전", value: appVersion)
                }
                .font(.footnote)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
            .confirmationDialog("모든 게임을 목록에서 지울까요?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("모두 지우기", role: .destructive) { library.removeAll() }
            } message: {
                Text("게임 앱과 파일은 그대로예요. 게임덱 목록만 비워져요.")
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
