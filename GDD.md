# Sidewalk Showdown — Game Design Document

**File:** `GDD.md`  
**Version:** v0.1  
**Status:** Draft / build-planning document  
**Source Canon:** `GAME_BIBLE.md` v1.1  
**Genre:** Mature-rated 2D pixel-art arcade fighting game  
**Recommended Engine:** Godot 4.x  
**Primary Goal:** Define the playable design, technical direction, content structure, and production phases needed to move from story bible to prototype.

---

## 0. Research Basis

This GDD is written from the current **Sidewalk Showdown Game Bible** and current public engine / fighting-game implementation research.

Research-informed assumptions:

- **Godot 4.x** is suitable for a 2D fighting game prototype and full PC release.
- **PC-first development** is the safest initial target for a solo / small-team project.
- **Local versus and offline campaign** should be built before online play.
- **Online play**, if added later, should be planned around deterministic simulation and rollback-style requirements from the beginning.
- **Pixel-art production** should use strict resolution, import, scaling, and animation standards to avoid visual drift.
- **Fighting-game combat** should be built around clear states, frame timing, hitboxes, hurtboxes, pushboxes, recovery, blockstun, hitstun, knockdown, and repeatable frame data.

Primary reference areas:

- Godot 4 documentation: exporting, input events/actions, 2D animation, multiple resolutions, UI, audio, project organization, version control, networking, and `Area2D`.
- GGPO rollback networking references for future online-play planning.
- Current `GAME_BIBLE.md` canon for story, tone, roster, stages, METHtalities, and Tripp’s hidden-boss role.

---

## 1. Game Overview

### 1.1 Elevator Pitch

**Sidewalk Showdown** is a raunchy, Mature-rated, retro pixel-art fighting game where a washed-up livestreamer named **Tripp Vlogs** turns local sidewalk chaos into a scammy, winner-takes-all fighting tournament. Players choose from a roster of ridiculous street legends, fight through Tripp’s manipulated bracket, expose his livestream con, and defeat him as the hidden final boss.

### 1.2 High-Level Game Identity

| Field | Direction |
|---|---|
| **Title** | Sidewalk Showdown |
| **Genre** | 2D arcade fighting game |
| **Tone** | Raunchy, violent, absurd, grimy, adult, weirdly heartfelt |
| **Visual Style** | 8-bit / 16-bit-inspired pixel art |
| **Camera** | Side-view fighting-game camera |
| **Match Format** | 1v1, best 2-out-of-3 rounds |
| **Primary Mode** | Character-based story/campaign mode |
| **Main Antagonist** | Tripp Vlogs |
| **Boss Structure** | Tripp is the only boss and is not playable |
| **Finisher System** | METHtalities |
| **Target Rating** | Mature |
| **Initial Platform Target** | PC |
| **Recommended Engine** | Godot 4.x |

### 1.3 Design Pillars

#### Fast, Readable Arcade Combat

The game should be immediately readable. Every hit, block, whiff, dodge, special move, and METHtality should be clear at a glance.

#### Character-First Comedy

The humor should come from specific personalities, petty grudges, bad decisions, and ridiculous self-confidence. The fighters are funny because they are memorable and theatrical, not because they are generic joke characters.

#### Place-Based Worldbuilding

Stages should feel like iconic places: **The Bus Stop**, **The Liquor Store**, **Under the Bridge**, **Gas-N-Go**, **Dumpster Alley**, and other recognizable battlegrounds. No real towns or real brands.

#### Simple to Prototype, Deep Enough to Expand

The first playable build should be small: two fighters, one or two stages, basic match flow, and clean controls. The design should support later expansion into full roster, full campaign, METHtalities, and optional online play.

#### Mature, Raunchy, but Not Random

The game can be crude, violent, profane, and adult. The comedy should still be structured. Every character, stage, and system should reinforce the same world.

---

## 2. Target Platform

### 2.1 Primary Target

**PC first.**

Initial builds should target:

- Windows
- Linux
- macOS, if testing resources are available

Suggested storefront targets:

- Steam
- Itch.io
- Direct downloadable builds during testing

### 2.2 Secondary / Later Targets

Potential later targets:

- Web demo
- Steam Deck compatibility
- Consoles only after PC release maturity and legal/platform requirements are understood

### 2.3 Engine Recommendation

Use **Godot 4.x** with GDScript for the first prototype.

Recommended reasons:

- Strong 2D workflow
- Free and open-source
- Easy iteration
- Built-in input mapping
- Built-in animation tools
- Built-in UI system
- Export support for desktop platforms
- Lightweight enough for a solo developer workflow

### 2.4 Platform Non-Goals for v0.1

Do not target these in the first playable prototype:

- mobile
- console
- online ranked play
- crossplay
- rollback multiplayer
- Steam achievements
- workshop support

These can be evaluated later.

---

## 3. Gameplay Loop

### 3.1 Core Match Loop

```text
Character intro
↓
Round start
↓
Neutral spacing
↓
Approach / poke / defend
↓
Hit confirm or punish
↓
Combo / knockdown / reset
↓
Meter gain and special usage
↓
KO
↓
Next round or finish prompt
↓
Victory pose / quote
```

### 3.2 Campaign Loop

```text
Choose fighter
↓
Watch intro motivation
↓
Fight early opponent
↓
Fight personality-clash opponent
↓
Fight rival
↓
Fight sponsor/stunt match
↓
Fight late-bracket chaos match
↓
Fight final tournament opponent
↓
Hidden boss reveal
↓
Fight Tripp Vlogs
↓
Character ending
```

### 3.3 Player Motivation Loop

The player should want to:

- learn a fighter’s moves
- master timing and spacing
- discover rival dialogue
- unlock endings
- see each fighter’s METHtality
- beat Tripp with every character
- unlock gallery extras, concept art, and blooper-style content

### 3.4 Session Length Targets

| Session Type | Target Length |
|---|---:|
| Single match | 2–4 minutes |
| Story route | 20–35 minutes |
| Versus session | Unlimited / replayable |
| Training session | Player-controlled |
| Survival run | 10–20 minutes |

---

## 4. Controls

### 4.1 Control Philosophy

Controls should be:

- simple enough for casual players
- responsive enough for fighting-game players
- readable on keyboard and controller
- remappable
- consistent across all fighters
- compatible with future accessibility options

### 4.2 Recommended Base Layout

