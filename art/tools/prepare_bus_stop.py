#!/usr/bin/env python3
"""Prepare the layered Bus Stop stage art for runtime.

The owner's source art lives read-only in art/source/Stages/BusStop/. This
script copies the authored 320x180 stage layers into the Godot project at
native resolution (scale 1.0, no resampling) and derives the 80x45 stage-select
thumbnail from the sky+foreground composite with an exact 4x box downsample.

It validates only what the pipeline guarantees, never the picture content:
dimensions, binary/opaque alpha, frame counts, and a bounded per-layer palette.
The layout JSON is the source of truth for the layer positions and frame lists.
Rerunning it from unchanged sources produces byte-identical runtime assets.

Usage:
    python3 art/tools/prepare_bus_stop.py
"""
from pathlib import Path
import json
import shutil
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "art" / "source" / "Stages" / "BusStop"
OUT_DIR = ROOT / "game" / "art" / "stages" / "bus_stop"
LAYOUT_FILE = SOURCE_DIR / "bus_stop_layout.json"

VIEWPORT = (320, 180)
THUMBNAIL_SIZE = (80, 45)
CLOUD_SIZE = (640, 40)
CLOUD_POSITION = (0, 6)
FIRE_SIZE = (74, 55)
FIRE_POSITION = (166, 103)
FIRE_FRAME_COUNT = 4
SIGN_SIZE = (49, 13)
SIGN_POSITION = (6, 91)

# Source file -> (runtime file, size, alpha mode). The base composite stays a
# source-only reference; the match draws the individual layers.
COPIES = {
    "bus_stop_sky_320x180.png": ("bus_stop_sky.png", VIEWPORT, "opaque"),
    "bus_stop_clouds_640x40.png": ("bus_stop_clouds.png", CLOUD_SIZE, "binary"),
    "bus_stop_foreground_320x180.png":
        ("bus_stop_foreground.png", VIEWPORT, "binary"),
    "bus_stop_fire_f1.png": ("bus_stop_fire_f1.png", FIRE_SIZE, "binary"),
    "bus_stop_fire_f2.png": ("bus_stop_fire_f2.png", FIRE_SIZE, "binary"),
    "bus_stop_fire_f3.png": ("bus_stop_fire_f3.png", FIRE_SIZE, "binary"),
    "bus_stop_fire_f4.png": ("bus_stop_fire_f4.png", FIRE_SIZE, "binary"),
    "bus_stop_liquor_sign_on.png":
        ("bus_stop_liquor_sign_on.png", SIGN_SIZE, "binary"),
    "bus_stop_liquor_sign_off.png":
        ("bus_stop_liquor_sign_off.png", SIGN_SIZE, "binary"),
}
BASE_REFERENCE = "bus_stop_base_320x180.png"


def fail(message: str) -> None:
    raise SystemExit(f"prepare_bus_stop: {message}")


def validate_image(path: Path, expected_size: tuple[int, int],
                   alpha_mode: str, palette_check: bool = True) -> None:
    with Image.open(path) as image:
        if image.size != expected_size:
            fail(f"{path} is {image.size}, expected {expected_size}")
        if image.mode != "RGBA":
            fail(f"{path} is {image.mode}, expected RGBA")
        alpha_values = set(image.getchannel("A").get_flattened_data())
        if not alpha_values <= {0, 255}:
            fail(f"{path} has partial alpha values: {sorted(alpha_values)[:8]}")
        if alpha_mode == "opaque" and alpha_values != {255}:
            fail(f"{path} is expected to be fully opaque")
        # Indexed pixel-art layers stay well under the budget; this catches an
        # accidental photo/gradient export without inspecting the pixels.
        if palette_check:
            palette_size = len(set(image.get_flattened_data()))
            if palette_size > 256:
                fail(f"{path} has {palette_size} colours, over the 256-colour budget")


