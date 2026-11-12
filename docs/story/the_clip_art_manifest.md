# “The Clip” panel art slots

The intro is data-driven. Drop finished panel artwork into
`game/art/story/the_clip/` using these names; the panel data already points to
the slots. No scene or script edits should be needed.

## Delivery spec

- One full-panel PNG per slot, native size **320 × 180 px**, **16:9**.
  640 × 360 is also accepted for crisper detail; the game downsamples it
  with nearest-neighbor on import.
- Art style: **chunky retro pixel art** matching the character sprites —
  large visible square pixels, hard pixel edges, no anti-aliasing or
  smooth gradients, one consistent pixel size per image. See
  `docs/story/the_clip_art_prompts.md` for the full v2 prompt kit.
- RGB or RGBA; transparent pixels are optional, not required.
- Keep captions, speech, chat, the flyer headline, and other legible copy out of
  the image. Those are live, owner-editable panel data rendered by the UI.
- Use pixel-art forms with bold comic silhouettes and keep faces/action readable
  at 320 × 180. Do not include legible flyer's fine print: panel 10 gets only an
  illegible smudge/squiggle there.
- Panels 3–8 may use the existing `game/art/stages/bus_stop/BusStopNight.png`
  as the temporary backdrop. Panel artwork, when supplied, takes precedence.
- Until a slot exists, the intro renders a halftone placeholder, an ink-framed
  panel number, and the art note from `game/data/story/the_clip.panels` in comic
  lettering.

| Panel | Expected file | Art direction |
|---:|---|---|
| 1 | `panel_01.png` | Tripp's apartment: ring lights, dead energy cans, follower counter at 47. |
| 2 | `panel_02.png` | Phone upload grid with the three data-file video titles/views. |
| 3 | `panel_03.png` | Bus stop; phone taped to a mop; Peggy and Richard stay in the background. |
| 4 | `panel_04.png` | Peggy and Richard square up over a bench. |
| 5 | `panel_05.png` | Wide brawl behind Tripp's still-streaming phone. |
| 6 | `panel_06.png` | Extreme close-up of Tripp's thumb tapping zoom. |
| 7 | `panel_07.png` | View counter spins; reaction thumbnails spawn on the phone. |
| 8 | `panel_08.png` | Garish “Probably Legal Energy” email notification. |
| 9 | `panel_09.png` | Parking lot, folding table, hand-painted tournament banner. |
| 10 | `panel_10.png` | Full-frame flyer; prize headline is data-rendered; fine print is an illegible mark. |
| 11 | `panel_11.png` | Three signup vignettes: grudge, upside-down flyer, hot dog. |
| 12 | `panel_12.png` | Tripp to camera, hand on heart, ring-light halo. |
| 13 | `panel_13.png` | 15 bracket portraits; Peggy/Richard in color. Do not depict the host as a fighter. |
| 14 | `panel_14.png` | Crop at bracket bottom; sixteenth “?” tease, intro-only. |
| 15 | `panel_15.png` | Tournament logo and subscriber count climbing. |

The `?` belongs only in panels 14's intro bracket art/data. It is not a fighter
record or a character-select slot. See the canon locks in `GAME_BIBLE.md` §2 and
`GDD.md` §9.3.
