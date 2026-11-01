# 화면 QR

화면에 떠 있는 QR 코드를 **버튼 한 번으로** 바로 여는 앱/확장 프로그램입니다.
캡처해서 저장하고, 앱을 열고, 업로드하는 과정이 없습니다.

| 어디서 | 어떻게 | 비고 |
|---|---|---|
| 아이폰 (모든 앱: 크롬, 인스타, 카톡…) | 뒷면 두 번 탭 / 동작 버튼 / 제어 센터 | 단축어 사용 |
| 아이폰 Safari | 주소창 메뉴 → 화면 QR | 단축어 필요 없음 |
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

1. **단축어** 앱 → **+**
2. 액션 **"스크린샷 찍기"** 추가
3. 액션 **"이미지 속 QR 열기"**(화면 QR) 추가. "**스크린샷**에서 QR 열기"로 이어졌는지 확인
4. 이름을 **"QR 열기"** 로 저장 (앱 이름 "화면 QR"과 헷갈리지 않게)

처음 실행하면 "스크린샷을 공유하도록 허용하시겠습니까?"라고 묻습니다. **항상 허용**을 누르세요.

버튼을 눌렀는데 **사진 선택** 창이 뜨면 "스크린샷 찍기"가 빠진 것입니다. 버튼에 앱의 "이미지 속 QR 열기" 동작이 아니라 만든 단축어 **QR 열기**가 연결됐는지, 단축어의 첫 줄이 "스크린샷 찍기"인지 확인하세요.

### 실행 방법 (원하는 것 모두)

| 방법 | 설정 |
|---|---|
| 뒷면 탭 | 설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 이중 탭 → QR 열기 |
| 동작 버튼 (15 Pro 이상) | 설정 → 동작 버튼 → 단축어 → 내 단축어의 QR 열기 |
| 제어 센터 | 제어 센터 빈 곳 길게 누르기 → 컨트롤 추가 → 단축어 → QR 열기 |
| Safari | 설정 → 앱 → Safari → 확장 프로그램 → 화면 QR 켜기 |

## 브라우저 확장 설치

### Chrome · Edge · 웨일 · Brave · Opera · Vivaldi (PC)

1. `ScreenQR-browser-extension.zip`을 받아 압축을 풉니다.
2. 주소창에 `chrome://extensions` (Edge는 `edge://extensions`, 웨일은 `whale://extensions`) 입력
3. **개발자 모드** 켜기 → **압축해제된 확장 프로그램 로드** → 압축 푼 폴더 선택
4. 툴바의 퍼즐 아이콘에서 화면 QR을 **고정**해 두면 편합니다. 단축키는 `chrome://extensions/shortcuts`에서 바꿀 수 있습니다.

### Firefox (PC · 안드로이드)

Firefox는 Mozilla 서명을 받은 확장만 계속 설치해 둘 수 있습니다.

- 잠깐 써 보기: `about:debugging` → 이 Firefox → **임시 부가 기능 로드** → `manifest.json` 선택 (브라우저를 끄면 사라짐)
- 계속 쓰기: [addons.mozilla.org](https://addons.mozilla.org/developers/)에서 무료로 서명받거나 등록합니다. 등록하면 안드로이드 Firefox에서도 설치할 수 있습니다.

### 스토어 등록

Chrome 웹 스토어(1회 $5)나 Edge 부가 기능(무료)에 올리면 개발자 모드 없이 누구나 설치할 수 있습니다. `ScreenQR-browser-extension.zip`을 그대로 업로드하면 됩니다.

### 참고: 휴대폰 브라우저

아이폰의 Chrome·Edge·웨일 등은 Apple 정책상 확장 프로그램을 지원하지 않습니다. 대신 **뒷면 탭 단축어가 모든 앱에서 동작**하므로 아이폰 Chrome에서도 그대로 쓰면 됩니다.

## 구조

- `ScreenQR/`: iOS 앱 (Liquid Glass 홈 화면, 단축어 액션 App Intent, Vision 기반 QR 인식)
- `SafariExtension/`: iOS Safari 확장 (네이티브 Vision으로 인식)
- `browser-extension/`: Chrome/Edge/Firefox 등 공용 확장 (Manifest V3, ZXing WASM으로 인식)
  - `vendor/zxing-reader.js`, `vendor/zxing_reader.wasm`: [zxing-wasm](https://github.com/Sec-ant/zxing-wasm) 3.1.5 (MIT)
- `.github/workflows/build.yml`: iOS 앱 빌드(서명 없는 IPA), 확장 검사·패키징, Releases 업로드
- 직접 Xcode로 빌드하려면: `brew install xcodegen && xcodegen generate` 후 두 타깃 모두 Team 선택 (iOS 26, Xcode 26 이상)

## 다른 앱

- [게임덱 (GameDeck)](GameDeck/README.md): 스위치·스팀 게임을 한 화면에 모아 두고 컨트롤러로 바로 실행하는 디로이드덱 스타일 런처