Use a simplified 4-button fighting layout for the first prototype.

| Action | Keyboard Default | Gamepad Default | Notes |
|---|---|---|---|
| Move Left | A / Left Arrow | D-Pad Left / Left Stick | Walk backward/forward depends on side |
| Move Right | D / Right Arrow | D-Pad Right / Left Stick | Walk backward/forward depends on side |
| Jump | W / Up Arrow | D-Pad Up / Left Stick Up | Directional jump supported |
| Crouch | S / Down Arrow | D-Pad Down / Left Stick Down | Enables crouching attacks/block |
| Light Attack | J | Face Button West / X | Fast, low damage |
| Heavy Attack | K | Face Button North / Y | Slower, higher damage |
| Special | L | Face Button East / B | Character-specific special input |
| Grab / Throw | U | Face Button South / A | Close-range throw |
| METHtality / Super | I | Right Shoulder | Contextual; only active when available |
| Pause | Esc | Start/Menu | Pause menu |
| Confirm | Enter / Space | A / South | UI confirm |
| Back | Backspace | B / East | UI back |

### 4.3 Blocking

Default blocking should use classic fighting-game logic:

- Hold away from opponent to block standing attacks.
- Hold down-away to block low attacks.
- Jumping cannot block unless a specific character/system rule adds it later.

This keeps the game genre-readable and avoids needing a dedicated block button.

### 4.4 Special Move Input Direction

For the first prototype, use accessible directional specials:

```text
Neutral + Special
Forward + Special
Down + Special
Back + Special
Air + Special
```

Classic quarter-circle inputs can be tested later as an optional advanced input layer.

This prevents the first prototype from getting stuck on input parsing before the combat is fun.

### 4.5 Input Buffering

Implement an input buffer early.

Recommended starting values:

| Input Type | Buffer Window |
|---|---:|
| Normal attack | 4–6 frames |
| Special attack | 6–8 frames |
| Grab | 3–5 frames |
| METHtality trigger | 10–15 frames during finish prompt |

Input buffering should make the game feel responsive without turning every button mash into accidental specials.

> **Implementation-status note (2026-11-09):** attack/grab/special buffering is
> implemented. The METHtality input buffer is 7 frames; activation requires a
> full meter only, not the future finish-prompt flow. See §5.9.

### 4.6 Remapping Requirement

All gameplay and UI inputs must be remappable in the options menu.

Use named input actions rather than hard-coded keys.

Example input action names:

```text
p1_left
p1_right
p1_up
p1_down
p1_light
p1_heavy
p1_special
p1_grab
p1_meth
p1_pause
ui_confirm
ui_back
ui_left
ui_right
ui_up
ui_down
```

> **Implementation-status note (2026-11-05):** the current input map is a fixed
> keyboard table generated by `game/tools/setup_input.gd`. Gamepad mappings and
> the in-game remapping UI are not implemented; they remain requirements for the
> §14 first-playable gate. See `docs/PHASE_STATUS.md`.

---

## 5. Combat Systems

### 5.1 Match Rules

| Rule | Default |
|---|---|
| Match type | 1v1 |
| Rounds | Best 2 out of 3 |
| Round timer | 99 seconds |
| Win condition | Reduce opponent health to 0 or have more health when time expires |
| Draw handling | Sudden-death sliver health round or double-KO rule |
| Stage hazards | Visual only in prototype |
| METHtality availability | Final round only after decisive KO / finish prompt |

> **Implementation-status note (2026-11-09):** current METHtality availability
> differs from the row above: the player needs a full meter and must press the
> METHtality input; opponent health, state, and invulnerability do not block
> activation. The final-round finish prompt is future work; see §5.9 and
> `docs/PHASE_STATUS.md`.

### 5.2 Core Combat States

Every fighter should use a clear state machine.

Required states:

```text
idle
walk_forward
walk_backward
crouch
jump_start
jump_rise
jump_fall
land
dash_forward
dash_backward
normal_light
normal_heavy
crouch_light
crouch_heavy
jump_light
jump_heavy
special_neutral
special_forward
special_down
special_back
grab_start
grab_success
grab_whiff
block_stand
block_crouch
hitstun
blockstun
knockdown
wake_up
round_win
round_lose
meth_start
meth_cinematic
```

> **Implementation-status note (2026-11-05):** this is the target state
> vocabulary. The current fighter uses one `ATTACK` state for moves (including
> grabs and the METHtality finisher) and has no `dash_forward`/`dash_backward`
> states. Treat the dash/grab/METH state names above as future requirements, not
> a description of current code. See `docs/PHASE_STATUS.md` and the
> [current-baseline audit](docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md).

### 5.3 Frame Data

All attacks should be defined with frame data.

Each attack requires:

| Field | Description |
|---|---|
| Startup | Frames before the move can hit |
| Active | Frames where hitbox is active |
| Recovery | Frames after active frames before control returns |
| Damage | Health damage |
| Block Damage | Chip damage, if any |
| Hitstun | Frames opponent is stunned on hit |
| Blockstun | Frames opponent is stunned on block |
| Knockback | Horizontal/vertical push |
| Hit Level | High, mid, low, overhead, throw |
| Cancel Rules | Whether move can cancel into special/super |
| Meter Gain | Hype gained on hit, block, whiff, or receive |

> **Implementation-status note (2026-11-06, updated for PR 2):** `MoveData`
> implements startup/active/recovery, damage, block damage, hit/blockstun,
> knockback, knockdown, hit level, hitbox data, meter gain, and now a per-move
> `cancels` array of `CancelRule` resources (target/kind/condition/window), with
> counter-specific rules taking precedence over ordinary `HIT` rules (PROPOSALS
> §6). The legacy engine-coded routes were migrated to this data with
> behavior exactly preserved (hit-only confirms, legacy windows).

### 5.4 Hitboxes, Hurtboxes, and Pushboxes

Use separate boxes for each combat purpose.

| Box Type | Purpose |
|---|---|
| Hurtbox | Area where character can be hit |
| Hitbox | Area where attack can hit opponent |
| Pushbox | Physical space occupied by fighter |
| Throwbox | Close-range grab detection |
| Proximity Box | Optional box for AI and close-range logic |
| Stage Bounds | Keeps fighters inside arena |

Prototype implementation can use Godot `Area2D` nodes for hit/hurt detection and `CollisionShape2D` for debug-visible rectangles.

