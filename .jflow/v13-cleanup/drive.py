#!/usr/bin/env python3
"""Checker driver for v13-cleanup rows 5 and 7.

  python3 .jflow/v13-cleanup/drive.py contrast [--actual]
  python3 .jflow/v13-cleanup/drive.py assets BASE_SHA

contrast: for each stale text in Panel.qml, blends its effective alpha over the
theme background and prints the lowest WCAG ratio per text across every
/usr/share/omarchy/themes/*/colors.toml. Without --actual it uses `foreground`
for every text, as row 5 is written. With --actual it uses the colors the panel
really draws: Qt.darker(foreground, 1.4) for PanelSectionHeader and `accent`
for the launch link.

assets: lists assets/, prints format, size and dimensions, and SSIM against the
PNG of the same family at BASE_SHA, as row 7 is written.
"""
import colorsys
import glob
import os
import re
import subprocess
import sys
import tempfile

THEMES = "/usr/share/omarchy/themes"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# name: (stale alpha, fresh alpha, color role), read from Panel.qml at HEAD.
TEXTS = {
    "countdown": (0.7, 1, "fg"),
    "mission": (0.7, 1, "fg"),
    "field label": (0.649, 0.65, "fg"),
    "field value": (0.7, 1, "fg"),
    "launch link": (0.98, 1, "accent"),
    "upcoming date": (0.7, 1, "fg"),
    "upcoming mission": (0.7, 1, "fg"),
    "upcoming rocket": (0.649, 0.65, "fg"),
    "section header": (0.85, 1, "header"),
}


def hexrgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def lum(c):
    def ch(v):
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(v) for v in c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def blend(fg, bg, a):
    return tuple(f * a + b * (1 - a) for f, b in zip(fg, bg))


def qt_darker(c, factor=1.4):
    # QColor::darker: HSV value divided by factor, hue and saturation kept.
    h, s, v = colorsys.rgb_to_hsv(*c)
    return colorsys.hsv_to_rgb(h, s, v / factor)


def theme_colors(path):
    vals = {}
    for line in open(path):
        m = re.match(r'\s*([a-z_]+)\s*=\s*"(#[0-9a-fA-F]{6})', line)
        if m:
            vals[m.group(1)] = m.group(2)
    return vals


def contrast(actual):
    files = sorted(glob.glob(os.path.join(THEMES, "*", "colors.toml")))
    print(f"themes: {len(files)}  mode: {'actual colors' if actual else 'foreground, as row 5 is written'}")
    worst_all = (99, "", "")
    for name, (stale, fresh, role) in TEXTS.items():
        worst = (99, "")
        for f in files:
            t = theme_colors(f)
            bg, fg = hexrgb(t["background"]), hexrgb(t["foreground"])
            color = fg
            if actual and role == "header":
                color = qt_darker(fg)
            elif actual and role == "accent":
                color = hexrgb(t.get("accent", t["foreground"]))
            r = ratio(blend(color, bg, stale), bg)
            theme = os.path.basename(os.path.dirname(f))
            if r < worst[0]:
                worst = (r, theme)
        flag = "ok" if worst[0] >= 3.0 and stale < fresh else "FAIL"
        print(f"  {name:17s} stale {stale:<5} fresh {fresh:<5} lowest {worst[0]:.2f} ({worst[1]}) {flag}")
        if worst[0] < worst_all[0]:
            worst_all = (worst[0], name, worst[1])
    print(f"lowest overall: {worst_all[0]:.2f} {worst_all[1]} in {worst_all[2]}")


def assets(base):
    os.chdir(ROOT)
    files = sorted(os.listdir("assets"))
    print("assets/:", files)
    tmp = tempfile.mkdtemp()
    for f in files:
        p = os.path.join("assets", f)
        info = subprocess.run(["magick", "identify", "-format", "%m %wx%h", p],
                              capture_output=True, text=True).stdout
        size = os.path.getsize(p)
        stem = f.rsplit(".", 1)[0]
        old = os.path.join(tmp, stem + ".png")
        with open(old, "wb") as out:
            subprocess.run(["git", "show", f"{base}:assets/{stem}.png"], stdout=out, check=True)
        # Compare at the new size; SSIM needs equal dimensions.
        dims = info.split()[1]
        resized = os.path.join(tmp, stem + "-base.png")
        subprocess.run(["magick", old, "-resize", dims + "!", resized], check=True)
        cmp = subprocess.run(["magick", "compare", "-metric", "SSIM", p, resized, "null:"],
                             capture_output=True, text=True)
        print(f"  {f}: {info}, {size} bytes ({size / 1024:.0f} KiB, {size / 1000:.0f} kB), "
              f"base PNG {subprocess.run(['magick', 'identify', '-format', '%wx%h', old], capture_output=True, text=True).stdout}, "
              f"compare SSIM output: {cmp.stderr.strip()}")


if __name__ == "__main__":
    if sys.argv[1] == "contrast":
        contrast("--actual" in sys.argv)
    elif sys.argv[1] == "assets":
        assets(sys.argv[2])
