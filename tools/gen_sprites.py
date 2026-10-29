"""Generator sprite placeholder untuk Gang Roh (tanpa library tambahan).

Jalankan dari folder proyek:  python tools/gen_sprites.py
Sprite boleh ditimpa dengan buatan sendiri asal ukuran frame sama (lihat CLAUDE.md).
"""
import os
import random
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "sprites")
CLEAR = (0, 0, 0, 0)


def rgb(r, g, b, a=255):
    return (r, g, b, a)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[CLEAR] * w for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x] if 0 <= x < self.w and 0 <= y < self.h else CLEAR

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.set(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def blit(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                c = other.px[y][x]
                if c[3] > 0:
                    self.set(ox + x, oy + y, c)

    def outline(self, c):
        solid = [[p[3] > 0 for p in row] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if solid[y][x]:
                    continue
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < self.w and 0 <= ny < self.h and solid[ny][nx]:
                        self.px[y][x] = c
                        break

    def save(self, name):
        raw = b"".join(b"\x00" + bytes(v for p in row for v in p) for row in self.px)

        def chunk(tag, data):
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
        with open(os.path.join(OUT, name), "wb") as f:
            f.write(png)
        print("ditulis:", name, f"{self.w}x{self.h}")


def sheet(frames):
    w, h = frames[0].w, frames[0].h
    s = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.blit(f, i * w, 0)
    return s


OUT_C = rgb(42, 36, 48)
GLASS, GLASS_L, FRAME = rgb(44, 70, 78), rgb(78, 112, 118), rgb(64, 64, 74)
LIGHT, LIGHT_D = rgb(255, 214, 120), rgb(240, 170, 90)
WHITE = rgb(238, 236, 228)

# Tiga gaya gedung: keramik abu (ref 1), beton oranye (ref 2), krem
STYLES = [
    dict(wall=rgb(198, 200, 204), wall_d=rgb(160, 162, 172), line=rgb(184, 186, 192), band=rgb(70, 150, 150),
         sign=rgb(214, 92, 140), sign_d=rgb(160, 60, 104), awn=rgb(80, 150, 150), awn_d=rgb(50, 108, 114)),
    dict(wall=rgb(206, 124, 72), wall_d=rgb(164, 88, 54), line=rgb(192, 112, 64), band=rgb(150, 76, 48),
         sign=rgb(236, 232, 220), sign_d=rgb(200, 60, 60), awn=rgb(214, 58, 64), awn_d=rgb(156, 38, 52)),
    dict(wall=rgb(228, 214, 184), wall_d=rgb(190, 172, 142), line=rgb(214, 200, 170), band=rgb(110, 120, 150),
         sign=rgb(70, 110, 150), sign_d=rgb(44, 74, 110), awn=rgb(236, 186, 70), awn_d=rgb(186, 136, 40)),
]
GOODS = [rgb(230, 80, 70), rgb(250, 200, 70), rgb(120, 190, 110), rgb(90, 150, 220), rgb(240, 240, 230), rgb(230, 130, 170)]


def shop(si, lights=False):
    s = STYLES[si]
    r = random.Random(si)
    c = Canvas(48, 32)
    if not lights:
        c.rect(0, 0, 47, 31, s["wall"])
        for y in range(1, 32, 4):
            c.rect(0, y, 47, y, s["line"])
        c.rect(0, 0, 0, 31, OUT_C); c.rect(47, 0, 47, 31, OUT_C)
        # papan nama
        c.rect(3, 2, 44, 8, s["sign"])
        c.rect(3, 2, 44, 2, s["sign_d"]); c.rect(3, 8, 44, 8, s["sign_d"])
        c.rect(3, 2, 3, 8, s["sign_d"]); c.rect(44, 2, 44, 8, s["sign_d"])
        txt = WHITE if si != 1 else s["sign_d"]
        for x in range(7, 32, 4):
            c.rect(x, 4, x + 2, 6, txt)
        c.rect(36, 4, 41, 6, txt)
        # awning bergaris
        for y in range(10, 15):
            for x in range(1, 47):
                stripe = (x // 4) % 2 == 0
                col = s["awn"] if stripe else (WHITE if si == 1 else s["awn_d"])
                if y == 14 and x % 4 >= 2:
                    continue
                c.set(x, y, col)
        c.rect(1, 15, 46, 15, s["wall_d"])
    # etalase
    if lights:
        c.rect(4, 18, 25, 27, LIGHT)
        c.rect(31, 21, 39, 25, LIGHT)
        return c
    c.rect(3, 17, 26, 28, FRAME)
    c.rect(4, 18, 25, 27, GLASS)
    for y in (21, 25):
        c.rect(4, y, 25, y, FRAME)
    for y in (19, 20, 22, 23, 24, 26):
        for x in range(5, 25):
            if r.random() < 0.45:
                c.set(x, y, r.choice(GOODS))
    c.line(6, 27, 12, 18, GLASS_L)
    # pintu + noren
    c.rect(30, 17, 40, 31, FRAME)
    c.rect(31, 18, 39, 31, rgb(36, 40, 50))
    c.rect(31, 21, 39, 25, GLASS)
    c.rect(31, 17, 39, 20, rgb(50, 62, 96))
    c.rect(35, 17, 35, 20, rgb(36, 44, 70))
    c.set(33, 18, WHITE); c.set(37, 18, WHITE)
    c.set(38, 27, rgb(200, 180, 120))
    c.rect(1, 29, 29, 31, s["wall_d"]); c.rect(41, 29, 46, 31, s["wall_d"])
    return c


def apt(si, lights=False):
    s = STYLES[si]
    r = random.Random(10 + si)
    c = Canvas(48, 32)
    if lights:
        for x0, x1 in ((7, 17), (19, 29), (31, 40)):
            c.rect(x0, 7, x1, 16, LIGHT)
            c.rect(x0, 7, x1, 7, LIGHT_D)
        return c
    c.rect(0, 0, 47, 31, s["wall"])
    if si == 0:
        for y in range(0, 32, 3):
            c.rect(0, y, 47, y, s["line"])
        for x in range(0, 48, 4):
            c.rect(x, 0, x, 31, s["line"])
    c.rect(0, 0, 0, 31, OUT_C); c.rect(47, 0, 47, 31, OUT_C)
    # ceruk balkon
    c.rect(3, 3, 44, 24, s["wall_d"])
    c.rect(6, 6, 41, 24, FRAME)
    for x0, x1 in ((7, 17), (19, 29), (31, 40)):
        c.rect(x0, 7, x1, 23, GLASS)
        c.line(x0 + 1, 15, x0 + 5, 8, GLASS_L)
    # tirai acak
    for x0 in (7, 19, 31):
        if r.random() < 0.6:
            c.rect(x0, 7, x0 + 3, 16, rgb(214, 206, 190))
    # pagar balkon
    c.rect(2, 17, 45, 17, OUT_C)
    for x in range(3, 45, 3):
        c.rect(x, 18, x, 24, FRAME)
    c.rect(2, 25, 45, 25, OUT_C)
    # panel depan + noda air (gaya ref 2)
    c.rect(1, 26, 46, 28, s["wall"])
    if si == 0:
        for x in range(4, 44, 9):
            c.rect(x, 27, x + 2, 27, rgb(170, 150, 170))
    if si == 1:
        for _ in range(5):
            x = r.randint(2, 45)
            c.rect(x, 26, x, 26 + r.randint(1, 4), s["wall_d"])
    c.rect(0, 29, 47, 31, s["band"])
    c.rect(0, 29, 47, 29, OUT_C)
    return c


def roof(si):
    s = STYLES[si]
    c = Canvas(48, 10)
    c.rect(0, 6, 47, 9, s["wall_d"])
    c.rect(0, 6, 47, 6, s["wall"])
    c.rect(0, 6, 0, 9, OUT_C); c.rect(47, 6, 47, 9, OUT_C)
    c.rect(1, 1, 46, 1, OUT_C)
    for x in range(1, 47, 6):
        c.rect(x, 1, x, 5, OUT_C)
    c.rect(46, 1, 46, 5, OUT_C)
    return c


def tank():
    c = Canvas(12, 14)
    c.rect(1, 1, 10, 9, rgb(150, 170, 180))
    c.rect(1, 1, 10, 1, rgb(190, 205, 212))
    c.rect(9, 2, 10, 9, rgb(118, 136, 148))
    c.rect(1, 5, 10, 5, rgb(118, 136, 148))
    c.rect(2, 10, 2, 13, FRAME); c.rect(9, 10, 9, 13, FRAME)
    c.rect(2, 12, 9, 12, FRAME)
    c.outline(OUT_C)
    return c


def ladder():
    c = Canvas(6, 32)
    c.rect(0, 0, 0, 31, OUT_C); c.rect(5, 0, 5, 31, OUT_C)
    for y in (3, 11, 19, 27):
        c.rect(1, y, 4, y, rgb(110, 112, 124))
    return c


def scaffold():
    c = Canvas(48, 32)
    c.rect(0, 0, 47, 31, rgb(70, 150, 110, 120))
    pole, plank = rgb(150, 120, 80), rgb(178, 146, 92)
    for x in (1, 24, 46):
        c.rect(x, 0, x, 31, pole)
    for y in (0, 15, 30):
        c.rect(0, y, 47, y + 1, plank)
    c.line(2, 14, 23, 2, pole); c.line(25, 29, 45, 17, pole)
    return c


def lot():
    c = Canvas(48, 16)
    c.rect(0, 13, 47, 15, rgb(126, 108, 88))
    for x in range(1, 47, 3):
        c.set(x, 13, rgb(146, 128, 104))
    for x in (2, 14, 34, 45):
        c.rect(x, 5, x, 13, rgb(120, 120, 132))
    c.rect(2, 7, 45, 7, rgb(150, 150, 160)); c.rect(2, 10, 45, 10, rgb(150, 150, 160))
    c.rect(16, 1, 32, 9, WHITE)
    c.rect(16, 1, 32, 1, rgb(200, 60, 60)); c.rect(16, 9, 32, 9, rgb(200, 60, 60))
    c.rect(16, 1, 16, 9, rgb(200, 60, 60)); c.rect(32, 1, 32, 9, rgb(200, 60, 60))
    c.rect(22, 3, 26, 7, rgb(240, 196, 72)); c.rect(23, 4, 25, 6, rgb(200, 150, 40))
    c.rect(24, 10, 24, 13, FRAME)
    return c


def shrine():
    c = Canvas(24, 30)
    c.rect(2, 25, 21, 29, rgb(150, 150, 150))
    c.rect(2, 25, 21, 25, rgb(180, 180, 178))
    c.rect(9, 19, 14, 25, rgb(150, 80, 50))
    c.rect(5, 10, 18, 20, rgb(196, 62, 50))
    c.rect(9, 13, 14, 18, rgb(40, 30, 36))
    c.set(11, 15, rgb(240, 196, 72)); c.set(12, 15, rgb(240, 196, 72))
    for y, (x0, x1) in enumerate(((7, 16), (5, 18), (3, 20), (2, 21))):
        c.rect(x0, 6 + y, x1, 6 + y, rgb(62, 52, 64))
    c.rect(7, 6, 16, 6, rgb(96, 84, 98))
    for x in range(5, 19):
        c.set(x, 11 if x % 2 else 12, WHITE)
    c.rect(3, 21, 8, 24, rgb(150, 100, 60)); c.rect(3, 21, 8, 21, rgb(180, 130, 80))
    c.outline(OUT_C)
    return c


def ac_unit(frame):
    c = Canvas(10, 8)
    c.rect(0, 0, 9, 7, rgb(230, 232, 228))
    c.rect(1, 1, 5, 6, rgb(60, 64, 80))
    blade = rgb(200, 204, 212)
    if frame == 0:
        c.rect(3, 2, 3, 5, blade); c.rect(2, 3, 4, 4, blade)
    else:
        c.set(2, 2, blade); c.set(4, 2, blade); c.set(3, 3, blade); c.set(3, 4, blade); c.set(2, 5, blade); c.set(4, 5, blade)
    for y in (2, 4):
        c.rect(7, y, 8, y, rgb(150, 160, 170))
    c.outline(OUT_C)
    return c


def plant(seed):
    r = random.Random(seed)
    c = Canvas(10, 12)
    c.rect(2, 9, 7, 11, rgb(170, 100, 60)); c.rect(2, 9, 7, 9, rgb(196, 124, 78))
    for _ in range(18):
        x, y = r.randint(1, 8), r.randint(1, 8)
        c.set(x, y, r.choice([rgb(90, 140, 70), rgb(60, 104, 62), rgb(124, 170, 90)]))
    return c


def laundry():
    c = Canvas(16, 12)
    c.rect(0, 0, 15, 0, FRAME)
    c.rect(2, 1, 6, 6, WHITE); c.rect(1, 1, 7, 2, WHITE); c.rect(2, 6, 6, 6, rgb(200, 200, 196))
    c.rect(9, 1, 13, 9, rgb(222, 100, 124)); c.rect(9, 9, 13, 9, rgb(180, 70, 96))
    return c


DOA_CORE, DOA_MID, DOA_EDGE = rgb(250, 255, 255), rgb(160, 225, 255), rgb(96, 160, 240)


def coin(frame):
    """Doa: bola cahaya biru-putih yang berdenyut (4 frame, 6x6)."""
    c = Canvas(6, 6)
    edge = [DOA_EDGE, rgb(120, 185, 250), rgb(150, 210, 255), rgb(120, 185, 250)][frame]
    c.rect(1, 1, 4, 4, edge); c.rect(2, 0, 3, 5, edge); c.rect(0, 2, 5, 3, edge)
    c.rect(1, 2, 4, 3, DOA_MID); c.rect(2, 1, 3, 4, DOA_MID)
    c.rect(2, 2, 3, 3, DOA_CORE)
    if frame == 2:
        c.set(2, 1, DOA_CORE)
    return c


def slots():
    c = Canvas(10, 5)
    for x in (1, 2, 3):
        c.set(x, 0, rgb(200, 200, 200, 200)); c.set(x, 4, rgb(200, 200, 200, 200))
    for y in (1, 2, 3):
        c.set(0, y, rgb(200, 200, 200, 200)); c.set(4, y, rgb(200, 200, 200, 200))
    c.rect(6, 0, 8, 4, DOA_EDGE); c.rect(5, 1, 9, 3, DOA_EDGE)
    c.rect(6, 1, 8, 3, DOA_MID); c.set(7, 2, DOA_CORE)
    return c


# ---------------------------------------------------------------- kucing maneki-neko
CW, CWS, COR, CBK = rgb(242, 240, 232), rgb(204, 200, 196), rgb(226, 140, 56), rgb(52, 44, 48)
CRED, CGOLD, CPINK, CEYE = rgb(200, 50, 50), rgb(240, 196, 72), rgb(232, 150, 150), rgb(40, 34, 40)
TAILS = [
    [(2, 10), (1, 9), (1, 8), (1, 7), (2, 6)],
    [(2, 10), (1, 9), (1, 8), (2, 7), (3, 6)],
    [(2, 10), (2, 9), (2, 8), (3, 7), (4, 6)],
    [(2, 10), (1, 9), (1, 8), (2, 7), (3, 6)],
]


def cat(tail=0, legs=(4, 6, 9, 11), lift=(), body_dy=0, wave=0):
    c = Canvas(16, 16)
    for i, x in enumerate(legs):
        top = 13 - (1 if i in lift else 0)
        c.rect(x, top, x, 15 - (1 if i in lift else 0), CW)
    d = body_dy
    c.rect(5, 8 + d, 10, 8 + d, CW)
    c.rect(3, 9 + d, 11, 12 + d, CW)
    c.rect(4, 13 + d, 10, 13 + d, CWS)
    c.rect(5, 9 + d, 7, 9 + d, COR); c.set(6, 10 + d, COR); c.rect(4, 11 + d, 4, 12 + d, CBK)
    for i, (x, y) in enumerate(TAILS[tail]):
        c.set(x, y + d, COR if i == len(TAILS[tail]) - 1 else CW)
    # kepala
    c.rect(9, 2 + d, 13, 2 + d, CW)
    c.rect(8, 3 + d, 14, 7 + d, CW)
    c.rect(9, 8 + d, 13, 8 + d, CW)
    c.set(9, 1 + d, CW); c.set(13, 1 + d, CW)
    c.rect(9, 3 + d, 10, 3 + d, COR); c.set(9, 4 + d, COR); c.set(13, 2 + d, CBK)
    c.set(11, 5 + d, CEYE); c.set(13, 5 + d, CEYE); c.set(14, 6 + d, CPINK)
    c.set(10, 6 + d, CPINK)
    c.rect(9, 8 + d, 12, 8 + d, CRED); c.set(11, 9 + d, CGOLD)
    if wave:
        top = 3 if wave == 1 else 5
        c.line(12, 9 + d, 14, top + d, CW)
        c.set(14, top - 1 + d, CW); c.set(15, top + d, CPINK)
    c.outline(OUT_C)
    return c


def cat_sheet():
    frames = [cat(tail=t) for t in range(4)]                                       # 0-3 diam
    frames += [cat(legs=(4, 6, 9, 11), lift=(0, 3), body_dy=0), cat(legs=(5, 6, 10, 11), body_dy=1),
               cat(legs=(4, 6, 9, 11), lift=(1, 2), body_dy=0), cat(legs=(4, 5, 9, 10), body_dy=1)]  # 4-7 jalan
    frames += [cat(lift=(0, 2), tail=1), cat(lift=(1, 3), tail=3)]                # 8-9 memanjat
    frames += [cat(wave=1, tail=2), cat(wave=2, tail=0)]                          # 10-11 melambai
    return sheet(frames)


# ---------------------------------------------------------------- latar
def city(w, h, base, win, seed, min_h, max_h):
    r = random.Random(seed)
    c = Canvas(w, h)
    x = 0
    while x < w:
        bw = r.randint(14, 30)
        bh = r.randint(min_h, max_h)
        bw = min(bw, w - x)
        c.rect(x, h - bh, x + bw - 1, h - 1, base)
        if r.random() < 0.3:
            c.rect(x + 3, h - bh - 4, x + 5, h - bh - 1, base)
        for wy in range(h - bh + 3, h - 2, 5):
            for wx in range(x + 2, x + bw - 2, 4):
                if r.random() < 0.5:
                    c.rect(wx, wy, wx + 1, wy + 1, win)
        x += bw + r.randint(0, 3)
    return c


def cloud(seed):
    r = random.Random(seed)
    c = Canvas(48, 14)
    for _ in range(6):
        cx, cy, rad = r.randint(10, 38), r.randint(6, 9), r.randint(4, 7)
        for y in range(14):
            for x in range(48):
                if (x - cx) ** 2 + ((y - cy) * 1.6) ** 2 < rad * rad:
                    c.set(x, y, rgb(240, 238, 236) if y < 9 else rgb(214, 214, 224))
    c.rect(4, 12, 44, 13, CLEAR)
    return c


def street():
    c = Canvas(32, 40)
    c.rect(0, 0, 31, 7, rgb(176, 176, 172))
    c.rect(0, 0, 31, 0, rgb(196, 196, 192))
    c.rect(0, 4, 31, 4, rgb(156, 156, 152)); c.rect(0, 0, 0, 7, rgb(156, 156, 152)); c.rect(16, 4, 16, 7, rgb(156, 156, 152))
    c.rect(0, 8, 31, 9, rgb(128, 128, 126))
    c.rect(0, 10, 31, 39, rgb(72, 72, 80))
    r = random.Random(3)
    for _ in range(30):
        c.set(r.randint(0, 31), r.randint(11, 39), rgb(86, 86, 94))
    c.rect(4, 24, 19, 25, rgb(214, 214, 204))
    return c


def button(kind):
    c = Canvas(24, 24)
    bg = rgb(20, 20, 30, 130)
    c.rect(2, 0, 21, 23, bg); c.rect(0, 2, 23, 21, bg); c.rect(1, 1, 22, 22, bg)
    fg = rgb(245, 240, 230, 230)
    if kind in ("left", "right", "up", "down"):
        for i in range(6):
            a, b = 7 + i, 11 - i
            if kind == "right":
                c.rect(a + 2, 6 + i, a + 2, 17 - i, fg)
            elif kind == "left":
                c.rect(b + 4, 6 + i, b + 4, 17 - i, fg)
            elif kind == "up":
                c.rect(6 + i, 15 - i, 17 - i, 15 - i, fg)
            else:
                c.rect(6 + i, 8 + i, 17 - i, 8 + i, fg)
    else:
        c.rect(8, 6, 15, 17, rgb(240, 196, 72)); c.rect(6, 8, 17, 15, rgb(240, 196, 72))
        c.rect(10, 9, 13, 14, rgb(186, 136, 40))
    return c


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet([shop(i) for i in range(3)]).save("shop.png")
    sheet([shop(i, True) for i in range(3)]).save("shop_lights.png")
    sheet([apt(i) for i in range(3)]).save("apt.png")
    sheet([apt(i, True) for i in range(3)]).save("apt_lights.png")
    sheet([roof(i) for i in range(3)]).save("roof.png")
    tank().save("tank.png")
    ladder().save("ladder.png")
    scaffold().save("scaffold.png")
    lot().save("lot.png")
    shrine().save("shrine.png")
    sheet([ac_unit(0), ac_unit(1)]).save("ac.png")
    sheet([plant(1), plant(2)]).save("plant.png")
    laundry().save("laundry.png")
    sheet([coin(i) for i in range(4)]).save("coin.png")
    slots().save("slots.png")
    cat_sheet().save("cat.png")
    city(160, 70, rgb(176, 168, 176), rgb(196, 190, 196), 1, 30, 66).save("city_far.png")
    city(160, 60, rgb(138, 128, 140), rgb(160, 150, 160), 2, 18, 50).save("city_mid.png")
    sheet([cloud(1), cloud(2)]).save("cloud.png")
    street().save("street.png")
    for k in ("left", "right", "up", "down", "action"):
        button(k).save(f"btn_{k}.png")


if __name__ == "__main__":
    main()
