#!/usr/bin/env python3
"""Generates every sprite and icon for Midnighty Room as pixel art.

Run from the project root:  python3 tools/gen_art.py
Output: assets/sprites/*.png, assets/icons/*.png, icon.png
Each sprite is drawn with rectangles/ellipses and then auto-outlined, so the
whole set keeps one consistent look. Replace any PNG with hand-made art of the
same size and the game picks it up with no code changes.
"""
import math
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
ICO = os.path.join(ROOT, "assets", "icons")
os.makedirs(SPR, exist_ok=True)
os.makedirs(ICO, exist_ok=True)


def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


OUT = C("1d1828")
W0, W1, W2, W3 = C("4a2f2a"), C("6b4636"), C("8c6047"), C("b08460")  # woods
CREAM, CREAM2 = C("efe2c6"), C("d6c4a3")
LAV0, LAV1, LAV2 = C("564685"), C("7461ab"), C("9a89cf")
PINK0, PINK1 = C("b8627f"), C("e08fa8")
TEAL0, TEAL1 = C("357f7d"), C("57aaa5")
AMB0, AMB1, AMB2 = C("c98432"), C("f2b866"), C("ffe3a3")
GRN0, GRN1, GRN2 = C("2f5c3a"), C("457f4b"), C("6aa861")
DK0, DK1, DK2 = C("2a2438"), C("3b3350"), C("564c72")
GREY0, GREY1, GREY2 = C("5e5874"), C("8a84a0"), C("bdb8cc")
WHITE = C("f5f0e6")
RED0, RED1 = C("a8483f"), C("d46a55")
BLUE0, BLUE1, BLUE2 = C("2f4a7a"), C("4f79b8"), C("8fc0ea")
CLAY0, CLAY1 = C("9c5a3c"), C("c47a54")


def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def outline(im, col=OUT):
    """Adds a 1px outline around all opaque pixels (needs 1px free margin)."""
    w, h = im.size
    src = im.load()
    out = im.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200:
                        dst[x, y] = col
                        break
    return out


def save(im, name, folder=SPR, ol=True):
    if ol:
        im = outline(im)
    im.save(os.path.join(folder, name + ".png"))
    return im


def R(d, x0, y0, x1, y1, c):
    d.rectangle([x0, y0, x1, y1], fill=c)


def E(d, x0, y0, x1, y1, c):
    d.ellipse([x0, y0, x1, y1], fill=c)


def L(d, pts, c):
    d.line(pts, fill=c)


def P(d, x, y, c):
    d.point((x, y), fill=c)


# ---------------------------------------------------------------- floor items
def bed():
    im, d = new(80, 46)
    R(d, 1, 6, 7, 40, W1); R(d, 1, 6, 7, 9, W2); R(d, 3, 12, 5, 34, W0)      # headboard
    R(d, 72, 22, 78, 40, W1); R(d, 72, 22, 78, 24, W2)                        # footboard
    R(d, 7, 30, 72, 38, W1); R(d, 7, 36, 72, 38, W0)                          # frame
    R(d, 3, 39, 6, 44, W0); R(d, 73, 39, 76, 44, W0)                          # legs
    R(d, 8, 22, 71, 30, CREAM); R(d, 8, 28, 71, 30, CREAM2)                   # mattress
    R(d, 10, 16, 26, 23, WHITE); R(d, 10, 21, 26, 23, CREAM2); R(d, 11, 15, 25, 16, WHITE)  # pillow
    R(d, 28, 19, 71, 31, LAV1); R(d, 28, 19, 71, 21, LAV2); R(d, 28, 29, 71, 31, LAV0)       # blanket
    R(d, 28, 19, 31, 31, LAV2)
    for x in range(36, 70, 8):
        R(d, x, 23, x + 1, 24, LAV2)
    R(d, 60, 31, 71, 35, LAV0); R(d, 62, 31, 71, 33, LAV1)                    # blanket drape
    return save(im, "bed")


