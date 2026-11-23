# PM Brief — Sidewalk Showdown

> **Keep this file current: every PR that changes features, tests, commands, or
> rules must update PM_BRIEF.md.**
> Last verified: **2026-11-23**, against `origin/main` at `5587b1c`
> (PR #99 UI Playtest Fixes) plus the design/audit history: PR #100's
> FX/METH design (`docs/FX_AND_METH_DESIGN.md`) and **Phase C — SHIPPED
> (PR #102, 2026-11-23)**: per-character hit/block FX and the two
> deterministic METH cinematics wired from the owner's **procedurally
> drawn, palette-locked art** (PixelLab Batch 1 draft PR #101 abandoned and
> closed; branch kept as the spend record). The FX layer (CanvasLayer 5) is
> presentation-only from `FighterData.fx_set`; the METH driver owns a new
> serialized `METH_CINEMATIC` phase (210 frames, existing clips only, per
> the owner beat maps). **This branch is the visual-review fix pass on
> PR #102's own captures**: back props were sorted behind the stage
> (negative z on a late sibling), the fire cone was anchored/mirrored
> wrong, the fumes were buried — fixed with ordered back/front prop
> roots and manifest-exact mirrored anchors; `meth_cinematic_test` now
> carries numeric per-beat prop visibility checks (**158**; they fail on
> the pre-fix driver). Review strips for the owner/PM live in
> `docs/assets/fx_meth/`: `walk_the_plank{,_mirrored}_strip.png`,
> `flaming_belch{,_mirrored}_strip.png`. serialization_test 28. **CI runs
> 26 headless suites.**
>
> The merged **UI Playtest Fixes**
> (owner batch 2026-11-23): m5x7 HUD names on dark plates under the health
> bars; hitbox debug off by default; BRK renamed BREAK beside its pip in the
> meter band; every router screen on a CanvasLayer above the HUD and all
> stage art; METHtality title/subtitle on separate lines; the gator hidden
> (81 px art cannot clear the new bounds or the meter strip); stage bounds
> 44-276 so the widest authored pose stays on screen; the training readout
> at y 29-51 showing DMG and never the -1 juggle sentinel; it hides while a
> fighter overlaps it. Results hides the
> match HUD, blocks pause, uses readable stat ink and a TOTAL DMG label.
> New `ui_layout_test` 354 checks; stage_floor 11; results_flow 23.
> CI runs 24 headless suites.
>
> Input Remapping (Settings → CONTROLS) and Training Mode (GDD §6.4) are on
> main: named-action remapping with per-player reset from
> `user://controls.cfg`, and the P1-picks-both training flow with dummy
> options, record/playback, resets, readouts, and serialized state.
> `remap_test` 36; `training_test` 79; `serialization_test` 27.
>
> The inherited HUD is Combo Phase 4: the defender's combo
> count/damage/base scale and juggle pips on the attacker's side, macro
> flash, stun bar, breaker pip, and BREAK!/CLIP CANCEL callouts. HUD count
> 82; the base ladder intentionally excludes move-specific repeat/variety.
> Existing CPU behavior, A2/A3/A4 rulings, versus and solo rules are
> unchanged by this batch (presentation-only: the stage bounds are the one
> arena-data change, 24-296 → 44-276).
>
> Baseline for this design branch at `982d5e3`: all 24 existing headless
> suites passed; this proposal does not change any suite counts or runtime
> behavior.
## 1. What this game is (verified stack)

**Sidewalk Showdown** is a mature-rated 2D pixel-art arcade fighter: a washed-up
livestreamer, Tripp Vlogs, rigs a sidewalk tournament; the vertical slice is Peg
Leg Peggy vs Whiskey Richard on two layered Florida stages, with a 15-panel
comic intro, solo-vs-CPU and local-versus modes, and a full deterministic
fighting-game core (frame data, blocking, throws/techs, EX meter spenders,
launchers/juggles, a full-bar METHtality finisher). Tech stack, verified in
`game/project.godot` and `.github/workflows/`:

| Item | Value |
|---|---|
| Engine | Godot **4.7.2** (`config/features "4.7"`; CI and local binary pin 4.7.2.stable) |
| Simulation | fixed **60 Hz** (`physics/common/physics_ticks_per_second = 60`) |
| Viewport | **320x180**, window override 1280x720, stretch `canvas_items`, integer scale, nearest-neighbor filter |
| Language | GDScript only (no C#); `.tres` resources for all balance data |
| Targets | PC: Linux x86_64 + Windows x64 (CI exports on every `main` push / `v*` tag) |
| Repo | `violentwave/sidewalk-showdown` (public), squash-merge-only `main` with a guard bot |

## 2. Current state of `main`

HEAD `982d5e3` on `origin/main` (2026-11-23; PR #99 UI Playtest Fixes,
after PR #98 Input Remapping, PR #97 Training, PR #95 README, and PR #96
Combo Phase 4 HUD). Phase
label: **GDD §13 Phase 2 — Vertical Slice, in
progress**. Shipped features, each verified in code/data:

| Feature | One-line status |
|---|---|
| Peg Leg Peggy | 1000 HP, walk 95/72, jump 285, body 26x54; throw 95; command grab 14/3/24 (dmg 120, whiff rec 24); neutral special = **Peg-Lock stun** (95 dmg kept, 45f window, 60f immunity — owner call 2026-11-21); forward special launches (130x/**274y**, `launcher` data flag — raised from 228 so the authored route jump_light+jump_heavy connects at human timing, jump f34–36; route 221.40), forward EX (150x/360y, cost 50; route 256.40); METH "Walk the Plank" (1000 dmg, hitstop 30) |
| Whiskey Richard | 1000 HP, same locomotion, body 32x60; throw 105; command grab 16/3/26 (dmg 140, whiff rec 26, meter_gain_hit 8.0 authored); neutral special = **Taser Belch stun** (decision #7: 105 → 40 dmg, 45f window, 240f immunity); launcher 260y base (full budget route jump_heavy+richard_air = 263.55 connects) / 340y EX (293.55); METH "Flaming Belch" |
| Meter (Hype) | Max 100; builds **only on landed hits** (`meter_gain_hit` 6.0 default, throws included, one award per connection); blocked pays `meter_gain_block x METER_GAIN_ON_BLOCK_SCALE` (static, **0.0**); whiff/receive values stay authored but are never awarded; **a stun-authored hit pays the attacker nothing (§10.5)**; spenders: EX specials (50 each), METHtality (full bar), and **extra combo breaks (40 each)** |
| Stuns (Phase 3) | Both neutral specials carry authored `StunEffect` rows (see the fighter rows). A landed stun replaces the move's hitstun with the 45f window (rides HITSTUN — no new states), shrinks with the hit's damage scale (below the 20f minimum it does not stun at all), never lands airborne (`launcher_safe` false), once per combo, shake-out mashing (up) cuts 3f per press after the 20f minimum, then immunity (Peggy 60f / Richard 240f); the follow-up string starts at scaling step 3; stun feedback is the authored tint on the existing flash path (no new art) |
| Combo breaker (Phase 3) | Grab+special together while in HITSTUN (grounded strings AND juggles; never blockstun): free once per round, extra breaks cost 40 meter (a 0-meter defender keeps the free one), 300f cooldown, once per combo (the rail clears with each fresh combo opening — the adversarial A1 fix). The pair persists through hitstop like the tech window (owner ruling A2: a single press on a long-hitstop impact — EX launchers 10f — still breaks once hitstop serves, via the serialized `breaker_pair_frames` latch; landed METHtalities are knockdowns and stay unbreakable). On break: the attacker's combo and dial-in die, both fighters separate 30 px over 6 frames via `direction_away_from()` (a wall-pinned defender's share transfers to the attacker — the corner-escape fix), and 20f of wake-up-style invulnerability gates everything. Round-scoped free uses re-arm in `begin_round`; all state serializes; HUD readouts/signals exposed for Phase 4 |
| Side switching | Facing is derived from the opponent each grounded neutral frame (IDLE/WALK/CROUCH), frozen everywhere else and during hitstop; 4 px deadzone; block/knockback/throw/tech side resolved positionally via `relative_side()` / `direction_away_from()` / `is_in_front_of()` (equal-x counts as in front of the attacker) |
| Pass-through | `MatchRoot.fighters_can_pass_through = true` (exported, ships ON): Smash-style bodies, no pushbox separation on ground or in air; `false` restores the legacy grounded pushbox with corner-transfer separation; jump-over works either way |
| CPU opponent | Solo P2 driven by `CpuController` (deterministic seeded LCG, presses the same `p2_*` actions as a human, ticks at physics priority -100 on completed frames); difficulties are data: `game/resources/ai/cpu_{easy,normal,hard}.tres` (reaction 22/14/8f, block 0.35/0.65/0.90, idle watchdog 90/60/40, plus the Phase 4 combo knobs string/route/launcher/stun/juggle/breaker/clip/shake); debug `p1_cpu` enables AI-vs-AI; since Phase 4 the CPU walks the authored cancel graph, chases juggles, fishes stuns, breaks (free first, meter when worthwhile), Clip Cancels, and shakes out of stuns |
| Stages | `gas_n_go` — "Everglades Gas-N-Go", `floor_y 158`, bounds 44-276, spawns 110/210; `bus_stop_night` — "Bus Stop", `floor_y 170`, bounds 44-276, spawns 110/210; each is a native 320x180 layered scene with visual-only ambience (clouds 5 px/s; Gas-N-Go 8 fps mosquitoes — the gator is hidden until it can be placed outside the bounds and clear of the meter strip; Bus Stop 8 fps 4-frame fire + flickering liquor sign). Bounds 44-276 (playtest fix 2026-11-23) keep the widest authored pose fully on screen (Richard 40.78 px half-width + 3 px slack) |
| Stage select | Shared pick after character select: every stage a `stage_scratch_ticket.png` (72x44) with its thumbnail **center-cropped** into the measured silver panel (36x16 AtlasTexture region, never scaled) and its name in outlined Marker; RANDOM last stays covered and confirms through an 18-frame integer-pixel scratch-off reveal before the same hand-off; the visual/meta RNG source is unchanged; resolved on the selector to a concrete stage id stored in `Main.last_stage_id`; empty/invalid roster stops `MatchRoot._ready()` before instantiating anything |
| Menus & flow | Content warning -> The Clip -> Title -> Main Menu (VERSUS / TRAINING / SETTINGS / EXTRAS grey / QUIT) -> VERSUS: mode select -> [solo] difficulty -> character select -> stage -> VS -> normal MatchRoot -> Results. TRAINING: P1-picks-both character select -> stage select -> training MatchRoot directly (no VS, intro, rounds, timer, KO or Results); back from character select returns to Main Menu. ScreenRouter still owns deferred transitions; FlowState carries the training-mode flag. Normal pause system options are unchanged; training adds a TRAINING/SYSTEM tab. |
| Settings | `Settings` autoload -> `user://settings.cfg` for preferences; Video / Audio / Gameplay / Accessibility / Stream / Controls tabs. `InputBindings` applies user overrides from `user://controls.cfg` at boot, swaps same-player conflicts, and supports per-player reset; settings changes save immediately. Audio buses Master/Music/SFX/Voice/UI default to 0 dB |
| Input policy | P1 keyboard + mouse only, P2 controller only (both `device = -1`); generated defaults remain in `game/tools/setup_input.gd` and `project.godot` is never edited by remapping. `combat_test` pins device policy; `remap_test` verifies runtime overrides and safety |
| Round rules | 99 s rounds; 2 wins to take the match **and lead** (2-2 continues into DECISIVE ROUNDS); double KO = both take a pip; two timeout ties draw, the third starts a 30 s SUDDEN DEATH resolved by health -> round damage -> meter -> P1 |
| Training Mode (GDD §6.4) | P1 picks both fighters, selects a stage, and enters training rules without the VS/round flow. `TrainingController` reads fighters, supplies dummy behavior through P2 actions, owns the seeded block RNG/recording/options, and serializes under MatchRoot. The only combat change is a zero-default, serialized training health floor. |
| Match HUD (UI Phase 2 + Combo Phase 4 HUD) | Street-junk HUD on the approved art: portrait/health/meter/timer frames, banners, round pips and commentary tape; m5x7 names on dark plates under the health bars; BREAK beside its pip in the meter band; a separate-line METHtality title/subtitle. Plus attacker-side combo count/damage/base-ladder tint and gated scale tag, 45-frame macro flash, remaining/spent juggle pips, stunned-fighter bar, free/paid/unavailable breaker pip, and 30-frame BREAK!/CLIP CANCEL callouts. Training adds a top-center DMG/advantage/startup/juggle/stun panel at y 29-51, hidden while a fighter overlaps it, pause tabs, and REC/PLAY state. All timers use `hud.sim_tick()`; state-backed readouts resync after load. |
| Hit FX + METH cinematics (Phase C) | Presentation-only FX on CanvasLayer 5, sheets from `FighterData.fx_set` (`game/resources/fighters/{peggy,richard}_fx_set.tres`, generated from the owner manifests): per-character light/heavy/counter/special/EX/block one-shots at the overlap center (one per contact, EX>counter>special>heavy>light), startup-attached whoosh/trail, shared landing/knockdown/wall dust; frozen by hitstop/pause, never serialized. Confirmed, unblocked METH contact starts the deterministic `METH_CINEMATIC` phase (210 frames, the 30f contact hitstop as the opening hold): both fighters puppeted from `sequence_frame` on the owner beat maps (existing clips only), props pair-anchored and clamped as one group inside 44-276 (never scaled), dim+letterbox, held banner, HUD clutter hidden; damage once on the boundary through the ordinary KO flow. Training restores the snapshot (full meter back) with a UI-confirm skip after 30f; serialize/load resumes mid-sequence; the CPU just waits. Pinned by `fx_events_test` (46) and `meth_cinematic_test` (158). |
| Combat core | 5f normal / 7f special+grab+METH buffers; hitstop per move (+2 on counter-hit); chip floors at 1 HP; damage scaling 100/100/85/70/55% (55% floor, data in `ComboTuning`); juggle POINT BUDGET: a grounded launcher grants 5 points, air normals cost 2, air specials 3, an unpayable hit rejects and stays live, with x0.7 knockback decay / x1.25 gravity / x0.9 hitstun decay per air hit (combo window gated on landing); knockdown 30f -> wake-up 12f with 6f strike / 8f throw invulnerability; knockdown rejects all throws and non-METH strikes (K1/R1); throws techable in 7f, whiff recovery 22f; command grabs untechable, in-front only; whiffed air moves lock 8f/12f un-blockable landing recovery |

## 3. Architecture map

| File | Owns |
|---|---|
| `game/scripts/main.gd` | Front-end flow: Clip -> mode -> difficulty -> character -> stage select -> match; restores the last matchup/stage on return; solo flag + `cpu_level` plumbed into `MatchRoot` |
| `game/scripts/match/match_root.gd` | `MatchRoot` — match orchestrator: phases (INTRO/FIGHT/KO/ROUND_END/MATCH_END), timer, hit polling/resolution (trades, counter-hits, B10 winner repair), pushbox separation, draw order, pause menu, CPU setup, full `serialize()`/`load()` |
| `game/scripts/combat/fighter_base.gd` | `FighterBase` — the 18-state fighter machine: input buffer, attack/cancel logic, `receive_hit()` (block/chip/tech/juggle/KO), meter, facing, and the shared side helpers (`relative_side`, `direction_away_from`, `is_in_front_of`); `serialize()`/`load()` |
| `game/scripts/combat/fighter_data.gd` | `FighterData` resource — stats, wake-up frames, tech window/recovery, METH move, `moves` array; `find_move()` skips EX rows, `find_ex_move()`, `find_command_grab()` |
| `game/scripts/combat/move_data.gd` | `MoveData` — one attack row: input/stance/level, startup/active/recovery, damage/chip, hitstun/blockstun, knockback (positive y = launcher), meter gains, hitbox, hitstop, landing/whiff recovery, invuln frames, EX cost, `cancels`, `meth` |
| `game/scripts/combat/cancel_rule.gd` | `CancelRule` — one authored cancel edge (target LIGHT/HEAVY/SPECIAL/EX, kind CHAIN/CANCEL, condition HIT/COUNTER_HIT — BLOCK/WHIFF reserved and rejected by `validate()`, inclusive frame window) |
| `game/scripts/stages/stage_data.gd` | `StageData` — registry entry: stable `id`, `display_name`, description, 80x45 thumbnail, scene |
| `game/scripts/stages/stage.gd` | Stage scene root: `floor_y`, `left_bound`/`right_bound`, `spawn_p1_x`/`spawn_p2_x`, `fire_modulate` |
| `game/scripts/match/match_roster.gd` | `MatchRoster` — `Array[FighterData]` + `Array[StageData]`; `load_default()`; the single source of truth for cast and stages |
| `game/scripts/ai/cpu_controller.gd` | `CpuController` — deterministic CPU: caches its fighter's moves/reaches at setup, plans (approach/block/poke/throw/anti-air/corner-jump/jump-in), seeded LCG, fairness reaction delay, full `serialize()`/`load_state()` |
| `game/scripts/ai/cpu_difficulty.gd` | `CpuDifficulty` — every AI knob as data; `load_level()` maps menu index -> `cpu_*.tres` with NORMAL fallback |
| `game/scripts/stages/stage_animation.gd` | Visual-only ambience (clouds, fire, sign, mosquitoes, gator) in `_process` on a visual RNG; frozen by pause, alive through hitstop, `freeze_ambient` debug toggle |
| `game/scripts/ui/screen_router.gd` | `ScreenRouter` — the front-end screen stack: push/pop/replace/clear, every push deferred (confirm-leak guard), overlays push without freeing below, last-input-device tracking for prompt glyphs. Every screen lives on a CanvasLayer (layer 20) ABOVE the match HUD and all stage art; the match itself is pushed onto the base canvas (playtest fix) |
| `game/scripts/ui/flow_state.gd` | `FlowState` — flow context: solo/versus, cpu_level, last picks, last stage, pending fighter data |
| `game/scripts/ui/settings.gd` | `Settings` autoload — `user://settings.cfg` persistence: defaults, version fill-in, apply on boot, save on change, reset applies+saves, `set_values_silently` for opening without saving; audio/video applied live |
| `game/scripts/ui/input_bindings.gd` | `InputBindings` — snapshots generated defaults, loads/saves user overrides in `user://controls.cfg`, applies per-device InputMap events at boot/runtime, swaps same-player conflicts, and validates menu routes |
| `game/scripts/ui/screens/vs_screen.gd` | `VsScreen` — the "TONIGHT'S MATCHUP" bumper: code-drawn diagonal split (P1/P2 colors, 40% edge darkening), busts sliding in over 12 integer steps, 150 frames, 20-frame skip guard |
| `game/scripts/ui/screens/results_screen.gd` | `ResultsScreen` — the match-end replacement for "Enter restarts": winner lettering + bust, stat rows from the tracker, REMATCH / CHARACTER SELECT / STAGE SELECT / MAIN MENU menu, 30-frame guard, runs above the frozen match |
| `game/scripts/ui/match_stats_tracker.gd` | `MatchStatsTracker` — presentation-only Results stats source: accumulates round_damage deltas, tracks combo maxima and meth_started, samples wins/timer at the end; never writes simulation state |
| `game/scripts/ui/screens/{content_warning,title,main_menu,quit_confirm,settings_overlay}.gd` | The Phase 1 screens (code-built, m5x7 theme, frame-counted timers, no RNG); price-sign slat rects are measured constants |
| `game/scripts/ui/ui_prompt_line.gd` | `UiPromptLine` — the confirm/back prompt with keyboard/pad glyphs matching the last device used (one bottom row, baseline y 172) |
| `game/scripts/ui/ui_text.gd` | `UiText` — the Phase 1 typography rules as helpers: Sidewalk Marker (native 10) / m5x7 (native 16), no theme outline/shadow on pixel fonts, integer positions, shared palette |
| `game/scripts/ui/mode_select.gd`, `difficulty_select.gd`, `character_select.gd`, `stage_select.gd` | The four text-style menu screens and their back- conventions (mode select back -> main menu since Phase 1) |
| `game/scripts/ui/the_clip_comic.gd` | The 15-panel intro: panel data (`game/data/story/the_clip.panels`), beat/panel advancement, procedural newsprint look, bundled OFL fonts |
| `game/scripts/ui/match_hud.gd` | `MatchHUD` — health/meter bars, timer, round pips, messages, combo counter, pause menu rendering |
| `game/scripts/match/training_controller.gd` | Training-only dummy/options/LCG/recording, P2 input playback, health/meter/breaker rules and serialized readouts |
| `game/scripts/ui/hud/training_panel.gd` | Training-only last-hit damage/advantage/startup, juggle/stun readout panel |
| `game/scripts/debug/debug_overlay.gd` | F1 boxes, F2 frame state/advantage/invuln countdown, F3 input history, F4 slow-mo, F5 frame-step, F6 refill; mutes itself headless |
| `game/scripts/audio/audio_manager.gd` | Intro/fight track looping + hit/block/UI/round/KO/METH cues (temporary audio) |
| `game/scripts/combat/peggy_clip_library.gd`, `richard_clip_library.gd` | Authored per-state/per-move clip tables (presentation only; cadence + `h_ref` scale) |
| `game/scripts/fx/fx_layer.gd` | `FxLayer` — CanvasLayer-5 presentation FX: contact one-shots from `FighterData.fx_set`, startup whoosh/trail, landing/knockdown/wall dust; sim-clock stepping frozen by hitstop/pause; never serialized |
| `game/scripts/fx/meth_cinematic_driver.gd` | `MethCinematicDriver` — the deterministic, serialized METH sequence: owner beat maps over existing clips, pair-anchored clamped props, dim/letterbox/shake, training snapshot restore + skip; MatchRoot owns the `METH_CINEMATIC` phase gate and the single deferred damage application |
| `game/tools/gen_fighter_data.gd` | Regenerates both fighter `.tres` from code — the source of truth for frame data |
| `game/tools/setup_input.gd` | Generates the whole `[input]` map from fixed tables |
| Serialization entry points | `MatchRoot.serialize()/load()` (flow + rules + CPU state + both fighters), `FighterBase.serialize()/load()`, `CpuController.serialize()/load_state()`; covered by `serialization_test.gd` and `cpu_test.gd`; inventory in `docs/SAVESTATE_PLAN.md` |

## 4. Test suites — real counts (run 2026-11-23 on this branch)

Counts are PASS+FAIL lines observed in real headless runs, not doc claims.

| Suite (`game/tests/`) | Covers | Checks | In CI |
|---|---|---:|---|
| `combat_test.gd` | Combat engine end-to-end: boxes, damage, block/chip, throws/techs, wake-up invuln, EX/METH (incl. the Phase C cinematic gate), landing, input-map device policy, side-switch/pass-through, counters, trades, juggle budget pins | **410**, 0 fail | yes |
| `round_flow_test.gd` | Phases, commentary, KO, pips, timeouts, draws, sudden death, tiebreaks, hitstop-clock, the decisive/FIGHT banners | **35**, 0 fail | yes |
| `character_select_test.gd` | Boot/warning/title/menu navigation, mode/difficulty/character/stage flow, solo two-pick, back-outs, restore, music/cues, the stage -> VS -> match hand-off | **55**, 0 fail | yes |
| `stage_select_test.gd` | Stage ids/thumbnails/scenes, RANDOM, ambience of both stages, invalid-roster guards, gator safely hidden, no stale `BusStopNight` art | **95**, 0 fail | yes |
| `stage_floor_test.gd` | Every roster stage's `floor_y` inside its measured band, pinned (158/170), bounds + spawns, and bounds keeping the widest authored fighter pose (40.78 px half-width) fully on screen | **11**, 0 fail | yes |
| `locomotion_speed_test.gd` | Peggy/Richard walk + jump parity (95/72/285 pinned) | **7**, 0 fail | yes |
| `cpu_test.gd` | CPU legality, determinism (same seed -> same hash), save/restore (incl. mid-combo/stun/break), blocking/damage/combo ordering (HARD > EASY), combo legality under fire (no breaker from blockstun), 8-match AI-vs-AI soak (3282–3896 frames, limit 5000 = worst + ~25%) | **41** | yes — fixed 2026-11-20 (engine was ticking the manually-stepped match; see §7 history); **Phase 4 combo coverage added 2026-11-22** |
| `the_clip_test.gd` | Panel art slots, canon guards, named confirm/back flow, skips, fonts | **23**, 0 fail | yes |
| `combo_test.gd` | Combo layer: legacy ladder pins, BLOCK/WHIFF cancels, Clip Cancel, macros, caps + meter-in-combo, Phase 2 juggle budget/routes/decay/serialization, mid-combo + mid-juggle save/restore, determinism, seeded route fuzz | **68**, 0 fail | yes |
| `combo_fuzz_test.gd` | Seeded fuzz over the combo layer: route search, 12/550 caps, macros/Clip-Cancel/blocked-macro/counter edges, two-build determinism, mid-combo serialize/restore, cross-up on both stages, juggle budget/routes/seeded juggle fuzz on both stages, Phase 3 stun/breaker fuzz (both matchups, both fighters as the breaking side), 8-match CPU-vs-CPU soak (3282–3896 frames after the Phase 4 CPU, limit 4900 = worst + ~25%) | **118**, 0 fail | yes — repaired 2026-11-21 (PR #76 harness port); Phase 2 juggle coverage added 2026-11-21; Phase 3 stun/breaker fuzz added 2026-11-21; **Phase 4 soak re-measured 2026-11-22** |
| `stun_breaker_test.gd` | Phase 3 stun and breaker rails end to end: window/shake-out/immunity/once-per-combo/step-3 scaling, blocked and airborne rails, buffer-freeze bounds, breaker free/meter/cooldown/once-per-combo economy, blockstun+neutral rejection, juggle breaks, the corner escape, mid-stun/mid-break serialize-restore, determinism | **55**, 0 fail | yes — **added 2026-11-21 (Phase 3)** |
| `combo_adversarial_test.gd` | INDEPENDENT audit of the combo layer (adversarial pass 2): breaker abuse, the shared grab+special pair, stun edges, seeded combined-loop fuzz, every-frame serialize/restore, P1/P2 symmetry, meter — plus the owner-ruling matrix (A2 hitstop-bridging for hitstop 6/10/30, A3 refused-pair consumption) on both stages, both slots | **102**, 0 fail | yes — **added 2026-11-22; rulings landed in `fix/adversarial-rulings`** |
| `serialization_test.gd` | Match serializable-surface keys (training mode/tab/controller, fighter health floor, and the Phase C `meth_cinematic` driver state) + round trip | **28**, 0 fail | yes |
| `b6_landing_whiff_test.gd` | Superseded B6 rule: landing a whiffed air move awards 0 meter, move clears, recovery runs | **5**, 0 fail | yes — added 2026-11-20 (asserts current behavior; exits cleanly) |
| `ui_flow_test.gd` | Phase 1 routing: router semantics, every forward/back path, confirm-leak guard, pause overlays and freed Settings overlays, greyed items, QuitConfirm default, press-required warning (30-frame guard), chat-free menu, wrap order, the stage -> VS -> match hand-off, title pulse | **55**, 0 fail | yes — 2026-11-21 polish pass (was 48; warning behavior pins updated with owner approval) |
| `settings_test.gd` | Settings persistence: defaults, fill-in, round trip, opening never saves, reset applies+saves, 0 dB defaults | **16**, 0 fail | yes — added 2026-11-21 (scratch config; player file untouched) |
| `ui_assets_test.gd` | Runtime UI art: prepare_ui size table re-run in verify mode + byte identity vs approved sources | **4**, 0 fail | yes — added 2026-11-21 |
| `ui_typography_test.gd` | Pixel-font/contrast rules and overlap-free labels in standard HUD, Controls tab, training panel and training pause tabs | **53**, 0 fail | yes |
| `ui_layout_test.gd` | Playtest-fix layout pins at 320x180: name ink vs health bars vs timer, opaque canopy-art mask, widest-pose bounds, BREAK vs meter band vs stun labels, METHtality title vs subtitle, training panel vs timer/jump apex/name ink and fighter overlap, Results banner/panel/prompt labels and TOTAL DMG totals, router/HUD/ambient z-order, and per-match F1 isolation — versus, solo, training, both stages, both character orders | **354**, 0 fail | yes — new playtest suite |
| `select_screens_test.gd` | PR A select reskins: Mode/Difficulty choices unchanged (names, order, defaults, emits, back paths), difficulty tallies, rap-sheet photo + wall copy, per-player scribble cursors, ticket focus lift, the 18-frame RANDOM scratch-off and its hand-off | **24**, 0 fail | yes — added 2026-11-22 (PR A) |
| `results_flow_test.gd` | PR B match wrap: the VS slide-in (12 integer steps), 20-frame skip guard, 150-frame duration and hand-off; Results appears at match end above the frozen match with the real winner/stats, the match HUD hidden and the pause key consumed (never opens the pause menu); no Settings overlay; serialize() identical while Results is up; the 30-frame Results guard; every Results option routes (REMATCH keeps fighters and stage through the VS bumper) | **23**, 0 fail | yes — PR B plus playtest fixes |
| `hud_test.gd` | UI Phase 2 + Combo Phase 4 HUD: combo side-mirroring, ladder tint/scale setting, macro flash, juggle/stun/breaker readouts, event callouts, pause/load resync, and unchanged MatchRoot serialization | **82**, 0 fail | yes |
| `training_test.gd` | Training flow/rules, dummy states/blocks/CPU, record/playback side-switch mirroring, resets, frame readouts, hitbox toggle, determinism and serialize/restore | **79**, 0 fail | yes — new GDD §6.4 suite; landed-METH training cinematic pinned 2026-11-23 |
| `fx_events_test.gd` | Phase C FX layer: z-order, FxSet-vs-manifest data + byte-identical runtime art, per-kind sheets per character, precedence, mirroring, attached streaks, landing/knockdown/wall dust, hitstop/pause freeze, serialize() unchanged by FX | **46**, 0 fail | yes — added 2026-11-23 (Phase C) |
| `meth_cinematic_test.gd` | Phase C METH driver: whiff/block/meter gates, exact 210-frame beat maps for both finishers, both stages/sides/walls, victim masking, mid-cinematic serialize/load, training restore + skip, CPU completion, pause freeze; per-beat numeric prop visibility/anchor/mirror checks (visual-review fix) | **158**, 0 fail | yes — added 2026-11-23 (Phase C) |
| `remap_test.gd` | Runtime key/pad rebinding, swaps/safety, persistence/corrupt fallback, per-player reset, deadzone, current prompts, and CPU/training/macro/breaker/Clip Cancel action-name paths | **36**, 0 fail | yes — new GDD §§4.1/4.6/14 suite |
| `air_probe.gd` | Balance metrics only, asserts nothing, always exits 0 | 0 (metrics) | yes (separate job) |
| `juggle_probe.gd` | Juggle balance metrics (every budget-legal launcher route, jab-only reference, candidate ladders), asserts nothing | 0 (metrics) | no |
| `juggle_route_probe.gd` | Real-hitbox juggle route timing search (human timing; ~7 min) | 0 (metrics) | no |
| `idle_render_check`, `peggy/richard_clip_render_check`, `jump_block_render_check`, `jump_block_trace`, `attack_scale_check`, `peggy/richard_jump_check`, `peggy/richard_live_soak` | Manual rendered/soak review tools; need a display, write to `/tmp/opencode/` | n/a | no |

CI (`.github/workflows/tests.yml`) runs import + the twenty-six suites (combat,
round_flow, character_select, stage_select, stage_floor, locomotion_speed,
cpu, combo, combo_fuzz, stun_breaker, combo_adversarial, the_clip, serialization, b6, ui_flow,
 settings, remap, ui_assets, ui_typography, ui_layout, select_screens, results_flow,
 hud_test, training_test, fx_events_test, meth_cinematic_test) plus the air-probe job
on push, PR, and manual dispatch; every step carries a `timeout-minutes` so
a hang fails fast. `export.yml` builds both desktop targets on `main`/`v*`;
`main_guard.yml` reverts unauthorized direct pushes to `main`.

## 5. Commands

```bash
godot --path game                                   # play (needs a display)
godot --headless --path game --import               # first run: build import cache

# headless suites (all deterministic)
godot --headless --path game --script res://tests/combat_test.gd
godot --headless --path game --script res://tests/round_flow_test.gd
godot --headless --path game --script res://tests/character_select_test.gd
godot --headless --path game --script res://tests/locomotion_speed_test.gd
godot --headless --path game --script res://tests/stage_select_test.gd
godot --headless --path game --script res://tests/stage_floor_test.gd
godot --headless --path game --script res://tests/cpu_test.gd
godot --headless --path game --script res://tests/the_clip_test.gd
godot --headless --path game --script res://tests/serialization_test.gd
godot --headless --path game --script res://tests/b6_landing_whiff_test.gd
godot --headless --path game --script res://tests/combo_test.gd
godot --headless --path game --script res://tests/combo_fuzz_test.gd
godot --headless --path game --script res://tests/stun_breaker_test.gd
godot --headless --path game --script res://tests/ui_flow_test.gd
godot --headless --path game --script res://tests/settings_test.gd
godot --headless --path game --script res://tests/remap_test.gd
godot --headless --path game --script res://tests/ui_assets_test.gd
godot --headless --path game --script res://tests/ui_typography_test.gd
godot --headless --path game --script res://tests/ui_layout_test.gd
godot --headless --path game --script res://tests/select_screens_test.gd
godot --headless --path game --script res://tests/results_flow_test.gd
godot --headless --path game --script res://tests/hud_test.gd
godot --headless --path game --script res://tests/training_test.gd
# metrics only: air_probe.gd (slow, always exits 0)

# rendered captures and manual harnesses (need DISPLAY=:0)
DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tools/readme_capture.gd   # -- swap poses swapped sides
DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tools/ui_polish_capture.gd  # regenerate docs/assets/ui/ screenshots
DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tools/training_capture.gd  # training readout capture
DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tests/richard_clip_render_check.gd

# regenerate runtime UI art from the approved street-junk set
# (copies unchanged + size-verified; never hand-edit game/art/ui/)
godot --headless --path game --script res://tools/prepare_ui.gd

# regenerate authored data (source of truth for fighter .tres)
godot --headless --path game --script res://tools/gen_fighter_data.gd

# regenerate the input map, then hand-restore the [physics] 60 Hz section
godot --headless --path game --script res://tools/setup_input.gd

# validate the owner-approved FX/METH art against its manifests and copy
# byte-identical runtime sheets into game/art/fx/ (never edits a PNG)
art/tools/prepare_fx.sh

# regenerate the per-fighter FxSet resources from fx_manifest.json
godot --headless --path game --script res://tools/gen_fx_sets.gd

# rendered captures of the METH cinematics at their key beats (needs DISPLAY)
DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tools/meth_capture.gd -- plank
DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tools/meth_capture.gd -- belch

# owner/PM review strips: 12 raw frames per sequence (f0..f198 step 18),
# then assemble the labeled 4x3 sheets into docs/assets/fx_meth/
for mode in plank_strip plank_strip_mirrored flaming_belch_strip flaming_belch_strip_mirrored; do
  DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tools/meth_capture.gd -- $mode
done
art/tools/meth_strip.sh

# local export (templates installed)
godot --headless --path game --import
godot --headless --path game --export-release linux   build/linux/sidewalk_showdown.x86_64
godot --headless --path game --export-release windows build/windows/sidewalk_showdown.exe
```

Stage art prep (`python3 art/tools/prepare_gas_n_go.py`,
`prepare_bus_stop.py`) rebuilds runtime stage layers from read-only sources;
it is owner-run — agent sessions do not use Python (see `docs/AGENT_RULES.md`).

## 6. Standing rules and gotchas

1. **Determinism is the product.** Fixed 60 Hz; every gameplay timing is
   simulation frames; presentation counters advance on the same clock so pause
   and hitstop freeze everything. No gameplay RNG: the only RNG in the loop is
   the CPU's seeded LCG; stage ambience uses a separate visual-only RNG.
2. **Every new piece of simulation state must join `serialize()`/`load()`**
   (match + fighter + CPU) and stay frame-counted — no clocks, no deltas, no
   node-order dependence. `docs/SAVESTATE_PLAN.md` is the inventory.
3. **Meter builds only on landed hits.** Never "fix" a whiff/block by awarding
   meter; `METER_GAIN_ON_BLOCK_SCALE` (0.0) is the single sanctioned knob.
4. **Art is layered and `art/source/` is read-only.** Source batches stay
   byte-for-byte untouched; `art/tools/prepare_*.py` produce normalized strips
   (owner-run); runtime art lives in `game/art/`. Combat code never hard-codes
   per-fighter balance — it lives in `.tres` regenerated by
   `gen_fighter_data.gd`.
5. **Presentation never changes gameplay.** Clip tables pick cels/cadence;
   damage, boxes, timings, knockback, buffers, cancels, invuln, hitstop, and
   round rules stay in the sim. Gameplay and presentation-only changes go in
   separate PRs.
6. **The input generator drops `physics_ticks_per_second = 60`.**
   `ProjectSettings.save()` omits engine-default values, so regenerating the
   input map deletes the `[physics]` section — re-add it by hand or the sim
   clock silently changes.
7. **`main` is squash-merge-only.** Branch from `origin/main`, open a PR, wait
   for green CI, squash-merge, delete the branch. The `main-guard` workflow
   reverts any direct push it cannot associate with a merged PR.
8. **No Python in agent sessions.** Use shell + Godot headless tooling only;
   the `art/tools/prepare_*.py` scripts are for the owner to run.
9. **Image generation stays under the 8-images-per-request limit**, and
   generated art follows `docs/PIXELLAB_ASSET_ORG.md` identity locks; nothing
   moves toward `game/art/` without owner review.
10. **Parallel agents work in separate worktrees** (`git worktree add ...`),
    never in each other's checkouts; keep commits small and single-purpose.

## 7. Open issues and decisions (verified)

Bugs / defects:

- **`cpu_test.gd` flake — FIXED (2026-11-20, root-caused).** The engine was
  still ticking the manually-stepped match: Godot re-enables a scene root's
  physics processing on tree entry in some paths, so the pre-add
  `set_physics_process(false)` from PR #67 did not reliably stick, and each
  awaited engine tick advanced phase/timer/state by wall timing. Fixed by
  disabling pre-add, post-add, and re-asserting after the ready awaits
  (`assert(not is_physics_processing())`), plus phase-driven intro stepping
  and buffer-injected scripted presses. Verified 20/20 consecutive runs
  (previously ~15/20). The same belt-and-braces build was applied to
  `combo_test.gd` (10/10).
- **`serialization_test.gd` never exits — FIXED (2026-11-20).** It now calls
  `quit(1 if failures > 0 else 0)` after the summary and gates CI.
- **`b6_landing_whiff_test.gd` is in CI (2026-11-20).** It already asserts
  the CURRENT meter economy (landing a whiffed air move awards 0 meter,
  move clears, recovery runs) — the superseding behavior, not the removed
  whiff-meter rule — and exits cleanly with 5/5.
- Kept-by-decision defects: wake-up's no-block tail (B7/W2) and air attacks
  stopping on attack (B5/M2) are owner-approved behavior, not bugs.
- Audit-era observations still open: B8 (implicit scaling, partially addressed
  by authored cancels) and B9 (hurt/push alias). Blockstun buffer aging (4b)
  remains deferred to playtest.

Balance notes (first-pass, not competitive claims):

- Air specials miss their reach target (measured 67% vs the ≤60% hypothesis)
  and stay attacker-advantaged on block; jump-in follow-ups connect only in a
  20-44 px window (kept); juggle routes measured 2026-11-21 (design §15.1):
  Peggy's base launcher connects NO air follow-up at human timing (route
  needs EX), Richard's base connects the full two-hit route; max launcher
  routes (258/286.5 base, 293/316.5 EX) vs jab-only ceilings (196.5/252.7)
  — Richard's average launcher route is still below his jab ceiling, so
  launcher economics alone do not dethrone the jab; command-grab values are
  provisional; METHtality presentation is a freeze + banner and a whiffed
  finisher still spends the full bar; no dash/backdash; CPU depth is v0.1
  (no fuzzy guard, no spacing game, no per-character gameplans).

Release blockers / decisions pending:

- **Music rights**: the owner-supplied `intro.mp3` / `fight.mp3`
  (`game/audio/temporary/`) have unconfirmed usage rights — must be resolved
  before any public release. Kenney SFX and the OGG loop are CC0; fonts OFL.
- **Licensing is undecided**; the repo defaults to all-rights-reserved.
  Three options (A all-rights-reserved + NOTICE, B CC BY-NC content + separate
  code license, C proprietary source-available) are compared in
  `docs/LICENSE_OPTIONS.md`; the owner chooses. AI-art copyrightability is
  called out for every option.
- **Human feel sign-off** is still required for Phase 1/2 exit criteria;
  passing suites are not a playtest.

## 8. Roadmap and in-progress work

- **UI foundation (Phase 1) — SHIPPED (2026-11-21).**
  ScreenRouter + FlowState, the Settings autoload + audio buses, the
  content warning / title / main menu / quit confirm screens, the
  6-item pause menu, the m5x7 theme, and the approved street-junk art
  wired via `art/tools/prepare_ui.gd`; documented in
  `docs/UI_SCREENS.md`. **Polish pass (2026-11-21, owner playtest
  feedback):** Sidewalk Marker + m5x7 typography rules
  (`game/scripts/ui/ui_text.gd`, enforced by `ui_typography_test`),
  the chat strip removed from the main menu, the content warning
  press-required, and screenshots in `docs/assets/ui/`. **Phase 3a
  (select screens) — SHIPPED on this branch (2026-11-22, PR A):** Mode
  and Difficulty restyled onto cardboard panels, Character Select
  reskinned as the mugshot board (portraits, rap sheet, scribble
  cursors), Stage Select reskinned as scratch tickets with the
  18-frame RANDOM reveal; pinned by `select_screens_test` (24). **Phase
  3b (match wrap) — SHIPPED (2026-11-22, PR B):** the VS bumper between
  stage select and the match (and every rematch), and the Results screen
  replacing "Enter restarts" with REMATCH / CHARACTER SELECT / STAGE
   SELECT / MAIN MENU; pinned by `results_flow_test` (23). **Phase 2
  (HUD) — SHIPPED on this branch (2026-11-22):** the full street-junk
  HUD reskin on the sim tick with five settings consumed, pinned by
  `hud_test` (82). **Combo Phase 4 HUD half — shipped on this branch:**
  attacker-side combo readouts, scale tint/tag, macro flash, juggle pips,
  stun bar, breaker pip and callouts, pinned by `hud_test` (82) and
   `ui_typography_test` (53). Controls is shipped on main (PR #98); Extras
   follow the plan in `docs/UI_HUD_SCREENS_PLAN.md`. **Owner playtest fix
   batch — this branch (2026-11-23):** smaller HUD names on dark plates,
   BREAK beside its pip, two-line METHtality banner, router screens above
   the HUD and all stage art, Results over a hidden HUD with no pause
   stacking and a TOTAL DMG label, stage bounds 44-276, the gator hidden,
   and the training readout relocated/relabeled; pinned by
   `ui_layout_test` (354), `stage_floor_test` (11), and
   `results_flow_test` (23).

- **Combo system** (design home: `docs/COMBO_SYSTEM_DESIGN.md`, merged
  2026-11-19 as PR #68): a four-component MK-style combo layer on the existing
  60 Hz sim — dial-a-combo macros, blockstrings/counter extensions, a
  recovery-only meter-burn "Clip Cancel", juggle-point economics, themed
  stuns, and a combo breaker. **Phase 1 (cancel-graph BLOCK unlock,
  `ComboTuning` replacing the hardcoded damage ladder, macro tracker, Clip
  Cancel) merged as PR #69.** **Phase 2 (juggle point budget, `launcher`
  data flags, authored §13 routes, landing-gated combo window, breaker hook,
  balance data + proposed retunes) merged as PR #82.** **Phase 3 (stuns +
  the combo breaker, plus the owner-approved Peggy launcher retune 228→274)
  merged as PR #85.** **Phase 4's CPU half is implemented on
  `feat/cpu-combos`** — the CPU walks the authored cancel graph, chases
  juggles, fishes stuns, breaks, Clip Cancels, and shakes out (design §12;
  knob table in `docs/CPU_OPPONENT.md`), including the A1 breaker-rail fix
  the adversarial pass recorded. The Phase 4 HUD half is now shipped on this
  branch; the eleven
  §15 decisions are all owner-approved, and the three 2026-11-21 Phase 3
  owner calls (launcher 274, ladder kept, jab deferred) are recorded in
  §15.1.
- **Training mode** (GDD §6.4) — shipped in PR #97: Main
  Menu -> P1-picks-both character select -> stage select -> training MatchRoot
  (no VS/round intro/timer/KO/Results); dummy options, seeded block modes,
  meter/health controls, P2-path record/loop playback, resets, F1 hitboxes,
  readout panel and training pause tab. Pinned by `training_test` (79).
- **Input remapping UI** (GDD §§4.1/4.6/14) — Settings → CONTROLS offers
  P1 KEYBOARD and P2 CONTROLLER sections, including gameplay, menu, pause and
  training actions. Overrides use runtime `InputMap`, save to
  `user://controls.cfg`, and leave generated defaults / `project.godot`
  untouched. `remap_test` (36) covers swaps, safety, persistence, deadzone,
  prompts, and named-action consumers.
- **METHtality presentation** — **SHIPPED (Phase C, 2026-11-23).** The full
  meter gate, spend, whiff/block rules and banner are unchanged; a confirmed,
  unblocked METH contact now plays the deterministic 210-frame cinematic
  (`MethCinematicDriver`, serialized as the `METH_CINEMATIC` phase) from the
  owner's procedurally drawn, palette-locked FX/props, with damage applied
  once at the boundary through the ordinary KO/round/Results flow; training
  restores the snapshot with a UI-confirm skip. Pinned by
  `fx_events_test` (46) and `meth_cinematic_test` (158); see
  `docs/FX_AND_METH_DESIGN.md` §7 for the as-implemented beat maps and the
  procedural-art decision (PixelLab Batch 1 draft PR #101 closed, branch kept
  as the spend record).
- **More stages** — the GDD §8 stage list is mostly unwired; the
  add-a-stage recipe (scene + `StageData` + roster append) is in
  `docs/STAGES.md`; no rotation/tournament order or per-stage music yet.
- **Roster expansion** toward the canon 15 (`CHARACTERS.md`, Phase 5);
  Burnout Bubba and Raccoon Randy are the next canon names but not slice
  alternatives.
- **Campaign** (Phase 7) — missing entirely.
- **Online / rollback** — explicitly deferred (GDD §2.4 v0.1 non-goal, §16 open
  question); the deterministic sim + full `serialize()` + pinned CPU seed are
  the preconditions being built now (`docs/SAVESTATE_PLAN.md`).

## 9. Docs index (every other Markdown file)

| Doc | One line | Status |
|---|---|---|
| `README.md` | Player/agent-facing overview: features, quick start, controls, builds, repo map, architecture rules | **Current** (2026-11-23: remap UI and controls config documented) |
| `GDD.md` | Full design + production plan (§13 phases, §14 gates, §16 open questions) | Current through input remapping and Training Mode |
| `GAME_BIBLE.md` | Story/world canon: Tripp, 15-fighter roster, rivalries, stage canon, METHtalities, campaign acts | Current (canon, not implementation status) |
| `CHARACTERS.md` | Roster bible: archetypes, five story layers, move kits, METHtalities for all 15 | Current (canon, design-only) |
| `docs/PHASE_STATUS.md` | GDD §13 phase-by-phase status with owner decisions | Current through the playtest fixes, 24-suite CI, and updated UI/test counts |
| `docs/KNOWN_ISSUES.md` | Defects + decisions, build contents, input policy, test inventory | Current through the playtest fixes (bounds, gator, z-order) and the 24-suite inventory |
| `docs/CPU_OPPONENT.md` | CPU architecture, behaviors, difficulty knobs, soak results + balance reading, 41-check suite | Current (2026-11-22: Phase 4 combo behaviors, knob table, soak tables, honest limits) |
| `docs/SIDE_SWITCHING.md` | Facing derivation, cross-up blocking, pass-through flag, determinism notes | Current (verified against `fighter_base.gd`/`match_root.gd`) |
| `docs/STAGES.md` | Both stages' layers/ambience, floor_y method, thumbnails, stage select, add-a-stage recipe | Current (floor_y 158/170, bounds, spawns verified) |
| `docs/COMBO_SYSTEM_DESIGN.md` | Combo-system audit (§§1-8) + design (§§9-16), 11 owner decisions, §15.1–§15.3 implementation notes | Phases 1–4 implemented, including the combo HUD |
| `docs/COMBO_FINDINGS.md` | Seeded combo-fuzz results: harness/counter history, Phase 2 snapshot-aliasing + mid-air-expiry + base-Peggy findings, soak history, honest 6500 limit, Phase 3 skip-list closure | Current (2026-11-21, includes the Phase 2 juggle + Phase 3 stun/breaker coverage: 118/68/55 checks) |
| `docs/SAVESTATE_PLAN.md` | What `serialize()` captures, AI state object, known gaps | Current (keys verified against code) |
| `docs/PROPOSALS.md` | Historical combat-system proposals with measured results (§§1-7) | Current (2026-11-20): §§1/7 whiff-meter passages now carry inline "superseded" notes pointing to the landed-hits economy (§5); history preserved |
| `docs/PIXELORAMA_PIPELINE.md` | Idle-sheet + authored-clip pipeline for both fighters (§8-§9b) | Current (integration status matches the clip libraries) |
| `docs/PIXELLAB_ASSET_ORG.md` | PixelLab MCP project rules, style anchors, generation locks, walk-test proposal | Current (subscription counters will drift) |
| `docs/FX_AND_METH_DESIGN.md` | Phase A audit/design + Phase C as-implemented record for the separate Peggy/Richard hit FX and canon METH cinematics, incl. the procedural-art decision and owner beat maps | Current: Phase A (design, PR #100) and Phase C (implementation) shipped; the §5 PixelLab plan is superseded history |
| `docs/UI_ASSETS.md` | UI art pipeline (generated -> approved -> runtime folders), Figma layout file link, per-asset manifest with native sizes | Current (2026-11-22): Phase 1 + select screens wired; `prepare_ui.gd` documented in §2 |
| `docs/UI_SCREENS.md` | Shipped front-end, select/match-wrap screens, HUD, typography/contrast rules and captures | Current: includes the training pause tabs and training readout capture |
| `docs/UI_HUD_SCREENS_PLAN.md` | Original HUD/screens plan, routing, ScreenRouter/Settings design, build phases and open decisions | Plan; UI Phases 1–3 and GDD §6.4 Training Mode now shipped—see `docs/UI_SCREENS.md` for actual deltas |
| `docs/UI_DESIGN_RESEARCH.md` | Menu/HUD design research: audience model, motion/audio language, sourced findings vs proposals | Research; **not implemented** |
| `docs/ART_CREDITS.md` | Art provenance, font licenses, all-rights-reserved notes | Current (2026-11-21): m5x7 (Daniel Linssen, CC0) added as the UI pixel font |
| `docs/LICENSE_OPTIONS.md` | License decision document (A/B/C), AI-art caveats | Current (decision pending) |
| `docs/MAIN_BRANCH_GUARD.md` | Why `main` is squash-merge-only and how the guard works | Current (2026-11-20): now records the repo is public since 2026-11-16 |
| `docs/story/the_clip_art_manifest.md` | Panel-art delivery slots + spec for the intro | Current |
| `docs/story/the_clip_art_prompts.md` | Owner-facing generation prompts for the 15 panels | Current |
| `docs/SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md` | Prompt pack for non-defining assets (props, decals, items) | Current reference |
| `docs/archive/*.md` (2 files) | Recovered pre-repo conversation/project history | Historical by design (frozen 2026-11-03) |
| `docs/audits/*.md` (2 files + logs) | Read-only combat audit at `d523ed0` and the `e6d40d9` reconciliation | Historical by design (claims pinned to old SHAs; e.g. 124 combat checks then vs 408 now) |
| `game/audio/temporary/README.md` | Temporary audio credits: CC0 SFX, unconfirmed-rights MP3s | Current |
| `.github/pull_request_template.md` | PR checklist (summary, evidence, docs) | Current: evidence block lists all 22 CI suites plus the air probe |

## 10. Verification notes

Everything in §2-§7 was checked on 2026-11-20 in a clean worktree of
`origin/main` (`ba0906feeb`): resources read directly, scripts read directly,
all suites executed headless with Godot 4.7.2, counts taken from PASS/FAIL
output lines. Two operational surprises found during verification are recorded
in §7 (flaky CPU save/restore check; `serialization_test.gd` never exits).
