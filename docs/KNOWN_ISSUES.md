# Known Issues — Phase 1 (Greybox Combat)

Exit criteria from GDD §13 Phase 1: two boxes can fight, hits feel responsive,
blocking works, round flow works, match can end/restart. **All met.**

## Deliberate gaps (next phases)

- **No animation.** Fighters are colored silhouettes; no sprite frames wired.
- **No audio or VFX.** No hit sparks, crowd, UI sounds, music.
- **No CPU AI.** Both fighters are human-controlled (GDD Phase 3 baseline).
- **METHtality is a stub.** Button is buffered (`p1_meth`/`p2_meth`) but no
  finisher state, prompt, or cinematic exists yet.
- **No character/stage select.** Fixed matchup + Bus Stop (Night).
- **Debug overlay is basic.** Boxes/frame-state/input-history/slow-mo only; no
  frame-step, frame advantage, AI state, or reset/refill hotkeys.
- **No throw tech, wake-up invulnerability, or corner pushback tuning.**
- **Hitstop does not pause the round timer** (fighters freeze only).
- **Pause is a stub.** Esc freezes the tree and shows a label; no menu.

## Tuning caveats

- Frame data is provisional, derived from GDD §5.6–§5.10 tables. It lives in
  `game/resources/fighters/*.tres` and can be regenerated with
  `game/tools/gen_fighter_data.gd`.
- Air specials exist in data but have had no balance pass.
- Damage scaling is per-defender combo count (85/70/55%, floor 35%).
- HUD uses the default Godot font at pixel-safe sizes; final pixel font comes
  with UI art direction (GDD Phase 4).

## Test coverage

- `game/tests/combat_test.gd` — hits, chip damage, low vs stand-block, throw
  unblockability, jump, P2 bindings.
- `game/tests/round_flow_test.gd` — intro→fight, KO, round wins, timeout
  resolution, best-of-3 match end.