def desk():
    im, d = new(62, 38)
    R(d, 1, 8, 60, 12, W2); R(d, 1, 8, 60, 9, W3); R(d, 1, 12, 60, 12, W0)    # top
    R(d, 3, 13, 6, 36, W1); R(d, 55, 13, 58, 36, W1)                          # legs
    R(d, 38, 13, 54, 26, W1); R(d, 39, 14, 53, 19, W2); R(d, 39, 21, 53, 25, W2)  # drawers
    R(d, 45, 16, 47, 16, AMB1); R(d, 45, 23, 47, 23, AMB1)
    R(d, 7, 30, 54, 31, W0)                                                   # stretcher
    return save(im, "desk")


def chair():
    im, d = new(22, 34)
    R(d, 5, 1, 16, 15, DK2); R(d, 6, 2, 15, 13, LAV1); R(d, 6, 2, 15, 3, LAV2)  # back
    R(d, 9, 15, 12, 18, DK1)
    R(d, 3, 18, 18, 22, LAV1); R(d, 3, 18, 18, 19, LAV2); R(d, 3, 22, 18, 22, LAV0)  # seat
    R(d, 10, 23, 11, 28, GREY0)                                               # post
    R(d, 3, 28, 18, 29, GREY0)
    R(d, 2, 30, 4, 32, DK0); R(d, 9, 30, 12, 32, DK0); R(d, 17, 30, 19, 32, DK0)  # wheels
    return save(im, "chair")


def bookshelf():
    im, d = new(38, 66)
    R(d, 1, 1, 36, 64, W1); R(d, 1, 1, 36, 2, W2)
    cols = [RED1, TEAL1, AMB1, LAV2, PINK1, BLUE1, GRN2, CREAM, RED0, TEAL0, LAV1, BLUE2]
    rnd = random.Random(7)
    for i, y in enumerate(range(4, 60, 15)):
        R(d, 3, y, 34, y + 12, W0)
        x = 4
        while x < 32:
            w = rnd.choice([2, 2, 3, 3, 4])
            h = rnd.choice([8, 9, 10, 11])
            if rnd.random() < 0.12:
                x += 3
                continue
            c = rnd.choice(cols)
            if x + w > 33:
                break
            R(d, x, y + 12 - h, x + w - 1, y + 12, c)
            P(d, x, y + 14 - h if h > 4 else y + 10, WHITE)
            x += w + (1 if rnd.random() < 0.25 else 0)
        if i == 1:
            R(d, 25, y + 5, 33, y + 12, W0)
            E(d, 26, y + 5, 32, y + 11, GRN1); R(d, 27, y + 9, 31, y + 12, CLAY1)
    R(d, 1, 62, 36, 64, W0)
    return save(im, "bookshelf")


def plant_big():
    im, d = new(26, 44)
    R(d, 8, 30, 17, 41, CLAY1); R(d, 7, 29, 18, 31, CLAY1); R(d, 8, 39, 17, 41, CLAY0)
    R(d, 7, 29, 18, 29, C("dc9a73"))
    L(d, [(12, 29), (12, 16)], GRN0); L(d, [(13, 29), (17, 14)], GRN0); L(d, [(12, 28), (7, 15)], GRN0)
    for (cx, cy, rx, ry, c) in [(12, 9, 5, 7, GRN1), (6, 14, 5, 5, GRN1), (19, 12, 5, 6, GRN1),
                                (9, 20, 4, 4, GRN2), (17, 20, 4, 4, GRN2), (13, 5, 3, 4, GRN2)]:
        E(d, cx - rx, cy - ry, cx + rx, cy + ry, c)
    for (x, y) in [(12, 6), (6, 13), (19, 10), (10, 19), (17, 19)]:
        L(d, [(x, y), (x, y + 4)], GRN0)
    return save(im, "plant_big")


def floor_lamp():
    im, d = new(20, 58)
    d.polygon([(5, 1), (14, 1), (17, 13), (2, 13)], fill=AMB1)
    R(d, 6, 1, 13, 2, AMB2); R(d, 3, 12, 16, 13, AMB0)
    R(d, 9, 14, 10, 52, GREY1); R(d, 9, 14, 9, 52, GREY2)
    R(d, 4, 53, 15, 55, GREY0); R(d, 5, 53, 14, 53, GREY1)
    return save(im, "floor_lamp")