> **Implementation-status note (2026-11-05):** hitboxes and pushboxes exist, but
> `hurtbox_rect()` currently aliases `pushbox_rect()`. There is no separate
> throwbox or proximity box and no hitbox/hurtbox editor workflow; those remain
> planned systems. See the [current-baseline audit](docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md)
> finding B9.

### 5.5 Hit Resolution Priority

When a move connects, resolve in this order:

1. Check if attacker is allowed to hit.
2. Check if defender is hittable.
3. Check throw immunity / strike immunity.
4. Check block state.
5. Apply hit or block result.
6. Apply hitstop.
7. Apply hitstun/blockstun.
8. Apply damage and meter changes.
9. Apply knockback.
10. Trigger VFX/SFX.
11. Check KO.
12. Check METHtality finish prompt if match-ending KO.

### 5.6 Hitstop

Hitstop is required for impact feel.

Recommended initial values:

| Impact Type | Hitstop |
|---|---:|
| Light hit | 4 frames |
| Heavy hit | 6–8 frames |
| Special hit | 8–10 frames |
| Counter hit | +2 frames |
| METHtality trigger | Cinematic freeze |

> **Implementation-status note (2026-11-05, updated for PR 1):** per-move hitstop
> is implemented and shared between attacker/defender. Counter hits are now
> detected: a strike that lands on a defender still in its own startup, and is
> not a same-frame trade, adds +2f of shared hitstop and shows a `COUNTER HIT`
> text indicator (GDD §10.3). Counter-hit cancel rules are not yet authored. See the
> [current-baseline audit](docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md)
> finding B8.

### 5.7 Health

Default health should be normalized.

Suggested prototype value:

```text
Max Health: 1000
```

Damage examples:

| Attack Type | Damage Range |
|---|---:|
| Light normal | 30–45 |
| Heavy normal | 70–100 |
| Special | 90–150 |
| Throw | 100–140 |
| Basic combo | 160–260 |
| Big punish | 280–380 |

### 5.8 Meter: Hype Meter

Use a universal meter called **Hype Meter**.

The Hype Meter represents crowd energy, livestream attention, and fighter momentum.

Meter builds from:

- landing hits
- blocking attacks
- taking damage
- whiffing risky specials slightly
- crowd-favorable actions
- taunts, if added later

Meter can be spent on:

- EX specials
- combo extensions
- defensive burst, if added
- super move, if added
- METHtality setup logic, if needed

> **Implementation-status note (2026-11-05):** EX specials are implemented as
> the current meter spender. Combo extensions, defensive burst, super moves, and
> METHtality-specific meter setup are future/conditional ideas; the current
> METHtality drains the full bar when activated at full meter.

### 5.9 METHtality Trigger

METHtalities should not interrupt normal gameplay randomly.

Recommended rule:

```text
If the player wins the final round with a valid match-ending hit,
the opponent enters a short "Finish" state.
The player has a brief window to input METHtality.
If successful, the cinematic finisher plays.
If missed, standard victory animation plays.
```

This makes METHtalities feel like a reward and keeps them from dominating match balance.

**Implementation-status note (2026-11-09):** the playable engine core differs
from the match-ending-hit recommendation above: pressing METHtality with a full
hype meter starts the finisher regardless of the opponent's health, state, or
invulnerability. The full bar is drained; the move may whiff if it cannot hit.
It reuses the normal KO flow. The final-round finish prompt, cinematic
finish-state, camera, and choreography in the recommendation remain future
work. See `docs/PROPOSALS.md` §4 and `docs/PHASE_STATUS.md`.

### 5.10 Combos and Cancels

Prototype combo rules:

- Light attacks can chain into light or heavy.
- Heavy attacks can cancel into specials on hit.
- Some specials can combo on counter-hit only.
- Throws cannot be comboed into by default.
- Jump attacks can start combos if landed deep.
- No infinite combos allowed.
- Damage scaling should apply after the third hit.

Suggested damage scaling:

| Combo Hit Count | Damage Scaling |
|---|---:|
| 1–2 hits | 100% |
| 3rd hit | 85% |
| 4th hit | 70% |
| 5th+ hit | 55% |
| Minimum scaling | 55% |

> **Owner decision (2026-11-06, documentation only):** the damage-scaling floor is
> **55%**, matching the implemented `_damage_scale()`. The 35% minimum originally
> proposed in this table is amended to 55%. The 35% value may be revisited only
> after a juggle limit exists.
>
> **Implementation-status note (2026-11-05):** the current `_damage_scale()`
> implements 100/100/85/70/55% for hits 1–2/3/4/5+, with a **55% floor**, which
> now matches the owner decision above. Cancel routes are authored in `MoveData`
> as of PR 2. The §6 juggle rules are now implemented (PR 3): at most
> **3 airborne hits per combo** (`FighterBase.JUGGLE_HIT_CAP`); the first
> airborne hit keeps the authored launch arc exactly, each repeat airborne hit
> scales horizontal pushback by `JUGGLE_KNOCKBACK_SCALE` (x0.7 per prior air
> hit), and airborne gravity is multiplied by `JUGGLE_GRAVITY_MULT` (x1.25)
> while a repeat hit carries the arc back to the floor. The counter resets only
> with the combo. Launchers are authored data as of the launcher PR: the forward
> special and its EX launch for both fighters (base ~80% of jump takeoff, EX
> higher), while crouch heavies stay hard knockdowns. The floor grid above is unchanged: the juggle limit now
> exists, but the owner has not approved revisiting the 55% floor. Counter-hit
> detection exists (see §5.6).
> Blocked strikes currently receive a fixed 45 px/s pushback in the real
> simulation, independent of authored hit knockback; there is no per-move block
> pushback or block-condition cancel data. The behavior-preserving authored-
> cancel migration and future combo rules are proposed in
> `docs/PROPOSALS.md` §6 for GDD Phase 3; they are not implemented and await
> approval. See `docs/PHASE_STATUS.md` and audit finding B8.

### 5.11 Defensive Systems

Initial defensive systems:

- stand block
- crouch block
- jump avoidance
- backdash
- throw tech, optional
- invulnerable wake-up, character-specific later

Do not add parry, burst, guard crush, roman-cancel-like mechanics, or assists in the prototype.

