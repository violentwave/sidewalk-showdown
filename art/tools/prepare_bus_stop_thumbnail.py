#!/usr/bin/env python3
"""Prepare the Bus Stop stage thumbnail used by stage select.

The match shows BusStopNight.png (1024x1024) as a centered Sprite2D at
position (160, 90) with scale 0.3125, so the 320x180 viewport sees the source
crop x 0..1024, y 224..800. This script derives the thumbnail from exactly that
crop, applies the scene's night modulate (0.55, 0.55, 0.62), shrinks the
1024x576 crop to the shown 320x180 with a box filter, and then takes the same
exact 4x box downsample to 80x45 that the Gas-N-Go preview uses.

Source art is read-only; only the derived thumbnail is written.

Usage:
    python3 art/tools/prepare_bus_stop_thumbnail.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art" / "source" / "Stages" / "BusStopNight.png"
OUT = ROOT / "game" / "art" / "stages" / "bus_stop" / "thumbnail.png"

VIEWPORT = (320, 180)
SPRITE_POSITION = (160, 90)
SPRITE_SCALE = 0.3125
SOURCE_SIZE = (1024, 1024)
NIGHT_MODULATE = (0.55, 0.55, 0.62)
THUMBNAIL_SIZE = (80, 45)


def fail(message: str) -> None:
    raise SystemExit(f"prepare_bus_stop_thumbnail: {message}")


def shown_source_rect() -> tuple[int, int, int, int]:
    display_left = SPRITE_POSITION[0] - SOURCE_SIZE[0] * SPRITE_SCALE * 0.5
    display_top = SPRITE_POSITION[1] - SOURCE_SIZE[1] * SPRITE_SCALE * 0.5
    return (
        round(-display_left / SPRITE_SCALE),
        round(-display_top / SPRITE_SCALE),
        round((-display_left + VIEWPORT[0]) / SPRITE_SCALE),
        round((-display_top + VIEWPORT[1]) / SPRITE_SCALE),
    )


def main() -> None:
    if not SOURCE.is_file():
        fail(f"missing source asset {SOURCE}")
    with Image.open(SOURCE) as source:
        if source.size != SOURCE_SIZE:
            fail(f"{SOURCE} is {source.size}, expected {SOURCE_SIZE}")
        if source.mode not in ("RGB", "RGBA"):
            fail(f"{SOURCE} is {source.mode}, expected RGB or RGBA")

        rect = shown_source_rect()
        # The sprite's top-left sits above the viewport; the crop starts at the
        # first visible source row, 224, and is 576 source rows tall.
        if rect != (0, 224, 1024, 800):
            fail(f"computed crop {rect}, expected (0, 224, 1024, 800)")

        shown = source.convert("RGBA").crop(rect).resize(
            VIEWPORT, Image.Resampling.BOX)
        # Match the runtime scene's Color(0.55, 0.55, 0.62, 1) modulate.
        channels = list(shown.split())
        for index in range(3):
            channels[index] = channels[index].point(
                lambda value, factor=NIGHT_MODULATE[index]: round(value * factor))
        tinted = Image.merge("RGBA", tuple(channels))

        thumbnail = tinted.resize(THUMBNAIL_SIZE, Image.Resampling.BOX)
        # The source is 250..255 alpha (near-opaque anti-aliased edges); menu
        # cards draw on an opaque panel, so store the preview fully opaque.
        thumbnail.putalpha(255)
        OUT.parent.mkdir(parents=True, exist_ok=True)
        thumbnail.save(OUT, optimize=True)

    with Image.open(OUT) as result:
        if result.size != THUMBNAIL_SIZE:
            fail(f"{OUT} is {result.size}, expected {THUMBNAIL_SIZE}")
        if set(result.getchannel("A").get_flattened_data()) != {255}:
            fail(f"{OUT} is not fully opaque")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
