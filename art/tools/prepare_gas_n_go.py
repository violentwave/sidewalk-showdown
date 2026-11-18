#!/usr/bin/env python3
"""Prepare the Gas-N-Go stage art for runtime.

The owner's source art lives read-only in art/source/Stages/GasNGo/. This
script copies the layered 320x180 stage assets into the Godot project at
native resolution (scale 1.0, no resampling) and derives one 80x45 stage
thumbnail with an exact 4x box downsample of the 320x180 preview.

It validates only what the pipeline guarantees, never the picture content:
dimensions, binary/opaque alpha, and a bounded per-layer palette. Rerunning it
from unchanged sources produces byte-identical runtime assets.

Usage:
    python3 art/tools/prepare_gas_n_go.py
"""
from pathlib import Path
import shutil
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "art" / "source" / "Stages" / "GasNGo"
OUT_DIR = ROOT / "game" / "art" / "stages" / "gas_n_go"

THUMBNAIL_SIZE = (80, 45)
THUMBNAIL_SOURCE = "preview_320x180.png"

# Source file -> runtime file. Sizes are the authored canvas sizes (the clouds
# file's name says 40 but the art is 44 rows tall, so the real size is used).
COPIES = {
    "gas_n_go_sky_320x180.png": ("gas_n_go_sky.png", (320, 180), "opaque"),
    "gas_n_go_clouds_640x40.png": ("gas_n_go_clouds.png", (640, 44), "binary"),
    "gas_n_go_foreground_320x180.png": ("gas_n_go_foreground.png", (320, 180), "binary"),
    "gas_n_go_sign_text.png": ("gas_n_go_sign_text.png", (105, 30), "binary"),
    "gas_n_go_gator_f1.png": ("gas_n_go_gator_f1.png", (81, 18), "binary"),
    "gas_n_go_gator_f2.png": ("gas_n_go_gator_f2.png", (81, 18), "binary"),
    "gas_n_go_gator_f3.png": ("gas_n_go_gator_f3.png", (81, 18), "binary"),
    "gas_n_go_mosquito_f1.png": ("gas_n_go_mosquito_f1.png", (24, 26), "binary"),
    "gas_n_go_mosquito_f2.png": ("gas_n_go_mosquito_f2.png", (24, 26), "binary"),
}


def fail(message: str) -> None:
    raise SystemExit(f"prepare_gas_n_go: {message}")


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
        # These are indexed pixel-art layers. A bounded palette catches an
        # accidental photo/gradient export without inspecting the pixels. The
        # box-filtered thumbnail is the one derived image that may blend new
        # intermediate colours, so its palette is not budgeted.
        if palette_check:
            palette_size = len(set(image.get_flattened_data()))
            if palette_size > 256:
                fail(f"{path} has {palette_size} colours, over the 256-colour budget")


def main() -> None:
    if not SOURCE_DIR.is_dir():
        fail(f"missing source directory {SOURCE_DIR}")

    for source_name, (runtime_name, size, alpha_mode) in COPIES.items():
        source = SOURCE_DIR / source_name
        if not source.is_file():
            fail(f"missing source asset {source}")
        validate_image(source, size, alpha_mode)

    thumbnail_source = SOURCE_DIR / THUMBNAIL_SOURCE
    if not thumbnail_source.is_file():
        fail(f"missing thumbnail source {thumbnail_source}")
    with Image.open(thumbnail_source) as preview:
        if preview.size != (320, 180):
            fail(f"{thumbnail_source} is {preview.size}, expected (320, 180)")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for source_name, (runtime_name, size, alpha_mode) in COPIES.items():
        destination = OUT_DIR / runtime_name
        shutil.copyfile(SOURCE_DIR / source_name, destination)
        validate_image(destination, size, alpha_mode)

    # Exact 4x box downsample: 320/4 = 80 and 180/4 = 45.
    with Image.open(thumbnail_source) as preview:
        thumbnail = preview.convert("RGBA").resize(
            THUMBNAIL_SIZE, Image.Resampling.BOX)
        thumbnail.save(OUT_DIR / "gas_n_go_thumbnail.png", optimize=True)
    validate_image(OUT_DIR / "gas_n_go_thumbnail.png", THUMBNAIL_SIZE,
                   "opaque", palette_check=False)

    print(f"wrote {len(COPIES)} runtime layers + 1 thumbnail to {OUT_DIR}")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as error:  # keep the failure readable in CI logs
        print(f"prepare_gas_n_go: {error}", file=sys.stderr)
        raise SystemExit(1)
