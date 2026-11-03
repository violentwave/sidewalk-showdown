# Known Issues — Phase 1.5 (Greybox Combat)

Exit criteria from GDD §13 Phase 1: two boxes can fight, hits feel responsive,
blocking works, round flow works, match can end/restart. **All met.**

Phase 1.5 audit fixes (KO landing, shared hitstop, blockstun blocking, jump arc
states, P1/P2 input separation, P2 pause, frame-locked gravity) are in.

## Deliberate gaps (next phases)

- **No animation.** Fighters are colored silhouettes; no sprite frames wired.
- **No audio or VFX.** No hit sparks, crowd, UI sounds, music.
- **No CPU AI.** Both fighters are human-controlled (GDD Phase 3 baseline).
- **METHtality is a stub.** Button is buffered (`p1_meth`/`p2_meth`) but no
  finisher state, prompt, or cinematic exists yet.
- **Hype meter has no spender.** It fills on hit/block/whiff but no move costs
  meter yet.
- **No character/stage select.** Fixed matchup + Bus Stop (Night).
- **Debug overlay is basic.** Boxes/frame-state/input-history/slow-mo only; no
  frame-step, frame advantage, AI state, or reset/refill hotkeys.
- **No throw tech or wake-up invulnerability.**
- **Pause is a stub.** Esc / Numpad 0 freezes the tree and shows a label; no menu.

## Known edge cases

- **Double KO** awards the round to the first fighter whose `ko` signal fires;
  there is no draw/replay handling for simultaneous KOs.
- **Round timer** ticks during hitstop, and a hit that lands on the same frame
  the timer expires is discarded.
- **Timeout tie** (equal health) resolves as a draw round with no win awarded.
- Frame data is provisional, derived from GDD §5.6–§5.10. It lives in
  `game/resources/fighters/*.tres` and can be regenerated with
  `game/tools/gen_fighter_data.gd`.
- Air specials exist in data but have had no balance pass.
- Damage scaling is per-defender combo count (85/70/55%, floor 35%).
- HUD uses the default Godot font at pixel-safe sizes; the final pixel font
  arrives with UI art direction (GDD Phase 4).
- **Licensing is undecided.** Treat the repo as all-rights-reserved until a
  LICENSE is added.

## Test coverage

- `game/tests/combat_test.gd` — hits, chip damage, low vs stand-block, throw
  unblockability, jump arc, P2 bindings, blockstring blocking, shared hitstop,
  KO landing.
- `game/tests/round_flow_test.gd` — intro→fight, KO, round wins, timeout
  resolution, best-of-3 match end.
- `.github/workflows/tests.yml` runs both suites on push/PR.
