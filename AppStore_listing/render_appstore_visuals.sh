#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="/tmp/effner-render-venv"

cleanup() {
  rm -rf "$VENV_PATH"
}
trap cleanup EXIT

python3 -m venv "$VENV_PATH"
"$VENV_PATH/bin/pip" install --quiet Pillow

cd "$SCRIPT_DIR"
"$VENV_PATH/bin/python" - <<'PY'
import json
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

BASE_DIR = Path(".")
CONFIG_PATH = BASE_DIR / "screenshots.json"
OUTPUT_DIR = BASE_DIR / "styled"
OUTPUT_DIR.mkdir(exist_ok=True)
OUTPUT_IPAD_DIR = BASE_DIR / "styled_ipad"
OUTPUT_IPAD_DIR.mkdir(exist_ok=True)
OUTPUT_MAC_DIR = BASE_DIR / "styled_mac"
OUTPUT_MAC_DIR.mkdir(exist_ok=True)

CANVAS_W, CANVAS_H = 1290, 2796
IPAD_W, IPAD_H = 2752, 2064
MAC_W, MAC_H = 1280, 800
TEXT_MARGIN_X = 94
HEADLINE_TOP = 150
SUBHEADLINE_GAP = 30
SCREENSHOT_TOP = 980
SCREENSHOT_MAX_W = 1160
SCREENSHOT_MAX_H = 2260
SCREENSHOT_SCALE = 1.4
SUBTLE_SHADOW_ALPHA = 0.24
SUBTLE_SHADOW_BLUR = 16
SUBTLE_SHADOW_OFFSET_X = 8
SUBTLE_SHADOW_OFFSET_Y = 14
SUBTLE_SHADOW_PAD = 34

GRADIENTS = [
    ((24, 47, 94), (39, 89, 183), (80, 166, 255)),
    ((63, 33, 109), (131, 58, 180), (246, 114, 128)),
    ((8, 74, 80), (9, 121, 105), (72, 202, 140)),
    ((56, 31, 90), (99, 102, 241), (56, 189, 248)),
    ((78, 18, 84), (134, 25, 143), (236, 72, 153)),
]


def pick_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> str:
    if not text:
        return ""
    words = text.split()
    lines = []
    current = []
    for word in words:
        trial = " ".join(current + [word])
        trial_box = draw.textbbox((0, 0), trial, font=font)
        if trial_box[2] - trial_box[0] <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return "\n".join(lines)


def build_gradient(size: tuple[int, int], colors: tuple[tuple[int, int, int], ...]) -> Image.Image:
    width, height = size
    top, mid, bottom = colors
    bg = Image.new("RGB", size)
    draw = ImageDraw.Draw(bg)
    half = height // 2

    for y in range(half):
        t = y / max(half - 1, 1)
        color = tuple(int(top[i] * (1 - t) + mid[i] * t) for i in range(3))
        draw.line([(0, y), (width, y)], fill=color)

    for y in range(half, height):
        t = (y - half) / max(height - half - 1, 1)
        color = tuple(int(mid[i] * (1 - t) + bottom[i] * t) for i in range(3))
        draw.line([(0, y), (width, y)], fill=color)

    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        [width * -0.15, height * 0.35, width * 1.15, height * 1.2],
        fill=(255, 255, 255, 38),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    return Image.alpha_composite(bg.convert("RGBA"), glow).convert("RGBA")


def perspective_coeffs(src_points: list[tuple[float, float]], dst_points: list[tuple[float, float]]) -> list[float]:
    matrix = []
    for (x_src, y_src), (x_dst, y_dst) in zip(src_points, dst_points):
        matrix.append([x_dst, y_dst, 1, 0, 0, 0, -x_src * x_dst, -x_src * y_dst])
        matrix.append([0, 0, 0, x_dst, y_dst, 1, -y_src * x_dst, -y_src * y_dst])

    vector = [coord for point in src_points for coord in point]

    # Solve an 8x8 system with Gaussian elimination to avoid extra dependencies.
    n = len(vector)
    aug = [row[:] + [vector[i]] for i, row in enumerate(matrix)]

    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(aug[r][col]))
        if abs(aug[pivot][col]) < 1e-12:
            raise ValueError("Perspective matrix is singular.")
        aug[col], aug[pivot] = aug[pivot], aug[col]
        pivot_val = aug[col][col]
        aug[col] = [v / pivot_val for v in aug[col]]
        for row in range(n):
            if row == col:
                continue
            factor = aug[row][col]
            aug[row] = [a - factor * b for a, b in zip(aug[row], aug[col])]

    return [aug[i][-1] for i in range(n)]


