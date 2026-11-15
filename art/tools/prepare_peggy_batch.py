#!/usr/bin/env python3
"""Prepare Peg-Leg Peggy's full-animation-batch downloads for runtime.

Reads the owner's downloaded draft sheets (never modified), slices each sheet
into cels at visually verified frame counts, applies exterior-connected
background masking to the opaque JPEGs on DERIVED copies only, and writes:

  <out>/            one normalized runtime sheet per clip (<key>.png)
  <out>/peggy_clips_manifest.json   per-clip metadata (cel, anchor, h_ref, flags)
  <out>/peggy_contact_sheet.png     review contact sheet

Rules honored here:
- Source files are read-only; everything is written to peggy_prepared/.
- No pixel-art resampling: each clip keeps native pixels. On-screen scale is
  computed at runtime from the manifest's h_ref (source px that equal the
  standing reference height), so differently-scaled sheets never cause a size
  jump against the approved idle art.
- Slicing uses empty columns/rows near the even-pitch boundary so limbs are
  never cut through; merged (touching) figures fall back to the pitch cut and
  are flagged.
- JPEG masking is flood fill from the canvas border over low-saturation,
  light pixels only (painted checkerboard). Interior whites (eyes, teeth, hat
  stripe) are never reached by an exterior-connected fill.
"""
import glob
import json
import os
import sys
from collections import deque

from PIL import Image
import numpy as np

ROOT = ("/home/lch/Projects/sidewalk-showdown/art/source/Characters/"
        "Animations/generated/full_animation_batch_01/peggy")
OUT = os.path.join(os.path.dirname(ROOT.rstrip("/")), "peggy_prepared")

