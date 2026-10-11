# 화면 QR

아이폰 화면에 떠 있는 QR 코드를 **버튼 한 번으로** 바로 여는 앱입니다.
캡처해서 사진첩에 저장하고, 앱을 열고, 업로드하는 과정이 없습니다.

```
뒷면 탭 / 동작 버튼 / 제어 센터 → (단축어) 스크린샷 찍기 → 이미지 속 QR 열기 → 링크 열림
Safari 주소창 메뉴 → 화면 QR → 링크 열림 (단축어 필요 없음)
```

- 평소에는 아무것도 실행되지 않습니다. 버튼을 눌렀을 때만 동작합니다.
- 스크린샷은 메모리에서만 쓰이고 사진첩에 저장되지 않습니다.
- QR 인식은 기기 안에서 Apple Vision으로 처리합니다.
- 링크(http, https, 전화, 메일 등)는 바로 열립니다. Wi-Fi 정보나 일반 텍스트는 앱에서 내용을 보여주고 복사할 수 있습니다.
- 화면에 QR이 여러 개 있으면 단축어는 가장 큰 QR을 열고, Safari에서는 목록으로 보여줍니다.

## 설치 (Mac 필요)

1. `brew install xcodegen`
2. 이 폴더에서 `xcodegen generate`
3. `ScreenQR.xcodeproj`를 열고 **ScreenQR**, **ScreenQRSafari** 두 타깃 모두 **Signing & Capabilities → Team**에서 본인 Apple ID를 선택합니다.
   번들 ID가 겹치면 `com.example.screenqr`를 바꾸세요. 확장 프로그램 ID는 앱 ID 뒤에 `.safari`를 붙인 값이어야 합니다.
4. 아이폰을 연결하고 실행합니다. iOS 26 이상, Xcode 26 이상이 필요합니다.
   - 무료 Apple ID로 설치하면 7일마다 다시 설치해야 합니다.
   - 아이폰에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 켜야 할 수 있습니다.

## 단축어 만들기 (한 번만)

1. **단축어** 앱 → **+**
2. 액션 **"스크린샷 찍기"** 추가
3. 액션 **"이미지 속 QR 열기"**(화면 QR) 추가. 입력이 "스크린샷"으로 연결됐는지 확인
4. 이름을 "화면 QR"로 저장

처음 실행하면 "스크린샷을 공유하도록 허용하시겠습니까?"라고 묻습니다. **항상 허용**을 누르세요.

## 실행 방법 (원하는 것 모두)

| 방법 | 설정 |
|---|---|
| 뒷면 탭 | 설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 이중 탭 → 화면 QR |
| 동작 버튼 (15 Pro 이상) | 설정 → 동작 버튼 → 단축어 → 화면 QR |
| 제어 센터 | 제어 센터 빈 곳 길게 누르기 → 컨트롤 추가 → 단축어 → 화면 QR |
| Safari | 설정 → 앱 → Safari → 확장 프로그램 → 화면 QR 켜기. 이후 주소창 메뉴에서 화면 QR |

## 구조

- `ScreenQR/ContentView.swift`: Liquid Glass 홈 화면(사용법)과 텍스트 QR 결과 화면입니다. 햅틱을 포함합니다.
- `ScreenQR/OpenQRFromImageIntent.swift`: 단축어 액션(App Intent)입니다. 이미지에서 QR을 해독하고 `OpenURLIntent`로 엽니다.
- `ScreenQR/QRDecoder.swift`: Vision 기반 QR 인식과 링크/텍스트 판별을 담당합니다. 앱과 Safari 확장이 함께 씁니다.
- `SafariExtension/`: Safari 웹 확장입니다. 보이는 화면을 캡처하고, 실패하면 페이지 이미지를 모아 네이티브 핸들러(Vision)로 해독합니다.
- `.github/workflows/build.yml`: macOS에서 서명 없이 빌드해 컴파일을 확인합니다.