def stylize_screenshot(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    img.thumbnail((SCREENSHOT_MAX_W, SCREENSHOT_MAX_H), Image.Resampling.LANCZOS)
    scaled_w = max(1, int(img.width * SCREENSHOT_SCALE))
    scaled_h = max(1, int(img.height * SCREENSHOT_SCALE))
    img = img.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)
    w, h = img.size

    radius = max(26, int(w * 0.038))
    rounded_mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(rounded_mask).rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    img.putalpha(ImageChops.multiply(img.getchannel("A"), rounded_mask))

    y_tilt_strength = random.uniform(0.10, 0.18)
    y_tilt_direction = random.choice([-1, 1])
    side_inset = int(w * y_tilt_strength)
    top_skew = int(max(8, side_inset * 0.34))
    output_w = w + side_inset

    if y_tilt_direction > 0:
        dst_points = [
            (0, top_skew),
            (output_w - side_inset, 0),
            (output_w - side_inset, h),
            (0, h - top_skew),
        ]
    else:
        dst_points = [
            (side_inset, 0),
            (output_w, top_skew),
            (output_w, h - top_skew),
            (side_inset, h),
        ]

    coeffs = perspective_coeffs(
        src_points=[(0, 0), (w, 0), (w, h), (0, h)],
        dst_points=dst_points,
    )
    projected = img.transform(
        (output_w, h),
        Image.Transform.PERSPECTIVE,
        coeffs,
        Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )

    shadow_alpha = projected.split()[-1].point(lambda p: int(p * SUBTLE_SHADOW_ALPHA))
    shadow = Image.new("RGBA", projected.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(SUBTLE_SHADOW_BLUR))

    pad = SUBTLE_SHADOW_PAD
    composed = Image.new("RGBA", (output_w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    base_x = pad
    base_y = pad
    composed.alpha_composite(shadow, dest=(base_x + SUBTLE_SHADOW_OFFSET_X, base_y + SUBTLE_SHADOW_OFFSET_Y))
    composed.alpha_composite(projected, dest=(base_x, base_y))
    return composed


def build_frame(item: dict, gradient: tuple[tuple[int, int, int], ...]) -> Image.Image:
    source_path = BASE_DIR / item["image_name"]
    if not source_path.exists():
        raise FileNotFoundError(f"Bild fehlt: {source_path}")

    background = build_gradient((CANVAS_W, CANVAS_H), gradient)
    draw = ImageDraw.Draw(background)

    headline_font = pick_font(98)
    subheadline_font = pick_font(50)

    headline = (item.get("headline") or source_path.stem).strip()
    subheadline = (item.get("subheadline") or "").strip()

    max_text_width = CANVAS_W - (TEXT_MARGIN_X * 2)
    headline_wrapped = wrap_text(draw, headline, headline_font, max_text_width)
    subheadline_wrapped = wrap_text(draw, subheadline, subheadline_font, max_text_width)

    draw.multiline_text(
        (TEXT_MARGIN_X + 2, HEADLINE_TOP + 2),
        headline_wrapped,
        font=headline_font,
        fill=(0, 0, 0, 88),
        spacing=12,
    )
    draw.multiline_text(
        (TEXT_MARGIN_X, HEADLINE_TOP),
        headline_wrapped,
        font=headline_font,
        fill=(255, 255, 255, 255),
        spacing=12,
    )

    headline_box = draw.multiline_textbbox((TEXT_MARGIN_X, HEADLINE_TOP), headline_wrapped, font=headline_font, spacing=12)
    current_y = headline_box[3] + SUBHEADLINE_GAP
    if subheadline_wrapped:
        draw.multiline_text(
            (TEXT_MARGIN_X + 2, current_y + 2),
            subheadline_wrapped,
            font=subheadline_font,
            fill=(0, 0, 0, 80),
            spacing=10,
        )
        draw.multiline_text(
            (TEXT_MARGIN_X, current_y),
            subheadline_wrapped,
            font=subheadline_font,
            fill=(255, 255, 255, 255),
            spacing=10,
        )

    with Image.open(source_path) as src:
        stylized = stylize_screenshot(src)

    alpha_bbox = stylized.getchannel("A").getbbox()
    if alpha_bbox:
        visual_center_x = (alpha_bbox[0] + alpha_bbox[2]) / 2
        x = int((CANVAS_W / 2) - visual_center_x)
    else:
        x = (CANVAS_W - stylized.width) // 2
    y = max(SCREENSHOT_TOP, current_y + 280)
    if y + stylized.height > CANVAS_H - 80:
        y = CANVAS_H - stylized.height - 80

    background.alpha_composite(stylized, dest=(x, y))
    return background.convert("RGB")


def build_device_frame(
    phone_frame: Image.Image,
    gradient: tuple[tuple[int, int, int], ...],
    target_size: tuple[int, int],
) -> Image.Image:
    target_w, target_h = target_size
    device_background = build_gradient((target_w, target_h), gradient).convert("RGB")
    scale = min(target_w / CANVAS_W, target_h / CANVAS_H)
    target_w = max(1, int(CANVAS_W * scale))
    target_h = max(1, int(CANVAS_H * scale))
    fitted = phone_frame.resize((target_w, target_h), Image.Resampling.LANCZOS)
    x = (target_size[0] - target_w) // 2
    y = (target_size[1] - target_h) // 2
    device_background.paste(fitted, (x, y))
    return device_background


def main() -> None:
    items = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    if not isinstance(items, list):
        raise ValueError("screenshots.json muss ein Array sein.")

    for idx, item in enumerate(items):
        if not isinstance(item, dict):
            raise ValueError("Jedes Array-Element muss ein Objekt sein.")
        if "image_name" not in item:
            raise ValueError("Jedes Objekt braucht image_name.")

        frame = build_frame(item, GRADIENTS[idx % len(GRADIENTS)])
        output_name = f"{Path(item['image_name']).stem}_appstore.png"
        output_path = OUTPUT_DIR / output_name
        frame.save(output_path, format="PNG", optimize=True)
        print(f"Erstellt: {output_path}")

        ipad_output_path = OUTPUT_IPAD_DIR / output_name
        build_device_frame(frame, GRADIENTS[idx % len(GRADIENTS)], (IPAD_W, IPAD_H)).save(
            ipad_output_path,
            format="PNG",
            optimize=True,
        )
        print(f"Erstellt: {ipad_output_path}")

        mac_output_path = OUTPUT_MAC_DIR / output_name
        build_device_frame(frame, GRADIENTS[idx % len(GRADIENTS)], (MAC_W, MAC_H)).save(
            mac_output_path,
            format="PNG",
            optimize=True,
        )
        print(f"Erstellt: {mac_output_path}")


if __name__ == "__main__":
    main()
PY