> **Implementation-status note (2026-11-05):** stand/crouch block, jump
> avoidance, throw tech, and a universal data-driven wake-up invulnerability
> exist. Backdash/dash are missing, and the vulnerable wake-up tail currently
> cannot block. Current throws are ordinary grounded, techable throws; no
> command-grab special was implemented in PR 6 (2026-11-06): forward+grab starts
> an UNTECHABLE THROW-level command grab per fighter (`docs/PROPOSALS.md` §7),
> while the normal grab stays techable. These are status notes; the design
> direction above remains unchanged.

### 5.12 AI Opponents

AI should be built in layers.

#### Prototype AI

- walks toward player
- blocks occasionally
- uses light/heavy attacks
- uses one special
- punishes obvious whiffs
- does not read inputs perfectly

#### Campaign AI

- personality-specific behavior
- Tripp manipulation modifiers
- stage-based aggression
- difficulty progression

#### Boss AI: Tripp

Tripp should feel unfair in presentation but fair in mechanics.

He can use drones, ring lights, and arena clutter, but every attack must have:

- readable startup
- clear telegraph
- consistent damage
- punishable recovery

### 5.13 Debug Tools

Build debug tools early.

Required debug toggles:

- show hitboxes
- show hurtboxes
- show pushboxes
- show frame state
- show frame advantage
- show input history
- show AI state
- reset round
- refill meter
- force METHtality prompt
- slow motion
- frame step

---

## 6. Game Modes

### 6.1 Story / Campaign Mode

Primary mode.

Player selects one of the 15 playable fighters and fights through a character-specific version of Tripp’s tournament.

Key features:

- fighter intro
- arcade ladder
- rival encounter
- Tripp manipulation cutscenes
- scam reveal
- hidden boss fight
- unique ending

### 6.2 Arcade Mode

A faster version of campaign mode.

Features:

- choose fighter
- fight a shorter ladder
- fight Tripp at the end
- unlock ending card
- minimal cutscenes

### 6.3 Versus Mode

Local 1v1 mode.

Features:

- player vs player
- player vs CPU
- stage select
- round settings
- timer settings
- METHtality toggle
- debug stage option for testing

### 6.4 Training Mode

Required for a fighting game.

Features:

- dummy behavior settings
- input display
- hitbox display
- frame data display
- damage readout
- combo counter
- meter controls
- reset position
- record/replay dummy input, later

### 6.5 Survival Mode

Player fights endless opponents until defeated.

Features:

- health partially restores between fights
- opponents get harder over time
- random stages
- score tracking

### 6.6 Tournament Mode

Offline bracket-style mode.

Features:

- 4-, 8-, or 16-slot bracket presentation
- CPU fill
- local multiplayer support
- random seeding
- optional Tripp interruption event

### 6.7 Gallery / Extras

Unlockable content.

Possible unlocks:

- concept art
- stage art
- character bios
- fake sponsor ads
- METHtality clips
- alternate palettes
- blooper-style Tripp clips
- ending cards

### 6.8 Online Mode

Deferred.

Online play should not be promised until the offline game feels good.

If online is pursued later, design should assume rollback-style constraints:

- deterministic gameplay
- input-based simulation
- state save/load
- re-simulation support
- strict separation of gameplay state from visuals/audio

---

## 7. Character System

### 7.1 Roster Rule

The current playable roster contains **15 fighters**.

**Tripp Vlogs is not playable.**

Tripp is the hidden final boss and the only boss in story/campaign mode.

### 7.2 Playable Fighters

| Fighter | Archetype | Rival |
|---|---|---|
| Peg Leg Peggy | Scrappy trick fighter | Stub Stan |
| Raccoon Randy | Wild rushdown / feral grappler | Garbage Gretchen |
| Deputy Deranged | Bruiser / control fighter | Stabatha Christie / Whiskey Richard |
| Lt. Dan Hurricane | Tank / survivalist | Burnout Bubba |
| Chuck Cheese Felon | Chaos / gadget fighter | Dogfood Debbie |
| ShroomBoom Betty | Trap / confusion fighter | Python Paulie |
| Python Paulie | Grappler / constrictor fighter | ShroomBoom Betty |
| Soapless Joe | Dirty speedster | Hairy Mary |
| Whiskey Richard | Power brawler / fire gimmick | Deputy Deranged |
| Dogfood Debbie | Weird zoner / bite fighter | Chuck Cheese Felon |
| Burnout Bubba | Heavy bruiser | Lt. Dan Hurricane |
| Garbage Gretchen | Projectile / zoning specialist | Raccoon Randy |
| Stub Stan | Tough mid-range fighter | Peg Leg Peggy |
| Hairy Mary | Grappler | Soapless Joe |
| Stabatha Christie | Fast assassin / slash fighter | Deputy Deranged |

### 7.3 Character Data Requirements

Each fighter should be defined by data wherever possible.

Required fields:

```yaml
id:
display_name:
archetype:
health:
walk_speed:
back_walk_speed:
jump_height:
jump_speed:
dash_distance:
weight:
meter_gain_modifier:
rival_id:
home_stage:
story_intro:
ending_id:
moves:
  normals:
  specials:
  throw:
  methtality:
palettes:
audio_voice_set:
```

> **Implementation-status and canon note (2026-11-05):** the current data
> generator authors the two playable fighters, their move rows, EX variants,
> ordinary throws, and METHtality rows, plus authored cancel rules, juggle
> limits, block pushback, and command-grab rows (PRs 2–6). See
> `docs/PROPOSALS.md` §§6–7 for the implementation status of each. Owner canon: “Combos are control-uniform across all
> fighters: every fighter shares the same input taxonomy (light/heavy x
> stand/crouch/air, five special directions, grab, EX, METH). Character identity
> comes from authored data and later animation, never from different control
> schemes.” The authored combo/grab systems must run on current silhouettes;
> animation wiring is a later art phase and not a dependency. Proposal scope is
> Peggy and Richard only.

### 7.4 Character Sheet Requirements

Each fighter should have a dedicated markdown file later:

```text
docs/characters/peg_leg_peggy.md
docs/characters/raccoon_randy.md
...
```

Each character file should include:

- public reason for entering
- private reason for entering
- what Tripp exploits
- what Tripp misunderstands
- how they reclaim their story
- archetype
- strengths
- weaknesses
- normals
- specials
- throw
- METHtality
- rival dialogue
- win quotes
- loss quotes
- arcade ending
- art notes
- animation list
- audio notes

### 7.5 Animation Requirements Per Fighter