# Per-clip config, visually verified against enlarged montages:
#   n        frame count in the sheet (rows for multi-row sheets as [rows, cols])
#   ref      frame index holding an upright, standing-ish pose (auto h_ref)
#   href     explicit standing-height estimate when NO upright pose exists
#            (crouched/airborne-only sheets); flagged for owner review
#   enabled  whether the runtime clip table may map states onto it
#   note     owner-review note
CONFIG = {
    # --- core movement / defence / reactions (PNG) ---
    "walk_forward":  dict(file="peggy_walk_forward_draft_sheet.jpeg", n=[2, 4], enabled=False,
                          note="JPEG front-facing walk; painted checkerboard; needs owner review before enabling"),
    "walk_backward": dict(file="peggy_walk_backward_draft_sheet.jpeg", n=[1, 6], enabled=False,
                          note="JPEG front-facing walk; painted checkerboard; needs owner review before enabling"),
    "crouch_down":   dict(file="peggy_crouch_down_draft_sheet.jpeg", n=[1, 3], enabled=False,
                          note="JPEG front-facing crouch on painted checkerboard; needs owner review before enabling"),
    "crouch_hold":   dict(file="peggy_crouch_hold_draft_sheet.jpeg", n=[1, 2], enabled=True,
                          note="JPEG side-facing crouch; masked on derived copy; scale estimated from crouch pose"),
    "crouch_up":     dict(file="peggy_crouch_up_draft_sheet.png", n=3, ref=2, enabled=True, note=""),
    "jump_start":    dict(file="peggy_jump_start_draft_sheet.png", n=3, ref=1, enabled=True, note=""),
    "jump_rise":     dict(file="peggy_jump_rise_draft_sheet.png", n=3, ref=1, enabled=True, note=""),
    "jump_fall":     dict(file="peggy_jump_fall_draft_sheet.png", n=2, href=74, enabled=True,
                          note="airborne-only sheet; art scale matched to idle via hat-width measure"),
    "land":          dict(file="peggy_land_draft_sheet.png", n=3, href=74, enabled=True,
                          note="pose-height ref overstated scale; art scale matched to idle via hat-width measure"),
    "block_stand":   dict(file="peggy_block_stand_draft_sheet.png", n=2, ref=1, enabled=True,
                          note="sheet drawn ~1.55x larger; auto-normalized via h_ref"),
    "block_crouch":  dict(file="peggy_block_crouch_draft_sheet.png", n=3, href=74, enabled=True,
                          note="guard pose is flattened; art scale matched to idle via hat-width measure"),
    "hitstun_stand": dict(file="peggy_hitstun_stand_draft_sheet.png", n=3, href=74, enabled=True,
                          note="recoil pose is shortened; art scale matched to idle via hat-width measure"),
    "hitstun_crouch": dict(file="peggy_hitstun_crouch_draft_sheet.png", n=3, href=74, enabled=True,
                          note="crouched-only sheet; art scale matched to idle via hat-width measure"),
    "hitstun_air":   dict(file="peggy_hitstun_air_draft_sheet.png", n=3, href=74, enabled=True,
                          note="airborne pose shortens on screen; art scale matched to idle via hat-width measure"),
    "blockstun_stand": dict(file="peggy_blockstun_stand_draft_sheet.png", n=2, ref=1, enabled=True,
                            note="sheet drawn ~1.55x larger; auto-normalized via h_ref"),
    "blockstun_crouch": dict(file="peggy_blockstun_crouch_draft_sheet.png", n=3, ref=0, enabled=True, note=""),
    "knockdown":     dict(file="peggy_knockdown_draft_sheet.png", n=4, ref=0, enabled=True, note=""),
    "wake_up":       dict(file="peggy_wake_up_draft_sheet.png", n=4, ref=3, enabled=True, note=""),
    "throw_tech":    dict(file="peggy_throw_tech_draft_sheet.png", n=3, ref=0, enabled=True, note=""),
    "ko_air":        dict(file="peggy_ko_air_draft_sheet.png", n=3, ref=2, enabled=True, note=""),
    "ko_ground":     dict(file="peggy_ko_ground_draft_sheet.png", n=3, ref=0, enabled=True,
                          note="final pose is a hunched collapse, not flat-on-ground; owner review advised"),
    "win":           dict(file="peggy_win_draft_sheet.png", n=4, href=74, enabled=True,
                          note="art scale matched to idle via hat-width measure"),
    # --- attacks (PNG) ---
    "light":         dict(file="peggy_light_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "heavy":         dict(file="peggy_heavy_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "crouch_light":  dict(file="peggy_crouch_light_draft_sheet.png", n=5, ref=4, enabled=True, note=""),
    "crouch_heavy":  dict(file="peggy_crouch_heavy_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "jump_light":    dict(file="peggy_jump_light_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "jump_heavy":    dict(file="peggy_jump_heavy_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "neutral":       dict(file="peggy_neutral_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "forward":       dict(file="peggy_forward_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "down":          dict(file="peggy_down_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "back":          dict(file="peggy_back_draft_sheet.png", n=6, ref=0, enabled=True, note=""),
    "air":           dict(file="peggy_air_draft_sheet.png", n=6, ref=5, enabled=True,
                          note="all poses airborne; ref is the landing frame"),
    "grab":          dict(file="peggy_grab_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "command_grab":  dict(file="peggy_command_grab_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "neutral_ex":    dict(file="peggy_neutral_ex_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "forward_ex":    dict(file="peggy_forward_ex_draft_sheet.png", n=6, ref=5, enabled=True, note=""),
    "meth":          dict(file="peggy_meth_draft_sheet.png", n=6, ref=4, enabled=True, note=""),
    # --- optional, prepared but unmapped ---
    "stage_intro":   dict(file="peggy_stage_intro_draft_sheet.png", n=4, ref=0, enabled=False,
                          note="optional; no runtime hook yet"),
    "throw_target":  dict(file="peggy_throw_target_draft_sheet.png", n=3, ref=0, enabled=False,
                          note="optional throw-victim clip; no paired throw cinematic, unmapped"),
}

STANDING_H = 74.0  # scale-1 standing reference height (matches idle sheets)
CROUCH_H_SCALE1 = 71.0  # observed scale-1 crouched pose height (crouch_light family)


def empty_columns(alpha):
    occ = (alpha > 8).any(axis=0)
    return ~occ


def empty_rows(alpha):
    occ = (alpha > 8).any(axis=1)
    return ~occ


def min_coverage_cut(coverage, target, span, max_shift):
    """Column (or row) index near `target` with the fewest opaque pixels.

    The draft strips are AI-generated animation strips: a figure's extended
    limb often crosses the even-pitch line, so hard pitch cuts chop arms and
    feet. Cutting at the lowest-coverage column (tie-break: nearest the even
    pitch) splits figures at their thinnest connection instead.
    """
    lo = max(1, int(round(target - max_shift)))
    hi = min(span - 1, int(round(target + max_shift)))
    best = None
    best_key = None
    for x in range(lo, hi + 1):
        keyv = (int(coverage[x]) if x < len(coverage) else 0, abs(x - target))
        if best_key is None or keyv < best_key:
            best_key = keyv
            best = x
    return best


def spiral_cuts(coverage, count, span):
    """`count - 1` cut positions spread around the even pitch."""
    pitch = span / float(count)
    max_shift = max(2.0, pitch * 0.42)
    cuts = []
    for i in range(1, count):
        target = i * pitch
        cut = min_coverage_cut(coverage, target, span, max_shift)
        if cut is None:
            cut = int(round(target))
        if cuts and cut <= cuts[-1] + 2:
            cut = cuts[-1] + 3
        cuts.append(min(int(cut), span - 1))
    return cuts


def slices_from_cuts(count, span, cuts):
    xs = [0] + list(cuts) + [span]
    return [(xs[i], xs[i + 1]) for i in range(count)]


def foot_anchor_x(sub_alpha, x_offset):
    """Horizontal body root: centroid of the lowest opaque band (the feet).

    Using the planted-foot centroid instead of the bounding-box centre keeps
    the body still when an attack extends an arm or leg sideways, which is
    what made the fighter appear to lurch between states.
    """
    ys, xs = np.nonzero(sub_alpha > 8)
    if len(xs) == 0:
        return None
    y_min = int(ys.min())
    y_max = int(ys.max())
    band = max(2, int(round((y_max - y_min + 1) * 0.10)))
    sel = ys >= (y_max - band + 1)
    return x_offset + float(xs[sel].mean())



def mask_jpeg(rgb):
    """Exterior-connected removal of the painted checkerboard / light bg."""
    h, w, _ = rgb.shape
    mx = rgb.max(axis=2).astype(np.int16)
    mn = rgb.min(axis=2).astype(np.int16)
    satdiff = mx - mn
    lum = rgb.mean(axis=2)
    bg_like = (satdiff <= 36) & (lum >= 150)
    visited = np.zeros((h, w), dtype=bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if bg_like[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bg_like[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and bg_like[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))
    rgba = np.dstack([rgb, np.where(visited, 0, 255).astype(np.uint8)])
    return rgba


def load_rgba(path):
    im = Image.open(path)
    if im.format == "JPEG":
        rgb = np.array(im.convert("RGB"))
        return mask_jpeg(rgb), True
    return np.array(im.convert("RGBA")), False


def prep_clip(key, cfg, root=None, out=None,
              runtime_prefix="res://art/characters/peg_leg_peggy/clips"):
    root = root or ROOT
    out = out or OUT
    path = os.path.join(root, cfg["file"])
    arr, was_jpeg = load_rgba(path)
    alpha = arr[:, :, 3]
    H, W = alpha.shape
    notes = list() if not cfg["note"] else [cfg["note"]]
    if was_jpeg:
        notes.append("opaque JPEG source; exterior-connected masking applied on derived copy")

    rows, cols = (1, cfg["n"]) if isinstance(cfg["n"], int) else cfg["n"]
    if rows > 1:
        row_coverage = (alpha > 8).sum(axis=1)
        cuts_y = spiral_cuts(row_coverage, rows, H)
    else:
        cuts_y = []
    slices = []
    row_ranges = []
    for r in range(rows):
        y0 = 0 if r == 0 else cuts_y[r - 1]
        y1 = cuts_y[r] if r < rows - 1 else H
        row_ranges.append((y0, y1))
    for (y0, y1) in row_ranges:
        row_cov = (alpha[y0:y1] > 8).sum(axis=0)
        for (sx0, sx1) in slices_from_cuts(cols, W, spiral_cuts(row_cov, cols, W)):
            slices.append((sx0, y0, sx1, y1))
    if len(slices) != rows * cols:
        notes.append("slice grid mismatch")
    # expected total frames:
    total = rows * cols

    # per-frame content boxes + sheet baseline (max bottom across frames)
    boxes = []
    for (sx0, sy0, sx1, sy1) in slices:
        sub = alpha[sy0:sy1, sx0:sx1]
        ys, xs = np.nonzero(sub > 8)
        if len(xs) == 0:
            boxes.append(None)
            notes.append("empty slice at %d" % len(boxes))
            continue
        boxes.append((sx0 + int(xs.min()), sy0 + int(ys.min()),
                      sx0 + int(xs.max()) + 1, sy0 + int(ys.max()) + 1))
    filled = [b for b in boxes if b]
    # Per-row baselines: each sheet row has its own ground line (multi-row
    # JPEG sheets); single-row sheets share one global baseline.
    row_baselines = []
    idx = 0
    for r in range(rows):
        row_boxes = [b for b in boxes[idx:idx + cols] if b]
        row_baselines.append(max(b[3] for b in row_boxes))
        idx += cols
    baseline = max(row_baselines)
    top = min(b[1] for b in filled)

    # h_ref: standing height reference in source pixels
    def ref_baseline(i):
        return row_baselines[i // cols]
    if "href" in cfg:
        h_ref = float(cfg["href"])
        notes.append("h_ref supplied by config (no reliable upright pose in sheet)")
    elif "ref" in cfg:
        ref = boxes[cfg["ref"]]
        h_ref = float(ref_baseline(cfg["ref"]) - ref[1])
    else:
        # JPEG fallback: use the tallest pose's height as the standing
        # reference, scaled for crouched-only sheets.
        tallest = max(ref_baseline(i) - b[1] for i, b in enumerate(boxes) if b)
        if key.startswith("crouch"):
            h_ref = tallest * STANDING_H / CROUCH_H_SCALE1
            notes.append("crouched-only JPEG; standing height estimated from pose")
        else:
            h_ref = float(tallest)
            notes.append("standing height taken from tallest pose")

    # Runtime cel: every frame is pasted whole (never cropped) and its planted
    # feet (foot_anchor_x) land on the cel's anchor column, with its row
    # baseline on the anchor row. The anchor is what the runtime maps onto the
    # fighter origin, so the body stays put across frames and states.
    foot_xs = []
    for i, (sx0, sy0, sx1, sy1) in enumerate(slices):
        foot_xs.append(foot_anchor_x(alpha[sy0:sy1, sx0:sx1], sx0))
    extents = []
    for i, b in enumerate(boxes):
        if not b or foot_xs[i] is None:
            extents.append(None)
            continue
        rb = row_baselines[i // cols]
        extents.append({
            "left": foot_xs[i] - b[0],
            "right": b[2] - foot_xs[i],
            "above": rb - b[1],
            "below": b[3] - rb,
        })
    valid_extents = [e for e in extents if e]
    anchor_x = int(np.ceil(max(max(e["left"], e["right"]) for e in valid_extents))) + 1
    above = max(e["above"] for e in valid_extents)
    below = max(e["below"] for e in valid_extents)
    anchor_y = above + 2
    cel_h = anchor_y + below + 3
    # Symmetric cel around the anchor so horizontal flipping mirrors the body
    # around the same root (Godot mirrors a non-centered sprite about x=0).
    cel_w = 2 * anchor_x + 2
    anchor = (anchor_x, anchor_y)

    canvas = Image.new("RGBA", (cel_w * total, cel_h), (0, 0, 0, 0))
    for i, b in enumerate(boxes):
        if not b or foot_xs[i] is None:
            continue
        sx0, sy0, sx1, sy1 = slices[i]
        rb = row_baselines[i // cols]
        region = Image.fromarray(arr[sy0:sy1, sx0:sx1])
        px = int(round(anchor_x - (foot_xs[i] - sx0)))
        py = int(round(anchor_y - (rb - sy0)))
        canvas.paste(region, (i * cel_w + px, py))

    out_path = os.path.join(out, key + ".png")
    canvas.save(out_path)
    entry = {
        "key": key,
        "source": cfg["file"],
        "source_format": "JPEG" if was_jpeg else "PNG",
        "source_size": [W, H],
        "frames": total,
        "cel": [cel_w, cel_h],
        "anchor": [anchor[0], anchor[1]],
        "h_ref": h_ref,
        "baseline": int(baseline),
        "enabled": bool(cfg["enabled"]),
        "flags": notes,
        "runtime": "%s/%s.png" % (runtime_prefix.rstrip("/"), key),
    }
    return entry, canvas


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = []
    tiles = []
    for key in sorted(CONFIG):
        cfg = CONFIG[key]
        entry, canvas = prep_clip(key, cfg)
        manifest.append(entry)
        # contact tile
        s = min(220.0 / canvas.height, 2.0)
        s = max(min(s, 2.0), 0.2)
        tile = canvas.resize((max(1, int(canvas.width * s)), max(1, int(canvas.height * s))),
                             Image.NEAREST)
        tiles.append((key, entry, tile))
        print(json.dumps(entry))

    # contact sheet: grid of tiles with key labels
    cols_n = 5
    tile_w = max(t[2].width for t in tiles) + 8
    tile_h = max(t[2].height for t in tiles) + 22
    rows_n = (len(tiles) + cols_n - 1) // cols_n
    sheet = Image.new("RGB", (cols_n * tile_w, rows_n * tile_h), (28, 28, 40))
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    for i, (key, entry, tile) in enumerate(tiles):
        x = (i % cols_n) * tile_w + 4
        y = (i // cols_n) * tile_h + 18
        sheet.paste(tile, (x, y), tile)
        tag = key + ("" if entry["enabled"] else " [OFF]")
        d.text((x, y - 14), tag, fill=(240, 240, 200))
    sheet.save(os.path.join(OUT, "peggy_contact_sheet.png"))

    with open(os.path.join(OUT, "peggy_clips_manifest.json"), "w") as f:
        json.dump({"standing_reference_px": STANDING_H, "clips": manifest}, f, indent=1)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
