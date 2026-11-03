# Known Issues — Phase 1.5f (Greybox Combat)

Exit criteria from GDD §13 Phase 1: two boxes can fight, hits feel responsive,
blocking works, round flow works, match can end/restart. **All met.**

Phase 1.5d audit fixes now in: KO landing, shared hitstop, blockstun blocking,
jump arc states, P1/P2 input separation, P2 pause, frame-locked gravity, and the
1.5d pass — device-agnostic keyboard bindings covered by a real-key test, a pause
that freezes the fighters and the round timer, silhouettes that scale with
fighter height, and a chip-damage floor so blocked hits can never KO.

Since 1.5e a trade that kills both fighters resolves as a **draw round**: neither
side gets a win pip, the HUD shows `DOUBLE K.O. / DRAW`, and the round advances
normally inside the same best-of-3.

Since 1.5e the round clock also respects hitstop: while either fighter has
hitstop frames left the timer holds, so a frozen exchange never burns time. Hits
are resolved before the timeout check, so a hit landing on the timer's final
frame counts — and a KO on that frame wins the round instead of being discarded.

Since 1.5f pause is a real menu rather than a label: Esc (P1) / Numpad 0 (P2)
freeze the fight and open RESUME / RESTART MATCH / QUIT TO DESKTOP, driven by
either player's up/down and light attack (or Enter). Pausing alters no sim state
— hitstun frames, health, and the round clock all resume exactly where they
stopped.

Since 1.5f the debug overlay covers frame-stepping: **F5** holds the tree paused
and advances exactly one simulation frame per press (while slow-mo is on), **F2**
adds a live frame-advantage readout during HITSTUN/BLOCKSTUN, and **F6** refills
both fighters at their round positions without disturbing the match phase. The
overlay mutes itself in headless runs so the test suites stay quiet.

## Input map

`game/tools/setup_input.gd` is the single source of truth for the `p1_*` /
`p2_*` actions. Do not hand-edit the `[input]` section of `project.godot`; change
the generator and regenerate:

```bash
godot --headless --path game --script res://tools/setup_input.gd
```

Every event is written with `device = -1` (matches any device). A concrete device
id — `16` is what Godot's text serializer stamps in if nobody sets it — never
matches a real keyboard, which reports device `0`, so the bindings look correct
in the editor and are dead in play. `game/tests/combat_test.gd` replays each
mapped key as a device-0 event and fails if any of them stops resolving.

Regeneration caveat: `ProjectSettings.save()` omits settings whose value equals
the engine default, and `physics/common/physics_ticks_per_second = 60` *is* the
default. Regenerating therefore deletes the explicit `[physics]` section. Re-add
that section by hand afterward — the simulation step comes from
`Engine.physics_ticks_per_second` via `FighterBase.delta_fixed()`.

## Deliberate gaps (next phases)

- **No animation.** Fighters are colored silhouettes; no sprite frames wired.
- **No audio or VFX.** No hit sparks, crowd, UI sounds, music.
- **No CPU AI.** Both fighters are human-controlled (GDD Phase 3 baseline).
- **METHtality is a stub.** Button is buffered (`p1_meth`/`p2_meth`) but no
  finisher state, prompt, or cinematic exists yet.
- **Hype meter has no spender.** It fills on hit/block/whiff but no move costs
  meter yet.
- **No character/stage select.** Fixed matchup + Bus Stop (Night).
- **Debug overlay is dev-only.** Boxes, frame state, frame advantage, input
  history, slow-mo, frame-step and refill/reset hotkeys exist; it has no AI state
  view (there is no AI yet) and no hitbox-invariant assertions.
- **No throw tech or wake-up invulnerability.**

## Known edge cases

- **Timeout tie** (equal health) resolves as a draw round with no win awarded.
- Frame data is provisional, derived from GDD §5.6–§5.10. It lives in
  `game/resources/fighters/*.tres` and can be regenerated with
  `game/tools/gen_fighter_data.gd`.
- Air specials exist in data but have had no balance pass.
- Damage scaling is per-defender combo count: 100/100/85/70/55% for hits
  1–2/3/4/5+, floor **55%**. Chip damage never kills — a blocked hit floors the
  defender at 1 HP.
- HUD uses the default Godot font at pixel-safe sizes; the final pixel font
  arrives with UI art direction (GDD Phase 4).
- **Licensing is undecided.** Treat the repo as all-rights-reserved until a
  LICENSE is added.

## Test coverage

- `game/tests/combat_test.gd` — hits, chip damage (including the chip-cannot-KO
  floor), low vs stand-block, throw unblockability, jump arc, P2 bindings,
  blockstring blocking, shared hitstop, KO landing, real-key input-map
  resolution, pause freezing fighters, the pause menu (navigation by both
  players, resume keeping mid-hitstun state, restart), debug frame-step,
  frame advantage and the F6 refill.
- `game/tests/round_flow_test.gd` — intro→fight, KO, round wins, timeout
  resolution, double KO -> draw (no pip, round advances, match still ends),
  the round clock frozen during hitstop, a hit on the timer's final frame
  counting, best-of-3 match end.
- `.github/workflows/tests.yml` runs both suites on push/PR.
