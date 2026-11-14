#!/usr/bin/env python3
"""Draws the Midnighty Room logo as pixel art.

Run from the project root:  python3 tools/gen_logo.py
Output in assets/branding/:
  logo.png           mark + wordmark on transparent, for store pages and docs
  logo_wordmark.png  wordmark only, transparent (used in the first-run guide)
  logo_mark.png      the window-and-cat mark, 512x512
  logo_banner.png    1280x640 on the night-sky background (GitHub social preview)
  logo.svg           vector copy of logo.png (one rect per pixel run)
Also rewrites icon.png and icon.ico in the project root from the mark.
"""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "branding")
os.makedirs(OUT, exist_ok=True)


def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


INK = C("1d1828")
NIGHT, NIGHT2 = C("1b1838"), C("2c3a73")
CREAM, AMB, AMB_D = C("fff2c9"), C("f2b866"), C("c98432")
LAV_L, LAV, LAV_D = C("cfc4f2"), C("9a89cf"), C("6d5ba0")
WOOD, WOOD_L = C("8c6047"), C("b08460")
CAT = C("e7a35c")
WHITE = C("f5f0e6")

GLYPHS = {
    "M": ["X...X", "XX.XX", "X.X.X", "X.X.X", "X...X", "X...X", "X...X"],
    "I": ["XXX", ".X.", ".X.", ".X.", ".X.", ".X.", "XXX"],
    "D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
    "N": ["X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X"],
    "G": [".XXX.", "X...X", "X....", "X.XXX", "X...X", "X...X", ".XXX."],
    "H": ["X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    "T": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
    "Y": ["X...X", "X...X", ".X.X.", "..X..", "..X..", "..X..", "..X.."],
    "R": ["XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X"],
    "O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
}


def text_mask(word, scale=1):
    """Returns a set of (x, y) pixels for `word`, one blank column between letters."""
    pixels, x = set(), 0
    for ch in word:
        rows = GLYPHS[ch]
        for y, row in enumerate(rows):
            for dx, cell in enumerate(row):
                if cell == "X":
                    for sy in range(scale):
                        for sx in range(scale):
                            pixels.add(((x + dx) * scale + sx, y * scale + sy))
        x += len(rows[0]) + 1
    return pixels, (x - 1) * scale, 7 * scale


def ramp(top, bottom, t):
    return tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4))


def wordmark():
    """MIDNIGHTY over a double-size ROOM whose first O is a crescent moon."""
    top, top_w, top_h = text_mask("MIDNIGHTY")
    room, room_w, room_h = text_mask("ROOM", 2)
    width = max(top_w, room_w) + 4
    height = top_h + 3 + room_h + 4
    im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    px = im.load()
    ox_top, oy_top = 2 + (width - 4 - top_w) // 2, 2
    ox_room, oy_room = 2 + (width - 4 - room_w) // 2, 2 + top_h + 3
    fill = {}
    for (x, y) in top:
        fill[(ox_top + x, oy_top + y)] = ramp(LAV_L, LAV, y / (top_h - 1))
    moon_x0, moon_x1 = 12, 21                      # columns of the first O at 2x scale
    for (x, y) in room:
        if moon_x0 <= x <= moon_x1:
            continue
        fill[(ox_room + x, oy_room + y)] = ramp(CREAM, AMB, y / (room_h - 1))
    # crescent moon in place of the first O
    cx, cy, r = ox_room + 16.5, oy_room + 6.5, 6.6
    for y in range(oy_room - 1, oy_room + room_h + 1):
        for x in range(ox_room + moon_x0 - 1, ox_room + moon_x1 + 2):
            inside = (x - cx) ** 2 + (y - cy) ** 2 <= r * r
            bite = (x - cx - 3.4) ** 2 + (y - cy + 2.2) ** 2 <= 5.6 ** 2
            if inside and not bite:
                fill[(x, y)] = ramp(CREAM, AMB, (y - oy_room) / (room_h - 1))
    # drop shadow, then outline, then the letters
    for (x, y) in fill:
        if 0 <= x + 1 < width and 0 <= y + 1 < height:
            px[x + 1, y + 1] = INK
    for (x, y) in fill:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= x + dx < width and 0 <= y + dy < height and (x + dx, y + dy) not in fill:
                px[x + dx, y + dy] = INK
    for (x, y), colour in fill.items():
        px[x, y] = colour
    # two little stars beside the moon
    for sx, sy in ((ox_room + 23, oy_room + 2),):
        px[sx, sy] = WHITE
    return im


