#!/usr/bin/env python3
"""앱 스토어 이미지 만들기.

시뮬레이터에서 찍은 원본 화면에 문구와 기기 틀을 입혀
- 아이폰 스크린샷 6장: 1320×2868 (6.9형 iPhone 원본에서. 검색 결과에는 앞의 3장이 나온다)
- 헤더 이미지 1장: 1920×1080
- 아이패드 스크린샷 6장: 2064×2752 (13형 iPad 원본에서, --ipad)
을 만든다. macOS의 Apple SD Gothic Neo 글꼴을 쓴다 (appstore.yml 워크플로에서 실행).

사용: python3 AppStore/compose.py <원본 폴더> <결과 폴더>
      python3 AppStore/compose.py --ipad <아이패드 원본 폴더> <결과 폴더>
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ICON = os.path.join(HERE, "..", "ScreenQR", "Assets.xcassets", "AppIcon.appiconset", "icon.png")

W, H = 1320, 2868
INK = (17, 17, 19)
GRAY = (110, 110, 115)

# (원본 화면 이름, 결과 파일 이름, 제목, 설명) — 앞의 3장이 검색 결과에 나온다.
SHOTS = [
    ("31-welcome", "1-screen-qr", "화면 속 QR,\n버튼 한 번으로", "캡처하고 저장할 필요 없이 바로 열려요"),
    ("32-run", "2-back-tap", "뒷면 톡톡이면 끝", "어떤 앱에서든 화면 속 QR을 바로 열어요"),
    ("33-steps", "3-tutorial", "1분이면 끝나는 설정", "튜토리얼이 한 단계씩 알려 줘요"),
    ("34-photo", "4-photo", "사진 속 QR도 바로", "링크는 바로 열고, 글은 내용을 보여 줘요"),
    ("35-make", "5-make-qr", "링크로 QR 만들기", "공유 · 저장 · 복사까지 한 번에"),
    ("36-safari", "6-safari", "Safari에서는\n단축어 없이도", "주소창 메뉴에서 바로 열어요"),
]

# 아이패드: 같은 화면이지만 아이패드에는 뒷면 탭이 없어서 두 번째 문구가 다르다.
IPAD_SHOTS = [
    ("31-welcome", "1-screen-qr", "화면 속 QR,\n버튼 한 번으로", "캡처하고 저장할 필요 없이 바로 열려요"),
    ("32-run", "2-run", "제어 센터 · Apple Pencil로\n어디서든 한 번에", "어떤 앱에서든 화면 속 QR을 바로 열어요"),
    ("33-steps", "3-tutorial", "1분이면 끝나는 설정", "튜토리얼이 한 단계씩 알려 줘요"),
    ("34-photo", "4-photo", "사진 속 QR도 바로", "링크는 바로 열고, 글은 내용을 보여 줘요"),
    ("35-make", "5-make-qr", "링크로 QR 만들기", "공유 · 저장 · 복사까지 한 번에"),
    ("36-safari", "6-safari", "Safari에서는\n단축어 없이도", "주소창 메뉴에서 바로 열어요"),
]
IPAD_W, IPAD_H = 2064, 2752

FONT_PATHS = [
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",
    "/System/Library/Fonts/Supplemental/AppleSDGothicNeo.ttc",
]


def font(style, size):
    """Apple SD Gothic Neo에서 원하는 굵기(Bold, Medium …)를 찾는다."""
    for path in FONT_PATHS:
        if not os.path.exists(path):
            continue
        for index in range(32):
            try:
                candidate = ImageFont.truetype(path, size, index=index)
            except (OSError, IndexError):
                break
            if candidate.getname()[1].replace(" ", "").lower() == style.lower():
                return candidate
        return ImageFont.truetype(path, size)
    raise SystemExit("Apple SD Gothic Neo 글꼴을 찾지 못했어요")


def background(width, height, top=(250, 250, 252), bottom=(229, 230, 235)):
    """위는 밝고 아래로 갈수록 살짝 회색인 배경"""
    image = Image.new("RGB", (width, height), top)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line([(0, y), (width, y)], fill=color)
    return image


def text_block(text, text_font, spacing):
    """여러 줄 글의 각 줄 크기와 전체 높이"""
    ascent, descent = text_font.getmetrics()
    line_height = round((ascent + descent) * spacing)
    lines = text.split("\n")
    return lines, line_height, line_height * (len(lines) - 1) + ascent + descent


def draw_lines(draw, text, text_font, top, color, left=None, width=None, spacing=1.12):
    """가운데(또는 왼쪽) 정렬로 여러 줄을 쓰고, 다 쓴 아래 위치를 돌려준다."""
    lines, line_height, _ = text_block(text, text_font, spacing)
    y = top
    for line in lines:
        if left is None:
            line_width = draw.textlength(line, font=text_font)
            x = (width - line_width) / 2
        else:
            x = left
        draw.text((x, y), line, font=text_font, fill=color)
        y += line_height
    ascent, descent = text_font.getmetrics()
    return y - line_height + ascent + descent


def device(shot, height, tablet=False):
    """원본 화면을 줄여 둥근 모서리 · 검은 테두리 · 다이내믹 아일랜드를 입힌 아이폰 (RGBA, 전체 높이 = height).
    tablet이면 테두리가 더 두껍고 모서리가 덜 둥근 아이패드 (다이내믹 아일랜드 없음)."""
    border = 110 if tablet else 40
    scale = height / (shot.height + border * 2)
    screen_w, screen_h = round(shot.width * scale), round(shot.height * scale)
    bezel = round(border * scale)
    # 화면 모서리: 아이폰 약 62pt × 3, 아이패드 약 18pt × 2
    radius = round((36 if tablet else 186) * scale)
    frame_w, frame_h = screen_w + bezel * 2, screen_h + bezel * 2

    out = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(out)
    draw.rounded_rectangle([0, 0, frame_w - 1, frame_h - 1], radius=radius + bezel, fill=(52, 52, 58, 255))
    ring = max(2, round(bezel * 0.16))
    draw.rounded_rectangle(
        [ring, ring, frame_w - 1 - ring, frame_h - 1 - ring], radius=radius + bezel - ring, fill=(8, 8, 10, 255)
    )

    screen = shot.convert("RGB").resize((screen_w, screen_h), Image.LANCZOS)
    mask = Image.new("L", (screen_w, screen_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, screen_w - 1, screen_h - 1], radius=radius, fill=255)
    out.paste(screen, (bezel, bezel), mask)
    if tablet:
        return out

    # 시뮬레이터 스크린샷에는 다이내믹 아일랜드가 찍히지 않아서 그려 넣는다 (약 126×37pt, 위에서 11pt).
    island_w, island_h = round(378 * scale), round(111 * scale)
    island_top = bezel + round(33 * scale)
    island_left = bezel + (screen_w - island_w) // 2
    draw.rounded_rectangle(
        [island_left, island_top, island_left + island_w, island_top + island_h], radius=island_h // 2, fill=(0, 0, 0, 255)
    )
    return out


def paste_with_shadow(canvas, item, x, y, blur=46, offset=34, strength=0.28):
    """그림자를 깔고 RGBA 그림을 얹는다 (화면 밖으로 나가도 된다)."""
    pad = blur * 3
    alpha = item.split()[-1].point(lambda a: round(a * strength))
    shadow = Image.new("RGBA", (item.width + pad * 2, item.height + pad * 2), (0, 0, 0, 0))
    shadow_alpha = Image.new("L", shadow.size, 0)
    shadow_alpha.paste(alpha, (pad, pad))
    shadow.putalpha(shadow_alpha.filter(ImageFilter.GaussianBlur(blur)))
    canvas.paste(shadow, (x - pad, y - pad + offset), shadow)
    canvas.paste(item, (x, y), item)


def screenshot(raw, title, subtitle, tablet=False):
    width, height = (IPAD_W, IPAD_H) if tablet else (W, H)
    canvas = background(width, height)
    draw = ImageDraw.Draw(canvas)
    title_font = font("Bold", 124 if tablet else 116)
    sub_font = font("Medium", 58 if tablet else 54)

    # 글은 위쪽 영역(기기 위) 가운데에
    device_top = 700 if tablet else 720
    _, _, title_h = text_block(title, title_font, 1.12)
    _, _, sub_h = text_block(subtitle, sub_font, 1.2)
    block_h = title_h + 40 + sub_h
    top = max(130, (device_top - 70 - block_h) // 2 + 40)
    y = draw_lines(draw, title, title_font, top, INK, width=width, spacing=1.12)
    draw_lines(draw, subtitle, sub_font, y + 40, GRAY, width=width, spacing=1.2)

    frame = device(raw, height - device_top - 90, tablet=tablet)
    paste_with_shadow(canvas, frame, (width - frame.width) // 2, device_top)
    return canvas


def rounded_icon(size, radius):
    icon = Image.open(ICON).convert("RGBA").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    icon.putalpha(mask)
    # 흰 아이콘이 배경에 묻히지 않게 아주 옅은 테두리
    ImageDraw.Draw(icon).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, outline=(0, 0, 0, 28), width=2)
    return icon


def header(raws):
    """1920×1080 헤더: 왼쪽에 아이콘 · 이름 · 문구, 오른쪽에 기기 두 대"""
    hw, hh = 1920, 1080
    canvas = background(hw, hh, top=(250, 250, 252), bottom=(226, 227, 233))
    draw = ImageDraw.Draw(canvas)

    left = 150
    icon = rounded_icon(168, 38)
    paste_with_shadow(canvas, icon, left, 212, blur=22, offset=12, strength=0.22)
    draw.text((left, 420), "Screen QR Scanner", font=font("Bold", 58), fill=INK)
    y = draw_lines(draw, "화면 속 QR,\n버튼 한 번으로", font("Bold", 96), 512, INK, left=left, spacing=1.1)
    draw_lines(draw, "뒷면 톡톡 · 동작 버튼 · 제어 센터 · Safari", font("Medium", 36), y + 34, GRAY, left=left)

    back = device(raws["32-run"], 880).rotate(7, resample=Image.BICUBIC, expand=True)
    front = device(raws["31-welcome"], 940).rotate(-6, resample=Image.BICUBIC, expand=True)
    paste_with_shadow(canvas, back, 1385, 165, blur=40, offset=30, strength=0.24)
    paste_with_shadow(canvas, front, 1000, 118, blur=44, offset=34, strength=0.3)
    return canvas


def main_ipad(source, destination):
    """13형 아이패드 원본으로 아이패드 스크린샷 6장 (2064×2752)"""
    os.makedirs(destination, exist_ok=True)
    for name, output, title, subtitle in IPAD_SHOTS:
        path = os.path.join(source, name + ".png")
        if not os.path.exists(path):
            raise SystemExit(f"원본 화면이 없어요: {path}")
        raw = Image.open(path)
        print(name, raw.size)
        image = screenshot(raw, title, subtitle, tablet=True)
        path = os.path.join(destination, f"ipad-screenshot-{output}.png")
        image.convert("RGB").save(path, optimize=True)
        print("saved", path, image.size)


def main():
    if sys.argv[1] == "--ipad":
        main_ipad(sys.argv[2], sys.argv[3])
        return
    source, destination = sys.argv[1], sys.argv[2]
    os.makedirs(destination, exist_ok=True)
    raws = {}
    for name, _, _, _ in SHOTS:
        path = os.path.join(source, name + ".png")
        if not os.path.exists(path):
            raise SystemExit(f"원본 화면이 없어요: {path}")
        raws[name] = Image.open(path)
        print(name, raws[name].size)

    for name, output, title, subtitle in SHOTS:
        image = screenshot(raws[name], title, subtitle)
        path = os.path.join(destination, f"screenshot-{output}.png")
        image.convert("RGB").save(path, optimize=True)
        print("saved", path, image.size)

    image = header(raws)
    path = os.path.join(destination, "header-1920x1080.png")
    image.convert("RGB").save(path, optimize=True)
    print("saved", path, image.size)


if __name__ == "__main__":
    main()