def beanbag():
    im, d = new(34, 24)
    E(d, 2, 6, 31, 22, PINK0); E(d, 4, 2, 28, 18, PINK1); E(d, 9, 4, 20, 10, C("efa9bd"))
    R(d, 4, 20, 29, 22, PINK0)
    return save(im, "beanbag")


def side_table():
    im, d = new(22, 22)
    R(d, 1, 3, 20, 6, W2); R(d, 1, 3, 20, 3, W3)
    R(d, 3, 7, 5, 20, W1); R(d, 16, 7, 18, 20, W1); R(d, 6, 13, 15, 14, W0)
    return save(im, "side_table")


def sofa():
    im, d = new(68, 36)
    R(d, 5, 3, 62, 22, TEAL0); R(d, 6, 4, 61, 6, TEAL1)                       # back
    R(d, 1, 12, 8, 30, TEAL1); R(d, 59, 12, 66, 30, TEAL1)                    # arms
    R(d, 1, 12, 8, 13, C("79c4bd")); R(d, 59, 12, 66, 13, C("79c4bd"))
    R(d, 9, 18, 58, 26, TEAL1); R(d, 9, 18, 58, 19, C("79c4bd")); R(d, 33, 19, 33, 26, TEAL0)  # cushions
    R(d, 3, 27, 64, 30, TEAL0)
    R(d, 4, 31, 6, 34, W0); R(d, 61, 31, 63, 34, W0)
    R(d, 12, 10, 21, 19, AMB1); R(d, 13, 11, 20, 12, AMB2)                    # pillow
    return save(im, "sofa")


def guitar():
    im, d = new(18, 46)
    R(d, 8, 2, 9, 26, W0); R(d, 7, 1, 10, 5, DK1)
    E(d, 3, 22, 14, 33, W2); E(d, 1, 29, 16, 43, W2); E(d, 3, 31, 14, 41, W3)
    E(d, 6, 30, 11, 35, DK0); R(d, 6, 38, 11, 39, W0)
    L(d, [(8, 5), (8, 38)], CREAM); L(d, [(9, 5), (9, 38)], CREAM2)
    return save(im, "guitar")


