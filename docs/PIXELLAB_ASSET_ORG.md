# PixelLab Asset Organization — Sidewalk Showdown

**Version:** v0.1
**Date:** 2026-11-13
**Purpose:** Rules for generating Sidewalk Showdown assets through the PixelLab MCP
server, reusing our approved fighter art as the primary visual references.

## 1. PixelLab Project

- **Project:** `Sidewalk Showdown` (folder project — groups assets on the website; NOT a Game Builder game, no second codebase)
- **Project ID:** `ad6330d1-09db-464d-96f5-7d3cf24cb152`
- Pre-existing folder was found under the misspelling "SIdewalk Showdown" and
  renamed to the exact name; no duplicate folder was created.
- Every generated asset that PixelLab supports (characters, objects, tilesets,
  maps, rooms, UI, gallery images) is filed into this project explicitly via
  `add_to_project(project_id, asset_id)` after review acceptance.

## 2. Account / Connection

- MCP server: `pixellab` (remote, `https://api.pixellab.ai/mcp`), configured in
  the project `opencode.json` with `oauth: false` and
  `Authorization: Bearer {env:PIXELLAB_API_KEY}`. The key lives only in the env
  var; never commit it.
- Verified balance at setup: **$0.00 credits; 2000/2000 subscription generations
  remaining (Tier 1: Pixel Apprentice, resets 2026-12-13)**.
- 2026-11-21: UI generation via the REST API (`docs/UI_ASSETS.md` §3 reference
  method) used 136 generations (1 bitforge test, 6 Tripp faces x 10, 5 UI
  pieces x 15); balance after: **925/2000**. API calls bill the subscription
  generations, not credits.
- Known issue: the OpenCode background service was observed repeatedly
  restarting while the pixellab MCP connection cycled, crashing the user's
  terminal. If this recurs, disconnect the server when not generating
  (`/mcps`) and reconnect for generation sessions only.

## 3. Primary Visual References (style anchors)

- **Peg Leg Peggy:** `art/source/Characters/Animations/generated/peggy_idle_review/peggy_idle_01.png`
- **Whiskey Richard:** `art/source/Characters/Animations/generated/richard_idle_review/richard_idle_01.png`

Both files verified present (96x80 cells, 4-frame idle sheets with per-frame
PNGs, `animations.json` metadata, loop previews, and raw generated sheets kept
in each review folder). These are the approved Pixelorama exports
(`art/source/Characters/Animations/peg_leg_peggy.pxo`,
`whiskey_richard.pxo`, last saved 2026-11-12 23:47; review frames exported
afterwards at 04:30 / 04:38), so they are current.

Pending verification: byte-level comparison of `.pxo` frame 1 composite vs
`*_idle_01.png` (script at `/tmp/opencode/pxo_compare.py` was interrupted by
terminal crashes). Run it before bulk production.

Old character cutouts must NOT be used as the primary style reference.

## 4. Generation Rules (all PixelLab jobs)

1. **Identity lock.** Preserve each fighter's approved identity: palette,
   pixel scale, silhouette, and facial features. Facial features stay fully
   opaque even where the body uses true transparency.
2. **Facing.** Screen-right consistent three-quarter facing (the idle review
   direction). Supply the idle frame as the generation's start/reference pose;
   never let a generator flip or straighten the facing.
3. **Transparency.** True alpha transparency for the figure's surroundings;
   facial features fully opaque.
4. **Peggy's peg leg** remains rigid — no knee bend, no wobble, in every frame.
5. **Richard's bottle** stays in the reference hand and never changes hands,
   disappears, or morphs.
6. **Cells.** Target padded cells of **160x112**. Do not enlarge the figure:
   generate at the native 96x80 art scale and pad transparent margins into the
   160x112 cell in post (pixel-exact work, e.g. the free `pixelart_workbench`),
   keeping the figure's pixel size identical. **Fit test required before bulk
   production:** confirm every attack's full extension (startup/active/
   recovery extremes) stays inside 160x112 without scaling; if any move
   overflows, re-examine cell size before proceeding — do not shrink the art.
7. **Timing.** Preserve the existing gameplay startup/active/recovery frame
   timing defined in `CHARACTERS.md` and current Godot animation resources.
   Generated frame counts must map onto those windows; adjust per-frame
   durations in-engine, not by re-timing the move design.
8. **Fallbacks.** Keep the existing idle-based animation fallbacks intact.
   Any generated set that fails review must leave the fallback wiring
   untouched and functional.
9. **Review folders.** Save every generated original sheet plus a
   `metadata.json` (tool, job IDs, prompts, palette, timestamps, cost) under
   `art/source/Characters/Animations/generated/<fighter>_<anim>_review/`
   following the existing idle review folder layout. Nothing moves toward
   `art/exports/` or `game/assets/` without review.
10. **Prompt pack.** Follow the style guardrails and negative prompts in
    `docs/SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md` (lowercase
    snake_case filenames, no real brands/towns/people, combat-readable
    chunky pixel art). That pack covers non-defining assets; fighter
    generations must additionally obey the identity rules above.

## 5. Proposed Walk-Animation Test (one per fighter — NOT submitted)

Status: **proposed only. Awaiting explicit user approval before any job.**

- **Tool:** PixelLab `create_character` (v3 mode) with each fighter's
  `*_idle_01.png` as the reference image, followed by `animate_character`
  (v3 custom motion, `action_description` = walk) — this is the supported
  route for animating existing art; animation requires a PixelLab character
  id, so each test is a two-step job.
- **Dimensions/frame counts:** art at native 96x80; walk test at 8 frames per
  fighter, one direction (the screen-right three-quarter facing). v3
  constraints satisfied: frames 4-16, width x height x frames <= 8x256x256.
  Padding to 160x112 happens in post, free, after review.
- **Cost estimate:** character creation with a 96x80 reference bills
  ceil(96x80x8/65536) = 1 generation (minimum 1) for the reference direction,
  plus 0.25 per imported extra direction; a single-direction walk animation at
  96x80x8 frames bills ceil(96x80x8/65536) = 3 generations per direction.
  Roughly **~4-5 generations per fighter, ~8-10 total** against the 2000
  remaining. Exact receipts are returned with each job; failed jobs are not
  charged.
- **Review:** each result lands in
  `art/source/Characters/Animations/generated/<fighter>_walk_review/` with
  metadata, then a side-by-side loop preview against the idle review before
  any decision.