def mark():
    """A window onto the night with a moon, and a cat asleep on the sill (32x32)."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, 31, 31], radius=7, fill=LAV_D)
    d.rounded_rectangle([1, 1, 30, 30], radius=6, fill=NIGHT)
    d.rectangle([6, 5, 25, 21], fill=WOOD)                     # frame
    d.rectangle([6, 5, 25, 5], fill=WOOD_L)
    d.rectangle([7, 6, 24, 20], fill=NIGHT2)                   # glass
    d.rectangle([7, 15, 24, 20], fill=C("3d4f95"))
    d.ellipse([17, 7, 23, 13], fill=CREAM)                     # crescent
    d.ellipse([19, 6, 25, 11], fill=NIGHT2)
    for x, y in ((9, 8), (12, 11), (10, 14), (22, 15)):
        d.point((x, y), fill=WHITE)
    for x, h in ((7, 4), (10, 6), (21, 5)):                    # skyline
        d.rectangle([x, 21 - h, x + 2, 20], fill=C("1f2550"))
        d.point((x + 1, 22 - h), fill=AMB)
    d.rectangle([15, 6, 15, 20], fill=WOOD)                    # mullions
    d.rectangle([7, 13, 24, 13], fill=WOOD)
    d.rectangle([4, 22, 27, 23], fill=WOOD_L)                  # sill
    d.rectangle([4, 24, 27, 24], fill=WOOD)
    d.ellipse([14, 16, 24, 22], fill=CAT)                      # cat
    d.rectangle([15, 20, 23, 22], fill=CAT)
    d.ellipse([10, 16, 16, 22], fill=CAT)
    d.polygon([(10, 18), (10, 15), (12, 17)], fill=CAT)
    d.polygon([(16, 18), (16, 15), (14, 17)], fill=CAT)
    d.point((12, 19), fill=INK); d.point((14, 19), fill=INK)
    d.point((13, 20), fill=C("b8627f"))
    for x in (18, 20, 22):
        d.line([(x, 17), (x, 18)], fill=C("c47f3e"))
    return im


def up(im, scale):
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


def to_svg(im, path, scale):
    """Writes the image as horizontal runs of same-coloured pixels."""
    px = im.load()
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" shape-rendering="crispEdges">'
             % (im.width, im.height, im.width * scale, im.height * scale), "<title>Midnighty Room</title>"]
    for y in range(im.height):
        x = 0
        while x < im.width:
            colour = px[x, y]
            run = 1
            while x + run < im.width and px[x + run, y] == colour:
                run += 1
            if colour[3] > 0:
                parts.append('<rect x="%d" y="%d" width="%d" height="1" fill="#%02x%02x%02x"/>' % (x, y, run, colour[0], colour[1], colour[2]))
            x += run
    parts.append("</svg>")
    with open(path, "w") as f:
        f.write("\n".join(parts))


def main():
    word = wordmark()
    icon = mark()
    small = icon
    gap = 5
    height = max(small.height, word.height)
    lockup = Image.new("RGBA", (small.width + gap + word.width, height), (0, 0, 0, 0))
    lockup.alpha_composite(small, (0, (height - small.height) // 2))
    lockup.alpha_composite(word, (small.width + gap, (height - word.height) // 2))

    up(lockup, 8).save(os.path.join(OUT, "logo.png"))
    up(word, 8).save(os.path.join(OUT, "logo_wordmark.png"))
    up(icon, 16).save(os.path.join(OUT, "logo_mark.png"))
    to_svg(lockup, os.path.join(OUT, "logo.svg"), 8)
    # the mark is also the app, window and exe icon
    app = up(icon, 8)
    app.save(os.path.join(ROOT, "icon.png"))
    app.save(os.path.join(ROOT, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

    banner = Image.new("RGBA", (160, 80), NIGHT)
    d = ImageDraw.Draw(banner)
    for y in range(80):
        d.line([(0, y), (159, y)], fill=ramp(C("0f1030"), C("2c2a5c"), y / 79))
    rng = random.Random(4042)
    for _ in range(70):
        x, y = rng.randrange(160), rng.randrange(62)
        banner.putpixel((x, y), ramp(WHITE, LAV, rng.random())[:3] + (rng.choice([255, 170, 110]),))
    x = 0
    while x < 160:                                 # skyline along the bottom
        w, h = rng.randint(6, 13), rng.randint(6, 18)
        d.rectangle([x, 80 - h, x + w, 80], fill=C("0b0c24"))
        for wy in range(82 - h, 79, 4):
            for wx in range(x + 1, x + w - 1, 4):
                if rng.random() < 0.45:
                    d.rectangle([wx, wy, wx + 1, wy + 1], fill=AMB)
        x += w + rng.randint(0, 2)
    banner.alpha_composite(lockup, ((160 - lockup.width) // 2, 20))
    up(banner, 8).convert("RGB").save(os.path.join(OUT, "logo_banner.png"))
    print("logo %dx%d, wordmark %dx%d" % (lockup.width * 8, lockup.height * 8, word.width * 8, word.height * 8))


if __name__ == "__main__":
    main()
