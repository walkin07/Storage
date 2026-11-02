# Screen QR Scanner

화면에 떠 있는 QR 코드를 **버튼 한 번으로** 바로 여는 앱/확장 프로그램입니다.
캡처해서 저장하고, 앱을 열고, 업로드하는 과정이 없습니다. 링크를 넣어 **QR 코드를 만드는** 기능도 있습니다.

| 어디서 | 어떻게 | 비고 |
|---|---|---|
| 아이폰 (모든 앱: 크롬, 인스타, 카톡…) | 뒷면 두 번 탭 / 동작 버튼 / 제어 센터 | 단축어 사용 |
| 아이패드 (모든 앱) | 제어 센터 / Apple Pencil Pro 스퀴즈 / AssistiveTouch | 단축어 사용 |
| 아이폰 · 아이패드 Safari | 주소창 메뉴 → Screen QR Scanner | 단축어 필요 없음 |
| PC Chrome · Edge · 웨일 · Brave · Opera · Vivaldi | 툴바 아이콘 또는 `Alt+Shift+Q` | |
| PC/안드로이드 Firefox | 툴바 아이콘 또는 `Alt+Shift+Q` | 서명 필요 (아래 참고) |

- 평소에는 아무것도 실행되지 않습니다. 버튼을 눌렀을 때만 동작합니다.
- 스크린샷은 저장되지 않으며, QR 인식은 모두 기기/브라우저 안에서 처리합니다(iOS: Apple Vision, 브라우저: ZXing WASM).
- 링크는 바로 열립니다. Wi-Fi 정보·일반 텍스트는 내용을 보여주고 복사할 수 있습니다.
- 화면에 QR이 여러 개면 확장 프로그램은 목록으로 보여주고, 단축어는 가장 큰 것을 엽니다.

## 다운로드

GitHub의 **Releases → screenqr-latest**에 항상 최신 빌드가 올라갑니다 (push할 때마다 자동 빌드).

- `ScreenQR-unsigned.ipa`: 아이폰 앱
- `ScreenQR-browser-extension.zip`: 브라우저 확장

## 아이폰에 설치 (Mac 없이)

빌드는 GitHub의 Mac 서버가 대신 해 줍니다. 설치용 서명만 하면 됩니다.

### 방법 A: Windows PC + Sideloadly (개발자 계정이 없을 때)

