#!/usr/bin/env python3
"""앱 스토어 이미지 만들기.

시뮬레이터에서 찍은 원본 화면에 문구와 기기 틀을 입혀
- 아이폰 스크린샷 6장: 1320×2868 (6.9형 iPhone 원본에서. 검색 결과에는 앞의 3장이 나온다)
  + 같은 그림을 줄인 1206×2622 (6.3형 칸이 받는 크기)
- 아이패드 스크린샷 6장: 2064×2752 (13형 iPad 원본에서, --ipad)
- 아이폰 듀오 스크린샷 6장: 1398×2034 (접은 바깥 화면 원본에서, --duo)
을 만들고, AppStore/에 있는 헤더 이미지(3840×1646 · 5244×2950)를 함께 넣는다.
macOS의 Apple SD Gothic Neo 글꼴을 쓴다 (appstore.yml 워크플로에서 실행).

사용: python3 AppStore/compose.py <원본 폴더> <결과 폴더>
      python3 AppStore/compose.py --ipad <아이패드 원본 폴더> <결과 폴더>
      python3 AppStore/compose.py --duo <아이폰 듀오 원본 폴더> <결과 폴더>
"""
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))

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

# 아이폰 6.3형 칸이 받는 크기. 6.9형(1320×2868)으로 만든 그림을 줄여서 함께 저장한다 (가로세로 비율이 같다).
IPHONE_SMALL = (1206, 2622)

# 아이폰 듀오: 접은 바깥 화면(세로 1398×2034). 문구는 아이폰과 같다.
DUO_W, DUO_H = 1398, 2034
DUO_SHOTS = SHOTS

# 헤더(SQRS 로고) — AppStore/ 폴더에 있는 그림을 그대로 넣는다.
# 3840×1646: 제품 페이지 헤더 전용 · 5244×2950: 헤더와 검색 결과에 함께 쓰는 PNG
HEADERS = ["header-3840x1646.png", "header-5244x2950.png"]

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


# 기기별 테두리 두께와 화면 모서리 (원본 화면 픽셀 기준)
# 아이폰: 모서리 약 62pt × 3 · 아이패드: 약 18pt × 2
# 아이폰 듀오 바깥 화면: 약 45pt × 3 (뒤로 버튼이 화면 맨 위 구석에 있어서 그보다 둥글면 버튼이 잘린다)
DEVICE_STYLES = {"phone": (40, 186), "tablet": (110, 36), "duo": (40, 135)}


def device(shot, height, style="phone"):
    """원본 화면을 줄여 둥근 모서리 · 검은 테두리를 입힌 기기 (RGBA, 전체 높이 = height).
    아이폰(phone)은 다이내믹 아일랜드를 그려 넣고, 아이패드(tablet) · 아이폰 듀오 바깥 화면(duo)은
    상태 막대가 오른쪽 세로줄에 있어서 그리지 않는다."""
    border, corner = DEVICE_STYLES[style]
    scale = height / (shot.height + border * 2)
    screen_w, screen_h = round(shot.width * scale), round(shot.height * scale)
    bezel = round(border * scale)
    radius = round(corner * scale)
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
    if style != "phone":
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


def screenshot(raw, title, subtitle, style="phone"):
    if style == "duo":
        return duo_screenshot(raw, title, subtitle)
    tablet = style == "tablet"
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

    frame = device(raw, height - device_top - 90, style=style)
    paste_with_shadow(canvas, frame, (width - frame.width) // 2, device_top)
    return canvas


def duo_screenshot(raw, title, subtitle):
    """아이폰 듀오 접은 화면: 위에 제목과 설명, 아래에 기기 (1398×2034).
    아이폰보다 세로가 짧아서 글을 조금 작게 쓰고, 제목이 한 줄이든 두 줄이든 기기는 같은 자리에 둔다."""
    width, height = (DUO_W, DUO_H) if raw.height >= raw.width else (DUO_H, DUO_W)
    canvas = background(width, height)
    draw = ImageDraw.Draw(canvas)
    title_font = font("Bold", 104)
    sub_font = font("Medium", 50)

    device_top = 500
    _, _, title_h = text_block(title, title_font, 1.12)
    _, _, sub_h = text_block(subtitle, sub_font, 1.2)
    block_h = title_h + 28 + sub_h
    top = max(84, (device_top - 50 - block_h) // 2 + 30)
    y = draw_lines(draw, title, title_font, top, INK, width=width, spacing=1.12)
    draw_lines(draw, subtitle, sub_font, y + 28, GRAY, width=width, spacing=1.2)

    border, _ = DEVICE_STYLES["duo"]
    aspect = (raw.width + border * 2) / (raw.height + border * 2)
    frame_h = min(height - device_top - 64, round((width - 2 * 120) / aspect))
    frame = device(raw, frame_h, style="duo")
    paste_with_shadow(canvas, frame, (width - frame.width) // 2, device_top)
    return canvas


def load_raws(shots, source):
    """원본 화면을 보이는 방향대로 읽는다. 시뮬레이터가 화면을 돌려 저장하고 방향 정보만 붙여 두는
    경우가 있어서(아이폰 듀오 펼친 화면 등), 그 정보대로 돌려 놓는다 (exif_transpose)."""
    raws = {}
    for name, _, _, _ in shots:
        path = os.path.join(source, name + ".png")
        if not os.path.exists(path):
            raise SystemExit(f"원본 화면이 없어요: {path}")
        raws[name] = ImageOps.exif_transpose(Image.open(path))
        print(name, raws[name].size)
    return raws


def save(image, destination, name):
    path = os.path.join(destination, name)
    image.convert("RGB").save(path, optimize=True)
    print("saved", path, image.size)


def main():
    args = sys.argv[1:]
    mode = args.pop(0)[2:] if args and args[0] in ("--ipad", "--duo") else "iphone"
    source, destination = args
    os.makedirs(destination, exist_ok=True)

    if mode == "ipad":
        raws = load_raws(IPAD_SHOTS, source)
        for name, output, title, subtitle in IPAD_SHOTS:
            save(screenshot(raws[name], title, subtitle, style="tablet"), destination, f"ipad-screenshot-{output}.png")
        return

    if mode == "duo":
        raws = load_raws(DUO_SHOTS, source)
        for name, output, title, subtitle in DUO_SHOTS:
            save(screenshot(raws[name], title, subtitle, style="duo"), destination, f"duo-screenshot-{output}.png")
        return

    raws = load_raws(SHOTS, source)
    for name, output, title, subtitle in SHOTS:
        image = screenshot(raws[name], title, subtitle)
        save(image, destination, f"screenshot-{output}.png")
        small = image.convert("RGB").resize(IPHONE_SMALL, Image.LANCZOS)
        save(small, destination, f"screenshot-{output}-{IPHONE_SMALL[0]}x{IPHONE_SMALL[1]}.png")

    for name in HEADERS:
        shutil.copy(os.path.join(HERE, name), os.path.join(destination, name))
        print("copied", name, Image.open(os.path.join(destination, name)).size)


if __name__ == "__main__":
    main()