def validate_layout() -> None:
    if not LAYOUT_FILE.is_file():
        fail(f"missing layout file {LAYOUT_FILE}")
    with LAYOUT_FILE.open(encoding="utf-8") as handle:
        layout = json.load(handle)

    if tuple(layout.get("viewport", ())) != VIEWPORT:
        fail(f"layout viewport is {layout.get('viewport')}, expected {VIEWPORT}")

    clouds = layout.get("clouds", {})
    if tuple(clouds.get("size", ())) != CLOUD_SIZE \
            or tuple(clouds.get("position", ())) != CLOUD_POSITION:
        fail(f"layout cloud geometry is {clouds}, expected {CLOUD_SIZE} at {CLOUD_POSITION}")
    if clouds.get("file") not in COPIES:
        fail(f"layout cloud file {clouds.get('file')} is not a prepared asset")

    fire = layout.get("fire", {})
    fire_files = list(fire.get("files", ()))
    expected_fire = [f"bus_stop_fire_f{index}.png"
                     for index in range(1, FIRE_FRAME_COUNT + 1)]
    if fire_files != expected_fire:
        fail(f"layout fire frames are {fire_files}, expected {expected_fire}")
    if tuple(fire.get("size", ())) != FIRE_SIZE \
            or tuple(fire.get("position", ())) != FIRE_POSITION:
        fail(f"layout fire geometry is {fire}, expected {FIRE_SIZE} at {FIRE_POSITION}")
    for name in fire_files:
        if name not in COPIES:
            fail(f"layout fire frame {name} is not a prepared asset")

    sign = layout.get("liquor_sign", {})
    if tuple(sign.get("size", ())) != SIGN_SIZE \
            or tuple(sign.get("position", ())) != SIGN_POSITION:
        fail(f"layout sign geometry is {sign}, expected {SIGN_SIZE} at {SIGN_POSITION}")
    for key in ("on", "off"):
        if sign.get(key) not in COPIES:
            fail(f"layout sign {key} frame {sign.get(key)} is not a prepared asset")


def make_thumbnail(destination: Path) -> None:
    sky_path = SOURCE_DIR / "bus_stop_sky_320x180.png"
    foreground_path = SOURCE_DIR / "bus_stop_foreground_320x180.png"
    with Image.open(sky_path) as sky, Image.open(foreground_path) as foreground:
        composite = Image.alpha_composite(
            sky.convert("RGBA"), foreground.convert("RGBA"))
        # Exact 4x box downsample of the sky+foreground composite: 320/4 = 80
        # and 180/4 = 45.
        thumbnail = composite.resize(THUMBNAIL_SIZE, Image.Resampling.BOX)
        thumbnail.putalpha(255)
        thumbnail.save(destination, optimize=True)


def main() -> None:
    if not SOURCE_DIR.is_dir():
        fail(f"missing source directory {SOURCE_DIR}")

    validate_layout()
    for source_name, (_, size, alpha_mode) in COPIES.items():
        source = SOURCE_DIR / source_name
        if not source.is_file():
            fail(f"missing source asset {source}")
        validate_image(source, size, alpha_mode)

    base = SOURCE_DIR / BASE_REFERENCE
    if not base.is_file():
        fail(f"missing reference composite {base}")
    with Image.open(base) as reference:
        # The reference composite is a flattened RGB image, not a layer.
        if reference.size != VIEWPORT:
            fail(f"{base} is {reference.size}, expected {VIEWPORT}")
        if reference.mode not in ("RGB", "RGBA"):
            fail(f"{base} is {reference.mode}, expected RGB or RGBA")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for source_name, (runtime_name, size, alpha_mode) in COPIES.items():
        destination = OUT_DIR / runtime_name
        shutil.copyfile(SOURCE_DIR / source_name, destination)
        validate_image(destination, size, alpha_mode)

    thumbnail = OUT_DIR / "thumbnail.png"
    make_thumbnail(thumbnail)
    validate_image(thumbnail, THUMBNAIL_SIZE, "opaque", palette_check=False)
    with Image.open(thumbnail) as result:
        if set(result.getchannel("A").get_flattened_data()) != {255}:
            fail(f"{thumbnail} is not fully opaque")

    print(f"wrote {len(COPIES)} runtime layers + 1 thumbnail to {OUT_DIR}")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as error:  # keep the failure readable in CI logs
        print(f"prepare_bus_stop: {error}", file=sys.stderr)
        raise SystemExit(1)