1. PC에 [Sideloadly](https://sideloadly.io)를 설치합니다. 안내에 따라 iTunes와 iCloud(Microsoft Store 버전이 아닌 웹 설치 버전)도 설치합니다.
2. 아이폰을 USB로 연결하고, PC를 "신뢰"합니다.
3. `ScreenQR-unsigned.ipa`를 Sideloadly 창에 끌어다 놓고, Apple ID를 입력한 뒤 **Start**.
4. 아이폰에서
   - 설정 → 일반 → VPN 및 기기 관리 → 내 Apple ID → **신뢰**
   - 설정 → 개인정보 보호 및 보안 → **개발자 모드** 켜기 (재시동 필요)
5. 무료 Apple ID는 **7일마다 다시 설치**해야 합니다. Sideloadly의 자동 갱신(Auto-refresh)을 켜 두면 같은 Wi-Fi에서 PC가 켜져 있을 때 알아서 갱신됩니다.

### 방법 B: Apple 개발자 계정 + TestFlight (PC 필요 없음, 추천)

push할 때마다 GitHub Actions가 빌드·서명해서 TestFlight에 올립니다. 아이폰의 **TestFlight** 앱에서 설치·업데이트합니다.

한 번만 준비하면 됩니다:

1. [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)에서 App ID 두 개 등록
   - `io.github.walkin07.screenqr` (앱)
   - `io.github.walkin07.screenqr.safari` (Safari 확장)
   - 다른 ID를 쓰려면 GitHub 저장소 변수 `APP_BUNDLE_ID`에 앱 ID를 넣으세요.
2. [App Store Connect → 앱 → +](https://appstoreconnect.apple.com/apps) → 신규 앱: 플랫폼 iOS, 번들 ID는 위의 앱 ID, SKU는 아무거나
3. App Store Connect → 사용자 및 액세스 → 통합 → App Store Connect API → **팀 키 생성** (액세스: **관리자**)
   - Issuer ID, 키 ID를 적어 두고 `.p8` 파일을 받습니다 (한 번만 받을 수 있음)
4. GitHub 저장소 → Settings → Secrets and variables → Actions → **New repository secret** 4개
   | 이름 | 값 |
   |---|---|
   | `APPLE_TEAM_ID` | developer.apple.com → 멤버십 세부 사항의 팀 ID |
   | `ASC_KEY_ID` | 키 ID |
   | `ASC_ISSUER_ID` | Issuer ID |
   | `ASC_KEY_P8` | `.p8` 파일을 메모장으로 열어 `-----BEGIN`부터 `END-----`까지 전부 |
5. Actions 탭에서 Build 워크플로를 다시 실행하거나 새로 push → 10~30분 뒤 App Store Connect의 TestFlight에 빌드가 나타납니다.
6. App Store Connect → TestFlight → 내부 테스트 그룹을 만들고 본인을 추가 → 아이폰에서 TestFlight 앱으로 설치

TestFlight 빌드는 90일 동안 쓸 수 있고, 새로 push하면 자동으로 새 빌드가 올라갑니다.

## 아이폰 설정 (한 번만)

### 단축어

앱을 처음 열면 **단축어 만들기 튜토리얼 보기**와 **건너뛰기** 중에서 고를 수 있습니다. 튜토리얼은 한 단계씩 그림으로 보여 주고, 단계를 마치고 **다음**을 누르면 다음 단계로 넘어갑니다. 단축어를 다 만들면 실행 방법 고르기(시험용 QR 포함), 마지막으로 Safari 확장 프로그램 페이지가 나오고 **완료**를 누르면 끝납니다. 건너뛰었거나 다시 보려면 홈의 **단축어 만들기 튜토리얼**을 누르세요 (끝까지 본 적이 있으면 위쪽에 X로 바로 닫을 수 있습니다).

튜토리얼 없이 직접 만들 때:

1. **단축어** 앱 → **+** 로 새 단축어
2. 아래쪽 "동작 검색"에 "스크린샷" → **"스크린샷 찍기"** (단축어 기본 동작이라 앱 목록에는 없습니다)
3. 다시 "QR" → **"이미지 속 QR 열기"**(Screen QR Scanner). "**스크린샷**에서 QR 열기"가 추가되면 끝 (단축어는 자동으로 저장됩니다)

처음 실행하면 "스크린샷을 공유하도록 허용하시겠습니까?"라고 묻습니다. **항상 허용**을 누르세요. 튜토리얼의 실행 방법 페이지에 있는 **시험용 QR**을 화면에 띄운 채 단축어를 실행하면, 단축어가 그 QR을 읽고 "잘 동작해요!"로 바뀌어 바로 확인할 수 있습니다 (카메라로 찍는 QR이 아닙니다).

링크가 아닌 QR(글, Wi-Fi 정보 등)은 단축어 동작이 앱에 직접 넘기고, 다른 앱을 보던 중이면 Screen QR Scanner를 앞으로 불러와 내용을 보여 줍니다. (단축어의 'URL 열기'로는 앱 자체 주소가 열리지 않아서 이렇게 합니다.)

앱은 다른 앱 화면을 캡처할 수 없어서 캡처는 이 "스크린샷 찍기"가 합니다. 단축어에 "이미지 속 QR 열기" 한 줄만 있으면 실행할 때 "스크린샷 찍기를 넣어 달라"는 안내가 나옵니다.

버튼을 눌렀는데 **사진 선택** 창이 뜨면 예전 버전이거나 "스크린샷 찍기"가 빠진 것입니다. 버튼에 앱의 "이미지 속 QR 열기" 동작이 아니라 **만든 단축어**가 연결됐는지, 단축어의 첫 줄이 "스크린샷 찍기"인지 확인하세요.

### 실행 방법 (원하는 것 모두)

| 방법 | 설정 |
|---|---|
| 뒷면 탭 | 설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 이중 탭 → 만든 단축어 |
| 동작 버튼 (15 Pro · 16 이후, 아이폰 듀오 제외) | 설정 → 동작 버튼 → 단축어 → 만든 단축어 |
| 제어 센터 | 제어 센터 왼쪽 위 ＋ → 컨트롤 추가 → 단축어 → 만든 단축어. 단축어 맨 위에 **대기 1초**를 넣어 주세요 (가끔 제어 센터가 닫히기 전에 찍혀서 QR을 못 찾는 것을 막습니다) |
| Apple Pencil Pro (아이패드) | 설정 → Apple Pencil → 스퀴즈 → 단축어 → 만든 단축어. 펜을 살짝 쥐면 실행 |
| AssistiveTouch (아이패드 · 아이폰) | 설정 → 손쉬운 사용 → 터치 → AssistiveTouch 켜기 → 이중 탭 → 만든 단축어 |
| Safari | 설정 → 앱 → Safari → 확장 프로그램 → Screen QR Scanner 켜기 |

튜토리얼의 실행 방법 페이지는 기기에 맞는 것만 보여 줍니다 (아이폰: 뒷면 탭 · 동작 버튼 · 제어 센터, 동작 버튼이 없는 아이폰 듀오: 뒷면 탭 · 제어 센터 · AssistiveTouch, 아이패드: 제어 센터 · Apple Pencil · AssistiveTouch).

## 아이패드 · 아이폰 듀오

- 아이패드에서도 아이폰 앱을 키운 것이 아니라 아이패드 화면에 맞춰 보입니다. 모든 방향으로 돌릴 수 있고, Split View · Stage Manager 창 크기에도 맞춰집니다.
- 가로로 넓은 화면(아이패드 가로, 펼친 아이폰 듀오)에서는 튜토리얼 그림과 설명이 나란히 놓이고, QR 만들기는 입력 칸 옆에 QR 코드가 나옵니다. 세로로 긴 화면에서는 가운데 한 줄로 모읍니다.
- 아이폰 듀오는 접은 바깥 화면처럼 세로가 짧은 화면에서도 튜토리얼 그림을 줄여 아래 버튼까지 한눈에 보이게 합니다. 펼친 안쪽 화면을 꽉 채워 쓰도록 iOS 27.1 SDK(Xcode 27.1)로 빌드합니다 (지원하는 최소 iOS는 그대로 26).
- 아이패드 튜토리얼은 아이패드 모양 그림(Safari 주소창이 위쪽)과 아이패드에서 쓸 수 있는 실행 방법으로 안내합니다.

## 사진에서 QR 열기 (아이폰 앱)

앱의 **QR 읽기** 맨 위에서 **사진 고르기**를 누르고, 저장해 둔 스크린샷이나 QR 사진을 고르면 바로 엽니다. QR이 여러 개면 어느 것을 열지 고를 수 있습니다. 사진 앱 전체 접근 권한은 필요 없습니다.

## QR 만들기 (아이폰 앱)

앱 위쪽의 **QR 만들기**를 누르고 링크나 글을 넣으면 QR 코드가 바로 만들어집니다.

- `naver.com`처럼 `https://`를 빼고 넣어도 주소로 만들어 줍니다.
- **공유**(메시지·카톡 등으로 보내기), **저장**(사진 앱, 처음 한 번 저장 허용), **복사**(다른 앱에 붙여넣기)
- QR 코드는 아이폰 안에서 만들어지고, 넣은 내용은 어디에도 보내지 않습니다.

## 앱 스토어 이미지

GitHub의 **Releases → screenqr-appstore**에 앱 스토어용 이미지가 올라갑니다.

- `screenshot-1` ~ `screenshot-6`: 1320×2868 (6.9형 iPhone). App Store Connect의 스크린샷에 순서대로 올리면 검색 결과에는 앞의 3장이 나옵니다.
- `header-1920x1080`: 헤더/홍보 이미지 (인앱 이벤트 카드, 피처링 요청, 웹·SNS 등)

실제 앱 화면을 6.9형 시뮬레이터에서 찍어(9:41 상태 막대) 문구와 기기 틀을 입힌 것입니다. 문구는 `AppStore/compose.py`의 `SHOTS`에서 고치고, Actions 탭의 **App Store images** 워크플로를 실행하면 다시 만들어집니다.

## 브라우저 확장 설치

### Chrome · Edge · 웨일 · Brave · Opera · Vivaldi (PC)

1. `ScreenQR-browser-extension.zip`을 받아 압축을 풉니다.
2. 주소창에 `chrome://extensions` (Edge는 `edge://extensions`, 웨일은 `whale://extensions`) 입력
3. **개발자 모드** 켜기 → **압축해제된 확장 프로그램 로드** → 압축 푼 폴더 선택
4. 툴바의 퍼즐 아이콘에서 Screen QR Scanner를 **고정**해 두면 편합니다. 단축키는 `chrome://extensions/shortcuts`에서 바꿀 수 있습니다.

### Firefox (PC · 안드로이드)

Firefox는 Mozilla 서명을 받은 확장만 계속 설치해 둘 수 있습니다.

- 잠깐 써 보기: `about:debugging` → 이 Firefox → **임시 부가 기능 로드** → `manifest.json` 선택 (브라우저를 끄면 사라짐)
- 계속 쓰기: [addons.mozilla.org](https://addons.mozilla.org/developers/)에서 무료로 서명받거나 등록합니다. 등록하면 안드로이드 Firefox에서도 설치할 수 있습니다.

### 스토어 등록

Chrome 웹 스토어(1회 $5)나 Edge 부가 기능(무료)에 올리면 개발자 모드 없이 누구나 설치할 수 있습니다. `ScreenQR-browser-extension.zip`을 그대로 업로드하면 됩니다.

### 참고: 휴대폰 브라우저

아이폰의 Chrome·Edge·웨일 등은 Apple 정책상 확장 프로그램을 지원하지 않습니다. 대신 **뒷면 탭 단축어가 모든 앱에서 동작**하므로 아이폰 Chrome에서도 그대로 쓰면 됩니다.

## 구조

- `ScreenQR/`: iOS 앱 (Liquid Glass 홈 화면, 첫 실행 단축어 튜토리얼, 단축어 액션 App Intent, Vision 기반 QR 인식)
- `ScreenQRUITests/`: 시뮬레이터에서 튜토리얼을 끝까지 넘겨 보는 UI 테스트 (CI가 페이지마다 스크린샷을 남김). `LayoutScreens`는 아이폰 · 아이패드(세로·가로) · 아이폰 듀오(접은·펼친 화면)에서 주요 화면을 찍어 배치를 확인합니다
- `SafariExtension/`: iOS Safari 확장 (네이티브 Vision으로 인식)
- `browser-extension/`: Chrome/Edge/Firefox 등 공용 확장 (Manifest V3, ZXing WASM으로 인식)
  - `vendor/zxing-reader.js`, `vendor/zxing_reader.wasm`: [zxing-wasm](https://github.com/Sec-ant/zxing-wasm) 3.1.5 (MIT)
- `.github/workflows/build.yml`: iOS 앱 빌드(서명 없는 IPA), 시뮬레이터 UI 테스트(아이폰 · 아이패드 · 아이폰 듀오), 확장 검사·패키징, Releases 업로드, TestFlight 업로드. 아이폰 듀오를 접고 펴는 데는 공개 도구 [duo-fold-control](https://github.com/tosbaha/duo-fold-control)(MIT)의 `duo-hinge`를 고정 버전으로 받아 씁니다
- `.github/workflows/appstore.yml`, `AppStore/compose.py`: 앱 스토어 이미지 만들기
- 직접 Xcode로 빌드하려면: `brew install xcodegen && xcodegen generate` 후 두 타깃 모두 Team 선택 (iOS 26 이상 지원, Xcode 27.1 이상)

## 다른 앱

- [게임덱 (GameDeck)](GameDeck/README.md): 스위치·스팀 게임을 한 화면에 모아 두고 컨트롤러로 바로 실행하는 디로이드덱 스타일 런처
