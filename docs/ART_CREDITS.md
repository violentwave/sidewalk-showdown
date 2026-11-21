# Art and type credits

## “The Clip” intro panel art

Panels 1–15 are owner-supplied pixel-art illustrations. Source files are kept in
`art/source/Intro/`; game-ready 640 × 360 versions are in
`game/art/story/the_clip/`.

## Peggy and Richard combat cutouts

The first-pass combat cutouts in `game/art/characters/` are crops of the
owner-supplied Peggy and Richard title-card stills in `art/source/Characters/`.
The title lettering and unused canvas are excluded; the original source files
are unchanged. Each cutout is a single pose animated at runtime with the
procedural `VisualRoot` state motion; these are not sprite sheets or final
frame-by-frame character animation.

## Peggy and Richard idle sprite sheets

The approved four-cel idle loops (`spr_peg_leg_peggy_idle.png`,
`spr_whiskey_richard_idle.png`) are AI-generated drafts that the owner cleaned,
palette-fixed, reviewed, and approved. The review packs (individual cels,
manifests, contact/loop previews) and the native editable Pixelorama projects
(`.pxo`) are kept in `art/source/Characters/Animations/`. No image-provider
license is claimed for the generated cels; they are treated as
owner-supplied, all-rights-reserved project assets like the rest of the art.
Non-idle states reuse cel 0 of these sheets as the fallback for gated or
missing clips. **Exception (Peggy and Richard):** both fighters' non-idle
states and attacks now play the owner's full-animation-batch clips (see
`docs/PIXELORAMA_PIPELINE.md` §8 for Peggy, §9 for Richard); those clips come
from the same AI-generated PixelLab download batch, are treated identically as
owner-supplied, all-rights-reserved project assets with no image-provider
license claimed. The front-facing JPEG-derived Peggy clips
(`walk_forward`, `walk_backward`, `crouch_down`, `crouch_hold`) still need
owner-cleaned exports, and several Richard sheets are drawn at different art
scales (measured per clip via `h_ref`), so uniform-scale re-exports are
welcome but not required for the current integration.

## Screenshots

`docs/assets/` holds captures of this build (match, The Clip intro panel, and
character select) used in `README.md`. They are framebuffer captures produced by
`game/tools/readme_capture.gd`, so they show only owner-supplied project art
under the same all-rights-reserved terms as the rest of the repository; no
third-party image is embedded in them.

## “The Clip” intro fonts

All three bundled families are licensed under the SIL Open Font License 1.1.
The license texts are included beside the font binaries in `game/assets/fonts/`.

| Font | Designer / author | Intro use | License | Source |
|---|---|---|---|---|
| Bangers | Vernon Adams | Comic captions, page labels, SFX, and display lettering | SIL OFL 1.1 | [Google Fonts specimen](https://fonts.google.com/specimen/Bangers) · [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/bangers) |
| Comic Neue | Craig Rozynski, Hrant Papazian | Speech-bubble body text | SIL OFL 1.1 | [Google Fonts specimen](https://fonts.google.com/specimen/Comic+Neue) · [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/comicneue) |
| Share Tech Mono | Carrois Apostrophe | Diegetic livestream chat and phone-screen upload titles | SIL OFL 1.1 | [Google Fonts specimen](https://fonts.google.com/specimen/Share+Tech+Mono) · [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/sharetechmono) |

Bundled files:

- `game/assets/fonts/Bangers-Regular.ttf` and `Bangers-OFL.txt`
- `game/assets/fonts/ComicNeue-Regular.ttf`, `ComicNeue-Bold.ttf`, and
  `ComicNeue-OFL.txt`
- `game/assets/fonts/ShareTechMono-Regular.ttf` and `ShareTechMono-OFL.txt`

Every `Label` created by the intro assigns one of these fonts explicitly, and
system-font fallback is disabled for the bundled font imports; no Godot
theme-default font is used for intro copy or UI hints.

## UI pixel font (menus and HUD, UI Phase 1)

| Font | Designer / author | UI use | License | Source |
|---|---|---|---|---|
| m5x7 | Daniel Linssen | Theme default for every Phase 1 screen, pause menu, prompt lines, and (from Phase 2) HUD labels, at its native size 16 — one game pixel per font pixel, antialiasing and subpixel positioning off | CC0 (attribution appreciated, not required) | [managore.itch.io/m5x7](https://managore.itch.io/m5x7) |

Bundled file: `game/assets/fonts/m5x7.ttf` (CC0 needs no license text
beside it; this credit line covers the "attribution appreciated" request).
Bangers stays for big headers and banner words, applied per label.
