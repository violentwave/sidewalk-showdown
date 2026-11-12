# GDD Phase Status

**Baseline:** `main` through PR #35 (`c9bc80779c2257a01855b2f095b5b54e7626013c`); this update makes “The Clip” manually advanced and gives it printed-comic presentation.
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
- The Clip (2026-11-11):
  - The two fighters in the viral clip are Peg Leg Peggy and Whiskey Richard,
    arguing over a bench. This is confirmed canon, not a draft.
  - The announced tournament prize is $100,000 and a free house. The flyer's
    fine print is a purely visual gag: render it as an illegible smudge or
    squiggle — do NOT author legible fine-print text. The later prize-scam canon
    (GAME_BIBLE Act VI) is unchanged.
  - The intro's bracket panel shows 15 fighters plus one "?" sixteenth slot.
    This tease exists ONLY in the intro; the character-select grid remains
    exactly 15 slots (Peggy/Richard selectable, 13 locked) with no "?" entry.
    Tripp is never a playable, selectable, or named fighter entity anywhere.

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
  The current suites contain 245 combat, 33 round-flow, 13 audio/select
  integration, and 15 intro checks. K1, R1, corner separation, bounded hitstop
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
  The Clip now plays before character select; it is a 15-panel, owner-editable
  comic intro with placeholder art and the approved Peggy/Richard origin. Space
  advances one panel, Esc skips, and no timer advances the story. Procedural
  newsprint/halftone and bundled OFL comic fonts are used throughout. The
  text-only local character-select mockup (added 2026-11-11) lets P1/P2 pick
  from the approved cast and routes both choices into the match. METHtality
  activates at full meter regardless of opponent health/state, drains the bar,
  and uses a 30-frame freeze, banner, and normal KO flow. The final-round finish
  prompt, cinematic, camera, and choreography remain future work. A temporary
  CC0 loop track and hit/block/UI/KO/METHtality cues are wired; final music,
  Tripp voice/commentary, and the broader SFX pass remain. Runtime fighters
  remain silhouettes.
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
  implemented. The text-only character-select mockup chooses between the two
  slice fighters, but `MatchRoot.gd` still preloads the slice's two fighter
  resources and one stage, so generic roster/stage loading is not demonstrated.
  Input has no remapping UI; training is limited to debug controls; AI,
  save/unlock, a full audio manager/mixer, and an authored hitbox editor workflow
  are missing. A small Phase 2 audio service plays the temporary track and cues.
  Dash/backdash states are absent.
- **Owner decisions:** forward-special and its EX variant are the shared launcher
  category; EX cancels are grounded-only. Richard's 260 base launcher is an
  intentional asymmetry and enables one follow-up; Peggy retains her authored
  route. The 3-airborne-hit cap and 55% scaling floor are implemented. The
  jump-in follow-up's measured 20–44 px / 10–30 px connect window is kept.
  Command grabs are untechable with slow, punishable startup; their values remain
  provisional for the later-roster pass. Shared controls, silhouette playability
  with animation deferred, and Peggy/Richard-only slice scope are canon. The
  owner-approved directions in `docs/PROPOSALS.md` §§6–7 are implemented where
  marked; additional systems listed above remain gaps.
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
  hitstop and a METHtality banner are basic scaffolding. Temporary CC0 music and
  core hit/block/UI/round cues are wired; there is no final mix, full SFX pass,
  Tripp voice, crowd, VFX, screen shake, victory poses, or finished animation.
- **Blockers:** production of the approved combat/cast decisions and Phase 2
  visual/audio direction; no such work is part of this update.

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
| First playable | Basic menu | **Partial:** pause/resume/restart/quit and a two-player character-select mockup exist; no full front-end/main menu or stage flow. |
| First playable | Keyboard/controller support | **Partial:** keyboard is device-agnostic and tested; no gamepad mappings, support UI, or controller test. This is a documented first-playable blocker unless the owner amends §14. |
| First playable | Hitbox debug | **Implemented:** F1 boxes and other debug controls exist; box separation is incomplete (B9). |
| Vertical slice | 2 polished fighters, 1 polished stage, real HUD, music/SFX, Tripp commentary, one METHtality, mini story route | **Partial:** official Peggy/Richard cast, Bus Stop stage, character-select mockup, HUD, and full-meter METHtality exist; polished art/audio, Tripp commentary and route are missing/minimal. |
| Full v1.0 | 15 fighters, hidden Tripp boss, stages, campaign/arcade/versus/training, METHtalities, endings, options/accessibility, credits/licenses | **Not met; later GDD priorities.** |

The companion reconciliation preserves the audit’s historical `d523ed0` claims
and separately records what was and was not rechecked at `e6d40d9`.
