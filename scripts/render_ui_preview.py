#!/usr/bin/env python3
"""Render ui_preview.lua frame traces with Pillow; not actual WoW rendering.

Usage: python3 scripts/render_ui_preview.py build/ui-preview/before.json
Requires Pillow. Output remains under ignored build/ui-preview. The trace comes
from executed UI.lua; font metrics, templates, layering and clipping approximate
WoW. Synthetic names/data only. Do not treat this as client compatibility proof.
"""
import argparse
import json
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

POINTS = {"TOPLEFT": (0, 0), "TOP": (.5, 0), "TOPRIGHT": (1, 0),
          "LEFT": (0, .5), "CENTER": (.5, .5), "RIGHT": (1, .5),
          "BOTTOMLEFT": (0, 1), "BOTTOM": (.5, 1), "BOTTOMRIGHT": (1, 1)}


def clean(text):
    return re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", text).replace("||", "|")


def color(value, default):
    return tuple(round(v * 255) for v in value[:3]) if value else default


def fontsize(node):
    return node.get("_renderScale", 1) * node.get("fontSize", {"GameFontNormalLarge": 16,
                                "GameFontHighlightSmall": 12}.get(node.get("font"), 13))


def font(node):
    size = max(8, round(fontsize(node)))
    for path in ("/System/Library/Fonts/Supplemental/Arial.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def wrapped(text, width, face):
    out = []
    for line in clean(text).split("\n"):
        row = ""
        for word in line.split(" "):
            candidate = (row + " " + word).lstrip()
            if row and face.getlength(candidate) > width:
                out.append(row)
                row = word
            else:
                row = candidate
        while row and face.getlength(row) > width:
            cut = len(row)
            while cut > 1 and face.getlength(row[:cut]) > width:
                cut -= 1
            out.append(row[:cut])
            row = row[cut:]
        out.append(row)
    return out


def render(case, path, label):
    width, height = case["width"], case["height"]
    nodes = {n["id"]: n for n in case["nodes"]}
    boxes = {1: (0, 0, width, height)}

    def box(nid, stack=()):
        if nid in boxes:
            return boxes[nid]
        if nid in stack:
            return (0, 0, 400, 20)
        n = nodes[nid]
        parent = box(n.get("parent", 1), stack + (nid,))
        w = n.get("w", parent[2] if n["kind"] == "FontString" else 100)
        text = clean(n.get("text", ""))
        h = n.get("h", sum(max(1, int(len(s) * fontsize(n) * .48 / max(1, w) + .999))
                            for s in text.split("\n")) * (fontsize(n) + 3))
        anchors = n.get("anchors", [])
        if isinstance(anchors, dict):
            anchors = []
        if not anchors and n.get("scrollParent"):
            anchors = [{"point": "TOPLEFT", "relative": n["scrollParent"],
                        "relativePoint": "TOPLEFT", "x": 0, "y": 0}]
        equations = []
        for a in anchors:
            rel = box(a["relative"], stack + (nid,))
            rp = POINTS.get(a["relativePoint"], (0, 0))
            p = POINTS.get(a["point"], (0, 0))
            equations.append((p, rel[0] + rp[0] * rel[2] + a.get("x", 0),
                              rel[1] + rp[1] * rel[3] - a.get("y", 0)))
        for axis, explicit in ((0, "w"), (1, "h")):
            if explicit not in n and len(equations) > 1:
                a, b = equations[0], equations[-1]
                delta = b[0][axis] - a[0][axis]
                if delta:
                    value = (b[axis + 1] - a[axis + 1]) / delta
                    if axis == 0:
                        w = value
                    else:
                        h = value
        if equations:
            p, x, y = equations[0]
            x -= p[0] * w
            y -= p[1] * h
        else:
            x, y = parent[:2]
        boxes[nid] = (round(x), round(y), max(1, round(w)), max(1, round(h)))
        return boxes[nid]

    def visible(n):
        return n.get("shown", True) and (not n.get("parent") or visible(nodes[n["parent"]]))

    # Approximate inherited scaling around the top-level frame's anchor. The
    # trace keeps source coordinates, while PNG geometry uses displayed pixels.
    for nid in nodes:
        box(nid)
    raw_boxes = dict(boxes)
    for nid, n in nodes.items():
        if nid == 1:
            continue
        root = n
        while root.get("parent") and root["parent"] != 1:
            root = nodes[root["parent"]]
        scale = root.get("scale", 1)
        n["_renderScale"] = scale
        if scale == 1:
            continue
        rx, ry, rw, rh = raw_boxes[root["id"]]
        anchors = root.get("anchors", [])
        if isinstance(anchors, list) and anchors:
            a = anchors[0]
            p = POINTS.get(a["point"], (0, 0))
            rp = POINTS.get(a["relativePoint"], (0, 0))
            nx = rp[0]*width + a.get("x", 0)*scale-p[0]*rw*scale
            ny = rp[1]*height-a.get("y", 0)*scale-p[1]*rh*scale
        else:
            nx, ny = rx, ry
        x, y, w, h = raw_boxes[nid]
        boxes[nid] = (round(nx+(x-rx)*scale), round(ny+(y-ry)*scale),
                      max(1, round(w*scale)), max(1, round(h*scale)))

    image = Image.new("RGB", (width, height + 70), (30, 36, 40))
    draw = ImageDraw.Draw(image)
    draw.text((16, 12), f"OFFLINE SIMULATION • {label} • {case['name']}", fill=(245, 218, 145), font=font({}))
    draw.text((16, 32), "Actual UI.lua frame trace; approximate fonts/templates; synthetic data; not WoW rendering.", fill=(200, 205, 210), font=font({}))
    if case.get("error"):
        draw.text((16, 50), "SYNTHETIC STATE ERROR: " + case["error"], fill=(255, 160, 140), font=font({}))
    surface = Image.new("RGBA", (width, height), (20, 29, 32, 255))
    for n in case["nodes"]:
        if n["id"] == 1 or not visible(n):
            continue
        x, y, w, h = box(n["id"])
        layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        if n.get("bg") or n.get("kind") in ("Button", "EditBox"):
            bg = color(n.get("bg"), (42, 47, 51))
            edge = color(n.get("border"), (94, 103, 104))
            d.rectangle((0, 0, w-1, h-1), fill=bg, outline=edge)
        if n.get("text"):
            face = font(n)
            fg = color(n.get("color"), (232, 217, 171) if n.get("font", "").startswith("GameFontNormal") else (225, 230, 231))
            if n.get("enabled") is False:
                fg = (125, 132, 136)
            lines = wrapped(n["text"], max(1, w-8 if n["kind"] == "Button" else w), face)
            yy = max(2, (h-(fontsize(n)+3))//2) if n["kind"] == "Button" else 0
            for line in lines:
                xx = max(2, (w-face.getlength(line))/2) if n["kind"] == "Button" else 0
                d.text((xx, yy), line, fill=fg, font=face)
                yy += fontsize(n)+3
        # Scroll viewports clip descendants. Other clipping uses each text node's
        # assigned height; real frame/template behavior must be checked in WoW.
        clip = (0, 0, width, height)
        parent_id = n.get("parent")
        while parent_id:
            p = nodes[parent_id]
            if p["kind"] == "ScrollFrame":
                px, py, pw, ph = box(parent_id)
                clip = (max(clip[0], px), max(clip[1], py), min(clip[2], px+pw), min(clip[3], py+ph))
            parent_id = p.get("parent")
        left, top, right, bottom = max(x, clip[0]), max(y, clip[1]), min(x+w, clip[2]), min(y+h, clip[3])
        if right > left and bottom > top:
            surface.alpha_composite(layer.crop((left-x, top-y, right-x, bottom-y)), (left, top))
    image.paste(surface.convert("RGB"), (0, 70))
    image.save(path)
    # Contact sheets crop around the main panel; standalone files preserve the
    # viewport, including evidence of clipping on the small-viewport fixture.
    panels = [box(n["id"]) for n in case["nodes"]
              if n.get("role") in ("feedbackFrame",) and visible(n)]
    if not panels:
        panels = [box(n["id"]) for n in case["nodes"] if n.get("role") == "frame"]
    if panels:
        x, y, w, h = panels[-1]
        crop = surface.crop((max(0, x-16), max(0, y-16), min(width, x+w+16), min(height, y+h+16))).convert("RGB")
        result = Image.new("RGB", (max(530, crop.width), crop.height+70), (30, 36, 40))
        rd = ImageDraw.Draw(result)
        rd.text((10, 10), f"OFFLINE • {label} • {case['name']}", fill=(245, 218, 145), font=font({}))
        rd.text((10, 30), "Synthetic frame trace; approximate, not WoW rendering", fill=(200, 205, 210), font=font({}))
        if case.get("error"):
            rd.text((10, 48), "Source error in this synthetic state (see full image)", fill=(255, 160, 140), font=font({}))
        result.paste(crop, ((result.width-crop.width)//2, 70))
        return result
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("trace", type=Path)
    args = parser.parse_args()
    label = args.trace.stem
    folder = args.trace.parent
    thumbs = []
    for case in json.loads(args.trace.read_text()):
        if case.get("error"):
            print(f"SOURCE ERROR [{label}/{case['name']}]: {case['error']}")
        img = render(case, folder / f"{label}-{case['name']}.png", label)
        img.save(folder / f"{label}-{case['name']}-panel.png")
        img.thumbnail((640, 770))
        thumbs.append(img)
    sheet = Image.new("RGB", (1280, 770*((len(thumbs)+1)//2)), (20, 29, 32))
    for i, img in enumerate(thumbs):
        sheet.paste(img, ((i % 2)*640, (i//2)*770))
    sheet.save(folder / f"{label}-contact-sheet.png")
    if label == "after" and (folder / "before-compact-grouped-panel.png").exists():
        pairs = []
        for state in ("compact-grouped", "expanded-grouped", "feedback"):
            pairs.append([Image.open(folder / f"{phase}-{state}-panel.png").convert("RGB")
                          for phase in ("before", "after")])
        cell_width = max(640, max(img.width for pair in pairs for img in pair))
        heights = [max(img.height for img in pair)+24 for pair in pairs]
        comparison = Image.new("RGB", (cell_width*2, sum(heights)), (20, 29, 32))
        y = 0
        for pair, height in zip(pairs, heights):
            for col, img in enumerate(pair):
                comparison.paste(img, (col*cell_width+(cell_width-img.width)//2, y))
            y += height
        comparison.save(folder / "before-after-comparison.png")
    print(f"Rendered {len(thumbs)} synthetic frame-trace previews for {label}")

if __name__ == "__main__":
    main()
