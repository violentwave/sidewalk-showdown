# GDD Phase Status

**Baseline:** `origin/main` at `e6d40d9607a0f0e3fc4a3be23ed592dbd9d43eda` (2026-11-05).
The companion audit reconciliation is [`docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md`](audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md).

## Current phase

The current official phase is **GDD §13 Phase 2 — Vertical Slice (in progress)**.
This is a phase placement, not an exit sign-off. The Phase 1 greybox feature set
exists, and many ordinary paths are covered by tests, but the combat audit's
knockdown loops and other uncovered edge behavior leave the overall Phase 1
feel/correctness claim at risk. Phase 2's presentation and private-show exit
criteria are not met. `README.md` now uses the same GDD phase label.

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
- **Status:** **Features implemented; exit partially verified / at risk.** The
  vertical-slice pair, stage, combat, HUD, round manager, debug overlay and pause
  path exist. Current suites exercise the listed basic paths (124 combat and 30
  round-flow checks). Current-main probes also reproduce B1, B2, B3, B4, B7 and
  B10; see the companion report. “Hits feel responsive” remains a human feel
  judgment, and the open knockdown loop/input issues prevent a blanket claim that
  combat correctness is closed.
- **Blockers:** disposition B1/B2/B3/B4/B10 before treating the foundation as
  fully verified. B5 and B7 require explicit feel/playtest decisions. Passing
  existing suites does not resolve uncovered runtime findings.

### Phase 2 — Vertical Slice

- **Requirements (§13 Phase 2, recommended content):** two playable fighters,
  one or two real stages, core HUD, a character-select mockup, one METHtality
  prototype, Tripp commentary, one music track, and core SFX. Exit: the game
  feels like Sidewalk Showdown, a match looks/sounds close to target, and it is
  suitable for a private showing.
- **Status:** **In progress; exit not met.** Peggy and Richard are playable on
  the Bus Stop stage; the HUD and METHtality engine prototype exist. METHtality
  currently uses the kill-confirm gate and a freeze/banner; GDD §5.9's
  final-round finish prompt, cinematic, camera, and choreography remain future
  work. There is no character-select mockup, Tripp commentary sample, music, or
  core SFX, and the runtime fighters remain silhouettes.
- **Blockers / decisions:** owner confirmation is needed if the recommended
  Phase 2 cast is intended to be strict: GDD §13 suggests Burnout Bubba plus
  Peggy or Randy, while the current pair is Peggy/Richard. Those names are under
  “Recommended content,” so this is a scope/canon decision, not silently treated
  as a failed hard requirement. The private-show exit also needs human approval.

### Phase 3 — Core Systems Buildout

- **Requirements / exit (§13 Phase 3):** character/move data, hitbox/hurtbox
  editor workflow, stage loader, match/round managers, input remapping, training
  tools, AI baseline, audio/UI managers, and save/unlock system. Exit: fighters
  can be added without rewriting core code, stages load cleanly, frame data is
  efficiently tunable, and debug tools work.
- **Status:** **Partial.** `FighterData`/`MoveData`, `.tres` resources and a
  generator exist; match/round flow and debug tools exist. But `MatchRoot.gd`
  preloads the two fighters and one stage, so generic selection/loading is not
  demonstrated. Input is generated from a keyboard table but has no remapping
  UI; training is limited to debug controls; AI, audio manager, save/unlock, and
  an authored hitbox editor workflow are missing. Dash/backdash states are
  absent. Cancel rules remain implicit in engine code, juggle/counter-hit rules
  are not authored, and the 55% implemented scaling floor remains unresolved
  against the GDD's proposed 35% (B8).
- **Exit verification:** not met; adding the current roster/stage still depends
  on hard-coded match setup, and several listed systems do not exist.

### Phase 4 — Art Direction Lock

- **Requirements / exit (§13 Phase 4):** final pixel scale/resolution/palette,
  UI style tile, character/stage templates, sponsor visual language, animation
  guide, and import/export settings. Exit: new art follows one standard and
  style changes require review.
- **Status:** **Partial / unverified.** AI/source concepts and prompt documents
  exist, along with export presets, but the runtime is still silhouettes and the
  final art templates/style lock are not evidenced. `KNOWN_ISSUES.md` records no
  wired animation.
- **Blockers:** art-direction approval and human review of source/exports.

### Phase 5 — Playable Roster Expansion

- **Requirements / exit (§13 Phase 5):** expand from the slice toward 15
  playable fighters; every fighter gets placeholder-complete gameplay, a
  special, a METHtality plan, and represented rivalries.
- **Status:** **Not met / early slice only.** Two fighters have gameplay data;
  the 15-character roster is canon, not a complete playable roster. Dialogue,
  campaign rivalry representation, and the remaining fighters are not complete.
- **Blockers:** Phase 3 data/selection architecture and the owner-approved
  vertical-slice cast/order.

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
  hitstop and a METHtality banner are basic scaffolding. No audio/VFX/crowd,
  screen shake, victory poses, or finished animation are wired.
- **Blockers:** do not begin until the owner approves the combat/cast decisions
  and the Phase 2 visual/audio direction.

### Phase 9 — Testing, Balance, and Optimization

- **Requirements / exit (§13 Phase 9):** latency/frame pacing, controller and
  keyboard, hitbox accuracy, AI, progression/unlocks, performance, exports,
  content/accessibility review. Exit: no progression blockers/crashes, stable
  match flow, usable modes, and builds on target PC specs.
- **Status:** **In progress; exit not met.** CI runs the combat/round suites and
  air probe; Linux/Windows export builds pass. The air probe is informational and
  has no balance assertions, but its separate CI job is still part of the
  workflow and can fail it. The current audit reproduced B1, B2, B3, B4, B7 and
  B10; controller support, latency/performance profiling, AI and progression
  coverage remain missing/unverified.
- **Blockers:** correctness and owner decisions from B1–B8, plus gamepad and
  target-machine validation. A passing old suite is not a blanket exit sign-off.

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
| First playable | Basic menu | **Partial:** pause/resume/restart/quit menu exists; no front-end/main menu or character flow. |
| First playable | Keyboard/controller support | **Partial:** keyboard is device-agnostic and tested; no gamepad mappings, support UI, or controller test. This is a documented first-playable blocker unless the owner amends §14. |
| First playable | Hitbox debug | **Implemented:** F1 boxes and other debug controls exist; box separation is incomplete (B9). |
| Vertical slice | 2 polished fighters, 1 polished stage, real HUD, music/SFX, Tripp commentary, one METHtality, mini story route | **Partial:** HUD and METHtality rules exist; polish, audio, commentary and route are missing/minimal. |
| Full v1.0 | 15 fighters, hidden Tripp boss, stages, campaign/arcade/versus/training, METHtalities, endings, options/accessibility, credits/licenses | **Not met; later GDD priorities.** |

The companion reconciliation preserves the audit’s historical `d523ed0` claims
and separately records what was and was not rechecked at `e6d40d9`.
