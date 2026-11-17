# GDD Phase Status

**Baseline:** `main` at `74e2543` (through PR #50), plus the 2026-11-16
crouch-entry transient pass. This document tracks the GDD §13 phases against
the current build; the earlier baseline note (PR #35, manually advanced “The
Clip”) is superseded.
The companion audit reconciliation is [`docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md`](audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md).

## Current phase

The current official phase is **GDD §13 Phase 2 — Vertical Slice (in progress)**.
Phase 1's greybox combat and round-flow implementation is verified by the
current suites and targeted regressions; subjective feel still needs human
playtesting. Phase 2's presentation and private-show exit criteria are not met.
`README.md` uses the same GDD phase label.

## Owner decisions — correctness, gameplay, and scope

- D1: K1 — knockdown rejects all strikes except `MoveData.meth` rows; METH
  activation is full-meter-only and works against a knocked-down target.
- D2: R1 — throws cannot connect during KNOCKDOWN.
- D3: PR 4a only — bounded hitstop buffer freeze capped at one normal
  buffer window, all buffered actions (including grab and its lockout)
  frozen together. Blockstun policy (4b) is deferred to playtest.
- METHtality (2026-11-09) — full meter plus the METH input is sufficient;
  opponent health, state, and invulnerability do not gate activation. The full
  bar is still spent and the authored 30-frame hitstop is unchanged.
- Vertical-slice cast (2026-11-09) — Peggy and Richard officially; Burnout Bubba
  and Raccoon Randy remain later-roster canon.
- The Clip (owner-confirmed, 2026-11-12):
  - The two fighters in the viral clip are Peg Leg Peggy and Whiskey Richard, arguing over a bench.
  - Announced prize: $100,000 and a free house. The flyer's fine print is an illegible squiggle only; never author legible fine print.
  - The intro bracket shows 15 fighters plus a "?" sixteenth slot. The tease exists ONLY in the intro. Character select is unchanged. Tripp is never a playable, selectable, or named fighter entity.
  - Panel 14 keeps BOTH halves of the joke: the "?" slot is drawn, and Tripp's dialogue denies it exists.
  - Name spelling stays "Tripp Vlogs" everywhere. (The owner's sprite title card reads "Vlogz"; do NOT change the spelling in code or docs.)
  - Sprite-confirmed looks: Richard wears a red bandana-style cap and carries a green bottle. Peggy wears a green beanie with a white stripe and has a slim tan peg leg. Tripp wears a blue tee reading "THOUGHTS & PRAYERS" (owner to confirm), blue jeans, and white sneakers with cyan soles, and holds a smartphone.

K1, R1, corner-separation transfer, bounded hitstop-only buffer freeze, and the
KO-phase winner repair are implemented with regression coverage. Blockstun
buffer policy 4b remains deferred to playtest.

Status labels distinguish the existence of features from validation of the
phase exit criteria:

- **Implemented:** the requirement is present in the current tree.
- **Partial:** some requirements exist, but the deliverable or exit criteria do
  not.
- **Missing:** no implementation/evidence found.
- **Deferred:** intentionally outside the current target or scheduled later.
- **Unverified:** evidence is insufficient to claim the behavior or exit.

## Production phases (`GDD.md` §13)

### Phase 0 — Project Setup and Source of Truth

- **Requirements / exit (§13 Phase 0):** game Bible/GDD, repo structure, Godot
  project, README, license notes, naming/import rules, and task tracker. Exit:
  project opens, docs are committed, structure is clear, and assistants can
  identify where work belongs.
- **Status:** **Mostly implemented; tracker evidence unverified.** `GDD.md`,
  `GAME_BIBLE.md`, `README.md`, `game/project.godot`, the repo layout, and
  licensing notes in `docs/LICENSE_OPTIONS.md` exist. The project imports and
  desktop exports have succeeded in CI. No task-tracker file was found in the
  repo; GitHub Projects/issues were not audited here.
- **Blockers / decisions:** the owner still chooses the project license. This
  does not block the current phase-status documentation.

### Phase 1 — Greybox Combat Prototype

- **Requirements (§13 Phase 1):** two placeholder fighters, one greybox stage,
  movement/jump/crouch/block, light/heavy/basic specials, health bars, timer,
  round reset, and hitbox debug. Exit: two boxes can fight, hits feel responsive,
  blocking and round flow work, and the match can end/restart.
- **Status:** **Implemented and regression-verified.** The Peggy/Richard slice,
  Bus Stop stage, combat, HUD, round manager, debug overlay, and pause path exist.
  The current suites contain 340 combat, 34 round-flow, 35 mode/character-select
  integration, and 23 intro checks. K1, R1, corner separation, bounded hitstop
  buffer freeze, and the
  post-KO winner-state repair are covered. Non-METH strikes reject during
  knockdown; METH remains the K1
  exception. Knockdown throws reject in both orientations; wall separation is
  covered in all four arrangements; hitstop buffer aging freezes for at most five
  frames. “Hits feel responsive” remains a human playtest judgment.
- **Owner playtest decisions (2026-11-07):** air attacks keep stop-on-attack
  (M2); the no-block wake-up tail is kept (W2); blockstun buffering 4b stays
  deferred (S4); the measured 20–44 px jump-in window is kept; command-grab
  values remain provisional. Richard's base launcher is 260 (one follow-up), an
  intentional asymmetry with Peggy's route. Forward-special/EX is the launcher
  category; EX cancels are grounded-only.
- **Blockers:** no known Phase 1 implementation blocker remains. Human feel
  validation is still required; Phase 2 presentation goals remain incomplete.

### Phase 2 — Vertical Slice

- **Requirements (§13 Phase 2, recommended content):** two playable fighters,
  one or two real stages, core HUD, a character-select mockup, one METHtality
  prototype, Tripp commentary, one music track, and core SFX. Exit: the game
  feels like Sidewalk Showdown, a match looks/sounds close to target, and it is
  suitable for a private showing.
- **Status:** **In progress; exit not met.** The official cast is Peggy and
  Richard on the Bus Stop stage; the HUD and METHtality engine prototype exist.
  The Clip now plays before mode select; it is a 15-panel, owner-editable
  comic intro with all 15 pixel-art panels and the approved Peggy/Richard origin.
  Space advances the current beat or panel (dense copy may take extra presses),
  Esc skips, and no timer advances the story. Procedural
  newsprint/halftone and bundled OFL comic fonts are used throughout. Mode
  select (added 2026-11-17) offers 1 PLAYER or 2 PLAYERS: solo lets P1 pick both
  fighters and spawns P2 with input disabled (no CPU AI yet), while versus keeps
  the two-player rules. The text-only character select (added 2026-11-11) lets
  each player pick from the approved cast and routes both choices into the
  match. METHtality activates at full meter regardless of opponent health/state,
  drains the bar,
  and uses a 30-frame freeze, banner, and normal KO flow. A text-only Tripp
  commentary sample appears at the first fight start. The intro/menu and fight
  MP3 tracks loop in their respective screens; hit/block/UI/KO/METHtality cues
  are wired. Peggy and Richard render the owner-approved four-cel idle
  sheets (Pixelorama pipeline, `docs/PIXELORAMA_PIPELINE.md`): the idle loop
  plays in IDLE and cel 0 is the static artwork for all other states over the
  state-driven VisualRoot motion. As of 2026-11-13, Peggy's
  non-idle states and all 16 attacks play the owner's full-animation-batch
  authored clips (`docs/PIXELORAMA_PIPELINE.md` §8); her walk/crouch-down JPEGs
  are gated off pending owner review. As of 2026-11-14, Richard
  also plays his own 40-clip batch (`docs/PIXELORAMA_PIPELINE.md` §9): 39 clips
  live (incl. side-facing walks, crouch-hold, and the `crouch_down` entry
  transient), 16/16 moves mapped, with `stage_intro`/`throw_target` gated.
  Richard's sheets are drawn at different art
  scales, so each clip records a measured `h_ref` and renders at the idle
  on-screen height with no resampling. As of 2026-11-15, a
  presentation-only polish pass (`docs/PIXELORAMA_PIPELINE.md` §9a) fixed
  frozen walk cycles, a landing pose that played mid-air, landing cel order,
  the skipped jump launch pose, and dead guard poses (stand/crouch guard now
  appears when holding back at a wall or crouch-blocking); six attack sheets
  that rendered 15–48 % oversized were recalibrated to idle height. Gameplay
  data is untouched. As of 2026-11-16, the crouch entry and stand-up
  transients are driven by a generic transient table rather than a single
  hard-coded stand-up clip, so `crouch_down` plays on entry without adding a
  simulation state.
  Both facings were reviewed in rendered matches; a 3,000-frame live-input
  soak for each fighter shows no sprite dropouts, stacking, or mid-move size
  pops.
  Remaining work: a throw cinematic (for `throw_target`), polished
  stage/fighter art, voiced/full commentary, a broader SFX pass,
  and the fighter-specific mini route. The final-round finish prompt,
  cinematic, camera, and choreography are future work. Confirm usage rights for
  owner-supplied MP3s before public release.
- **Decisions / blockers:** Burnout Bubba and Raccoon Randy remain later-roster
  canon; they are not alternatives for the approved slice cast. The private-show
  exit still needs human approval.

### Phase 3 — Core Systems Buildout

- **Requirements / exit (§13 Phase 3):** character/move data, hitbox/hurtbox
  editor workflow, stage loader, match/round managers, input remapping, training
  tools, AI baseline, audio/UI managers, and save/unlock system. Exit: fighters
  can be added without rewriting core code, stages load cleanly, frame data is
  efficiently tunable, and debug tools work.
- **Status:** **Partial, with substantial systems implemented.**
  `FighterData`/`MoveData`, `.tres` resources, and the generator exist. Authored
  cancel routes, counter-hit detection (+2 hitstop and HUD feedback), juggle/OTG
  rules, launcher/EX routes, command grabs, match/round flow, and debug tools are
  implemented. Mode select and character select choose the matchup (solo is
  P1-picks-both with an idle P2 until CPU AI lands). As of 2026-11-16 cast and
  stage come from
  `resources/match_roster.tres` (`MatchRoster` → `Array[FighterData]` +
  `Array[StageData]`); `MatchRoot` builds the stage from `selected_stage.scene`
  and no longer preloads either fighter or the Bus Stop scene, so adding a
  fighter or stage is a roster edit rather than a code edit.
  Gamepad play is implemented (2026-11-16): P1 keyboard + mouse, P2 controller,
  with the standard pad attack layout. There is no remapping UI; training is
  limited to debug controls; AI,
  save/unlock, a full audio manager/mixer, and an authored hitbox editor workflow
  are missing. A small Phase 2 audio service plays the temporary track and cues.
  Dash/backdash states are absent.
- **Owner decisions:** forward-special and its EX variant are the shared launcher
  category; EX cancels are grounded-only. Richard's 260 base launcher is an
  intentional asymmetry and enables one follow-up; Peggy retains her authored
  route. The 3-airborne-hit cap and 55% scaling floor are implemented. The
  jump-in follow-up's measured 20–44 px / 10–30 px connect window is kept.
  Command grabs are untechable with slow, punishable startup; their values remain
  provisional for the later-roster pass. Shared controls and Peggy/Richard-only
  slice scope are canon. The initial procedural silhouette
  animation direction is superseded by cropped still art under VisualRoot;
  authored pose/limb frames remain deferred. The owner-approved directions in
  `docs/PROPOSALS.md` §§6–7
  are implemented where marked; additional systems listed above remain gaps.
- **Exit verification:** partially met. Fighters and stages now load through the
  roster, and frame data is resource-driven, but the remaining listed systems
  (input remapping, training tools, AI, save/unlock, hitbox editor) do not exist.

### Phase 4 — Art Direction Lock

- **Requirements / exit (§13 Phase 4):** final pixel scale/resolution/palette,
  UI style tile, character/stage templates, sponsor visual language, animation
  guide, and import/export settings. Exit: new art follows one standard and
  style changes require review.
- **Status:** **Partial / unverified.** AI/source concepts and prompt documents
  exist, along with export presets, but runtime art is still first-pass cropped
  single poses and the final art templates/style lock are not evidenced. A
  procedural motion pass is present; authored sprite-frame animation remains
  unwired.
- **Blockers:** art-direction approval and human review of source/exports.

### Phase 5 — Playable Roster Expansion

- **Requirements / exit (§13 Phase 5):** expand from the slice toward 15
  playable fighters; every fighter gets placeholder-complete gameplay, a
  special, a METHtality plan, and represented rivalries.
- **Status:** **Not met / early slice only.** Two fighters have gameplay data;
  the 15-character roster is canon, not a complete playable roster. Dialogue,
  campaign rivalry representation, and the remaining fighters are not complete.
- **Blockers:** Phase 3 data/selection architecture and production of the
  remaining roster content.

### Phase 6 — Stage Expansion

- **Requirements / exit (§13 Phase 6):** regular stages plus Tripp’s arena;
  each playable, bounded, with music placeholders and readable combat.
- **Status:** **Not met.** Bus Stop Night is the only stage scene wired in
  `MatchRoot`; the other GDD stages and per-stage music/readability checks are
  absent.
- **Blockers:** generic stage loading from Phase 3 and art/audio production.

### Phase 7 — Campaign Implementation

- **Requirements / exit (§13 Phase 7):** intros, routes, rivals, Tripp
  commentary/reveal/fight, ending cards. Exit includes a complete route for one
  fighter and placeholder routes for all.
- **Status:** **Missing.** No route/campaign implementation or ending flow is
  evidenced.
- **Blockers:** slice/cast decisions and narrative/content production.

### Phase 8 — Audio, UI, and Juice Pass

- **Requirements / exit (§13 Phase 8):** hit effects, shake/freeze, crowd and
  announcer reactions, menu polish, METHtality effects, victory poses, and
  transition stingers. Exit: satisfying hits, on-theme menus, clear supporting
  audio, and non-obscuring effects.
- **Status:** **Partial / mostly missing.** A functional HUD and pause menu exist;
  hitstop and a METHtality banner are basic scaffolding. Temporary intro/menu and
  match tracks, a text-only Tripp sample, and core hit/block/UI/round cues are
  wired. The owner-supplied MP3 rights need confirmation before public release.
  There is no final mix, full SFX/voice pass, crowd, VFX, screen shake, victory
  poses, or finished animation.
- **Blockers:** final production and approval of the combat/cast, visual, and
  audio direction; this phase is not a substitute for human review.

### Phase 9 — Testing, Balance, and Optimization

- **Requirements / exit (§13 Phase 9):** latency/frame pacing, controller and
  keyboard, hitbox accuracy, AI, progression/unlocks, performance, exports,
  content/accessibility review. Exit: no progression blockers/crashes, stable
  match flow, usable modes, and builds on target PC specs.
- **Status:** **In progress; exit not met.** CI runs the combat/round suites and
  air probe; Linux/Windows export builds pass. The air probe is informational and
  has no balance assertions, but its separate CI job is still part of the
  workflow and can fail it. B1–B4 and B10 have regression-tested repairs; B7 is
  an explicit keep decision. B5/M2, B8/scaling, and B9/pushbox observations are
  tracked separately; controller support, latency/performance profiling, AI and
  progression coverage remain missing/unverified.
- **Blockers:** gamepad and target-machine validation, latency/performance
  profiling, and human playtesting. A passing suite is evidence for covered
  paths, not a blanket exit sign-off.

### Phase 10 — Release Preparation

- **Requirements / exit (§13 Phase 10):** store assets, trailer/screenshots,
  press kit, content description, credits/licenses, release exports, patch notes
  and bug-report process. Exit: release candidate, store assets/docs, known
  issues and approved launch plan.
- **Status:** **Not started.** CI export artifacts exist, but they are not a
  release candidate or release package. Licensing remains undecided.
- **Blockers:** all previous phase gates, license/credits decision, content and
  platform review.

### Phase 11 — Post-Launch Support

- **Requirements (§13 Phase 11):** possible post-launch balance, fixes, content
  and justified new systems.
- **Status:** **Deferred / not applicable before release.** Online is explicitly
  a GDD §2.4 v0.1 non-goal and a §16 open question; it is not a current phase
  blocker. GDD §13 Phase 11 calls an online prototype optional if justified.

## First-playable and later gates (`GDD.md` §14)

| Priority | Requirement | Current status / evidence |
|---|---|---|
| First playable | 2 fighters; 1 stage; movement; block; attacks/specials; health/timer; round flow | **Implemented** for the keyboard-controlled Peggy/Richard Bus Stop slice; edge-case findings remain. |
| First playable | Basic menu | **Partial:** pause/resume/restart/quit, mode select, and a character-select mockup exist; no full front-end/main menu or stage flow. |
| First playable | Keyboard/controller support | **Partial:** keyboard is device-agnostic and tested; no gamepad mappings, support UI, or controller test. This is a documented first-playable blocker unless the owner amends §14. |
| First playable | Hitbox debug | **Implemented:** F1 boxes and other debug controls exist; box separation is incomplete (B9). |
| Vertical slice | 2 polished fighters, 1 polished stage, real HUD, music/SFX, Tripp commentary, one METHtality, mini story route | **Partial:** official Peggy/Richard cast, Bus Stop stage, mode/character-select mockup, HUD, full-meter METHtality, 15-panel prologue, and one text-only Tripp commentary sample exist; polished runtime art, voiced/full commentary, broad SFX, and a fighter-specific route remain. |
| Full v1.0 | 15 fighters, hidden Tripp boss, stages, campaign/arcade/versus/training, METHtalities, endings, options/accessibility, credits/licenses | **Not met; later GDD priorities.** |

The companion reconciliation preserves the audit’s historical `d523ed0` claims
and separately records what was and was not rechecked at `e6d40d9`.
