#!/usr/bin/env python3
"""Prepare Whiskey Richard's full-animation-batch downloads for runtime.

Reuses the anchor/scale helpers from prepare_peggy_batch.py (which stays
unchanged for Peggy) and supplies Richard's own source folder, output folder,
runtime prefix, and per-clip config. Richard's strips are spaced unevenly and
several figures touch, so this script replaces the pitch/min-coverage slicer
with 8-connected component segmentation: each figure is one component, touching
figures are split at the thinnest central column, and tiny orphan slivers left
by the split are dropped. See prep_clip_seg() below.

Source sheets are read-only; everything is written to richard_prepared/.
All 40 Richard sheets are true-alpha PNGs (no JPEG masking needed).

Frame counts were verified visually against enlarged sheets. The draft sheets
render Richard at different art scales, so each clip's h_ref is measured from
the bandana (a rigid, identity-defining feature): max connected red-area across
the sheet vs the approved idle sheet. Snapping every clip to 74 (the Peggy
policy) would make the smaller-drawn sheets 20-35% too large on screen.
2026-11-15: six action sheets (forward, forward_ex, jump_light, jump_heavy,
meth, air) were recalibrated from foot-to-head height instead, because the
bandana is occluded or angled in those poses and the red-area estimate made
them render 15-48% larger than the idle body. Those hrefs are marked below.
"""
import json
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prepare_peggy_batch as pp  # noqa: E402

ROOT = ("/home/lch/Projects/sidewalk-showdown/art/source/Characters/"
        "Animations/generated/full_animation_batch_01/richard")
OUT = os.path.join(os.path.dirname(ROOT.rstrip("/")), "richard_prepared")
RUNTIME_PREFIX = "res://art/characters/whiskey_richard/clips"

