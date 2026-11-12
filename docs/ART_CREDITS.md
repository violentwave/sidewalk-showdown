# Art and type credits

## “The Clip” intro panel art

Panels 1–15 are owner-supplied pixel-art illustrations. Source files are kept in
`art/source/Intro/`; game-ready 640 × 360 versions are in
`game/art/story/the_clip/`.

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
