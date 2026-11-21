# UI Assets — Pipeline and Manifest

**Version:** v0.1
**Date:** 2026-11-20
**Status:** Planning. No UI art is wired into the game yet; the current HUD and
menus are built in code (`game/scripts/ui/`).

This file is the source of truth for UI art: what each asset is, its exact
native size, how it gets made, and where every version of the file lives.
It extends `docs/PIXELLAB_ASSET_ORG.md` (PixelLab project, MCP setup, review
folders) to UI. Where the two disagree on UI sizes or folders, this file wins.

## 1. The layout reference (Figma)

- **File:** [Sidewalk Showdown – UI Layout](https://www.figma.com/design/O4jfUUXLq5H0HISUDuv2EL)
  (in the team's Sidewalk Showdown folder).
- **Pages:** Tokens & Components (palette, text styles, one placeholder
  component per asset at native size), HUD (three 320x180 HUD states),
  Screens (11 menu/flow screens at 320x180).
- 1 Figma unit = 1 game pixel. Every frame is 320x180.
- Figma is the **layout and size spec only**. It never ships pixels into the
  game; its exports are not pixel art. Positions an agent needs are copied
  into the docs that drive the code (for the HUD: the HUD table in the plan
  and this manifest).
- Fonts in Figma are stand-ins: Bangers (headers) and Silkscreen (body)
  until the owner picks the final pixel font.

## 2. Where every file lives

| Stage | Path | Who writes it | Rules |
| --- | --- | --- | --- |
| 1. Raw generations | `art/source/UI/generated/<asset_id>_review/` | Agent (PixelLab MCP) or owner (PixelLab web) | Every original output, untouched, plus `metadata.json` (tool, job/asset ids, prompt, negative prompt, seed, init image, size requested, size received, timestamp, cost). Never edited after saving. |
| 2. Approved source | `art/source/UI/approved/<group>/<asset_id>.png` | Owner only | The chosen generation, cleaned by hand in Pixelorama to the **exact native size** in the manifest, transparent background, no anti-aliasing. Read-only after it lands (like all of `art/source/`). |
| 3. Runtime | `game/art/ui/<group>/<asset_id>.png` | `art/tools/prepare_ui.gd` (headless Godot; to be written in UI Phase 5) | Copied/cropped from stage 2 and checked against the manifest size. Never hand-edit. Imported with nearest filter, no mipmaps. |
| Layout preview (optional) | Figma component of the same name | PM/Claude via Figma connector | Approved PNG placed into its placeholder so screens preview with real art. |

The legacy concept art in `art/source/UI/` (`HealthFull.png`,
`HealthEmpty.png`, `MethtalityMeter.png`, `Time.png`, `UI.png`) stays where it
is and is used only as a **style reference** (init image), never as runtime art.

`<group>` is one of: `hud`, `stream`, `menu`, `select`, `stage`, `vs`, `ui`.
`<asset_id>` is lowercase snake_case, e.g. `hud_health_frame`.

## 3. How to make an asset

1. **Check the manifest** below for the native size and method.
2. **PixelLab assets: use the reference method** (proven 2026-11-21; the
   earlier init-image/pixflux attempt in PR #78 ignored the art and was
   closed):
   - **Tool:** `POST /v2/generate-with-style-v2` (REST) / the MCP's
     generate-with-style tool. Output is a square canvas sized by the largest
     style image and returns many variants per call (28 px → 64 images for
     10 generations; 72 px → 9 images for 15). Bitforge with an init image
     barely changes the reference and is not used.
   - **References:** crop the relevant region of the source art, then
     point-resize (nearest neighbour) it to its logical pixel scale, which is
     about 1/16 for the 1024–1536 px concept files. Never letterbox a whole
     sheet. Saved refs live in `art/source/UI/refs/` (recipes in each
     review folder's `metadata.json`).
   - **Prompt:** short and object-first ("the same bearded man's face,
     smirking, ..." / "wide horizontal banner plate with bevelled border and
     empty dark center, no text"), plus a one-line `style_description`. Do
     not paste the prompt pack's shared style block: its character words made
     the model draw people.
   - Non-square assets come back on a square canvas: treat them as style
     references and redraw or crop to native size during cleanup.
3. Generate 3–4 variants per asset; save all of them to the review folder.
4. **Owner review:** pick one, fix size and stray pixels in Pixelorama, save to
   `approved/`. PixelLab often returns the wrong canvas size: crop or pad to
   the exact size, never scale by a non-integer factor.
5. **Hand-drawn assets:** tiny pieces (pips, glyphs, skull, LIVE tag,
   digits) and plain bevelled shapes (health frame, meter frame, timer box,
   panel, buttons) are drawn directly in Pixelorama at native size, using the
   style refs above, and saved straight to `approved/`. They are faster to
   draw than to clean.
6. **Native-size drafts (agent, 2026-11-21):** trim the pick's transparent
   padding (`magick -trim`), shrink to (near) native with PixelLab's
   `POST /v2/resize` in ≤50%-per-step chains, and finish width with a
   9-slice compose (outer ~25% tape caps kept pixel-exact, a plain middle
   column tiled) — the resize API refuses any canvas side below 16px, so
   sub-16px-native assets are resized to height 16 and point-row-sampled
   down with ImageMagick. Drafts land next to the pick as
   `<asset_id>_native.png` (portraits: `<state>_native.png`), never
   overwriting anything. **Caution (PM review of PR #80):** `/v2/resize` is
   generative and can invent content on small targets (it drew a figure in
   the portrait frame, people on the commentary caps, and lost the sponsor
   bottle). Prefer trim + crop + 9-slice when the height already fits, check
   every resize output by eye, and run `+repage` after any append so the PNG
   carries no stale virtual-canvas size.
7. Update the **Status** column in the manifest in the same PR.

Agent sessions follow the usual image limits: stay under 8 images per
request, open at most 1 image at a time and fewer than 5 per session. Agents
save generations without reviewing them visually; the owner reviews.

## 4. Manifest

**Art direction (owner, 2026-11-21): street junk.** Sun-faded cardboard, silver duct tape, black sharpie, rust. Simple and catchy, readable at 320x180. **S** = street-junk refs `art/source/UI/refs/ref_sign.png` + `ref_clip.png` (from `Items/SnakeSign.png`, `Items/Clipboard.png`).

Style references: **A** = `art/source/UI/HealthFull.png`, **B** =
`art/source/UI/MethtalityMeter.png`, **C** = `art/source/UI/Time.png`,
**T** = `art/source/Characters/TrippVlogz.png`,
**F** = the fighter's approved idle frame per `docs/PIXELLAB_ASSET_ORG.md` §3.
"Pack #" is the prompt entry in the prompt pack.

### Batch 1 — HUD frame set + Tripp cam (start here)

| asset_id | Native size | Method | Ref | Pack # | Figma component | Notes | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `hud_health_frame` | 118x10 | PixelLab ref + Hand | S | 135 | `hud/health_frame 118×10` | Frame only, empty interior 116x8 at (1,1); fills are code-drawn. Mirrored for P2 in engine. | native final (PM-checked); ready to copy to approved/ |
| `hud_meter_frame` | 106x8 | PixelLab ref + Hand | S | 137 | `hud/meter_frame 106×8` | Empty interior 104x6 at (1,1); tick marks at 25 and 50 drawn in code. | native final (PM-checked); ready to copy to approved/ |
| `hud_timer_box` | 24x20 | PixelLab ref + Hand | S | 141 | `hud/timer_box 24×20` | Empty interior; digits are a separate strip. | native final (PM-checked); ready to copy to approved/ |
| `hud_timer_digits` | 8x12 per digit, strip 88x12 (0–9, ∞) | Hand | C | — | — | 11 glyphs in one strip, 8 px apart. | todo |
| `hud_portrait_frame` | 24x24 | PixelLab | S | — | `hud/portrait 24×24` | Holds a still of the fighter being played (not Tripp). Street-junk look: taped-down instant photo. | native final (PM-checked); ready to copy to approved/ |
| `hud_portrait_<fighter>` | 22x22 x3 states (normal, hurt, KO) | PixelLab + hand cleanup | fighter sprite | — | inside `hud/portrait 24×24` | Still of the fighter being played; sits in the taped photo frame. Generated for Pegleg Peg and Whiskey Richard (the playable pair). | native final (PM-checked); ready to copy to approved/ |
| `hud_pip_square` | 5x5 | Hand | — | 139/140 | `hud/pip_square 5×5` | Empty + filled + K/T/M/D letter variants. | todo |
| `hud_pip_diamond` | 5x5 | Hand | — | 139/140 | `hud/pip_diamond 5×5` | Same set as square, diamond shape (P2). | todo |
| `hud_meth_skull` | 8x8, 2 frames | Hand | B | 144 | `hud/meth_skull 8×8` | Wobble loop for METH READY. | todo |
| `hud_banner_plate` | 160x32 | PixelLab | S | 173 | `hud/banner 160×32` | Backing plate behind ROUND / FIGHT / K.O. lettering. | native final (PM-checked); ready to copy to approved/ |
| `stream_tripp_cam` | 6 faces, 28x28 | PixelLab + hand cleanup | T | — | — | **Dropped from the HUD (owner, 2026-11-21).** One face per expression kept for commentary/results screens. | generated (review) |
| `stream_live_tag` | 24x7 | Hand | — | 155 | `stream/live_tag 24×7` | "LIVE" in 5 px letters on red. | todo |

### Batch 2 — stream layer + shared UI kit

| asset_id | Native size | Method | Ref | Pack # | Figma component | Notes | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `stream_chat_panel` | 80x100 | PixelLab ref + Hand | S | 154 | `stream/chat_panel 80×100` | 9-slice-friendly border, empty interior. | native final (PM-checked); ready to copy to approved/ |
| `stream_sponsor_bug` | 40x12 | PixelLab ref + Hand | S | 156 | `stream/sponsor_bug 40×12` | Blank plate; fake brand names hand-pixeled later. | native final (PM-checked); ready to copy to approved/ |
| `stream_commentary_box` | 240x16 | PixelLab ref + Hand | S | 153 | (HUD between-rounds frame) | Between-rounds only. | native final (PM-checked); ready to copy to approved/ |
| `ui_panel` | 24x24 (8 px corners) | PixelLab ref + Hand | S | 146 | `panel/9slice 24×24` | 9-slice for every menu panel. | native final (PM-checked); ready to copy to approved/ |
| `ui_button` | 48x16 x4 states | PixelLab ref + Hand | S | — | `ui/button 48×16` | normal / focus / pressed / disabled, 9-slice-friendly. | native final (PM-checked); ready to copy to approved/ |
| `ui_glyphs` | 9x9 each | Hand | — | 148/149 | `ui/glyph 9×9` | Keyboard keys, pad face buttons, d-pad. | todo |

### Batch 3 — menu objects (wait for the owner's menu-direction decision)

| asset_id | Native size | Method | Ref | Pack # | Figma component | Notes | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `menu_price_sign` | 132x150 | PixelLab | — | — | (Screens / 03 Main Menu) | Gas-N-Go price board, night. Only if direction A is picked. | blocked |
| `menu_price_slat` | 96x14, normal + lit | PixelLab | — | — | `menu/price_slat 96×14` | | blocked |
| `select_portrait` | 64x64 per fighter | PixelLab | F | — | `select/portrait 64×64` | From final fighter art. | blocked |
| `select_mugshot_bg` | 320x180 | PixelLab | — | — | (Screens / 05) | Height-chart wall. | blocked |
| `select_rap_sheet` | 104x66 | PixelLab | — | — | (Screens / 05) | | blocked |
| `stage_scratch_ticket` | 72x44 + 3 scratch frames | PixelLab + hand | — | 160 | `stage/scratch_ticket 72×44` | | blocked |
| `vs_bust` | 96x128 per fighter | PixelLab | F | — | `vs/bust 96×128` | From final fighter art. | blocked |
| `ui_logo` | ~220x64 | PixelLab + hand | — | — | (Screens / 02 Title) | | blocked |
| `hud_banner_words` | ~160x32 each | Hand (lettering) | — | 172/173 | — | Waits for the font decision. | blocked |

## 5. Open owner decisions that affect art

- Final pixel font (m5x7 / monogram / Pixel Operator are CC0; m6x11 needs credit).
- Main menu direction (A price board, B stream deck, C route board).
- UI key colour.
- Tripp cam size (28x18 now).