def fireplace():
    im, d = new(54, 50)
    R(d, 1, 4, 52, 48, GREY1); R(d, 1, 1, 52, 5, W2); R(d, 1, 1, 52, 2, W3)   # mantle
    for y in range(8, 48, 5):                                                 # bricks
        off = 0 if (y // 5) % 2 else 4
        L(d, [(2, y), (51, y)], GREY0)
        for x in range(off + 2, 52, 9):
            L(d, [(x, y), (x, y + 4)], GREY0)
    R(d, 12, 20, 41, 48, DK0); d.pieslice([12, 12, 41, 30], 180, 360, fill=DK0)
    R(d, 17, 43, 36, 46, W0); R(d, 20, 41, 33, 43, W1)                        # logs
    d.polygon([(20, 42), (23, 30), (26, 37), (28, 26), (31, 36), (33, 31), (35, 42)], fill=AMB0)
    d.polygon([(23, 42), (25, 35), (27, 39), (28, 32), (30, 39), (32, 42)], fill=AMB1)
    d.polygon([(26, 42), (28, 37), (30, 42)], fill=AMB2)
    return save(im, "fireplace")


def cat(frame, awake):
    im, d = new(28, 18)
    body, dark, belly = C("e7a35c"), C("c47f3e"), C("f6d7ad")
    by = 1 if frame else 0                                                    # breathing
    E(d, 6, 6 - by, 25, 16, body); R(d, 8, 13, 24, 16, body)
    L(d, [(12, 7 - by), (12, 10)], dark); L(d, [(16, 6 - by), (16, 10)], dark); L(d, [(20, 7 - by), (20, 10)], dark)
    d.arc([18, 9, 27, 17], 300, 120, fill=dark)                               # tail curl
    R(d, 22, 15, 26, 16, dark)
    if awake:
        E(d, 1, 3, 11, 12, body)
        d.polygon([(2, 5), (2, 1), (5, 3)], fill=body); d.polygon([(10, 5), (10, 1), (7, 3)], fill=body)
        P(d, 3, 3, PINK1); P(d, 9, 3, PINK1)
        if frame:
            L(d, [(3, 7), (4, 7)], OUT); L(d, [(7, 7), (8, 7)], OUT)
        else:
            R(d, 3, 6, 4, 8, GRN2); R(d, 7, 6, 8, 8, GRN2); P(d, 4, 7, OUT); P(d, 8, 7, OUT)
        P(d, 6, 9, PINK0); R(d, 5, 10, 7, 11, belly)
    else:
        E(d, 2, 7, 12, 16, body)
        d.polygon([(3, 9), (3, 5), (6, 7)], fill=body); d.polygon([(11, 9), (11, 5), (8, 7)], fill=body)
        L(d, [(4, 11), (5, 12)], OUT); L(d, [(8, 12), (9, 11)], OUT)          # closed eyes
        P(d, 7, 13, PINK0); R(d, 6, 14, 8, 15, belly)
    return save(im, "cat_%s_%d" % ("awake" if awake else "sleep", frame))


# ------------------------------------------------------------- small "top" items
def desk_lamp():
    im, d = new(16, 20)
    d.polygon([(2, 1), (9, 1), (11, 7), (1, 7)], fill=RED1); R(d, 3, 1, 8, 2, C("e88a74"))
    R(d, 3, 8, 8, 8, AMB2)
    L(d, [(9, 5), (12, 12)], GREY1); L(d, [(12, 12), (9, 17)], GREY1)
    R(d, 5, 17, 13, 18, GREY0)
    return save(im, "desk_lamp")


def monitor(on):
    im, d = new(26, 22)
    R(d, 1, 1, 24, 15, DK0)
    if on:
        R(d, 2, 2, 23, 14, BLUE0); R(d, 2, 2, 23, 4, BLUE1)
        for y, w, c in [(6, 10, BLUE2), (8, 14, TEAL1), (10, 7, PINK1), (12, 12, BLUE2)]:
            R(d, 4, y, 4 + w, y, c)
    else:
        R(d, 2, 2, 23, 14, DK1); L(d, [(4, 4), (8, 4)], DK2)
    R(d, 11, 16, 14, 18, GREY0); R(d, 7, 19, 18, 20, GREY0)
    return save(im, "monitor_on" if on else "monitor_off")


def laptop():
    im, d = new(22, 15)
    R(d, 4, 1, 18, 10, DK0); R(d, 5, 2, 17, 9, BLUE0); R(d, 6, 3, 12, 3, BLUE2); R(d, 6, 5, 15, 5, TEAL1); R(d, 6, 7, 10, 7, BLUE2)
    R(d, 1, 11, 20, 13, GREY1); R(d, 1, 11, 20, 11, GREY2)
    return save(im, "laptop")


def mug():
    im, d = new(11, 11)
    R(d, 1, 3, 6, 9, WHITE); R(d, 1, 3, 6, 3, C("7a4a35")); R(d, 1, 8, 6, 9, CREAM2)
    R(d, 7, 4, 8, 4, WHITE); R(d, 9, 5, 9, 7, WHITE); R(d, 7, 8, 8, 8, WHITE)
    P(d, 3, 6, PINK1)
    return save(im, "mug")


def books_stack():
    im, d = new(16, 12)
    R(d, 1, 7, 13, 10, RED1); R(d, 2, 8, 12, 8, CREAM)
    R(d, 2, 4, 14, 6, TEAL1); R(d, 3, 5, 13, 5, CREAM)
    R(d, 3, 1, 12, 3, AMB1); R(d, 4, 2, 11, 2, CREAM)
    return save(im, "books_stack")


def record_player():
    im, d = new(24, 15)
    R(d, 1, 7, 22, 13, W1); R(d, 1, 7, 22, 8, W2); R(d, 3, 11, 5, 12, AMB1); R(d, 7, 11, 9, 12, GREY2)
    E(d, 4, 2, 17, 8, DK0); E(d, 8, 4, 13, 6, RED1); P(d, 10, 5, CREAM)
    L(d, [(20, 2), (16, 6)], GREY2); R(d, 19, 1, 21, 3, GREY1)
    return save(im, "record_player")


def candle():
    im, d = new(9, 14)
    R(d, 2, 6, 6, 12, CREAM); R(d, 2, 6, 6, 7, WHITE); R(d, 2, 11, 6, 12, CREAM2)
    P(d, 4, 5, OUT); R(d, 4, 2, 4, 4, AMB1); P(d, 4, 3, AMB2); P(d, 4, 1, AMB0)
    return save(im, "candle")


def succulent():
    im, d = new(13, 13)
    R(d, 3, 7, 9, 11, CLAY1); R(d, 2, 7, 10, 8, C("dc9a73")); R(d, 4, 11, 8, 11, CLAY0)
    d.polygon([(6, 1), (8, 6), (4, 6)], fill=GRN2); d.polygon([(2, 3), (6, 6), (3, 6)], fill=GRN1); d.polygon([(10, 3), (6, 6), (9, 6)], fill=GRN1)
    return save(im, "succulent")


def lava_lamp():
    im, d = new(11, 22)
    d.polygon([(3, 1), (7, 1), (9, 15), (1, 15)], fill=C("5b2f8a"))
    E(d, 3, 4, 6, 7, PINK1); E(d, 3, 9, 7, 13, C("ff9dc0")); P(d, 6, 3, PINK1)
    R(d, 1, 16, 9, 20, GREY0); R(d, 2, 16, 8, 16, GREY1); R(d, 3, 1, 7, 1, GREY1)
    return save(im, "lava_lamp")


# ------------------------------------------------------------------ wall items
def poster_moon():
    im, d = new(24, 30)
    R(d, 1, 1, 22, 28, C("1f2550")); R(d, 1, 20, 22, 28, C("2c3a73"))
    E(d, 7, 5, 16, 14, AMB2); E(d, 10, 4, 18, 12, C("1f2550"))
    for x, y in [(4, 4), (19, 7), (5, 14), (18, 16), (12, 17)]:
        P(d, x, y, WHITE)
    d.polygon([(1, 28), (7, 20), (12, 25), (17, 19), (22, 28)], fill=C("12173a"))
    return save(im, "poster_moon")


def poster_wave():
    im, d = new(24, 30)
    R(d, 1, 1, 22, 28, C("f3d9b1")); E(d, 8, 4, 16, 12, RED1)
    for i, c in enumerate([BLUE1, BLUE0, C("1f2f55")]):
        y = 15 + i * 4
        R(d, 1, y + 2, 22, 28, c)
        for x in range(1, 23, 6):
            d.pieslice([x - 1, y, x + 5, y + 5], 180, 360, fill=c)
    return save(im, "poster_wave")


def frame_cat():
    im, d = new(18, 18)
    R(d, 1, 1, 16, 16, W2); R(d, 3, 3, 14, 14, CREAM)
    E(d, 5, 7, 12, 14, DK1); d.polygon([(5, 9), (5, 5), (8, 7)], fill=DK1); d.polygon([(12, 9), (12, 5), (9, 7)], fill=DK1)
    P(d, 7, 10, AMB1); P(d, 10, 10, AMB1)
    return save(im, "frame_cat")


def wall_shelf():
    im, d = new(38, 20)
    R(d, 1, 14, 36, 16, W2); R(d, 1, 14, 36, 14, W3); R(d, 5, 17, 6, 18, W0); R(d, 31, 17, 32, 18, W0)
    R(d, 3, 6, 5, 13, RED1); R(d, 6, 4, 8, 13, TEAL1); R(d, 9, 7, 11, 13, AMB1); R(d, 12, 5, 13, 13, LAV2)
    R(d, 19, 9, 24, 13, CLAY1); E(d, 17, 2, 26, 10, GRN1); E(d, 20, 3, 24, 7, GRN2)
    R(d, 29, 8, 34, 13, GREY2); R(d, 30, 5, 33, 7, AMB2)
    return save(im, "wall_shelf")


def string_lights():
    im, d = new(100, 16)
    pts = [(x, int(3 + 7 * math.sin(math.pi * (x % 33) / 33.0))) for x in range(1, 99)]
    L(d, pts, DK1)
    cols = [AMB2, PINK1, AMB2, BLUE2, AMB2, C("b6f0c0")]
    for i, x in enumerate(range(5, 98, 8)):
        y = int(3 + 7 * math.sin(math.pi * (x % 33) / 33.0))
        R(d, x, y + 1, x + 1, y + 3, cols[i % len(cols)])
    return save(im, "string_lights", ol=False)


def wall_clock():
    im, d = new(18, 18)
    E(d, 1, 1, 16, 16, W2); E(d, 3, 3, 14, 14, CREAM)
    for a in range(0, 360, 90):
        P(d, 8.5 + 5 * math.cos(math.radians(a)), 8.5 + 5 * math.sin(math.radians(a)), DK1)
    return save(im, "wall_clock")


def neon_moon():
    im, d = new(26, 26)
    d.arc([3, 3, 22, 22], 40, 320, fill=C("d9a8ff"), width=2)
    d.arc([8, 3, 24, 20], 60, 290, fill=C("d9a8ff"), width=1)
    for x, y in [(19, 8), (21, 15)]:
        L(d, [(x - 1, y), (x + 1, y)], C("fff2a8")); L(d, [(x, y - 1), (x, y + 1)], C("fff2a8"))
    return save(im, "neon_moon", ol=False)


def window_frame():
    """Frame only: the pane area is transparent so the sky layer shows through."""
    im, d = new(92, 70)
    R(d, 1, 1, 90, 62, W2)
    R(d, 5, 5, 86, 58, (0, 0, 0, 0))
    R(d, 1, 1, 90, 2, W3); R(d, 1, 61, 90, 62, W0)
    R(d, 44, 5, 46, 58, W2); R(d, 5, 30, 86, 32, W2)                          # mullions
    R(d, 0, 63, 91, 67, W3); R(d, 0, 66, 91, 67, W1)                          # sill
    im.save(os.path.join(SPR, "window_frame.png"))
    return im


def curtains():
    im, d = new(104, 78)
    R(d, 1, 1, 102, 3, W0)
    for side in (0, 1):
        for i in range(5):
            x = 2 + i * 4 if side == 0 else 101 - i * 4 - 3
            c = LAV1 if i % 2 == 0 else LAV0
            R(d, x, 4, x + 3, 74 - (i * 2 if i > 2 else 0), c)
        x = 2 if side == 0 else 82
        R(d, x, 4, x + 19, 5, LAV2)
    return save(im, "curtains")


# ------------------------------------------------------------------------ rugs
def rug_round():
    im, d = new(64, 22)
    E(d, 1, 1, 62, 20, LAV0); E(d, 4, 3, 59, 18, LAV1); E(d, 12, 6, 51, 15, LAV2); E(d, 22, 8, 41, 13, CREAM)
    return save(im, "rug_round", ol=False)


def rug_stripe():
    im, d = new(76, 22)
    d.polygon([(8, 1), (74, 1), (67, 20), (1, 20)], fill=RED0)
    for i, c in enumerate([CREAM, AMB1, CREAM, TEAL1, CREAM]):
        x = 14 + i * 11
        d.polygon([(x, 1), (x + 4, 1), (x - 3, 20), (x - 7, 20)], fill=c)
    return save(im, "rug_stripe", ol=False)


# ----------------------------------------------------------------------- icons
def icon(name, draw):
    im, d = new(16, 16)
    draw(d)
    im.save(os.path.join(ICO, name + ".png"))


def icons():
    I = WHITE
    icon("timer", lambda d: (d.ellipse([2, 3, 13, 14], outline=I), d.line([(8, 5), (8, 9), (10, 10)], fill=I), d.rectangle([6, 1, 9, 2], fill=I)))
    icon("tasks", lambda d: ([d.rectangle([2, y, 4, y + 2], outline=I) for y in (2, 7, 12)], [d.line([(7, y + 1), (13, y + 1)], fill=I) for y in (2, 7, 12)], d.point((3, 3), fill=AMB1)))
    icon("sound", lambda d: (d.polygon([(2, 6), (5, 6), (8, 3), (8, 12), (5, 9), (2, 9)], fill=I), d.arc([7, 4, 12, 11], 300, 60, fill=I), d.arc([8, 2, 15, 13], 300, 60, fill=I)))
    icon("decorate", lambda d: (d.rectangle([3, 2, 10, 5], fill=I), d.line([(11, 3), (13, 3), (13, 8), (7, 8), (7, 10)], fill=I), d.rectangle([6, 10, 8, 14], fill=I)))
    icon("settings", lambda d: (d.ellipse([3, 3, 12, 12], outline=I), d.ellipse([6, 6, 9, 9], fill=I), [d.point(p, fill=I) for p in ((7, 1), (8, 1), (7, 14), (8, 14), (1, 7), (1, 8), (14, 7), (14, 8), (3, 3), (12, 3), (3, 12), (12, 12))]))
    icon("mini", lambda d: (d.rectangle([1, 2, 14, 12], outline=I), d.rectangle([8, 7, 13, 11], fill=I)))
    icon("stats", lambda d: (d.rectangle([2, 9, 4, 13], fill=I), d.rectangle([6, 5, 8, 13], fill=I), d.rectangle([10, 2, 12, 13], fill=I)))
    icon("coin", lambda d: (d.ellipse([2, 2, 13, 13], fill=AMB1), d.ellipse([4, 2, 13, 11], fill=AMB2), d.ellipse([7, 3, 14, 10], fill=AMB1), d.ellipse([2, 2, 13, 13], outline=AMB0)))
    icon("close", lambda d: (d.line([(3, 3), (12, 12)], fill=I, width=2), d.line([(12, 3), (3, 12)], fill=I, width=2)))


def app_icon():
    s = 64
    im, d = new(s, s)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=12, fill=C("1b1838"))
    d.rounded_rectangle([10, 10, 53, 44], radius=3, fill=C("2c3a73"))
    R(d, 10, 30, 53, 44, C("3d4f95"))
    E(d, 34, 14, 46, 26, AMB2); E(d, 38, 12, 50, 23, C("2c3a73"))
    for x, y in [(16, 15), (24, 22), (20, 30), (48, 32)]:
        P(d, x, y, WHITE)
    R(d, 31, 10, 32, 44, W2); R(d, 10, 27, 53, 28, W2)
    d.rounded_rectangle([8, 8, 55, 46], radius=3, outline=W2, width=2)
    R(d, 6, 46, 57, 49, W3)
    E(d, 36, 40, 50, 50, C("e7a35c")); E(d, 30, 42, 40, 50, C("e7a35c"))
    d.polygon([(31, 44), (31, 39), (34, 42)], fill=C("e7a35c")); d.polygon([(39, 44), (39, 39), (36, 42)], fill=C("e7a35c"))
    im = im.resize((256, 256), Image.NEAREST)
    im.save(os.path.join(ROOT, "icon.png"))


