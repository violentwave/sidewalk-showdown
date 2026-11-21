# Sidewalk Marker pixel font

Original project font (owned by Sidewalk Showdown), designed for the 320x180 native resolution.

- `glyphs.js`: the glyphs, 9 px cap height, 2 px strokes, uppercase-only (lowercase maps to the same glyphs), digits and common punctuation.
- `build.js`: writes the BMFont files in `game/assets/fonts/`:
  - `sidewalk_marker.fnt/.png`: white glyphs; colour them with `font_color`.
  - `sidewalk_marker_outline.fnt/.png`: white glyphs with a baked 1 px `#1C160D` outline (8-way); colour the fill with a `modulate`-free shader or use as-is.
- `render.sh`: renders a string to PNG (used for the banner words in `art/source/UI/approved/hud/hud_banner_*.png`, which are the font drawn at 2x with a 1 px outline; `DECISIVE ROUND` uses the 1x outline font so it fits the plate).

Run with Node (`node build.js`) and ImageMagick. These are owner/PM tools, not agent-session tools; agents use the generated files.
