#!/usr/bin/env python3
"""Draw the Math Quiz app icon and write the macOS icon set.

Run from the repo root: python3 Packaging/make-icon.py
The PNGs are committed so a Mac build does not need Python.
"""

import math
import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parent / "Assets.xcassets" / "AppIcon.appiconset"
SIZE = 1024


def clamp(value):
    return 0 if value < 0 else 255 if value > 255 else int(value)


def blend(dst, src, cover):
    if cover <= 0:
        return dst
    if cover >= 1:
        return src
    return tuple(clamp(dst[i] * (1 - cover) + src[i] * cover) for i in range(3))


def rounded_cover(px, py, x0, y0, x1, y1, radius):
    cx = min(max(px, x0 + radius), x1 - radius)
    cy = min(max(py, y0 + radius), y1 - radius)
    dist = ((px - cx) ** 2 + (py - cy) ** 2) ** 0.5
    return max(0.0, min(1.0, radius - dist + 0.75))


def circle_cover(px, py, cx, cy, radius):
    dist = ((px - cx) ** 2 + (py - cy) ** 2) ** 0.5
    return max(0.0, min(1.0, radius - dist + 0.75))


def star_points(cx, cy, outer, inner):
    points = []
    for index in range(10):
        angle = -math.pi / 2 + index * math.pi / 5
        radius = outer if index % 2 == 0 else inner
        points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return points


STAR = star_points(812, 806, 78, 32)


def star_cover(px, py):
    inside = False
    previous = len(STAR) - 1
    for index, (xi, yi) in enumerate(STAR):
        xj, yj = STAR[previous]
        if ((yi > py) != (yj > py)) and (px < (xj - xi) * (py - yi) / ((yj - yi) or 1e-9) + xi):
            inside = not inside
        previous = index
    return 1.0 if inside else 0.0


def paint(px, py):
    t = py / (SIZE - 1)
    top = (46, 111, 204)
    bottom = (16, 58, 130)
    color = tuple(clamp(top[i] * (1 - t) + bottom[i] * t) for i in range(3))

    card = rounded_cover(px, py, 88, 88, 936, 936, 210)
    color = blend(color, (255, 247, 235), card)

    arm = 92
    half = 292
    vertical = rounded_cover(px, py, 512 - arm, 512 - half, 512 + arm, 512 + half, arm)
    horizontal = rounded_cover(px, py, 512 - half, 512 - arm, 512 + half, 512 + arm, arm)
    plus = max(vertical, horizontal)
    color = blend(color, (22, 78, 158), plus)

    badge = circle_cover(px, py, 812, 812, 132)
    color = blend(color, (242, 184, 32), badge)
    if badge > 0:
        color = blend(color, (255, 250, 240), min(star_cover(px, py), badge))
    return color


def render_master():
    pixels = bytearray(SIZE * SIZE * 3)
    for y in range(SIZE):
        row = y * SIZE * 3
        for x in range(SIZE):
            red, green, blue = paint(x + 0.5, y + 0.5)
            index = row + x * 3
            pixels[index] = red
            pixels[index + 1] = green
            pixels[index + 2] = blue
    return pixels


def downsample(master, width):
    raw = bytearray()
    span = SIZE // width
    for y in range(width):
        raw.append(0)
        y0 = y * span
        for x in range(width):
            x0 = x * span
            red = green = blue = 0
            for yy in range(y0, y0 + span):
                row = yy * SIZE * 3
                for xx in range(x0, x0 + span):
                    index = row + xx * 3
                    red += master[index]
                    green += master[index + 1]
                    blue += master[index + 2]
            count = span * span
            raw.extend((red // count, green // count, blue // count))
    return bytes(raw)


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def png_rows(master):
    raw = bytearray()
    row_bytes = SIZE * 3
    for y in range(SIZE):
        raw.append(0)
        start = y * row_bytes
        raw.extend(master[start : start + row_bytes])
    return bytes(raw)


def write_png(path, width, height, raw):
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    print("drawing 1024px master")
    master = render_master()
    cache = {}
    for name, pixels in sizes.items():
        raw = cache.get(pixels)
        if raw is None:
            raw = downsample(master, pixels) if pixels != SIZE else png_rows(master)
            cache[pixels] = raw
        write_png(OUT / name, pixels, pixels, raw)
        print(f"wrote {name} ({pixels}px)")


if __name__ == "__main__":
    main()
