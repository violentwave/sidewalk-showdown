# Sidewalk Showdown

Mature-rated 2D retro pixel-art arcade fighting game. A washed-up livestreamer
(Tripp Vlogs) turns sidewalk chaos into a rigged tournament — and 15 local
legends eventually turn on him.

**Engine:** Godot 4.x (in `game/`)
**Target:** PC first (Windows / Linux / macOS)
**Status:** Phase 0 — project setup

## Source of truth

| Doc | Purpose |
|---|---|
| `GAME_BIBLE.md` | Story/world canon (Tripp, roster, stages, METHtalities) |
| `GDD.md` | Design & production plan (combat systems, phases) |
| `CHARACTERS.md` | Roster bible (archetypes, rivals, data direction) |
| `docs/SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md` | 315 art-generation prompts |

**Canon locks:** Tripp Vlogs is the only boss and is NOT playable. Roster = 15
fighters. Every fighter has one unique METHtality. No real towns, brands, or
public figures (this is fictional "Sidewalk Florida").

## Repo layout

```text
game/            Godot 4.x project
art/source/      Raw AI-generated asset prototypes (do not clean in place)
art/source/extras/   Non-canon / future-roster character art
art/exports/     Cleaned, snake_case, runtime-ready art
docs/            Supporting docs and archives
```

## Workflow rules

- Asset naming in `art/exports/`: lowercase snake_case
  (`spr_whiskey_richard_idle.png`, `stage_bus_stop_night_bg_far.png`).
- AI art pipeline: generate → save raw in `art/source/` → clean/pixel-fix →
  export into `art/exports/` only after review. Never edit `art/source/` files.
- Current vertical slice: **Peg Leg Peggy** vs **Whiskey Richard** on
  **The Bus Stop (Night)**.
