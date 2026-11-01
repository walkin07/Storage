# 게임덱 (GameDeck)

디로이드덱(DroidDeck)처럼, 아이폰에서 **닌텐도 스위치와 스팀 게임을 한 화면에 모아 두고 컨트롤러로 바로 실행**하는 런처입니다.

- 가로로 들면 스위치·스팀덱 같은 홈 화면(큰 정보 + 게임 선반), 세로로 들면 표지 격자
- 게임패드(D패드·스틱·A/B/X/Y·L/R)로 전부 조작, 터치도 됨
- MeloNX의 스위치 게임 목록을 아이콘째 한 번에 가져오기
- 스팀 게임 검색, 내 스팀 라이브러리 통째로 가져오기 (표지·배경 이미지 포함)
- 즐겨찾기, 최근 플레이순 정렬, 뒷면 탭으로 마지막 게임 이어하기

> **게임덱은 게임을 직접 돌리지 않습니다.** 디로이드덱도 사실 Valve의 스팀 클라이언트·Proton·FEX를 한 앱에 묶은 것인데, 아이폰에서는 애플이 JIT와 다른 프로그램 실행을 막아서 같은 역할의 엔진들이 **각각 따로 된 앱**으로 나와 있습니다. 게임덱은 그 엔진 앱들을 하나의 라이브러리로 묶고, 게임을 누르면 해당 엔진에서 그 게임이 바로 켜지게 이어 줍니다.

## 엔진