# n        frame count (rows, cols) for multi-row sheets
# href     source standing-height equivalent (74 = reads at the idle art scale)
# enabled  false = prepared but gated off / unmapped
CONFIG = {
    # --- core movement / defence / reactions (PNG, side-facing) ---
    "walk_forward":  dict(file="richard_walk_forward_draft_sheet.png", n=[2, 3], href=78, enabled=True,
                          note="side-facing walk cycle"),
    "walk_backward": dict(file="richard_walk_backward_draft_sheet.png", n=6, href=65, enabled=True,
                          note="side-facing walk cycle"),
    "crouch_down":   dict(file="richard_crouch_down_draft_sheet.png", n=3, href=74, enabled=True, note=""),
    "crouch_hold":   dict(file="richard_crouch_hold_draft_sheet.png", n=2, href=74, enabled=True, note=""),
    "crouch_up":     dict(file="richard_crouch_up_draft_sheet.png", n=3, href=74, enabled=True, note=""),
    "jump_start":    dict(file="richard_jump_start_draft_sheet.png", n=2, href=74, enabled=True, note=""),
    "jump_rise":     dict(file="richard_jump_rise_draft_sheet.png", n=2, href=74, enabled=True, note=""),
    "jump_fall":     dict(file="richard_jump_fall_draft_sheet.png", n=2, href=71, enabled=True,
                          note="airborne-only sheet; h_ref measured from bandana"),
    "land":          dict(file="richard_land_draft_sheet.png", n=3, href=81, enabled=True,
                          note="sheet drawn slightly larger than idle; h_ref measured from bandana"),
    "block_stand":   dict(file="richard_block_stand_draft_sheet.png", n=2, href=74, enabled=True, note=""),
    "block_crouch":  dict(file="richard_block_crouch_draft_sheet.png", n=2, href=71, enabled=True,
                          note="crouched guard; h_ref measured from bandana"),
    "hitstun_stand": dict(file="richard_hitstun_stand_draft_sheet.png", n=3, href=73, enabled=True, note=""),
    "hitstun_crouch": dict(file="richard_hitstun_crouch_draft_sheet.png", n=3, href=68, enabled=True,
                          note="crouched recoil; h_ref measured from bandana"),
    "hitstun_air":   dict(file="richard_hitstun_air_draft_sheet.png", n=3, href=74, enabled=True, note=""),
    "blockstun_stand": dict(file="richard_blockstun_stand_draft_sheet.png", n=2, href=74, enabled=True, note=""),
    "blockstun_crouch": dict(file="richard_blockstun_crouch_draft_sheet.png", n=2, href=74, enabled=True, note=""),
    "knockdown":     dict(file="richard_knockdown_draft_sheet.png", n=4, href=63, enabled=True,
                          note="reclining frames; h_ref measured from bandana"),
    "wake_up":       dict(file="richard_wake_up_draft_sheet.png", n=4, href=73, enabled=True, note=""),
    "throw_tech":    dict(file="richard_throw_tech_draft_sheet.png", n=3, href=74, enabled=True, note=""),
    "ko_air":        dict(file="richard_ko_air_draft_sheet.png", n=3, href=67, enabled=True,
                          note="airborne KO; h_ref measured from bandana"),
    "ko_ground":     dict(file="richard_ko_ground_draft_sheet.png", n=3, href=74, enabled=True, note=""),
    "win":           dict(file="richard_win_draft_sheet.png", n=4, href=74, enabled=True, note=""),
    # --- attacks (PNG) ---
    "light":         dict(file="richard_light_draft_sheet.png", n=5, href=74, enabled=True, note=""),
    "heavy":         dict(file="richard_heavy_draft_sheet.png", n=5, href=70, enabled=True,
                          note="bottle windup above head; h_ref measured from bandana"),
    "crouch_light":  dict(file="richard_crouch_light_draft_sheet.png", n=6, href=59, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "crouch_heavy":  dict(file="richard_crouch_heavy_draft_sheet.png", n=6, href=57, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "jump_light":    dict(file="richard_jump_light_draft_sheet.png", n=6, href=65, enabled=True,  # head-height calibrated
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "jump_heavy":    dict(file="richard_jump_heavy_draft_sheet.png", n=6, href=70, enabled=True,  # head-height calibrated
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "neutral":       dict(file="richard_neutral_draft_sheet.png", n=6, href=58, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "forward":       dict(file="richard_forward_draft_sheet.png", n=6, href=72, enabled=True,  # head-height calibrated
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "down":          dict(file="richard_down_draft_sheet.png", n=6, href=50, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "back":          dict(file="richard_back_draft_sheet.png", n=6, href=60, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "air":           dict(file="richard_air_draft_sheet.png", n=6, href=71, enabled=True,  # head-height calibrated
                          note="all poses airborne; h_ref measured from bandana"),
    "grab":          dict(file="richard_grab_draft_sheet.png", n=6, href=62, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "command_grab":  dict(file="richard_command_grab_draft_sheet.png", n=6, href=53, enabled=True,
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "neutral_ex":    dict(file="richard_neutral_ex_draft_sheet.png", n=5, href=73, enabled=True, note=""),
    "forward_ex":    dict(file="richard_forward_ex_draft_sheet.png", n=6, href=75, enabled=True,  # head-height calibrated
                          note="sheet drawn smaller than idle; h_ref measured from bandana"),
    "meth":          dict(file="richard_meth_draft_sheet.png", n=6, href=56, enabled=True,  # head-height calibrated
                          note="crouched super; sheet drawn smaller than idle; h_ref measured from bandana"),
    # --- optional, prepared but unmapped ---
    "stage_intro":   dict(file="richard_stage_intro_draft_sheet.png", n=4, href=73, enabled=False,
                          note="optional; no runtime hook yet"),
    "throw_target":  dict(file="richard_throw_target_draft_sheet.png", n=3, href=51, enabled=False,
                          note="optional throw-victim clip; no paired throw cinematic, unmapped"),
}


def _components(alpha, min_px=12):
    """8-connected opaque components; returns (label_map, list of dicts).

    Richard's strips are true-alpha PNGs, so each figure is normally one
    component. Unlike the pitch slicer, this lets us take a whole figure even
    when the animation's spacing is uneven (e.g. grab) or when a figure's
    extended arm reaches past the even-pitch line.
    """
    h, w = alpha.shape
    a = alpha > 8
    lab = np.zeros((h, w), dtype=np.int32)
    comps = []
    cid = 0
    for y in range(h):
        for x in range(w):
            if not a[y, x] or lab[y, x]:
                continue
            cid += 1
            q = deque([(y, x)])
            lab[y, x] = cid
            xs = []
            ys = []
            while q:
                cy, cx = q.popleft()
                xs.append(cx)
                ys.append(cy)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = cy + dy, cx + dx
                        if (0 <= ny < h and 0 <= nx < w
                                and a[ny, nx] and not lab[ny, nx]):
                            lab[ny, nx] = cid
                            q.append((ny, nx))
            if len(xs) >= min_px:
                xsa = np.array(xs)
                ysa = np.array(ys)
                comps.append({
                    "id": cid, "n": len(xs),
                    "x0": int(xsa.min()), "x1": int(xsa.max()) + 1,
                    "y0": int(ysa.min()), "y1": int(ysa.max()) + 1,
                    "cx": float(xsa.mean()), "cy": float(ysa.mean()),
                })
    return lab, comps


def _row_groups(comps, rows):
    """Cluster components into sheet rows by their vertical centres."""
    if rows == 1:
        return [sorted(comps, key=lambda c: c["cx"])]
    order = sorted(comps, key=lambda c: c["cy"])
    gaps = sorted(((order[i + 1]["cy"] - order[i]["cy"], i)
                   for i in range(len(order) - 1)), reverse=True)[: rows - 1]
    cut_idx = sorted(i for _gap, i in gaps)
    groups = []
    prev = -1
    for ci in cut_idx + [len(order) - 1]:
        groups.append(order[prev + 1:ci + 1])
        prev = ci
    return [sorted(g, key=lambda c: c["cx"]) for g in groups]


def _mask_of(comp, lab):
    return (lab == comp["id"])


def _strip_small_parts(mask, min_area=20, ratio=0.18):
    """Drop disconnected specks left over from a touch-split.

    When two touching figures are cut apart, a sliver of one figure's boot or
    hair can land on the other side of the cut as an isolated island. Keep the
    cel's main body and only substantial satellite parts (e.g. a genuinely
    detached hand), never tiny slivers.
    """
    lab, comps = _components(mask.astype(np.uint8) * 255, min_px=1)
    if len(comps) <= 1:
        return mask
    largest = max(c["n"] for c in comps)
    keep = {c["id"] for c in comps
            if c["n"] >= max(min_area, largest * ratio)}
    out = np.zeros_like(mask)
    for cid in keep:
        out |= (lab == cid)
    return out


def _split_mask(mask):
    """Split a touching-figure mask at its thinnest central column."""
    ys, xs = np.nonzero(mask)
    x0, x1 = int(xs.min()), int(xs.max()) + 1
    span = x1 - x0
    cov = np.bincount(xs, minlength=mask.shape[1])
    lo = x0 + max(1, int(span * 0.30))
    hi = x1 - max(1, int(span * 0.30))
    if hi <= lo:
        lo, hi = x0 + 1, x1 - 1
    centre = (x0 + x1) / 2.0
    cut = min(range(lo, hi + 1), key=lambda x: (int(cov[x]), abs(x - centre)))
    m1 = mask.copy()
    m1[:, cut:] = False
    m2 = mask.copy()
    m2[:, :cut] = False
    return _strip_small_parts(m1), _strip_small_parts(m2)


def _cels_for_row(masks, cols):
    """Reduce/expand a row's masks to exactly `cols` figure masks."""
    cels = list(masks)
    while len(cels) > cols:  # stray specks
        cels.pop(min(range(len(cels)), key=lambda i: int(cels[i].sum())))
    while len(cels) < cols:  # touching figures
        def width(m):
            xs = np.nonzero(m)[1]
            return int(xs.max() - xs.min() + 1) if xs.size else 0
        i = max(range(len(cels)), key=lambda j: width(cels[j]))
        m = cels.pop(i)
        cels[i:i] = list(_split_mask(m))
    return cels


def prep_clip_seg(key, cfg):
    """Component-segmented counterpart to prepare_peggy_batch.prep_clip."""
    path = os.path.join(ROOT, cfg["file"])
    arr, was_jpeg = pp.load_rgba(path)
    alpha = arr[:, :, 3]
    H, W = alpha.shape
    rows, cols = (1, cfg["n"]) if isinstance(cfg["n"], int) else cfg["n"]
    notes = [] if not cfg["note"] else [cfg["note"]]
    if was_jpeg:
        notes.append("opaque JPEG source; exterior-connected masking applied")

    lab, comps = _components(alpha)
    groups = _row_groups(comps, rows)
    before = [len(g) for g in groups]
    row_masks = []
    for g in groups:
        row_masks.append(_cels_for_row([_mask_of(c, lab) for c in g], cols))
    if before != [cols] * rows:
        notes.append("component segmentation %r -> %d solo figures (touch-split/speck-drop)"
                     % (before, rows * cols))
    masks = [m for row in row_masks for m in row]
    total = len(masks)

    boxes = []
    foot_xs = []
    for m in masks:
        ys, xs = np.nonzero(m)
        if len(xs) == 0:
            boxes.append(None)
            foot_xs.append(None)
            notes.append("empty cel in segmentation")
            continue
        boxes.append((int(xs.min()), int(ys.min()),
                      int(xs.max()) + 1, int(ys.max()) + 1))
        foot_xs.append(pp.foot_anchor_x(arr[:, :, 3] * m, 0))

    row_baselines = []
    for r in range(rows):
        rbs = [b[3] for b in boxes[r * cols:(r + 1) * cols] if b]
        row_baselines.append(max(rbs) if rbs else pp.STANDING_H)
    baseline = max(row_baselines)

    h_ref = float(cfg["href"])
    notes.append("h_ref supplied by config (bandana-area scale vs idle)")

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
    valid = [e for e in extents if e]
    anchor_x = int(np.ceil(max(max(e["left"], e["right"]) for e in valid))) + 1
    above = max(e["above"] for e in valid)
    below = max(e["below"] for e in valid)
    anchor_y = above + 2
    cel_h = anchor_y + below + 3
    cel_w = 2 * anchor_x + 2
    anchor = (anchor_x, anchor_y)

    canvas = Image.new("RGBA", (cel_w * total, cel_h), (0, 0, 0, 0))
    for i, m in enumerate(masks):
        b = boxes[i]
        if not b or foot_xs[i] is None:
            continue
        rb = row_baselines[i // cols]
        clean = arr.copy()
        clean[:, :, 3] = np.where(m, arr[:, :, 3], 0).astype(np.uint8)
        region = Image.fromarray(clean[b[1]:b[3], b[0]:b[2]])
        px = int(round(anchor_x - (foot_xs[i] - b[0])))
        py = int(round(anchor_y - (rb - b[1])))
        canvas.paste(region, (i * cel_w + px, py))

    out_path = os.path.join(OUT, key + ".png")
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
        "runtime": "%s/%s.png" % (RUNTIME_PREFIX.rstrip("/"), key),
    }
    return entry, canvas


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = []
    for key in sorted(CONFIG):
        entry, _canvas = prep_clip_seg(key, CONFIG[key])
        entry["flags"].append(
            "frame count verified visually; h_ref from bandana-area scale vs idle")
        manifest.append(entry)
        print(json.dumps(entry))
    with open(os.path.join(OUT, "richard_clips_manifest.json"), "w") as f:
        json.dump({"standing_reference_px": pp.STANDING_H, "clips": manifest}, f, indent=1)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
