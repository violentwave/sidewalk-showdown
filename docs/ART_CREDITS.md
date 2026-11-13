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
Non-idle states currently reuse cel 0 of these sheets as static artwork while
the remaining animations are authored.

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