| 게임 | 엔진 | 방식 | JIT | 게임덱에서 |
|---|---|---|---|---|
| 스위치 | [MeloNX](https://melonx.org) | 에뮬레이터 | 필요 | 목록·아이콘 가져오기, 게임 바로 실행 |
| 스위치 | [nxnative](https://github.com/seedds/nxnative) | 게임을 아이폰 앱으로 변환해 칩에서 직접 실행 (**Mac 필요**) | 불필요 | 단축어 · StikDebug · LiveContainer로 실행 |
| 스팀 | [Steam Link](https://apps.apple.com/app/id1246969117) | PC에서 스트리밍 | 불필요 | 단축어로 열기 |
| 스팀 | [Madeira](https://github.com/willfaust/madeira) | 윈도우 게임을 아이폰에서 직접 (FEX + Wine + DXMT) | 필요 | 게임 바로 실행 |
| 스팀 | [iDeck](https://github.com/kuscholar/iDeck) | 스팀 빅 픽처 화면 그대로 (Madeira 기반) | 필요 | 앱 열기 |
| 스팀 | [Playport](https://github.com/playportdev/playport) | 스팀 · GOG · 에픽 게임 직접 실행 | 필요 | 앱 열기 |

도구: [StikDebug](https://github.com/StikDebug/StikDebug)(JIT 켜기, 앱 실행), [LocalDevVPN](https://apps.apple.com/app/id6755608044)(JIT용 VPN), [LiveContainer](https://github.com/LiveContainer/LiveContainer)(여러 앱을 한 앱 안에 설치), 단축어.

앱의 **엔진 준비 상태**(번개 버튼) 화면에서 무엇이 설치됐는지 바로 확인할 수 있습니다.

### 어떤 조합이 좋을까

| 상황 | 스위치 | 스팀 |
|---|---|---|
| Windows PC만 있음 (Mac 없음) | MeloNX | 게임용 PC가 있으면 Steam Link, 아이폰에서 직접 돌리려면 iDeck · Madeira · Playport |
| Mac이 있음 | nxnative (지원 게임은 JIT 없이 가장 빠름) + 나머지는 MeloNX | 위와 같음 |

- 기기는 **iPhone 15 Pro 이상 · iOS 26 이상**을 권장합니다 (nxnative, Madeira, Playport가 iOS 26 이상이고, 스위치 게임은 메모리를 많이 씁니다).
- 아이폰에서 직접 돌리는 스팀 엔진(Madeira · iDeck · Playport)은 아직 실험 단계라 되는 게임이 제한적입니다. 가장 안정적인 건 Steam Link 스트리밍입니다.

## 다운로드

GitHub의 **Releases → gamedeck-latest**에 항상 최신 빌드가 올라갑니다 (`GameDeck/`가 바뀐 push마다 자동 빌드).

- `GameDeck-unsigned.ipa`: 아이폰·아이패드 앱 (iOS 26 이상)

## 설치 순서

1. **게임덱 설치**: 화면 QR과 같은 방법으로 Sideloadly에 `GameDeck-unsigned.ipa`를 넣어 설치합니다 ([저장소 README의 ‘아이폰에 설치’](../README.md#아이폰에-설치-mac-없이)).
   - 무료 Apple ID는 사이드로드 앱이 3개까지입니다. 엔진이 여러 개면 **LiveContainer 하나에 엔진들을 넣는** 방법을 권장합니다. 게임덱 자체는 LiveContainer 밖에 설치하세요 (그래야 링크와 설치 확인이 정확합니다).
2. **JIT 준비** (MeloNX · Madeira · iDeck · Playport를 쓸 때): App Store에서 LocalDevVPN을 받고, StikDebug를 설치한 뒤 PC에서 [페어링 파일](https://github.com/StikDebug/StikDebug-Guide/blob/main/pairing_file.md)을 한 번 만들어 넣습니다.
3. **엔진 설치**: 위 표의 각 공식 페이지 안내를 따릅니다. MeloNX는 메모리 한도 늘리기(Increased Memory Limit)를 켜고 설치하세요.
4. **게임덱에 게임 추가** (아래) → 플레이.

## 게임 추가 (+ 버튼)

### 스위치: MeloNX

**MeloNX에서 가져오기**를 누르면 MeloNX가 잠깐 열렸다가 게임 목록(이름, 타이틀 ID, 아이콘)을 게임덱으로 돌려줍니다. 이후 게임을 누르면 `melonx://game?id=<타이틀 ID>`로 MeloNX에서 그 게임이 바로 시작되고, JIT가 꺼져 있으면 MeloNX가 StikDebug로 JIT를 켠 뒤 이어서 시작합니다.

- 목록이 비어 오면 MeloNX를 한 번 열어 게임 목록이 뜬 걸 확인한 뒤 다시 시도하세요.
- 게임을 MeloNX에 새로 넣었다면 다시 가져오기만 하면 됩니다 (이미 있는 게임은 건너뜁니다).

### 스위치: nxnative

nxnative는 게임마다 **Mac에서** IPA로 변환합니다 ([nxnative 안내](https://github.com/seedds/nxnative#how-to-play)). 만든 게임 앱에는 URL 스킴이 없어서, 게임덱은 아래 셋 중 하나로 실행합니다.

| 실행 방법 | 준비 | 게임덱에 넣을 값 |
|---|---|---|
| **단축어** (가장 쉬움) | 단축어 앱 → + → ‘앱 열기’ 동작 → 게임 앱 고르기 → 저장 | 단축어 이름 |
| **StikDebug** | StikDebug와 LocalDevVPN 켜기 | 번들 ID (기본 `org.nxnative.<타이틀 ID 소문자>`, AltStore·SideStore로 설치했다면 뒤에 팀 ID가 붙음) |
| **LiveContainer** | IPA를 LiveContainer 안에 설치 | 앱 폴더 이름 (보통 `org.nxnative.<타이틀 ID 소문자>.app`) |

타이틀 ID(게임 파일 이름의 `[0100…]`)를 넣으면 번들 ID와 폴더 이름을 자동으로 채워 줍니다. 표지는 사진에서 고를 수 있습니다.

### 스팀

- **스팀에서 게임 찾기**: 이름으로 검색해 표지와 함께 추가합니다 (키 필요 없음).
- **내 스팀 라이브러리 가져오기**: [Steam Web API 키](https://steamcommunity.com/dev/apikey)(도메인 칸은 아무거나, 예: `localhost`)와 스팀 ID 또는 프로필 주소를 넣으면 가진 게임을 전부 가져옵니다. 프로필의 ‘게임 세부 정보’가 공개여야 합니다. 키는 아이폰 키체인에만 저장됩니다.
- 실행 방법은 게임마다 고를 수 있고, 새로 넣는 게임의 기본값은 설정에서 바꿉니다.
  - **Steam Link**: 단축어 앱에서 ‘앱 열기 → Steam Link’ 단축어를 `Steam Link`라는 이름으로 만들어 두세요. 같은 Wi-Fi의 PC에서 Steam이 켜져 있어야 합니다.
  - **Madeira**: Madeira의 게임 상세 화면에서 바로가기 링크(`madeira://play?exe=…`)를 복사해 게임 편집 화면에 붙여넣으면 그 게임이 바로 시작됩니다. 비워 두면 Madeira만 열립니다.
  - **iDeck · Playport**: 앱이 열리고, 게임은 그 안에서 고릅니다 (게임별 링크를 지원하지 않음).

### 기타

**직접 추가**에 다른 에뮬레이터나 앱이 지원하는 URL 스킴 링크를 넣으면 무엇이든 목록에 넣을 수 있습니다.

## 조작

| 게임패드 | 동작 |
|---|---|
| D패드 · 왼쪽 스틱 | 게임 고르기 (누르고 있으면 계속 이동) |
| A | 플레이 |
| B | 창 닫기 |
| X | 게임 정보 · 편집 |
| Y | 게임 추가 |
| L · R | 목록 바꾸기 (전체 · 스위치 · 스팀 · 기타 · 즐겨찾기) |
| ≡ (메뉴) | 설정 |
| ⧉ (옵션) | 엔진 준비 상태 |

터치: 카드를 한 번 누르면 선택, 선택된 카드를 다시 누르면 플레이, 길게 누르면 메뉴(플레이 · 정보 · 즐겨찾기 · 삭제).

## 뒷면 탭으로 이어하기

설정 → **이어하기 링크 복사**(`gamedeck://resume`) → 단축어 앱에서 ‘URL 열기’ 동작에 붙여넣어 저장 → 설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 이중 탭에 그 단축어를 연결하면, 뒷면을 두 번 두드려 마지막 게임을 바로 켤 수 있습니다. 게임 정보 화면의 **바로가기 링크**(`gamedeck://play?id=…`)로 특정 게임 아이콘을 홈 화면에 만들 수도 있습니다.

## 링크 규격 (참고)

| 대상 | 링크 |
|---|---|
| MeloNX 게임 실행 | `melonx://game?id=<타이틀 ID 또는 게임 이름>` |
| MeloNX 게임 목록 요청 | `melonx://gameInfo?scheme=gamedeck` → `gamedeck://melonx?games=<base64url JSON>` |
| Madeira 게임 실행 | `madeira://play?exe=<윈도우 경로>` |
| LiveContainer 앱 실행 | `livecontainer://livecontainer-launch?bundle-name=<앱 폴더 이름>` |
| StikDebug 앱 실행 | `stikjit://launch-app?bundle-id=<번들 ID>` |
| 단축어 실행 | `shortcuts://run-shortcut?name=<이름>` |
| 게임덱 | `gamedeck://play?id=<게임 ID>`, `gamedeck://resume` |

## 주의

- 게임덱에는 게임 파일, 키, 펌웨어가 들어 있지 않고, 그런 파일을 다루지도 않습니다. MeloNX와 nxnative 모두 **본인 스위치에서 뽑은** 키와 게임이 필요합니다. 본인이 가진 게임만 쓰세요.
- 각 엔진은 별개의 프로젝트입니다. 엔진 안에서 생기는 문제(게임이 안 켜짐, 느림 등)는 해당 프로젝트의 안내를 보세요.
- 스팀 검색과 표지는 스팀의 공개 스토어 API와 이미지 서버를 씁니다.

## 구조

- `Sources/HomeView.swift`: 홈 화면 (가로 선반 · 세로 격자, 게임패드 조작, 링크 처리)
- `Sources/Engines.swift`: 엔진 목록 (역할 · 필요 조건 · 받는 곳 · 설치 확인)
- `Sources/Models.swift`: 게임과 실행 방법(`LaunchMethod`)이 만드는 링크
- `Sources/Launcher.swift`: 실행과 MeloNX 목록 가져오기
- `Sources/SteamAPI.swift`: 스팀 검색 · 라이브러리 · 표지
- `Sources/Controller.swift`: 게임패드 입력
- `project.yml`: XcodeGen 설정, `../.github/workflows/gamedeck.yml`: 서명 없는 IPA 빌드와 `gamedeck-latest` 릴리스
- 직접 Xcode로 빌드하려면: `brew install xcodegen && xcodegen generate --spec GameDeck/project.yml` 후 `GameDeck/GameDeck.xcodeproj`를 열고 Team 선택 (Xcode 26 이상)
