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

GitHub의 **Releases → latest**에 항상 최신 빌드가 올라갑니다 (push할 때마다 자동 빌드).

- `ScreenQR-unsigned.ipa`: 아이폰 앱
- `ScreenQR-browser-extension.zip`: 브라우저 확장

## 아이폰에 설치 (Mac 없이)

빌드는 GitHub의 Mac 서버가 대신 해 줍니다. 설치용 서명만 하면 됩니다.

### 방법 A: Windows PC + Sideloadly (무료 Apple ID)

1. PC에 [Sideloadly](https://sideloadly.io)를 설치합니다. 안내에 따라 iTunes와 iCloud(Microsoft Store 버전이 아닌 웹 설치 버전)도 설치합니다.
2. 아이폰을 USB로 연결하고, PC를 "신뢰"합니다.
3. `ScreenQR-unsigned.ipa`를 Sideloadly 창에 끌어다 놓고, Apple ID를 입력한 뒤 **Start**.
4. 아이폰에서
   - 설정 → 일반 → VPN 및 기기 관리 → 내 Apple ID → **신뢰**
   - 설정 → 개인정보 보호 및 보안 → **개발자 모드** 켜기 (재시동 필요)
5. 무료 Apple ID는 **7일마다 다시 설치**해야 합니다. Sideloadly의 자동 갱신(Auto-refresh)을 켜 두면 같은 Wi-Fi에서 PC가 켜져 있을 때 알아서 갱신됩니다.

### 방법 B: 유료 Apple 개발자 계정 (연 $99)

PC가 전혀 필요 없습니다. 계정이 있으면 GitHub Actions가 빌드 후 **TestFlight**로 바로 올리도록 설정할 수 있고, 아이폰의 TestFlight 앱에서 설치합니다 (90일마다 새 빌드).

## 아이폰 설정 (한 번만)

### 단축어

1. **단축어** 앱 → **+**
2. 액션 **"스크린샷 찍기"** 추가
3. 액션 **"이미지 속 QR 열기"**(화면 QR) 추가. 입력이 "스크린샷"으로 연결됐는지 확인
4. 이름을 "화면 QR"로 저장

처음 실행하면 "스크린샷을 공유하도록 허용하시겠습니까?"라고 묻습니다. **항상 허용**을 누르세요.

### 실행 방법 (원하는 것 모두)

| 방법 | 설정 |
|---|---|
| 뒷면 탭 | 설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 이중 탭 → 화면 QR |
| 동작 버튼 (15 Pro 이상) | 설정 → 동작 버튼 → 단축어 → 화면 QR |
| 제어 센터 | 제어 센터 빈 곳 길게 누르기 → 컨트롤 추가 → 단축어 → 화면 QR |
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