Prototype animation budget:

| Animation | Frames |
|---|---:|
| Idle | 4 |
| Walk forward | 6 |
| Walk backward | 6 |
| Crouch | 1–2 |
| Jump start | 1 |
| Jump rise/fall | 2–3 |
| Landing | 1 |
| Light attack | 3–5 |
| Heavy attack | 5–8 |
| Crouch attacks | 3–6 |
| Jump attacks | 3–6 |
| Special 1 | 6–10 |
| Special 2 | 6–10 |
| Grab / throw | 6–12 |
| Hurt | 2 |
| Knockdown | 3–5 |
| Wake-up | 2–4 |
| Victory pose | 4–8 |
| METHtality | 8–20+ cinematic frames |

Full production can expand these.

### 7.6 Balance Goals

Each fighter should have:

- a clear identity
- at least one obvious strength
- at least one obvious weakness
- one beginner-friendly tactic
- one advanced tactic
- one unique METHtality
- one rival matchup that highlights personality

### 7.7 Boss Character: Tripp Vlogs

Tripp is not balanced like a normal playable character.

He should be:

- cinematic
- gimmicky
- annoying
- theatrical
- readable
- beatable
- memorable

He should not be playable unless a later non-canon debug or bonus mode explicitly allows it.

---

## 8. Stage System

### 8.1 Stage Design Philosophy

Stages should be place-based, readable, funny, and mechanically fair.

Each stage should contain:

- clear floor plane
- visible left/right bounds
- readable fighters against background
- foreground detail that does not obscure combat
- background gags
- animated elements
- fake signage
- spectators or environmental storytelling
- a clear narrative purpose

### 8.2 Stage List

| Stage | Role |
|---|---|
| The Bus Stop | Origin / tutorial / early stage |
| The Liquor Store | Early bracket spectacle |
| Under the Bridge | Mythic street-legend stage |
| Gas-N-Go | First sponsor-corruption stage |
| Dumpster Alley | Garbage Gretchen / Raccoon Randy drama |
| The Parking Lot | Public grudge battleground |
| The Encampment | Backstage / fighter chemistry hub |
| The Drainage Canal | Late-bracket danger stage |
| The Laundromat | Comic character-flavor stage |
| The Flea Market | Tournament becomes local phenomenon |
| The Alley Behind the Bar | Semi-final pressure cooker |
| Tripp’s Livestream Arena | Final boss stage only |

### 8.3 Stage Technical Requirements

Each stage should define:

```yaml
id:
display_name:
camera_bounds:
floor_y:
left_wall_x:
right_wall_x:
music_track:
ambient_loop:
parallax_layers:
background_animations:
foreground_elements:
spectator_points:
intro_dialogue_tags:
stage_gags:
home_character_ids:
```

### 8.4 Stage Layers

Recommended layer structure:

```text
Background sky / far structures
↓
Far parallax details
↓
Midground buildings / props
↓
Spectators / animated gags
↓
Fight floor
↓
Foreground framing props
↓
UI layer
```

### 8.5 Stage Hazards

Prototype rule:

> Stage hazards are visual only.

Do not add gameplay hazards until core combat is fun.

Later optional hazards:

- passing bus visual shake
- drone camera sweep
- shopping cart roll-by
- flickering lights
- crowd item toss in special modes only

Hazards should never decide competitive matches unless a specific party mode enables them.

### 8.6 Stage Intros

Each stage should have a short intro sting:

```text
Stage title card
↓
Fake sponsor splash
↓
Character intro pose
↓
Tripp commentary line
↓
Round start
```

Example:

> THE BUS STOP  
> Presented by Probably Legal Energy  
> “Where every route is late and every beef is personal.”

---

## 9. Campaign Flow

### 9.1 Campaign Structure

Campaign mode is character-based.

The player chooses one fighter and experiences the tournament through that fighter’s warped worldview.

The tournament is presented as a bracket, but Tripp manipulates the structure constantly.

This means the campaign can use an arcade ladder while still feeling like a rigged tournament.

### 9.2 Route Template

| Step | Purpose |
|---|---|
| Intro Scene | Establish fighter motivation |
| Fight 1 | Local opponent / easy onboarding |
| Fight 2 | Personality clash |
| Fight 3 | Rival fight |
| Fight 4 | Sponsor/stunt match |
| Fight 5 | Late-bracket chaos |
| Fight 6 | Final tournament opponent |
| Hidden Boss | Tripp Vlogs |
| Ending | Character-specific payoff |

### 9.3 Act Structure

#### Opening Cinematic: “The Clip”

Tripp films a desperate livestream at **The Bus Stop**. A fight breaks out behind him. He zooms in. The clip goes viral.

#### Act I: Tournament Announcement

Tripp announces **Sidewalk Showdown** from a folding table in a parking lot. The prize sounds big, vague, and suspicious.

#### Act II: Early Bracket

Early fights are funny, personal, and low-budget. Tripp introduces fighters with insulting nicknames and fake emotional angles.

#### Act III: The Stream Gets Bigger

Tripp adds drones, fake sponsors, live polls, merch booths, crowd chants, punishment rounds, and mid-fight ads.

#### Act IV: The Scam Cracks Open

The fighters compare contracts and realize the prize is fake, conditional, or buried under scam language.

#### Act V: Late-Game Chaos

The fighters keep fighting, but now they are also sabotaging Tripp’s production and exposing raw footage.

#### Act VI: Hidden Boss

The winner reaches the end. Tripp refuses to pay, reveals the hidden commissioner clause, and becomes the final boss.

#### Implementation notes — “The Clip” (owner-confirmed, 2026-11-12)

