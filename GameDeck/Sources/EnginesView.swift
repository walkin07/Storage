import SwiftUI

/// 엔진 앱이 설치됐는지, 무엇이 필요한지, 어디서 받는지
struct EnginesView: View {
    @EnvironmentObject private var engines: EngineMonitor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    setupGuide
                } header: {
                    Text("처음 설정 순서")
                }
                ForEach(EngineGroup.allCases) { group in
                    Section(group.title) {
                        ForEach(EngineID.allCases.filter { $0.info.group == group }) { engine in
                            EngineRow(engine: engine, status: engines.status(of: engine)) { url in
                                openURL(url)
                            }
                        }
                    }
                }
                Section {
                    Text("게임덱은 게임 파일이나 키를 다루지 않아요. 게임 · 키 · 펌웨어는 본인이 가진 기기와 게임에서만, 각 엔진의 안내에 따라 준비하세요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("엔진 준비 상태")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        engines.refresh()
                    } label: {
                        Label("다시 확인", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear { engines.refresh() }
        }
    }

    private var setupGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            GuideStep(number: 1, title: "설치 도구", text: "Windows PC라면 Sideloadly로 IPA를 설치해요. 무료 Apple ID는 앱 3개까지라, 여러 개를 쓰려면 LiveContainer 하나에 넣는 게 좋아요.")
            GuideStep(number: 2, title: "JIT 준비 (에뮬레이터 · PC 게임)", text: "App Store에서 LocalDevVPN을 받고 StikDebug를 설치한 뒤, PC에서 페어링 파일을 한 번 만들어 StikDebug에 넣어요.")
            GuideStep(number: 3, title: "스위치", text: "Mac이 없으면 MeloNX(에뮬레이터), Mac이 있으면 nxnative(게임마다 변환, JIT 불필요)를 써요.")
            GuideStep(number: 4, title: "스팀", text: "게임용 PC가 있으면 Steam Link 스트리밍이 가장 안정적이에요. 아이폰에서 직접 돌리려면 iDeck · Madeira · Playport (실험 단계).")
            GuideStep(number: 5, title: "게임덱에 추가", text: "+ 버튼에서 MeloNX 가져오기, 스팀 검색 · 라이브러리, nxnative · Madeira 게임을 넣고 플레이!")
        }
        .padding(.vertical, 6)
    }
}

private struct GuideStep: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.weight(.bold))
                .frame(width: 24, height: 24)
                .background(.tint, in: .circle)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct EngineRow: View {
    let engine: EngineID
    let status: EngineMonitor.Status
    let open: (URL) -> Void

    var body: some View {
        let info = engine.info
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: info.symbol)
                    .font(.title3.weight(.semibold))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.name)
                        .font(.headline)
                    Text(info.role)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                StatusPill(status: status)
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(info.notes, id: \.self) { note in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                        Text(note)
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                if status == .installed, let url = info.openURL {
                    Button("열기") { open(url) }
                        .buttonStyle(.glassProminent)
                }
                Button(status == .installed ? "안내 페이지" : "받는 곳") { open(info.homepage) }
                    .buttonStyle(.glass)
            }
            .controlSize(.small)
        }
        .padding(.vertical, 6)
    }
}
