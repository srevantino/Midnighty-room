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
PINK0, PINK1, PINK2 = C("b8627f"), C("e08fa8"), C("efa9bd")
TEAL0, TEAL1, TEAL2 = C("357f7d"), C("57aaa5"), C("79c4bd")
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
    E(d, 2, 6, 31, 22, PINK0); E(d, 4, 2, 28, 18, PINK1); E(d, 9, 4, 20, 10, PINK2)
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
    R(d, 1, 12, 8, 13, TEAL2); R(d, 59, 12, 66, 13, C("79c4bd"))
    R(d, 9, 18, 58, 26, TEAL1); R(d, 9, 18, 58, 19, TEAL2); R(d, 33, 19, 33, 26, TEAL0)  # cushions
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


def fireplace(frame=0):
    im, d = new(54, 50)
    R(d, 1, 4, 52, 48, GREY1); R(d, 1, 1, 52, 5, W2); R(d, 1, 1, 52, 2, W3)   # mantle
    for y in range(8, 48, 5):                                                 # bricks
        off = 0 if (y // 5) % 2 else 4
        L(d, [(2, y), (51, y)], GREY0)
        for x in range(off + 2, 52, 9):
            L(d, [(x, y), (x, y + 4)], GREY0)
    R(d, 12, 20, 41, 48, DK0); d.pieslice([12, 12, 41, 30], 180, 360, fill=DK0)
    R(d, 17, 43, 36, 46, W0); R(d, 20, 41, 33, 43, W1)                        # logs
    if frame == 0:
        d.polygon([(20, 42), (23, 30), (26, 37), (28, 26), (31, 36), (33, 31), (35, 42)], fill=AMB0)
        d.polygon([(23, 42), (25, 35), (27, 39), (28, 32), (30, 39), (32, 42)], fill=AMB1)
    else:
        d.polygon([(20, 42), (22, 33), (25, 38), (27, 28), (30, 35), (34, 29), (35, 42)], fill=AMB0)
        d.polygon([(23, 42), (24, 37), (27, 40), (29, 33), (31, 38), (32, 42)], fill=AMB1)
    d.polygon([(26, 42), (28, 37 + frame), (30, 42)], fill=AMB2)
    return save(im, "fireplace" if frame == 0 else "fireplace_1")


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


def cat_up(frame, walking):
    """Standing (walk) or sitting cat, facing left."""
    im, d = new(28, 20)
    body, dark, belly = C("e7a35c"), C("c47f3e"), C("f6d7ad")
    if walking:
        R(d, 8, 8, 23, 14, body); E(d, 6, 7, 12, 14, body); E(d, 19, 7, 25, 14, body)
        for x in (12, 16, 20):
            L(d, [(x, 8), (x, 11)], dark)
        legs = [(8, 0), (12, 1), (18, 1), (22, 0)] if frame == 0 else [(8, 1), (12, 0), (18, 0), (22, 1)]
        for x, up in legs:
            R(d, x, 14, x + 1, 18 - up, body)
        L(d, [(24, 9), (26, 5 + frame), (26, 3 + frame)], dark)
        E(d, 1, 3, 10, 11, body); hx, hy = 1, 3
    else:
        E(d, 10, 7, 22, 18, body); R(d, 11, 14, 21, 18, body); R(d, 9, 15, 12, 18, belly)
        d.arc([16, 12, 26, 19], 320, 100, fill=dark); R(d, 21, 17, 25, 18, dark)
        L(d, [(15, 9), (15, 12)], dark); L(d, [(18, 9), (18, 12)], dark)
        E(d, 5, 1, 14, 9, body); hx, hy = 5, 1
    d.polygon([(hx + 1, hy + 2), (hx + 1, hy - 2 + 1), (hx + 4, hy)], fill=body)
    d.polygon([(hx + 8, hy + 2), (hx + 8, hy - 1), (hx + 5, hy)], fill=body)
    if frame and not walking:
        L(d, [(hx + 2, hy + 4), (hx + 3, hy + 4)], OUT); L(d, [(hx + 6, hy + 4), (hx + 7, hy + 4)], OUT)
    else:
        R(d, hx + 2, hy + 3, hx + 3, hy + 5, GRN2); R(d, hx + 6, hy + 3, hx + 7, hy + 5, GRN2)
        P(d, hx + 2, hy + 4, OUT); P(d, hx + 6, hy + 4, OUT)
    P(d, hx + 4, hy + 6, PINK0)
    return save(im, "cat_%s_%d" % ("walk" if walking else "sit", frame))


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
        for y, w, c in [(6, 10, BLUE2), (8, 14, TEAL1), (10, 7, PINK1), (12, 12 if on == 1 else 9, BLUE2)]:
            R(d, 4, y, 4 + w, y, c)
    else:
        R(d, 2, 2, 23, 14, DK1); L(d, [(4, 4), (8, 4)], DK2)
    R(d, 11, 16, 14, 18, GREY0); R(d, 7, 19, 18, 20, GREY0)
    return save(im, {0: "monitor_off", 1: "monitor_on", 2: "monitor_on_1"}[int(on)])


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


def record_player(frame=0):
    im, d = new(24, 15)
    R(d, 1, 7, 22, 13, W1); R(d, 1, 7, 22, 8, W2); R(d, 3, 11, 5, 12, AMB1); R(d, 7, 11, 9, 12, GREY2)
    E(d, 4, 2, 17, 8, DK0); E(d, 8, 4, 13, 6, RED1); P(d, 10 + frame, 5, CREAM); P(d, 6 + frame * 8, 5 - frame, GREY0)
    L(d, [(20, 2), (16, 6)], GREY2); R(d, 19, 1, 21, 3, GREY1)
    return save(im, "record_player" if frame == 0 else "record_player_1")


def candle(frame=0):
    im, d = new(9, 14)
    R(d, 2, 6, 6, 12, CREAM); R(d, 2, 6, 6, 7, WHITE); R(d, 2, 11, 6, 12, CREAM2)
    P(d, 4, 5, OUT); R(d, 4, 2, 4, 4, AMB1); P(d, 4, 3, AMB2); P(d, 4 + frame, 1, AMB0)
    return save(im, "candle" if frame == 0 else "candle_1")


def succulent():
    im, d = new(13, 13)
    R(d, 3, 7, 9, 11, CLAY1); R(d, 2, 7, 10, 8, C("dc9a73")); R(d, 4, 11, 8, 11, CLAY0)
    d.polygon([(6, 1), (8, 6), (4, 6)], fill=GRN2); d.polygon([(2, 3), (6, 6), (3, 6)], fill=GRN1); d.polygon([(10, 3), (6, 6), (9, 6)], fill=GRN1)
    return save(im, "succulent")


def lava_lamp(frame=0):
    im, d = new(11, 22)
    d.polygon([(3, 1), (7, 1), (9, 15), (1, 15)], fill=C("5b2f8a"))
    if frame == 0:
        E(d, 3, 4, 6, 7, PINK1); E(d, 3, 9, 7, 13, C("ff9dc0")); P(d, 6, 3, PINK1)
    else:
        E(d, 4, 2, 6, 5, PINK1); E(d, 3, 7, 7, 10, C("ff9dc0")); E(d, 3, 12, 6, 14, PINK1)
    R(d, 1, 16, 9, 20, GREY0); R(d, 2, 16, 8, 16, GREY1); R(d, 3, 1, 7, 1, GREY1)
    return save(im, "lava_lamp" if frame == 0 else "lava_lamp_1")


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


def string_lights(frame=0):
    im, d = new(100, 16)
    pts = [(x, int(3 + 7 * math.sin(math.pi * (x % 33) / 33.0))) for x in range(1, 99)]
    L(d, pts, DK1)
    cols = [AMB2, PINK1, AMB2, BLUE2, AMB2, C("b6f0c0")]
    for i, x in enumerate(range(5, 98, 8)):
        y = int(3 + 7 * math.sin(math.pi * (x % 33) / 33.0))
        R(d, x, y + 1, x + 1, y + 3, cols[(i + frame * 3) % len(cols)])
    return save(im, "string_lights" if frame == 0 else "string_lights_1", ol=False)


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
    w = 520
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


# =========================================================== version 0.2 art
RAMPS = {
    "lavender": [LAV0, LAV1, LAV2], "teal": [TEAL0, TEAL1, TEAL2], "rose": [PINK0, PINK1, PINK2],
    "amber": [AMB0, AMB1, AMB2], "sage": [GRN0, GRN1, GRN2], "slate": [GREY0, GREY1, GREY2],
}


def variants(name, base, others):
    """Writes name__<ramp>.png recolours of an already saved sprite."""
    src = Image.open(os.path.join(SPR, name + ".png")).convert("RGBA")
    for other in others:
        table = dict(zip(RAMPS[base], RAMPS[other]))
        if other in ("amber", "teal") and base != other:
            table.update(dict(zip(RAMPS[other], RAMPS[base])))      # keep accents readable
        im = src.copy()
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                if px[x, y] in table:
                    px[x, y] = table[px[x, y]]
        im.save(os.path.join(SPR, "%s__%s.png" % (name, other)))


def sway(name, y_max, out):
    """Second frame for plants: nudges the top rows one pixel sideways."""
    src = Image.open(os.path.join(SPR, name + ".png")).convert("RGBA")
    im = Image.new("RGBA", src.size, (0, 0, 0, 0))
    im.paste(src.crop((0, y_max, src.width, src.height)), (0, y_max))
    top = src.crop((0, 0, src.width, y_max))
    im.alpha_composite(top.crop((0, 0, src.width - 1, y_max // 2)), (1, 0))
    im.alpha_composite(top.crop((0, y_max // 2, src.width, y_max)), (0, y_max // 2))
    im.save(os.path.join(SPR, out + ".png"))


def avatar(pose, frame):
    """You, sitting on the desk chair, facing left. pose: idle/type/rest/sleep."""
    im, d = new(28, 42)
    skin, hair, pants, shoe = C("f0c8a0"), C("3a2a3f"), DK1, C("f5f0e6")
    R(d, 18, 9, 23, 25, DK2); R(d, 19, 10, 22, 23, GREY0)                     # chair back
    R(d, 7, 26, 21, 29, GREY0); R(d, 7, 26, 21, 26, GREY1)                    # seat
    R(d, 13, 30, 14, 35, GREY0); R(d, 6, 35, 21, 36, GREY0)
    R(d, 5, 37, 7, 39, DK0); R(d, 12, 37, 15, 39, DK0); R(d, 20, 37, 22, 39, DK0)
    R(d, 5, 23, 16, 26, pants); R(d, 5, 26, 7, 35, pants); R(d, 3, 35, 7, 36, shoe)   # legs
    R(d, 10, 14, 18, 25, LAV1); R(d, 10, 14, 18, 15, LAV2); R(d, 16, 16, 18, 25, LAV0)  # hoodie
    R(d, 15, 12, 18, 15, LAV0)                                                # hood
    drop = 3 if pose == "sleep" else 0
    hx, hy = 8 - (1 if pose == "sleep" else 0), 3 + drop
    E(d, hx, hy, hx + 9, hy + 9, skin)
    d.pieslice([hx - 1, hy - 1, hx + 10, hy + 9], 180, 360, fill=hair); R(d, hx + 6, hy + 3, hx + 10, hy + 8, hair)
    if pose == "sleep" or (pose == "idle" and frame == 1):
        L(d, [(hx + 2, hy + 6), (hx + 3, hy + 6)], OUT)
    else:
        R(d, hx + 2, hy + 5, hx + 2, hy + 6, OUT)
    if pose == "type":
        R(d, 5, 18, 13, 20, LAV1); R(d, 2, 18 + frame, 5, 19 + frame, skin)
    elif pose == "rest":
        R(d, 8, 16, 12, 18, LAV1); R(d, 5, 12 - frame, 8, 17, LAV1)
        R(d, 3, 9 - frame, 6, 12 - frame, WHITE); R(d, 5, 12 - frame, 6, 13 - frame, skin)
    elif pose == "sleep":
        R(d, 5, 19, 13, 21, LAV1); R(d, 2, 20, 5, 21, skin)
        if frame:
            P(d, 5, 3, WHITE); P(d, 3, 1, WHITE)
    else:
        R(d, 8, 19, 14, 21, LAV1); R(d, 6, 21, 9, 22, skin)
    return save(im, "avatar_%s_%d" % (pose, frame))


def more_floor():
    out = []
    im, d = new(40, 68)                                                       # wardrobe
    R(d, 1, 1, 38, 63, W1); R(d, 1, 1, 38, 2, W3); R(d, 3, 5, 18, 58, W2); R(d, 21, 5, 36, 58, W2)
    R(d, 16, 28, 17, 33, AMB1); R(d, 22, 28, 23, 33, AMB1); R(d, 3, 59, 5, 66, W0); R(d, 34, 59, 36, 66, W0)
    out.append(save(im, "wardrobe"))
    im, d = new(44, 34)                                                       # dresser
    R(d, 1, 1, 42, 30, W1); R(d, 1, 1, 42, 2, W3)
    for y in (5, 14, 23):
        R(d, 3, y, 40, y + 6, W2); R(d, 19, y + 3, 24, y + 3, AMB1)
    R(d, 3, 31, 5, 32, W0); R(d, 38, 31, 40, 32, W0)
    out.append(save(im, "dresser"))
    im, d = new(46, 20)                                                       # coffee table
    R(d, 1, 3, 44, 6, W2); R(d, 1, 3, 44, 3, W3); R(d, 4, 7, 6, 18, W1); R(d, 39, 7, 41, 18, W1); R(d, 7, 12, 38, 13, W0)
    out.append(save(im, "coffee_table"))
    im, d = new(34, 36)                                                       # armchair
    R(d, 5, 2, 28, 22, AMB0); R(d, 6, 3, 27, 5, AMB1); R(d, 1, 14, 7, 30, AMB1); R(d, 26, 14, 32, 30, AMB1)
    R(d, 1, 14, 7, 15, AMB2); R(d, 26, 14, 32, 15, AMB2); R(d, 8, 19, 25, 27, AMB1); R(d, 8, 19, 25, 20, AMB2)
    R(d, 3, 28, 30, 30, AMB0); R(d, 4, 31, 6, 34, W0); R(d, 27, 31, 29, 34, W0)
    out.append(save(im, "armchair"))
    im, d = new(26, 12)                                                       # floor cushion
    E(d, 1, 2, 24, 10, TEAL0); E(d, 2, 1, 23, 8, TEAL1); E(d, 7, 2, 16, 5, TEAL2); P(d, 12, 5, TEAL0)
    out.append(save(im, "floor_cushion"))
    im, d = new(50, 44)                                                       # tv stand
    R(d, 5, 1, 44, 24, DK0); R(d, 7, 3, 42, 22, BLUE0); R(d, 7, 3, 42, 8, C("3a5f9c")); E(d, 28, 9, 38, 19, AMB1); R(d, 7, 18, 42, 22, C("26365c"))
    R(d, 22, 25, 27, 27, GREY0); R(d, 1, 28, 48, 38, W1); R(d, 1, 28, 48, 29, W3); R(d, 4, 31, 22, 36, W0); R(d, 27, 31, 45, 36, W0)
    R(d, 3, 39, 5, 42, W0); R(d, 44, 39, 46, 42, W0)
    out.append(save(im, "tv_stand"))
    im, d = new(48, 30)                                                       # keyboard piano
    R(d, 1, 6, 46, 14, DK1); R(d, 1, 6, 46, 7, DK2); R(d, 3, 10, 44, 13, WHITE)
    for x in range(5, 44, 3):
        L(d, [(x, 10), (x, 13)], GREY1)
    for x in range(4, 43, 6):
        R(d, x, 10, x + 1, 11, DK0)
    L(d, [(8, 15), (38, 27)], GREY0); L(d, [(38, 15), (8, 27)], GREY0); R(d, 6, 27, 11, 28, GREY0); R(d, 35, 27, 40, 28, GREY0)
    out.append(save(im, "keyboard"))
    im, d = new(28, 50)                                                       # easel
    L(d, [(6, 46), (13, 2)], W1); L(d, [(21, 46), (14, 2)], W1); L(d, [(14, 4), (14, 44)], W0); R(d, 3, 34, 24, 35, W2)
    R(d, 5, 8, 22, 33, CREAM); R(d, 6, 22, 21, 32, TEAL1); E(d, 14, 10, 20, 16, AMB1); d.polygon([(6, 32), (11, 20), (16, 32)], fill=GRN1)
    out.append(save(im, "easel"))
    im, d = new(22, 54)                                                       # floor mirror
    d.rounded_rectangle([2, 1, 19, 48], radius=6, fill=W2); d.rounded_rectangle([4, 3, 17, 46], radius=5, fill=C("a9cfe6"))
    L(d, [(6, 14), (12, 6)], WHITE); L(d, [(7, 20), (15, 9)], C("d3e8f5")); R(d, 4, 49, 6, 52, W0); R(d, 15, 49, 17, 52, W0)
    out.append(save(im, "floor_mirror"))
    im, d = new(14, 24)                                                       # lantern
    R(d, 4, 1, 9, 2, GREY0); R(d, 2, 4, 11, 5, DK1); R(d, 3, 6, 10, 18, AMB1); R(d, 5, 9, 8, 15, AMB2)
    L(d, [(3, 6), (3, 18)], DK1); L(d, [(10, 6), (10, 18)], DK1); L(d, [(6, 6), (6, 18)], DK1); R(d, 2, 19, 11, 21, DK1)
    out.append(save(im, "lantern"))
    im, d = new(16, 30)                                                       # cactus
    R(d, 4, 20, 11, 27, CLAY1); R(d, 3, 19, 12, 20, C("dc9a73")); R(d, 6, 4, 9, 19, GRN1); R(d, 6, 4, 6, 19, GRN2)
    R(d, 2, 9, 3, 14, GRN1); R(d, 3, 13, 6, 14, GRN1); R(d, 12, 7, 13, 12, GRN1); R(d, 9, 11, 12, 12, GRN1); P(d, 7, 3, PINK1); P(d, 8, 3, PINK1)
    out.append(save(im, "cactus"))
    im, d = new(18, 42)                                                       # snake plant
    R(d, 4, 31, 13, 39, GREY2); R(d, 3, 30, 14, 31, WHITE)
    for x, h, c in [(5, 22, GRN1), (8, 28, GRN2), (11, 24, GRN1), (3, 14, GRN0), (13, 16, GRN0)]:
        d.polygon([(x, 30), (x + 2, 30), (x + 1, 30 - h)], fill=c); L(d, [(x + 1, 30), (x + 1, 32 - h)], AMB1 if c != GRN0 else GRN1)
    out.append(save(im, "snake_plant"))
    for f in (0, 1):                                                          # aquarium
        im, d = new(40, 40)
        R(d, 1, 3, 38, 24, C("3f8fc4")); R(d, 1, 3, 38, 5, C("8fd0f0")); R(d, 1, 21, 38, 24, CREAM2)
        L(d, [(8, 21), (8, 14)], GRN2); L(d, [(10, 21), (11, 12)], GRN1); L(d, [(30, 21), (29, 15)], GRN2)
        for x, y, c in [(14 + f * 3, 10, AMB1), (26 - f * 2, 15, PINK1), (20 + f, 18, WHITE)]:
            R(d, x, y, x + 3, y + 1, c); P(d, x + 4, y, c); P(d, x + 4, y + 1, c)
        P(d, 33, 9 - f * 2, WHITE); P(d, 34, 14 - f * 2, WHITE)
        R(d, 1, 1, 38, 2, DK1); R(d, 1, 25, 38, 26, DK1); R(d, 2, 27, 37, 36, W1); R(d, 2, 27, 37, 28, W2); R(d, 4, 37, 6, 38, W0); R(d, 33, 37, 35, 38, W0)
        out.append(save(im, "aquarium" if f == 0 else "aquarium_1"))
    im, d = new(26, 42)                                                       # mini fridge
    R(d, 1, 1, 24, 38, C("d9e6ea")); R(d, 1, 1, 24, 2, WHITE); R(d, 1, 13, 24, 13, GREY1); R(d, 20, 5, 21, 10, GREY0); R(d, 20, 17, 21, 26, GREY0)
    R(d, 4, 18, 9, 22, PINK1); R(d, 5, 26, 8, 29, AMB1); R(d, 3, 39, 5, 40, DK0); R(d, 20, 39, 22, 40, DK0)
    out.append(save(im, "mini_fridge"))
    im, d = new(34, 58)                                                       # cat tree
    R(d, 14, 8, 19, 52, CREAM2)
    for y in range(10, 52, 3):
        L(d, [(14, y), (19, y)], CREAM)
    R(d, 4, 5, 29, 8, LAV1); R(d, 4, 5, 29, 5, LAV2); R(d, 16, 26, 32, 29, LAV1); R(d, 16, 26, 32, 26, LAV2); R(d, 2, 52, 31, 56, LAV0); R(d, 2, 52, 31, 53, LAV1)
    L(d, [(27, 30), (27, 36)], GREY1); E(d, 25, 36, 29, 40, PINK1)
    out.append(save(im, "cat_tree"))
    im, d = new(30, 46)                                                       # telescope
    L(d, [(14, 20), (5, 43)], GREY0); L(d, [(15, 20), (24, 43)], GREY0); L(d, [(15, 20), (15, 43)], GREY0)
    d.polygon([(3, 16), (5, 20), (26, 9), (24, 4)], fill=C("d9e6ea")); d.polygon([(22, 5), (25, 11), (28, 9), (26, 3)], fill=AMB1); R(d, 2, 16, 4, 19, DK1)
    out.append(save(im, "telescope"))
    im, d = new(24, 26)                                                       # nightstand
    R(d, 1, 1, 22, 21, W1); R(d, 1, 1, 22, 2, W3); R(d, 3, 5, 20, 11, W2); R(d, 3, 13, 20, 19, W2); R(d, 10, 8, 13, 8, AMB1); R(d, 10, 16, 13, 16, AMB1)
    R(d, 3, 22, 5, 24, W0); R(d, 18, 22, 20, 24, W0)
    out.append(save(im, "nightstand"))
    im, d = new(30, 56)                                                       # arcade cabinet
    d.polygon([(3, 1), (26, 1), (26, 52), (3, 52)], fill=C("3a2f6b")); R(d, 3, 1, 26, 7, PINK0); R(d, 6, 3, 23, 5, AMB2)
    R(d, 6, 10, 23, 26, DK0); R(d, 7, 11, 22, 25, C("16324f")); R(d, 9, 20, 11, 22, GRN2); R(d, 14, 14, 15, 15, PINK1); R(d, 18, 17, 19, 18, AMB1); R(d, 12, 23, 17, 23, WHITE)
    d.polygon([(3, 28), (26, 28), (28, 33), (1, 33)], fill=C("54468c")); R(d, 8, 29, 9, 31, RED1); P(d, 16, 30, AMB1); P(d, 20, 30, TEAL1)
    R(d, 6, 37, 23, 48, C("2c2452")); R(d, 12, 40, 17, 45, DK0)
    out.append(save(im, "arcade"))
    im, d = new(32, 40)                                                       # small bookshelf
    R(d, 1, 1, 30, 36, W1); R(d, 1, 1, 30, 2, W3)
    rnd = random.Random(3)
    for y in (5, 20):
        R(d, 3, y, 28, y + 12, W0)
        x = 4
        while x < 26:
            w, h = rnd.choice([2, 3]), rnd.choice([8, 9, 10])
            R(d, x, y + 12 - h, x + w - 1, y + 12, rnd.choice([RED1, TEAL1, AMB1, LAV2, PINK1, BLUE1, CREAM]))
            x += w + rnd.choice([0, 0, 1])
    R(d, 1, 34, 30, 36, W0); R(d, 3, 37, 5, 38, W0); R(d, 26, 37, 28, 38, W0)
    out.append(save(im, "bookshelf_small"))
    return out


def more_top():
    out = []
    im, d = new(14, 18)                                                       # globe
    E(d, 2, 1, 11, 10, BLUE1); R(d, 4, 3, 6, 5, GRN2); R(d, 7, 5, 9, 8, GRN2); P(d, 5, 7, GRN2); d.arc([1, 0, 12, 11], 300, 100, fill=AMB1)
    R(d, 6, 12, 7, 14, AMB0); R(d, 3, 15, 10, 16, W1)
    out.append(save(im, "globe"))
    im, d = new(12, 12)                                                       # alarm clock
    E(d, 1, 2, 10, 10, RED1); E(d, 3, 4, 8, 8, CREAM); P(d, 5, 6, OUT); P(d, 5, 5, OUT); P(d, 6, 6, OUT); R(d, 1, 1, 3, 2, GREY2); R(d, 8, 1, 10, 2, GREY2); P(d, 2, 10, DK1); P(d, 9, 10, DK1)
    out.append(save(im, "alarm_clock"))
    im, d = new(12, 14)                                                       # photo frame
    R(d, 1, 1, 10, 11, W2); R(d, 3, 3, 8, 9, C("8fc0ea")); R(d, 3, 7, 8, 9, GRN2); P(d, 7, 4, AMB2); L(d, [(8, 12), (9, 12)], W0)
    out.append(save(im, "photo_frame"))
    im, d = new(15, 12)                                                       # teapot
    E(d, 3, 3, 11, 10, TEAL1); R(d, 5, 2, 9, 3, TEAL0); P(d, 7, 1, AMB1); L(d, [(1, 5), (3, 7)], TEAL1); d.arc([10, 4, 14, 9], 270, 90, fill=TEAL1); R(d, 5, 5, 6, 6, TEAL2)
    out.append(save(im, "teapot"))
    im, d = new(14, 12)                                                       # headphones
    d.arc([2, 1, 11, 12], 180, 360, fill=DK2, width=2); R(d, 1, 6, 3, 10, PINK1); R(d, 10, 6, 12, 10, PINK1)
    out.append(save(im, "headphones"))
    im, d = new(18, 9)                                                        # game console
    R(d, 1, 2, 16, 7, GREY2); R(d, 1, 2, 4, 7, TEAL1); R(d, 13, 2, 16, 7, RED1); R(d, 5, 3, 12, 6, DK0); P(d, 2, 4, DK0); P(d, 14, 4, DK0)
    out.append(save(im, "game_console"))
    im, d = new(14, 16)                                                       # plush bear
    E(d, 3, 7, 10, 14, W3); E(d, 3, 2, 10, 8, W3); E(d, 2, 1, 4, 3, W3); E(d, 9, 1, 11, 3, W3); E(d, 5, 5, 8, 7, CREAM); P(d, 5, 4, OUT); P(d, 8, 4, OUT); P(d, 6, 6, OUT)
    R(d, 5, 10, 8, 12, CREAM); R(d, 2, 12, 4, 14, W3); R(d, 9, 12, 11, 14, W3)
    out.append(save(im, "plush_bear"))
    im, d = new(13, 14)                                                       # snow globe
    E(d, 2, 1, 10, 9, C("bfe3f7")); R(d, 5, 5, 7, 8, GRN1); P(d, 6, 4, GRN2); P(d, 4, 3, WHITE); P(d, 8, 5, WHITE); P(d, 7, 2, WHITE); R(d, 2, 10, 10, 12, RED0)
    out.append(save(im, "snow_globe"))
    im, d = new(11, 15)                                                       # fairy jar
    R(d, 2, 4, 8, 12, C("5a6d8c")); R(d, 3, 2, 7, 3, W2); P(d, 4, 6, AMB2); P(d, 6, 8, AMB2); P(d, 3, 10, AMB2); P(d, 7, 5, AMB2); P(d, 5, 11, AMB2); R(d, 2, 4, 2, 12, C("8fa3c4"))
    out.append(save(im, "fairy_jar"))
    im, d = new(16, 14)                                                       # terrarium
    d.polygon([(2, 12), (2, 6), (8, 1), (14, 6), (14, 12)], fill=C("9fc7d6")); R(d, 3, 9, 13, 12, W1); E(d, 4, 5, 8, 9, GRN2); E(d, 8, 6, 12, 9, GRN1); L(d, [(8, 1), (8, 12)], WHITE)
    out.append(save(im, "terrarium"))
    im, d = new(20, 12)                                                       # typewriter
    R(d, 2, 5, 17, 10, TEAL0); R(d, 4, 7, 15, 9, DK0); R(d, 5, 1, 14, 5, CREAM); R(d, 1, 3, 3, 4, GREY1); R(d, 16, 3, 18, 4, GREY1)
    for x in range(5, 15, 2):
        P(d, x, 8, CREAM)
    out.append(save(im, "typewriter"))
    im, d = new(14, 11)                                                       # camera
    R(d, 1, 3, 12, 9, DK1); R(d, 3, 1, 6, 2, DK2); E(d, 5, 3, 10, 8, GREY2); E(d, 6, 4, 9, 7, BLUE0); P(d, 11, 4, AMB1)
    out.append(save(im, "camera"))
    im, d = new(13, 20)                                                       # vase
    d.polygon([(4, 18), (3, 13), (5, 9), (7, 9), (9, 13), (8, 18)], fill=BLUE1); R(d, 5, 9, 7, 9, BLUE2)
    L(d, [(6, 9), (6, 4)], GRN1); L(d, [(5, 9), (3, 5)], GRN1); L(d, [(7, 9), (9, 5)], GRN1); E(d, 5, 1, 7, 4, PINK1); E(d, 1, 3, 4, 6, AMB1); E(d, 8, 3, 11, 6, RED1)
    out.append(save(im, "vase"))
    im, d = new(14, 10)                                                       # ramen
    d.polygon([(1, 3), (12, 3), (10, 8), (3, 8)], fill=RED1); R(d, 2, 3, 11, 3, CREAM); R(d, 4, 2, 6, 2, AMB1); P(d, 8, 2, GRN2); L(d, [(9, 3), (13, 0)], W2)
    out.append(save(im, "ramen"))
    im, d = new(20, 14)                                                       # radio
    R(d, 1, 3, 18, 12, W2); R(d, 1, 3, 18, 4, W3); E(d, 3, 5, 9, 11, DK1); E(d, 5, 7, 7, 9, GREY0); R(d, 11, 6, 16, 8, CREAM); P(d, 13, 7, RED1); P(d, 12, 10, AMB1); P(d, 15, 10, AMB1); L(d, [(14, 3), (18, 0)], GREY2)
    out.append(save(im, "radio"))
    return out


def more_wall():
    out = []
    im, d = new(24, 30)                                                       # city poster
    R(d, 1, 1, 22, 28, C("f08c5a")); R(d, 1, 1, 22, 12, C("f5b27a")); E(d, 8, 6, 15, 13, AMB2)
    for x, h in [(2, 10), (6, 15), (10, 8), (14, 13), (18, 11)]:
        R(d, x, 28 - h, x + 3, 28, C("3a2f6b")); P(d, x + 1, 30 - h, AMB2)
    out.append(save(im, "poster_city"))
    im, d = new(22, 28)                                                       # botanical print
    R(d, 1, 1, 20, 26, W3); R(d, 3, 3, 18, 24, CREAM); L(d, [(10, 22), (10, 8)], GRN0)
    for y, s in [(10, -1), (13, 1), (16, -1), (19, 1)]:
        E(d, 10 + (s * 5 if s < 0 else 1), y - 2, 10 + (s if s < 0 else 5), y + 1, GRN1)
    out.append(save(im, "print_botanical"))
    im, d = new(30, 14)                                                       # pennant
    d.polygon([(1, 1), (28, 6), (1, 12)], fill=RED1); d.polygon([(1, 1), (6, 2), (6, 11), (1, 12)], fill=CREAM); R(d, 9, 5, 18, 7, AMB2)
    out.append(save(im, "pennant"))
    im, d = new(34, 26)                                                       # corkboard
    R(d, 1, 1, 32, 24, W2); R(d, 3, 3, 30, 22, C("c79b6b")); R(d, 5, 5, 12, 12, CREAM); R(d, 15, 6, 22, 11, PINK1); R(d, 24, 5, 29, 13, BLUE2); R(d, 7, 14, 15, 20, AMB2); R(d, 18, 14, 27, 20, WHITE)
    for x, y in [(8, 5), (18, 6), (26, 5), (11, 14), (22, 14)]:
        P(d, x, y, RED0)
    out.append(save(im, "corkboard"))
    im, d = new(20, 20)                                                       # round mirror
    E(d, 1, 1, 18, 18, AMB1); E(d, 3, 3, 16, 16, C("a9cfe6")); L(d, [(6, 11), (11, 6)], WHITE)
    out.append(save(im, "mirror_round"))
    im, d = new(18, 34)                                                       # hanging plant
    L(d, [(8, 1), (3, 14)], CREAM2); L(d, [(9, 1), (14, 14)], CREAM2); R(d, 4, 14, 13, 20, CLAY1); R(d, 3, 14, 14, 15, C("dc9a73"))
    E(d, 3, 8, 14, 15, GRN1); L(d, [(4, 15), (3, 28)], GRN2); L(d, [(13, 15), (15, 25)], GRN2); L(d, [(8, 20), (8, 31)], GRN1)
    for x, y in [(2, 22), (4, 26), (14, 20), (16, 24), (7, 26), (9, 30)]:
        R(d, x, y, x + 1, y + 1, GRN2)
    out.append(save(im, "hanging_plant"))
    im, d = new(12, 18)                                                       # wall sconce
    d.polygon([(2, 2), (9, 2), (11, 10), (0, 10)], fill=AMB1); R(d, 3, 2, 8, 3, AMB2); R(d, 5, 11, 6, 15, GREY0); R(d, 3, 15, 8, 16, GREY0)
    out.append(save(im, "sconce"))
    im, d = new(64, 22)                                                       # paper lanterns
    L(d, [(1, 2), (20, 5), (42, 5), (62, 2)], DK1)
    for x, c, c2 in [(8, RED1, RED0), (26, AMB1, AMB0), (44, PINK1, PINK0)]:
        E(d, x, 7, x + 11, 19, c); L(d, [(x + 3, 8), (x + 3, 18)], c2); L(d, [(x + 8, 8), (x + 8, 18)], c2); R(d, x + 4, 5, x + 7, 6, DK1)
    out.append(save(im, "paper_lanterns"))
    im, d = new(18, 22)                                                       # calendar
    R(d, 1, 3, 16, 20, WHITE); R(d, 1, 3, 16, 7, RED1); P(d, 4, 2, GREY0); P(d, 13, 2, GREY0)
    for y in (10, 13, 16):
        for x in range(3, 15, 3):
            P(d, x, y, GREY1)
    R(d, 9, 13, 10, 14, RED1)
    out.append(save(im, "calendar"))
    im, d = new(40, 46)                                                       # tapestry
    R(d, 1, 1, 38, 2, W1); R(d, 3, 3, 36, 40, C("2c3a73")); E(d, 13, 12, 26, 25, AMB2); E(d, 17, 11, 29, 22, C("2c3a73"))
    for x, y in [(8, 9), (30, 12), (10, 28), (28, 30), (20, 33), (7, 19)]:
        P(d, x, y, WHITE)
    for x in range(4, 36, 4):
        L(d, [(x, 41), (x, 44)], AMB1)
    out.append(save(im, "tapestry"))
    im, d = new(60, 20)                                                       # polaroids
    L(d, [(1, 2), (30, 6), (58, 2)], CREAM2)
    for i, (x, c) in enumerate([(5, BLUE2), (19, PINK1), (33, GRN2), (46, AMB1)]):
        y = 5 + (1 if i in (1, 2) else 0)
        R(d, x, y, x + 8, y + 11, WHITE); R(d, x + 1, y + 1, x + 7, y + 7, c); P(d, x + 4, y - 1, RED0)
    out.append(save(im, "polaroids"))
    im, d = new(24, 24)                                                       # neon heart
    for dx in (0, 1):
        d.line([(11, 20), (3, 11), (3, 6), (6, 3), (9, 3), (11 + dx, 6), (14, 3), (17, 3), (20, 6), (20, 11), (12, 20)], fill=C("ff7fb0"))
    out.append(save(im, "neon_heart", ol=False))
    im, d = new(12, 40)                                                       # skateboard deck
    d.rounded_rectangle([2, 1, 9, 38], radius=4, fill=TEAL1); R(d, 4, 8, 7, 10, AMB2); d.polygon([(3, 16), (8, 16), (5, 26)], fill=PINK1); R(d, 4, 30, 7, 31, WHITE)
    out.append(save(im, "skate_deck"))
    im, d = new(40, 18)                                                       # trophy shelf
    R(d, 1, 13, 38, 15, W2); R(d, 1, 13, 38, 13, W3); R(d, 6, 16, 7, 17, W0); R(d, 32, 16, 33, 17, W0)
    R(d, 5, 5, 10, 9, AMB1); R(d, 7, 10, 8, 11, AMB0); R(d, 5, 12, 10, 12, AMB0); E(d, 15, 6, 21, 12, BLUE1); R(d, 26, 4, 28, 12, PINK1); R(d, 29, 6, 31, 12, TEAL1); R(d, 32, 3, 34, 12, AMB2)
    out.append(save(im, "trophy_shelf"))
    return out


def more_rugs():
    out = []
    im, d = new(70, 22)
    d.polygon([(8, 1), (68, 1), (61, 20), (1, 20)], fill=CREAM)
    for row in range(4):
        for col in range(8):
            if (row + col) % 2 == 0:
                x = 8 + col * 7.5 - row * 1.8
                d.polygon([(x, 1 + row * 5), (x + 7.5, 1 + row * 5), (x + 5.7, 6 + row * 5), (x - 1.8, 6 + row * 5)], fill=TEAL1)
    out.append(save(im, "rug_check", ol=False))
    im, d = new(60, 22)
    E(d, 1, 1, 58, 20, C("1f2550")); E(d, 4, 3, 55, 18, C("2c3a73"))
    for x, y in [(14, 8), (24, 13), (38, 7), (46, 13), (30, 5), (20, 5), (34, 15)]:
        P(d, x, y, AMB2); P(d, x + 1, y, AMB2)
    E(d, 26, 8, 33, 13, AMB2); E(d, 28, 7, 35, 12, C("2c3a73"))
    out.append(save(im, "rug_star", ol=False))
    im, d = new(60, 22)
    E(d, 2, 2, 57, 19, WHITE); E(d, 1, 6, 20, 18, WHITE); E(d, 40, 3, 58, 16, WHITE); E(d, 14, 1, 44, 12, WHITE)
    for x, y in [(12, 10), (25, 14), (36, 8), (46, 12), (20, 6), (30, 17)]:
        L(d, [(x, y), (x + 3, y + 1)], CREAM2)
    out.append(save(im, "rug_fur", ol=False))
    return out


def windows():
    im, d = new(52, 50)
    R(d, 1, 1, 50, 42, W2); R(d, 5, 5, 46, 38, (0, 0, 0, 0)); R(d, 1, 1, 50, 2, W3); R(d, 1, 41, 50, 42, W0)
    R(d, 25, 5, 26, 38, W2); R(d, 5, 21, 46, 22, W2); R(d, 0, 43, 51, 47, W3); R(d, 0, 46, 51, 47, W1)
    im.save(os.path.join(SPR, "window_small.png"))
    im, d = new(172, 70)
    R(d, 1, 1, 170, 62, DK1); R(d, 5, 5, 166, 58, (0, 0, 0, 0)); R(d, 1, 1, 170, 2, DK2); R(d, 1, 61, 170, 62, DK0)
    for x in (44, 85, 126):
        R(d, x, 5, x + 1, 58, DK1)
    R(d, 5, 18, 166, 19, DK1); R(d, 0, 63, 171, 67, DK2); R(d, 0, 66, 171, 67, DK0)
    im.save(os.path.join(SPR, "window_wide.png"))


def more_icons():
    I = WHITE
    icon("rooms", lambda d: (d.polygon([(8, 2), (14, 7), (2, 7)], fill=I), d.rectangle([4, 7, 12, 13], outline=I), d.rectangle([7, 10, 9, 13], fill=I)))
    icon("collapse", lambda d: d.line([(4, 8), (11, 8)], fill=I, width=2))
    icon("expand", lambda d: (d.line([(4, 8), (11, 8)], fill=I, width=2), d.line([(7, 4), (7, 11)], fill=I, width=2)))
    icon("star", lambda d: d.polygon([(8, 1), (10, 6), (15, 6), (11, 9), (13, 14), (8, 11), (3, 14), (5, 9), (1, 6), (6, 6)], fill=AMB1))
    icon("check", lambda d: d.line([(3, 8), (6, 11), (12, 4)], fill=GRN2, width=2))
    icon("lock", lambda d: (d.rectangle([4, 7, 11, 13], fill=GREY1), d.arc([5, 2, 10, 10], 180, 360, fill=GREY1, width=2)))
    src = Image.open(os.path.join(ROOT, "icon.png"))
    src.save(os.path.join(ROOT, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])


if __name__ == "__main__":
    imgs = [bed(), desk(), chair(), bookshelf(), plant_big(), floor_lamp(), beanbag(), side_table(), sofa(),
            guitar(), fireplace(), fireplace(1), cat(0, False), cat(1, False), cat(0, True), cat(1, True),
            cat_up(0, True), cat_up(1, True), cat_up(0, False), cat_up(1, False), desk_lamp(),
            monitor(1), monitor(2), monitor(0), laptop(), mug(), books_stack(), record_player(), record_player(1),
            candle(), candle(1), succulent(), lava_lamp(), lava_lamp(1), poster_moon(), poster_wave(), frame_cat(),
            wall_shelf(), string_lights(), string_lights(1), wall_clock(), neon_moon(), window_frame(), curtains(),
            rug_round(), rug_stripe()]
    for pose in ("idle", "type", "rest", "sleep"):
        imgs += [avatar(pose, 0), avatar(pose, 1)]
    imgs += more_floor() + more_top() + more_wall() + more_rugs()
    windows()
    sway("plant_big", 28, "plant_big_1"); sway("snake_plant", 30, "snake_plant_1"); sway("hanging_plant", 34, "hanging_plant_1")
    variants("bed", "lavender", ["teal", "rose", "amber"])
    variants("chair", "lavender", ["teal", "rose", "slate"])
    variants("curtains", "lavender", ["teal", "rose", "amber"])
    variants("rug_round", "lavender", ["teal", "rose"])
    variants("sofa", "teal", ["lavender", "rose", "slate"])
    variants("beanbag", "rose", ["teal", "lavender", "amber"])
    variants("armchair", "amber", ["teal", "rose", "lavender"])
    variants("floor_cushion", "teal", ["rose", "lavender", "amber"])
    variants("cat_tree", "lavender", ["teal", "rose"])
    for pose in ("idle", "type", "rest", "sleep"):
        for f in (0, 1):
            variants("avatar_%s_%d" % (pose, f), "lavender", ["teal", "rose", "amber"])
    icons()
    app_icon()
    more_icons()
    sheet(imgs)
    print("wrote %d base sprites, %d files" % (len(imgs), len(os.listdir(SPR))))