def sheet(images):
    """Contact sheet for eyeballing the art (not used by the game)."""
    pad = 6
    w = 400
    x = y = pad
    row_h = 0
    pos = []
    for im in images:
        if x + im.width + pad > w:
            x = pad
            y += row_h + pad
            row_h = 0
        pos.append((x, y))
        x += im.width + pad
        row_h = max(row_h, im.height)
    sh = Image.new("RGBA", (w, y + row_h + pad), C("3a3355"))
    for im, p in zip(images, pos):
        sh.alpha_composite(im, p)
    sh = sh.resize((sh.width * 3, sh.height * 3), Image.NEAREST)
    sh.save(os.path.join(ROOT, "tools", "art_preview.png"))


if __name__ == "__main__":
    imgs = [bed(), desk(), chair(), bookshelf(), plant_big(), floor_lamp(), beanbag(), side_table(), sofa(),
            guitar(), fireplace(), cat(0, False), cat(1, False), cat(0, True), cat(1, True), desk_lamp(),
            monitor(True), monitor(False), laptop(), mug(), books_stack(), record_player(), candle(),
            succulent(), lava_lamp(), poster_moon(), poster_wave(), frame_cat(), wall_shelf(), string_lights(),
            wall_clock(), neon_moon(), window_frame(), curtains(), rug_round(), rug_stripe()]
    icons()
    app_icon()
    sheet(imgs)
    print("wrote %d sprites" % len(imgs))
