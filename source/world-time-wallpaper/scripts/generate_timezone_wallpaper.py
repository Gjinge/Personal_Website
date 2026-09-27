from __future__ import annotations

import math
import random
import urllib.request
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "output" / "wallpapers"
OUT_DIR.mkdir(parents=True, exist_ok=True)

WIDTH = 1707
HEIGHT = 1067
SOURCE = OUT_DIR / "city_lights_2012_flat_map.jpg"
TARGET = OUT_DIR / "timezone_night_world_1707x1067.png"
CLEAN_TARGET = OUT_DIR / "timezone_night_world_clean_1707x1067.png"
SOURCE_URL = "https://commons.wikimedia.org/wiki/Special:FilePath/City_Lights_2012_-_Flat_map.jpg"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    names = [
        "C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc",
        "C:/Windows/Fonts/seguisb.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for name in names:
        path = Path(name)
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def download_source() -> None:
    if SOURCE.exists() and SOURCE.stat().st_size > 1_000_000:
        return
    request = urllib.request.Request(
        SOURCE_URL,
        headers={"User-Agent": "Codex wallpaper generator"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        SOURCE.write_bytes(response.read())


def x_for_longitude(lon: float) -> int:
    return round((lon + 180) / 360 * WIDTH)


def add_gradient_overlay(img: Image.Image) -> None:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    pixels = overlay.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            top = max(0, 145 - y) / 145
            bottom = max(0, y - 690) / 377
            edge = max(abs(x - WIDTH / 2) / (WIDTH / 2) - 0.55, 0) / 0.45
            alpha = int(75 * top + 135 * bottom + 50 * edge)
            pixels[x, y] = (0, 11, 23, min(alpha, 180))
    img.alpha_composite(overlay)


def add_stars(draw: ImageDraw.ImageDraw) -> None:
    random.seed(25)
    for _ in range(1400):
        x = random.randrange(WIDTH)
        y = random.randrange(0, 325)
        radius = random.choice([1, 1, 1, 2])
        shade = random.randrange(115, 235)
        alpha = random.randrange(70, 190)
        draw.ellipse((x, y, x + radius, y + radius), fill=(shade, shade + 5, 255, alpha))

    for cx, cy, rx, ry, alpha in [(780, 145, 520, 18, 90), (950, 132, 390, 12, 65)]:
        for i in range(650):
            angle = random.random() * math.tau
            dist = random.random() ** 2.2
            x = int(cx + math.cos(angle) * rx * dist)
            y = int(cy + math.sin(angle) * ry * dist + random.gauss(0, 10))
            if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                draw.point((x, y), fill=(170, 190, 255, alpha))


def prepare_map() -> Image.Image:
    raw = Image.open(SOURCE).convert("RGB")
    # The source is equirectangular. Resize to screen width and keep the full world visible.
    map_h = round(WIDTH / 2)
    earth = raw.resize((WIDTH, map_h), Image.Resampling.LANCZOS)
    earth = ImageEnhance.Color(earth).enhance(0.62)
    earth = ImageEnhance.Contrast(earth).enhance(1.23)
    earth = ImageEnhance.Brightness(earth).enhance(0.66)

    tint = Image.new("RGB", earth.size, (9, 30, 50))
    earth = Image.blend(earth, tint, 0.18).convert("RGBA")
    mask = Image.new("L", earth.size, 0)
    mdraw = ImageDraw.Draw(mask)
    for y in range(map_h):
        fade_top = min(1.0, y / 80)
        fade_bottom = min(1.0, (map_h - y) / 165)
        mdraw.line((0, y, WIDTH, y), fill=int(232 * fade_top * fade_bottom))
    earth.putalpha(mask.filter(ImageFilter.GaussianBlur(0.4)))
    return earth


def draw_timezone_lines(draw: ImageDraw.ImageDraw) -> None:
    label_font = font(27)
    small_font = font(15)
    zones = [-12, -9, -6, -3, 0, 3, 6, 9, 12, 14]
    for z in zones:
        x = x_for_longitude(z * 15)
        draw.line((x, 96, x, 914), fill=(154, 177, 205, 58), width=1)
        label = f"{z:+d}" if z > 0 else str(z)
        if z == 0:
            label = "0"
        bbox = draw.textbbox((0, 0), label, font=label_font)
        tx = max(8, min(WIDTH - (bbox[2] - bbox[0]) - 8, x - (bbox[2] - bbox[0]) / 2))
        draw.text((tx, 126), label, font=label_font, fill=(225, 233, 245, 220))
    draw.text((WIDTH - 218, 1026), "Generated locally - static wallpaper", font=small_font, fill=(150, 170, 195, 130))


def draw_city_clocks(draw: ImageDraw.ImageDraw) -> None:
    now = datetime.now()
    cities = [
        ("檀香山", "HST", "UTC-10", "Pacific/Honolulu", -157.85, (172, 142, 255)),
        ("洛杉磯", "PDT", "UTC-7", "America/Los_Angeles", -118.24, (103, 165, 255)),
        ("威斯康辛麥迪遜", "CDT", "UTC-5", "America/Chicago", -89.40, (151, 213, 245)),
        ("紐約", "EDT", "UTC-4", "America/New_York", -74.00, (91, 210, 226)),
        ("倫敦", "BST", "UTC+1", "Europe/London", -0.13, (112, 224, 159)),
        ("巴黎", "CEST", "UTC+2", "Europe/Paris", 2.35, (255, 215, 114)),
        ("杜拜", "GST", "UTC+4", "Asia/Dubai", 55.27, (255, 169, 126)),
        ("新德里", "IST", "UTC+5:30", "Asia/Kolkata", 77.21, (255, 111, 125)),
        ("北京", "CST", "UTC+8", "Asia/Shanghai", 116.40, (232, 142, 239)),
        ("東京", "JST", "UTC+9", "Asia/Tokyo", 139.69, (181, 179, 255)),
    ]
    city_font = font(22, bold=True)
    meta_font = font(15)
    time_font = font(38)
    date_font = font(16)
    y0 = 834
    gutter = 38
    col_w = (WIDTH - gutter * 2) / len(cities)
    for i, (name, abbr, utc, tz, lon, color) in enumerate(cities):
        x = round(gutter + i * col_w + 4)
        local = now.astimezone(ZoneInfo(tz))
        draw.line((x - 14, y0 - 4, x - 14, HEIGHT - 95), fill=(*color, 205), width=2)
        draw.text((x, y0), name, font=city_font, fill=(241, 246, 255, 235))
        draw.text((x, y0 + 37), f"{abbr}  {utc}", font=meta_font, fill=(215, 224, 236, 210))
        draw.text((x, y0 + 74), local.strftime("%H:%M"), font=time_font, fill=(*color, 255))
        draw.text((x, y0 + 125), local.strftime("%Y/%m/%d"), font=date_font, fill=(222, 230, 241, 205))
        weekday = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][local.weekday()]
        draw.text((x, y0 + 154), weekday, font=date_font, fill=(198, 209, 224, 190))


def build_wallpaper(draw_static_clocks: bool, target: Path) -> None:
    download_source()
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), (1, 9, 20, 255))
    draw = ImageDraw.Draw(canvas, "RGBA")
    add_stars(draw)

    earth = prepare_map()
    canvas.alpha_composite(earth, (0, 176))
    add_gradient_overlay(canvas)
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw_timezone_lines(draw)
    if draw_static_clocks:
        draw_city_clocks(draw)
    canvas.convert("RGB").save(target, quality=95)


def main() -> None:
    build_wallpaper(True, TARGET)
    build_wallpaper(False, CLEAN_TARGET)
    print(TARGET)
    print(CLEAN_TARGET)


if __name__ == "__main__":
    main()