- The two fighters in the viral clip are Peg Leg Peggy and Whiskey Richard, arguing over a bench.
- Announced prize: $100,000 and a free house. The flyer's fine print is an illegible squiggle only; never author legible fine print.
- The intro bracket shows 15 fighters plus a "?" sixteenth slot. The tease exists ONLY in the intro. Character select is unchanged. Tripp is never a playable, selectable, or named fighter entity.
- Panel 14 keeps BOTH halves of the joke: the "?" slot is drawn, and Tripp's dialogue denies it exists.
- Name spelling stays "Tripp Vlogs" everywhere. (The owner's sprite title card reads "Vlogz"; do NOT change the spelling in code or docs.)
- Sprite-confirmed looks: Richard wears a red bandana-style cap and carries a green bottle. Peggy wears a green beanie with a white stripe and has a slim tan peg leg. Tripp wears a blue tee reading "THOUGHTS & PRAYERS" (owner to confirm), blue jeans, and white sneakers with cyan soles, and holds a smartphone.

> **Implementation-status note (2026-11-12):** boot runs the 15-panel `TheClip`
> scene before the existing character select. Space advances the current beat or
> panel (dense copy may take extra presses); Esc skips directly to select, and
> the story never advances on a timer. Panel copy and deprecated `hold_seconds`
> values live in `game/data/story/the_clip.panels`; all 15 pixel-art slots are
> installed per `docs/story/the_clip_art_manifest.md`. The printed-page styling,
> bundled fonts, and art attribution are documented in `docs/ART_CREDITS.md`.

#### Ending

Tripp is exposed. The winner gets a personal ending. The fighters share a strange, filthy, temporary sense of victory.

### 9.4 Story Delivery

Use lightweight story delivery methods first:

- intro cards
- character portraits
- dialogue boxes
- fake livestream overlays
- Tripp commentary
- short animated panels
- ending cards

Avoid full cutscene animation until the vertical slice proves the game is fun.

---

## 10. UI Requirements

### 10.1 UI Style

The UI should look like a corrupted retro arcade broadcast mixed with a cheap livestream overlay.

Visual ingredients:

- chunky pixel fonts
- bold outlines
- yellow/orange/red warning accents
- fake sponsor banners
- glitchy stream widgets
- chat popups
- cheap lower-thirds
- VHS/compression artifacts, used lightly
- high readability over chaotic backgrounds

### 10.2 Required Screens

| Screen | Purpose |
|---|---|
| Splash / Content Warning | Mature tone warning |
| Main Menu | Mode selection |
| Character Select | Select fighter and palette |
| Stage Select | Select stage for versus/training |
| Versus Screen | Fighter matchup presentation |
| Loading Screen | Tips, fake ads, lore jokes |
| Match HUD | Health, timer, round count, meter |
| Pause Menu | Resume, controls, restart, quit |
| Options | video, audio, controls, accessibility |
| Training Menu | dummy settings, meters, reset, display toggles |
| Story Dialogue | campaign text, portraits, Tripp commentary |
| Results Screen | winner, time, score, unlocks |
| Gallery | extras and unlockables |
| Credits | team, licenses, tools |

### 10.3 Match HUD

Required HUD elements:

- player names
- health bars
- timer
- round markers
- Hype Meter
- METHtality readiness indicator
- combo counter
- counter-hit indicator
- optional fake livestream viewer count during campaign
- optional Tripp commentary popups

Combo-counter status (PR 2): the combo counter exists (per-defender consecutive
hits driven by the §6 combo state and its reset timer) and hit feedback is
silhouette-only: a 3-frame strong flash on hit and a 2-frame subtle lightening
on block, both frozen for the duration of hitstop and restored to the body
color afterwards. Visual only - no sprites, animation, audio, or simulation
changes.

### 10.4 Character Select Requirements

Character select should show:

- fighter portrait
- name
- archetype
- short insult/tagline
- control difficulty
- rival hint
- home stage hint
- palette options

Tripp should not appear as selectable.

### 10.5 Accessibility Requirements

Minimum accessibility requirements:

- remappable controls
- screen shake toggle
- flashing light reduction
- subtitles for all voice lines
- separate music/SFX/voice sliders
- readable font mode
- colorblind-safe health/meter indicators
- hold-to-confirm option for METHtality input, if needed
- mature content warning screen

### 10.6 Debug UI

Developer/debug UI should include:

- FPS
- frame state
- current animation
- current attack ID
- hitbox/hurtbox toggle
- input history
- damage display
- combo counter
- AI state
- stage coordinates
- rollback-readiness state snapshot status, later

---

## 11. Art Direction

### 11.1 Visual Target

The game should look like a modern indie interpretation of 8-bit / 16-bit arcade pixel art.

It should be:

- chunky
- readable
- expressive
- exaggerated
- grimy
- colorful
- high-contrast
- funny at a glance

### 11.2 Resolution Strategy

Recommended internal reference:

```text
Base design resolution: 320x180
Aspect ratio: 16:9
Upscale target: integer scaling where possible
Common target output: 1280x720, 1920x1080
```

Use a consistent base resolution and scale up cleanly.

### 11.3 Pixel-Art Import Rules

Use strict import rules for pixel art:

- nearest-neighbor filtering
- no unwanted texture smoothing
- consistent pixels-per-unit
- consistent palette workflow
- no random mixed-resolution sprites
- no anti-aliased edges unless deliberately approved
- sprite sheets named and organized by character/action

### 11.4 Character Sprite Direction

Fighters should be readable silhouettes with exaggerated proportions.

Recommended fighter sprite height:

```text
Prototype: 64–96 px tall at base resolution
```

Use larger sprites if readability demands it.

Characters should have:

- strong silhouette
- 1–2 dominant colors
- black or dark outline
- exaggerated face/hair/props
- instantly readable gimmick
- animation that sells personality

### 11.5 Stage Art Direction

Stages should feel like playable urban legends.

Each stage needs:

- readable fight floor
- strong color mood
- recognizable landmark props
- background gags
- place-specific signage
- parallax depth
- animated environmental jokes

### 11.6 UI Art Direction

UI should combine:

- arcade cabinet energy
- cheap livestream overlays
- fake sponsor graphics
- pixel fonts
- bold damage indicators
- glitchy but readable presentation

Do not let livestream jokes obscure combat clarity.

### 11.7 Palette Direction

Overall palette:

- hot oranges
- dirty yellows
- swamp greens
- neon pinks
- gas-station reds
- old asphalt grays
- liquor-store blues
- harsh white ring lights
- saturated sunset skies

### 11.8 Asset Naming Convention

Use lowercase snake case.

Examples:

```text
spr_peg_leg_peggy_idle.png
spr_peg_leg_peggy_light_01.png
stage_bus_stop_bg_far.png
stage_bus_stop_floor.png
ui_health_bar_frame.png
sfx_hit_heavy_01.wav
music_bus_stop_loop.ogg
```

### 11.9 Suggested Art Folder Structure

```text
art/
  concepts/
  approved/
  characters/
    peg_leg_peggy/
      portraits/
      sprites/
      methtality/
  stages/
    bus_stop/
      concepts/
      layers/
      props/
  ui/
  fake_sponsors/
  palettes/
```

---

## 12. Audio Direction

### 12.1 Audio Identity

The audio should sound like a busted arcade cabinet plugged into a gas station PA system.

The soundtrack should blend:

- chiptune
- arcade rock
- dirty surf punk
- cheap synth bass
- distorted drum machines
- swampy blues riffs
- fake livestream stingers
- exaggerated impact sounds

### 12.2 Music Requirements

Each major stage should have:

- loopable main track
- intro sting
- final-round intensity layer, optional
- victory sting
- METHtality sting, optional

Music should loop cleanly and stay energetic without overwhelming combat cues.

### 12.3 SFX Requirements

Required SFX categories:

- light hit
- heavy hit
- blocked hit
- whiff
- jump
- land
- dash
- throw
- special move
- knockdown
- KO
- menu navigation
- crowd reaction
- Tripp notification sounds
- fake sponsor stingers
- METHtality-specific effects

### 12.4 Voice / Announcer Direction

Tripp should be the main campaign commentator until the final boss reveal.

Voice style:

- fake inspirational
- smug
- desperate
- performative
- increasingly panicked

A secondary livestream bot voice can undercut him.

Example:

```text
Tripp: “The crowd is going insane!”
Livestream Bot: “Detected crowd size: eleven. Four are looking for bathrooms.”
```

### 12.5 Audio Mixing

Audio sliders required:

- master
- music
- SFX
- voice
- UI
- crowd

Combat SFX should always remain readable above music.

### 12.6 File Format Direction

Suggested working formats:

| Asset Type | Working Format | Runtime Format |
|---|---|---|
| SFX | WAV | WAV/OGG |
| Music | WAV/FLAC project source | OGG loop |
| Voice | WAV | OGG |
| UI blips | WAV | WAV |

Keep source files separate from compressed runtime exports.

---

## 13. Production Phases

> **Implementation-status note:** `docs/PHASE_STATUS.md` is the current
> execution/evidence tracker for these phases. This section remains the
> production plan. The audit's “Stage 1–6” roadmap is a separate audit grouping;
> it does not renumber or replace these GDD phases.

### Phase 0 — Project Setup and Source of Truth

**Goal:** Create a clean repo and docs structure.

Deliverables:

- `GAME_BIBLE.md`
- `GDD.md`
- repo folder structure
- Godot project initialized
- README
- license notes
- naming conventions
- asset import rules
- task tracker

Exit criteria:

- project opens in Godot
- docs are committed
- file structure is clear
- AI assistants can understand where work belongs

---

### Phase 1 — Greybox Combat Prototype

**Goal:** Prove the core fighting feel before final art.

Content:

- 2 placeholder fighters
- 1 greybox stage
- movement
- jumping
- crouching
- blocking
- light/heavy attacks
- basic specials
- health bars
- timer
- round reset
- hitbox debug overlay

Exit criteria:

- two ugly boxes can fight
- hits feel responsive
- blocking works
- round flow works
- match can end and restart

> **Implementation-status note (2026-11-05):** the feature list and ordinary
> flow paths exist, and the current suites pass, but the Phase 1 exit is **not a
> blanket sign-off**. Current-main probes reproduced a knockdown strike loop
> (B1), knockdown throws (B2), freeze/stun buffer aging (B3), corner pushbox
> overlap (B4), an un-blockable wake-up tail (B7), and a post-KO winner-state
> order issue (B10); “hits feel responsive” also requires human playtesting. See
> `docs/PHASE_STATUS.md` and the
> [current-baseline reconciliation](docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md).

---

### Phase 2 — Vertical Slice

**Goal:** Create one polished sample of the real game.

Recommended content:

- 2 playable fighters: **Peg Leg Peggy and Whiskey Richard** (official
  vertical-slice cast; owner decision, 2026-11-09).
- Burnout Bubba and Raccoon Randy remain later-roster canon, not slice-cast
  alternatives.
- 1–2 real stages
  - The Bus Stop
  - Gas-N-Go
- core HUD
- character select mockup
- one METHtality prototype
- Tripp commentary sample
- one music track
- core SFX pass

Exit criteria:

- the game feels like Sidewalk Showdown
- one match looks and sounds close to the final target
- the prototype is good enough to show privately

> **Implementation-status note (2026-11-12):** the current slice implements the
> officially selected Peggy/Richard pair on Bus Stop Night with a HUD, a
> text-only two-player character-select mockup, and METHtality engine prototype.
> The 15-panel Clip prologue and its pixel-art panels are installed; a text-only
> Tripp commentary sample appears at the first fight start. The intro/menu and
> fight MP3 tracks are wired to their respective screens. The polish/private-show
> exit is still unmet: runtime fighters use a first-pass state-driven animation
> on silhouettes, but authored fighter frames and polished stage/art are not
> final; voiced/full commentary and the broader SFX pass are absent, the fighter-
> specific mini route is not implemented, and private-show approval is pending.
> Confirm usage rights for the owner-supplied MP3 tracks before public release.

---

### Phase 3 — Core Systems Buildout

**Goal:** Build reusable systems before scaling content.

Systems:

- character data system
- move data system
- hitbox/hurtbox editor workflow
- stage loader
- match manager
- round manager
- input remapping
- training mode tools
- AI baseline
- audio manager
- UI manager
- save/unlock system

Exit criteria:

- new fighters can be added without rewriting core code
- new stages can be loaded cleanly
- frame data can be tuned efficiently
- debug tools work

---

### Phase 4 — Art Direction Lock

**Goal:** Freeze the visual language.

Deliverables:

- final pixel-art scale
- final base resolution
- final palette rules
- final UI style tile
- final character sprite template
- final stage layer template
- fake sponsor visual language
- animation guide
- export/import settings

Exit criteria:

- all new art can follow one standard
- AI-generated art can be checked against the style guide
- no major visual direction changes without deliberate review

---

### Phase 5 — Playable Roster Expansion

**Goal:** Expand from vertical slice toward full roster.

Recommended order:

1. Finish 4 core fighters.
2. Balance core combat.
3. Add 4 more fighters.
4. Add remaining fighters in batches.
5. Add Tripp last as boss.

Exit criteria:

- every fighter has placeholder-complete gameplay
- every fighter has at least one special
- every fighter has a rough METHtality plan
- all rivalries are represented in dialogue or campaign flow

---

### Phase 6 — Stage Expansion

**Goal:** Add all regular stages before final boss arena polish.

Stage batch recommendation:

1. The Bus Stop
2. Gas-N-Go
3. The Liquor Store
4. Dumpster Alley
5. The Parking Lot
6. The Laundromat
7. Under the Bridge
8. The Drainage Canal
9. The Flea Market
10. The Alley Behind the Bar
11. The Encampment
12. Tripp’s Livestream Arena

Exit criteria:

- every stage is playable
- every stage has clean bounds
- every stage has music placeholder
- no stage background hurts combat readability

---

### Phase 7 — Campaign Implementation

**Goal:** Implement story/campaign mode.

Deliverables:

- character intro scenes
- route generation
- rival fights
- Tripp commentary
- scam reveal
- hidden boss reveal
- Tripp fight
- ending cards

Exit criteria:

- one fighter has a complete story route
- all fighters have placeholder story routes
- Tripp appears only at the end
- endings trigger correctly

---

### Phase 8 — Audio, UI, and Juice Pass

**Goal:** Make the game feel alive.

Work areas:

- hit sparks
- screen shake
- freeze frames
- crowd reactions
- announcer lines
- menu polish
- fake sponsors
- METHtality effects
- victory poses
- transition stingers

Exit criteria:

- hits feel satisfying
- menus feel on-theme
- audio supports gameplay clarity
- visual effects enhance, not obscure, combat

---

### Phase 9 — Testing, Balance, and Optimization

**Goal:** Stabilize the game.

Testing areas:

- input latency
- frame pacing
- controller support
- keyboard support
- hitbox accuracy
- AI difficulty
- story progression
- unlocks
- memory/performance
- export builds
- mature content review
- accessibility settings

Exit criteria:

- no progression blockers
- no known crash bugs
- match flow stable
- all modes usable
- builds run on target PC specs

---

### Phase 10 — Release Preparation

**Goal:** Prepare public release candidate.

Deliverables:

- store page assets
- trailer
- screenshots
- press kit
- mature content description
- credits
- licenses
- final exports
- patch notes template
- bug report process

Exit criteria:

- release candidate build exists
- store assets ready
- documentation ready
- known issues documented
- launch plan approved

---

### Phase 11 — Post-Launch Support

**Goal:** Support and improve after release.

Possible updates:

- balance patches
- bug fixes
- new palettes
- extra stages
- extra fighter
- challenge mode
- online prototype, if justified
- content warnings / platform compliance improvements

---

## 14. Build Priorities

### Must-Have for First Playable

- 2 fighters
- 1 stage
- movement
- blocking
- attacks
- specials
- health/timer
- round flow
- basic menu
- keyboard/controller support
- hitbox debug

> **Implementation-status note (2026-11-11):** keyboard support exists and is
> tested; gamepad support and the remap UI are missing. A text-only character
> select mockup now precedes the match, but there is no full main-menu or stage
> select flow. See `docs/PHASE_STATUS.md` for the gate status.

### Must-Have for Vertical Slice

- 2 polished fighters
- 1 polished stage
- real HUD
- music and SFX
- Tripp commentary sample
- one METHtality
- one mini story route

### Must-Have for Full v1.0

- 15 playable fighters
- Tripp hidden boss
- all core stages
- story/campaign mode
- arcade mode
- versus mode
- training mode
- METHtalities
- endings
- options/accessibility
- credits/licenses

---

## 15. Technical Architecture Notes

### 15.1 Suggested Godot Scene Structure

```text
scenes/
  main/
    Main.tscn
  menus/
    MainMenu.tscn
    CharacterSelect.tscn
    StageSelect.tscn
  match/
    MatchRoot.tscn
    MatchHUD.tscn
    RoundManager.tscn
  fighters/
    FighterBase.tscn
    peg_leg_peggy/
    raccoon_randy/
  stages/
    bus_stop/
    gas_n_go/
  ui/
  fx/
```

### 15.2 Suggested Script Structure

```text
scripts/
  core/
    GameState.gd
    SceneLoader.gd
    SaveManager.gd
  input/
    InputManager.gd
    InputBuffer.gd
  combat/
    FighterController.gd
    FighterStateMachine.gd
    Hitbox.gd
    Hurtbox.gd
    MoveData.gd
    DamageResolver.gd
  match/
    MatchManager.gd
    RoundManager.gd
  ai/
    FighterAI.gd
  ui/
  audio/
```

### 15.3 Data-Driven Content

Whenever possible, fighter moves, stats, stage metadata, and dialogue should be data-driven.

Recommended data format:

```text
JSON or Godot Resources
```

Use data for:

- fighter stats
- move definitions
- damage
- frame data
- stage metadata
- campaign route rules
- dialogue
- unlock conditions

This makes the project easier for AI assistants to edit safely.

---

## 16. Open Questions

These should be decided later, not before the first prototype.

1. Should the full game use simple directional specials only, or optional classic fighting-game inputs?
2. Should METHtalities require a specific input or a single contextual button?
3. Should campaign route order be fixed per character or generated from rules?
4. Should Tripp have multiple boss phases?
5. Should stage hazards remain cosmetic forever or exist in party modes?
6. Should online play be part of v1.0 or a post-launch goal?
7. Should Steam Deck be an explicit target after PC vertical slice?
8. Should the full game include voice acting, text-only dialogue, or partial voice barks?

---

## 17. Immediate Next Steps

1. Create the Godot project.
2. Create repo folder structure.
3. Add `GAME_BIBLE.md` and `GDD.md`.
4. Build greybox arena.
5. Build `FighterBase`.
6. Implement movement, facing, blocking, and attacks.
7. Add hitbox/hurtbox debug display.
8. Make two placeholder fighters.
9. Playtest for feel before creating final sprites.

---

## 18. Final Design Statement

**Sidewalk Showdown** should be built like a real fighting game before it is dressed like a trashy livestream circus.

The story, art, METHtalities, fake sponsors, and character comedy are the flavor.

The foundation is:

- responsive controls
- readable combat
- clean hit detection
- consistent frame timing
- clear UI
- strong character identity
- replayable match flow

If the greybox version is fun with two ugly placeholder fighters, the full version has a real chance.

If the greybox is not fun, no amount of pixel art, jokes, or METHtalities will save it.

Gameplay first.

Then grime.

Then glory.
