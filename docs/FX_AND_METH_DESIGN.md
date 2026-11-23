# Phase A — Per-character hit FX and METHtality cinematics

**Status:** Phase A (audit/design, PR #100) and Phase C (implementation) are
**shipped**. The FX and prop art is **procedurally drawn, palette-locked, by
the PM — not PixelLab**; the PixelLab Batch 1 draft PR #101 was abandoned
(see §7) and its branch is kept only as the spend record. No game-code or
runtime-art change was produced by the PixelLab batches. The image artifacts
from the design phase are one audit contact sheet, two palette-only strips,
and the owner-approved animatic GIFs; Phase C added the 320×180 key-beat
captures in `docs/assets/fx_meth/`.

**Scope:** (1) full per-character normal-attack FX sets for Peg Leg Peggy and
Whiskey Richard; (2) scripted 3.5-second versions of their canon METHtalities,
ending in the existing KO/round flow. The fighter-specific hit effects are
separate sets, not recolors of one shared sprite.

**Owner locks carried forward:** METHtalities are deterministic, scripted
cinematics with props; their METH hit still spends the full meter and preserves
the existing whiff rule; normal-attack FX are fully per-character; victims use
their existing clips plus masks/props—there is no victim-art set.

## 1. Current-presentation audit

### 1.1 Contact, feedback, and METH flow

- `MatchRoot._physics_process()` advances the 60 Hz `sim_frame`, polls both
  attacks before resolving either (so same-frame trades remain trades), and
  returns before timer decrement when either fighter is in hitstop.
- `MatchRoot._poll_hit()` supplies the contact gate: active attack hitbox
  intersects the defender hurtbox, the defender is not invulnerable, and any
  throw-specific checks pass. It returns the move, not a contact point.
  `_resolve_hits()` calls `FighterBase.receive_hit()` and then routes the
  existing `hit_light`, `hit_heavy`, or `block` sound.
- There are no sprites for hit or block impacts today. `receive_hit()` sets a
  **3-sim-frame white hit flash** or **2-sim-frame lighter block flash**.
  Flash counters are below the hitstop early-return, so hitstop freezes them.
  Pause freezes normal physics processing.
- A counter-hit is resolved only for a landed hit when the defender was in its
  own attack startup and did not trade. It adds two frames of shared hitstop and
  emits `counter_hit_landed`. A grounded launcher is recognized from positive
  vertical knockback with `knockdown == false`.
- Stun already has fighter-authored `StunEffect.tint` feedback (Peggy’s
  ice-blue Peg-Lock; Richard’s Taser Belch yellow) through the same flash path.
  `stun_started`/`stun_ended` exist. The proposal adds **no stun sprites**.
- Breaker already emits `breaker_used(was_free)` and the HUD gives it a
  `BREAK!` callout. Clip Cancel emits `clip_cancelled` and shows `CLIP CANCEL`.
  These are sufficient reads; the proposal adds **no separate breaker or
  Clip-Cancel particle set**.
- `FighterBase._landing_check()` transitions airborne fighters into `LAND`;
  knockdown is a fighter state. There is no dedicated wall-contact FX event.
  Landing/knockdown dust can be one shared **environmental** set, not an
  attack effect. A Phase C wall event is needed only on an actual clamp/contact,
  not every frame a fighter is wall-pinned.
- Existing world ordering is fighters at z 0/1 (attacker above defender),
  stage ambience can be z 10, HUD CanvasLayer 10, and router screens CanvasLayer
  20. Recommended FX CanvasLayer 5 is above all stage/world pixels and fighters,
  below the HUD and router. Cinematic actor clones and props use a separate
  presentation group so foreground masks can cover a victim.
- Stage ambience is visual-only `_process()` work: pause freezes it, hitstop
  does not. The new FX/cinematic clocks must be sim-frame work and must freeze
  on both pause and hitstop.

### 1.2 Existing METHtality behavior (no Phase A change)

`can_meth()` requires a METH row and 100/100 meter; it does **not** check target
health, state, or invulnerability. `_try_start_meth()` spends the entire meter,
starts the authored row, then emits `meth_started`. The current rows are
`3 startup / 2 active / 24 recovery`, 1000 damage, knockdown, and 30f hitstop.
The 30f hitstop is applied on a connecting hit, not a whiff. Meter is still
spent on a whiff (including out-of-range or invulnerable targets).
If a legal defender blocks the METH, current block/chip handling applies
(including the row’s hitstop); that is not a cinematic hit and must not KO.

`meth_started` immediately shows the existing `METHtality / <name>` HUD banner
and plays the temporary `meth` cue. Its banner art/layout comes from HUD PR #92
and was refined in the UI playtest batch in PR #99. The banner currently
auto-removes after 120 sim frames. A lethal hit enters `MatchRoot`’s ordinary 100-frame KO phase,
then the regular round/match/Results flow. There is currently no cinematic
driver, camera work, or choreography. Phase C should keep the same full-meter
gate, spend, data damage, 30f contact freeze, whiff behavior, and normal KO flow.

### 1.3 Proposed event/anchor map

| Event | Current source / state | FX decision and anchor |
|---|---|---|
| Hit | `MatchRoot._resolve_hits()` → `receive_hit()` | Per-character light/heavy/special/EX set; anchor at the **intersection of hitbox and hurtbox**, with the active-cel limb tip as a small artwork alignment offset. |
| Block | Same contact resolver; defender enters `BLOCKSTUN` | Per-character block set at the overlap center, palette subdued but still character-specific. |
| Counter-hit | `receive_hit(counter=true)`, `counter_hit_landed` | Replace (do not stack) the normal hit burst with that fighter’s counter set at the same overlap point. |
| Launcher | Landed move with positive `knockback.y` and no knockdown | Special/launcher burst at impact plus that attacker’s short directional trail; do not trail the whole victim. |
| Stun | `stun_started`, authored tint | Keep the existing tint; no sprite/aura. The one impact burst still uses the move’s normal per-character FX. |
| Breaker | `breaker_used` | Keep the existing HUD callout; no extra particles to obscure the defensive read. |
| Clip Cancel | `clip_cancelled` | Keep the callout; optionally reuse the owner’s own special trail for a short cancellation streak. No new asset. |
| Landing | State transition to `LAND` | Shared dust at `(fighter.x, stage.floor_y)`, one-shot once per transition. |
| Knockdown | State transition to `KNOCKDOWN` | Same shared dust, only when feet actually reach the floor. |
| Wall | `clamp_to_stage()` / knockback wall stop | Phase C emits one `wall_contact` event on the collision edge. Reuse shared dust at the fighter/wall contact; do not emit every pinned frame. |

The proposed contact point is deterministic and uses the current combat
rectangles. The source clip table below also records each move’s hitbox-center
offset and the visible striking endpoint in its active cel. The offset is
fighter-root local pixels (x is multiplied by facing; y is screen-space).
`hitbox_center` is the fallback anchor; do not assume it is the exact drawn
limb tip.

### 1.4 Attack-clip audit

The sheet [`docs/assets/fx_meth/attack_clip_audit.png`](assets/fx_meth/attack_clip_audit.png)
shows **all frames** of all 16 MoveData clips per fighter. Labels report frame
count and the one-based active cel. Frame counts and anchors come from the two
clip manifests; active cels are recalculated from the current MoveData
startup/active/recovery values and `FighterBase._attack_clip_frame()`’s
phase allocation (not inferred from an AI sheet). A source clip’s full cel is
not upscaled in the sheet.

| Fighter / MoveData ID | Clip frames | Startup / active / recovery | Active cel(s), 1-based | Active-cel landmark; hitbox center |
|---|---:|---:|---:|---|
| Peggy `light` | 6 | 3 / 2 / 7 | 3 | Lead wrench/fist at upper-mid reach; `(22,-44)` |
| Peggy `heavy` | 6 | 7 / 3 / 15 | 3 | Lead tool/forearm swing; `(26,-42)` |
| Peggy `crouch_light` | 5 | 4 / 2 / 9 | 2 | Low reaching hand/tool; `(22,-24)` |
| Peggy `crouch_heavy` | 6 | 8 / 3 / 18 | 3 | Rigid prosthetic sweep near the floor; `(28,-20)` |
| Peggy `jump_light` | 6 | 4 / 3 / 10 | 2 | Forward hand in the airborne pose; `(22,-38)` |
| Peggy `jump_heavy` | 6 | 7 / 3 / 13 | 3 | Leading airborne striking limb; `(26,-36)` |
| Peggy `peggy_neutral` | 6 | 9 / 3 / 19 | 3 | Peg-Lock lead limb at chest height; `(26,-40)` |
| Peggy `peggy_forward` | 6 | 11 / 4 / 22 | 3 | Long prosthetic poke tip; `(30,-40)` |
| Peggy `peggy_down` | 6 | 10 / 3 / 20 | 3 | Low peg/foot sweep tip; `(28,-18)` |
| Peggy `peggy_back` | 6 | 8 / 3 / 18 | 3 | Counter-shuffle’s forward limb; `(24,-40)` |
| Peggy `peggy_air` | 6 | 12 / 2 / 16 | 3 | Air-special extended limb; `(26,-40)` |
| Peggy `grab` | 6 | 5 / 2 / 16 | 2 | Reaching hand; `(20,-36)` |
| Peggy `peggy_command_grab` | 6 | 14 / 3 / 24 | 3 | Command-grab contact limb; `(20,-36)` |
| Peggy `peggy_neutral_ex` | 6 | 7 / 3 / 17 | 3 | Lead tool/hand at upper-mid reach; `(28,-40)` |
| Peggy `peggy_forward_ex` | 6 | 9 / 4 / 20 | 3 | Extended peg tip; `(32,-40)` |
| Peggy `peggy_meth` | 6 | 3 / 2 / 24 | 2 | Finisher contact limb; `(30,-40)` |
| Richard `light` | 5 | 4 / 2 / 9 | 2 | Bottle hand/neck at upper-mid reach; `(22,-44)` |
| Richard `heavy` | 5 | 9 / 3 / 17 | 3 | Bottle/wrist swing after the above-head windup; `(26,-42)` |
| Richard `crouch_light` | 6 | 5 / 2 / 10 | 3 | Low bottle hand; `(22,-24)` |
| Richard `crouch_heavy` | 6 | 10 / 3 / 19 | 3 | Low leading limb; `(28,-20)` |
| Richard `jump_light` | 6 | 4 / 3 / 10 | 2 | Forward airborne bottle hand; `(22,-38)` |
| Richard `jump_heavy` | 6 | 7 / 3 / 13 | 3 | Leading airborne striking limb; `(26,-36)` |
| Richard `richard_neutral` | 6 | 9 / 3 / 19 | 3 | Taser-Belch mouth/hand effect origin; `(26,-40)` |
| Richard `richard_forward` | 6 | 11 / 4 / 22 | 3 | Forward lunge shoulder/arm; `(30,-40)` |
| Richard `richard_down` | 6 | 10 / 3 / 20 | 3 | Sliding low limb; `(28,-18)` |
| Richard `richard_back` | 6 | 8 / 3 / 18 | 3 | Counter-shuffle forward limb; `(24,-40)` |
| Richard `richard_air` | 6 | 12 / 2 / 16 | 3 | Air-special leading limb; `(26,-40)` |
| Richard `grab` | 6 | 5 / 2 / 16 | 2 | Bottle/hand-free grasping hand; `(20,-36)` |
| Richard `richard_command_grab` | 6 | 16 / 3 / 26 | 3 | Command-grab hand; `(20,-36)` |
| Richard `richard_neutral_ex` | 5 | 7 / 4 / 17 | 2 | Belch/leading-hand burst origin; `(28,-40)` |
| Richard `richard_forward_ex` | 6 | 9 / 4 / 20 | 3 | Launcher’s extended leading limb; `(32,-40)` |
| Richard `richard_meth` | 6 | 3 / 2 / 24 | 2 | Finisher mouth/belch origin; `(32,-40)` |

**Clip defects / review flags**

- **Confirmed current defect:** Peggy `meth.png`, cel **4 of 6** (one-based), is
  only a floating peg leg in the contact sheet. Repair that derived cel in
  Pixelorama before the clip can be used beyond the initial METH contact. Keep
  the approved raw source untouched.
- **Richard raw-source history, not a newly verified runtime defect:** the
  Pixelorama pipeline records detached/overlapping arm or boot components in
  the original draft sheets for `light`, `grab`, `down`, `command_grab`,
  `crouch_light`, `forward_ex`, and `neutral_ex`. The prepared runtime copies
  were re-sliced with 8-connected component handling and checked for one body
  per cel/no sub-18%-area islands. Recheck these rows against their `.pxo`
  before accepting any new edits; do not edit the raw generated batch. The
  contact sheet does not establish a second unambiguous broken forearm in the
  prepared runtime strips.
- Richard `heavy.png` deliberately raises the bottle above the head in its
  windup (`richard_clips_manifest.json` flag). Check that its hand-to-bottle
  join stays legible in the active-to-recovery transition; treat this as a
  continuity review, not a proven detached-limb defect.
- `throw_target` is disabled/unmapped for both fighters. It is not needed here:
  cinematic victims use the other fighters’ existing hitstun/knockdown/KO clips.

### 1.5 Render scale and attachment rule

The approved fighter art uses 96×80 source idle cells. `FighterBase` renders
around `SILHOUETTE_HEIGHT = 56` screen pixels and uses per-clip
`_idle_art_scale * 74 / h_ref`; Peggy’s nominal clip `h_ref` is 74, while
Richard’s sheets carry measured per-clip `h_ref` values (roughly 47–81). Typical
source-to-screen scale is therefore about `56/74 ≈ 0.76`, with the exact
per-fighter/per-clip scale taken from the renderer.

**Recommendation:** effects are authored at native **1:1 320×180 screen
pixels** and rendered at scale 1, nearest-neighbor, never resized in engine.
PixelLab’s fighter references remain 96×80 art, padded without resampling into
the mandated 160×112 actor-motion cell. Convert a clip-local endpoint into
screen space using its actual `h_ref` scale; attach the impact sprite at the
overlap center and use the active-cel endpoint only as a small, per-move visual
offset. Radial sparks are not mirrored; directional splinters, bottle spray,
and trails mirror with facing. Generate only screen-right; existing runtime
`flip_h` handles the other side.

## 2. Design A — fully per-character attack FX

Each fighter receives all eight effects below as its **own** sheet and palette.
No Peggy-to-Richard recolor or shared attack burst. FX draw in world space on a
presentation layer above the stage and fighters, below the HUD; no collision,
hurtbox, hitstop, meter, or gameplay effect. Trigger once per resolved contact,
not once per active frame.

| FX | On-screen footprint / source cell | Frames × sim ticks per frame | Trigger and anchor | Peggy treatment | Richard treatment |
|---|---|---|---|---|---|
| Light hit | ~12×12 / 32×32 | 5 × 2 = 10f | Confirmed light; overlap center, aligned to fist/tool or bottle tip | Two wood chips, one bent nail, warm metal pinprick | Amber splash and one bottle-glass glint |
| Heavy hit | ~24×20 / 32×32 | 7 × 2 = 14f | Confirmed heavy; overlap center | Broad splinter fan and one bent nail | Wider whiskey splash, two glass glints, one tiny 3×5px warm flame lick |
| Counter hit | ~24×24 / 32×32 | 7 × 2 = 14f | Counter replaces ordinary burst at same overlap center | Crossed nail/metal flash with a short splinter ring | Bottle-glass cross glint and amber burst |
| Block | ~14×12 / 32×32 | 5 × 2 = 10f | Blocked contact; overlap center; slightly lower contrast than hit | Duct-tape fleck + dull tool-on-tool spark | Small amber splash + glass tick |
| Special / launcher hit | ~36×24 / 48×32 | 7 × 2 = 14f | Special contact; launcher variant adds a short upward streak from the hit point | Peg/hardware streak and a few wood slivers | Amber-red flame wisp and glass glint |
| EX hit | ~36×32 / 48×48 | 9 × 2 = 18f | EX contact; replaces normal/special burst | Larger metal spray, still limited to Peggy’s sampled colors | Brighter amber/cream flare with dark-red glass shards |
| Heavy whoosh | ~30×10 / 48×24 | 5 × 2 = 10f | Heavy startup, beside the moving hand/tool/bottle and behind the strike direction | Short duct-tape/wood-and-metal scrape | Bottle/arm amber streak |
| Special trail | ~40×14 / 64×32 | 7 × 2 = 14f | Special startup/active arc; attached to the source limb path, not the victim | Long peg/tool streak, especially for forward specials | Short flame/whiskey ribbon; never a fireball projectile |

FX frames are one-shot and keyed to `MatchRoot.sim_frame`: they freeze during
pause and hitstop and never use wall-clock time, `delta`, RNG, or serialized
gameplay state. For each move family, use the active-cel landmarks in §1.4 and
local hitbox center as the default. If effect collisions overlap (counter + EX),
apply precedence **EX > counter > launcher/special > heavy > light** and spawn
only one primary impact.

**Not attack FX:** stun continues to use its existing per-character tint;
breaker and Clip Cancel keep their current HUD callouts with no new sprite.
Landing/knockdown uses one shared environmental `landing_dust_sheet.png`
(~40×12 visible, 5 frames × 3 ticks = 15f), anchored to feet/floor contact.
This is generic dirt/surface dust, not either fighter’s weapon effect.

### Palette locks used by every effect

These are exact opaque colors sampled from the approved idle frame plus the
named current clip references. `P-FX` and `R-FX` remain closed palettes for
**fighter pixels**; no new hue is allowed on either actor. FX/props may add
only the separate accents below.

- **Peggy palette `P-FX`:** `#211711`, `#251913`, `#2F1D14`, `#442C1F`,
  `#464834`, `#70281D`, `#BF7E4B`, `#DA9259`, `#DD965D`, `#CD854F`.
  The rust/olive/ochre hardware colors are preferred over a new bright-yellow
  or cool-blue spark.
- **Richard palette `R-FX`:** `#000000`, `#0B0200`, `#28140C`, `#1F2B3A`,
  `#273645`, `#731711`, `#89281C`, `#CB8A60`, `#DDA074`, `#E3CEB4`.
  The “fire” read is amber/cream against his sampled dark-red/black, not a new
  neon yellow. Whiskey fumes use the warm brown/cream portion.
- **Peggy FX-only accent `P-ACCENT`:** `#C9D1CC` pale steel highlight,
  `#FFF2B3` hot spark white-yellow, `#E9822A` warm orange ember.
- **Richard FX-only accent `R-ACCENT`:** `#F16A2D` flame orange,
  `#FFD34F` flame yellow, `#FFF2DA` hot cream/white core. Whiskey fumes do
  **not** use these accents: keep them amber/brown from `R-FX`, with opaque
  pixel dithering rather than semi-transparent alpha.

The accents are never used on fighter pixels. Define `P-VFX = P-FX ∪
P-ACCENT` and `R-VFX = R-FX ∪ R-ACCENT`; hit FX and colored props may use only
the matching VFX union. Richard fumes use `R-FX` only, amber/brown with
opaque-pixel dithering (no partial-alpha smoke). Fighter animation jobs receive
`P-FX` or `R-FX` alone. The two pure, 32×416 swatch strips are
`docs/assets/fx_meth/peggy_fx_palette_strip.png` and
`docs/assets/fx_meth/richard_fx_palette_strip.png`; each is sampled `P-PAL` or
`R-PAL` followed by its three FX-only accents, with no labels/background colors.

The list for the shared dust is the union of the two sampled palettes’ dark
earth/cream colors. Phase B should re-sample these files from bytes before
submitting jobs; if any listed color is absent from the exact chosen reference
pair, replace it with a color that is present and update the table/metadata.

`P-PAL` is the union sampled from `P-ID`,
`game/art/characters/peg_leg_peggy/clips/heavy.png` cel 3, and
`game/art/characters/peg_leg_peggy/clips/forward.png` cel 3. `R-PAL` is the
union sampled from `R-ID`,
`game/art/characters/whiskey_richard/clips/heavy.png` cel 3,
`game/art/characters/whiskey_richard/clips/neutral.png` cel 3, and
`game/art/characters/whiskey_richard/clips/meth.png` cel 2. For
`color_image_url`, Phase B makes one nearest-neighbor palette-reference strip
from those exact source pixels inside each review folder (not a generated
asset). Metadata records the source paths, cel numbers, and exact palette hex
list.

## 3. Design B — full METHtality storyboards

Both storyboards run for **210 sim frames (3.5 s)** from a confirmed METH
contact. The existing **30f hitstop is the opening freeze**; the remaining 180
frames are the active choreography. The METH banner appears on `meth_started`
as it does today and is held for the sequence by the existing banner node
(retime its current 120f auto-remove to 210f only while the cinematic owns it).
Props are attached to the attacker/target pair’s relative midpoint and clamped
as one composition to the 44–276 arena bounds. They are never placed at a
hard-coded stage x/y, so both fighters’ side order, both walls, and both
current stages work without stage-art edits.

The table’s victim clips are existing assets: `hitstun_stand` (3 frames),
`knockdown` (4), `ko_air` (3), and `ko_ground` (3) from whichever current or
future fighter is the victim. If a future fighter lacks one of those clips,
the driver uses that fighter’s existing fallback/static artwork; it never asks
for new victim art. `throw_target` is currently disabled for Peggy and Richard
and is not required. The victim’s existing sprite is puppeted; no victim pose
sheet is generated.

### Peg Leg Peggy — **Walk the Plank**

Tone: practical, dangerous, and confident. The shot is a clever hardware-store
trap, not a sympathy beat. Her peg remains rigid and on its authored side.

| Sequence frames | Attacker clip / motion | Victim clip / placement | Props, mask, screen, audio |
|---|---|---|---|
| 0–29 (opening 0.5s) | Existing METH move, hold the confirmed `meth` active pose through the existing 30f contact hitstop | Hold the captured impact position; no new victim art | `meth_started` shows the existing METHTALITY / WALK THE PLANK banner and plays existing `meth` SFX. Pair-local composition is chosen; letterbox begins and ordinary HUD is dimmed. |
| 30–59 | New `meth_plank_slam`, 6 frames at 5 ticks/cel: Peggy sets her stance and drives the target down onto a broken plank | Existing `hitstun_stand` for the stumble, then the first `knockdown` cel at the board | `plank_base.png` slides in under the victim, anchored to the pair midpoint. Add one 2–3px presentation-only shake on contact; `meth_plank_hit` cue slot. |
| 60–89 | New `meth_prosthetic_pin`, 4 frames at 6 ticks/cel, then hold its final pin pose for 6 ticks | Existing `knockdown` clip; pin the victim without changing the clip or adding victim art | Peggy’s rigid prosthetic pins the board beside/over the victim. Camera/overlay shake is visual only. Optional `meth_peg_pin` click/clank cue slot. |
| 90–119 | New `meth_plank_stomp`, 6 frames at 5 ticks/cel; lift and stomp decisively | Hold the final `knockdown` pose | The plank snaps (`plank_snap_sheet.png`); the floor opening begins. One 4–6px screen-space shake, never a fighter/physics transform. `meth_plank_crack` cue slot. |
| 120–167 | Hold the stomp’s last cel; no new attacker clip | Existing `ko_air` 3×10 ticks tumbles toward the opening; then use the existing `ko_ground` cel behind the aperture for the last part | Open the pair-anchored sewer/channel mask and splash surface. Victim draws behind a foreground rim/waterline, is clipped downward, and disappears—no new victim art. `meth_sewer_drop` cue slot. |
| 168–209 | Hold Peggy’s confident stomp/recovery pose (reuse the new clip’s final cel) | Keep the existing KO pose hidden below the rim | Water/cover settles; retain the letterbox and banner until the end. On frame 210 apply the METH damage once and enter ordinary KO flow. Optional `meth_water_splash` cue slot. |

**Drop mask:** draw a dark opening behind the fighter clone, put the existing
victim sprite in a cinematic-only clip/mask group, move that sprite down in
pair-local screen coordinates, and draw the rim/water foreground over it. A
shrinking clip aperture or equivalent alpha mask hides the lower body first;
the front rim covers the last pixels. No absolute stage placement or generated
victim image. Clamp the entire board/opening group to the available safe area;
never rescale it to squeeze it beside a wall.

### Whiskey Richard — **Flaming Belch**

Tone: pathetic **and** powerful at once—the absurd belch is a dangerous,
confident finish, not a realistic alcohol depiction. The existing bottle stays
in the same hand in every new Richard frame.

| Sequence frames | Attacker clip / motion | Victim clip / placement | Props, mask, screen, audio |
|---|---|---|---|
| 0–29 (opening 0.5s) | Existing METH move; hold its confirmed active pose through the same 30f hitstop | Hold the captured impact pose | Existing METH banner and `meth` cue. Dim the scene and begin the short letterbox. |
| 30–59 | New `meth_bottle_drench`, 6 frames at 5 ticks/cel: Richard tips/splashes from the bottle in its reference hand | Existing `hitstun_stand` 3×10, held afterward | Build `whiskey_fumes_sheet.png` from the attacker/bottle anchor outward; keep faces, silhouettes, and feet readable. `meth_bottle_slosh` cue slot. |
| 60–89 | Hold the drench pose; no new attacker art | Hold the existing hitstun pose | The fume cloud expands across the **pair composition** and fills the view, but stays a translucent backdrop. It is attached to the fighter group, not a stage layer. |
| 90–119 | New `meth_belch_ignite`, 6 frames at 5 ticks/cel: chest lift, absurd belch, flame pose | Hold hitstun until launch | `fire_belch_sheet.png` starts at the mouth/belch anchor. Warm palette flash and a maximum 2px/6f screen-only shake. `meth_belch` cue slot. |
| 120–149 | Hold the ignition pose / final cel | Existing `ko_air` starts its 3-cel tumble as the flame launches the victim toward the sign | Light the fumes with a brief overlay; the sign appears ahead of the victim in pair-local space. `meth_fume_ignite` cue slot. |
| 150–179 | New `meth_sign_crash`, 6 frames at 5 ticks/cel: Richard’s follow-through, bottle still in hand | Continue existing `ko_air`; then `ko_ground` behind the sign mask | The victim passes through the fictional sign; back sign plane sits behind, front frame/shards over the fighter. Split sign fragments into back/front layers around the existing clip; no victim sheet. `meth_sign_crash` cue slot. |
| 180–209 | Hold the last follow-through, then a short embarrassed cough pose from the same reviewed clip (if the pose does not read, hold the last cel) | Victim remains occluded behind the sign/fume layer | Fumes clear enough to see Richard’s pathetic-but-powerful silhouette. Banner and letterbox end on frame 210; then apply METH damage and use ordinary KO flow. |

**Sign mask:** place the intact sign’s back plane behind the victim, animate the
existing `ko_air` sprite through its aperture, then overlay the front frame and
foreground shards at impact. The shards and planes are attached to the fighter
pair’s local anchor, not either stage’s real signage. Clip/foreground occlusion
hides any frame edge that would otherwise appear to pass through the sign.

### Shared cinematic treatment

- Use a 35% dark overlay and 8px top/bottom matte strips on the cinematic
  presentation layer. Hide timer, meter, and normal HUD clutter while retaining
  the existing METH banner; restore the normal HUD for the next round. No
  camera zoom or stage-art edit.
- Shake only a presentation canvas/group (maximum 2–4px, short, deterministic
  frame list). Never move fighter collision roots for camera shake.
- Props and actor clones use relative coordinates: attacker facing and the
  captured attacker/victim pair midpoint define the local x-axis; victim stays
  on the struck side. If the group would cross a wall, slide the **whole**
  composition inward before the first beat, with no scaling. Board/manhole/sign
  positions remain tied to the fighters throughout.
- Sound slots use the existing `meth`, `hit_heavy`, and final `ko` where
  appropriate. New one-shot slots, if approved, are `meth_plank_hit`,
  `meth_peg_pin`, `meth_plank_crack`, `meth_sewer_drop`, `meth_water_splash`,
  `meth_bottle_slosh`, `meth_belch`, `meth_fume_ignite`, and
  `meth_sign_crash`. Phase A creates no audio.

## 4. Design C — engine work required later

1. Add a deterministic `MethCinematicDriver` owned by MatchRoot and a
   `METH_CINEMATIC` phase (or equivalent serialized subphase). The driver owns
   sequence id, attacker/victim slots, start facings/positions, sequence frame,
   beat id, training/replay policy, and any pre-cinematic snapshot needed for
   training restoration.
2. Start it only on **confirmed, unblocked, valid METH contact**. `meth_started` still fires
   at full-meter activation, the meter still drains immediately, and the banner/
   `meth` cue still appear. If the METH whiffs, is out of range, or hits an
   invulnerable target, it spends meter and plays the current move/recovery, but
    starts **no cinematic** and causes no KO. A blocked METH keeps the existing
    block/chip/hitstop handling but does not start a cinematic. This keeps
    today’s miss and block rules.
3. Intercept the confirmed hit before immediate 1000 damage/KO. The 30f contact
   hitstop is the cinematic’s opening hold. Defer METH damage, do not charge
   another 30f hitstop at the ending, then apply the authored 1000 damage once
   through the ordinary hit/KO path on the final frame. Keep METH data; no
   changes to the full-meter gate or move timing.
4. Add a cinematic puppet/visual override for attacker and victim. Suspend
   both fighter state machines, ordinary hit polling/collision response, and
   input consumption during VS; the driver moves the two fighter roots along
   deterministic pair-local positions and selects pose/facing/clip-frame from
   `sequence_frame`. These scripted positions are finisher state (serialized),
   not FX transforms. Victims select their own existing `hitstun_stand`,
   `knockdown`, `ko_air`, `ko_ground`, and `throw_target` only if enabled.
   Runtime never loads a victim-specific generated clip.
5. Add an effect event interface at hit/block resolution containing attacker,
   defender, move id, contact-rectangle intersection, facing, and hit/block/
   counter/launcher kind. Add transition events for landing, knockdown,
   breaker, Clip Cancel, stun, and one-shot wall contact. These are presentation
   signals only; they must not change combat outcomes.
6. Add a match presentation FX root on CanvasLayer 5 and a cinematic layer
   between the world and HUD. Sprite transforms, props, masks, letterbox, dim,
   and shake update only from sim-frame events; freeze on pause/hitstop and use
   no `Tween`, wall-clock, `delta`, or RNG. FX one-shots are never serialized
   as gameplay state.
7. Serialize/load the active cinematic’s deterministic driver state (sequence,
   frame/beat, actor slots, facing, pair anchor, training snapshot) so save/load
   mid-cinematic resumes on the same frame. Recreate props/masks from that
   sequence state; do not serialize particles or FX instances.
8. Freeze the match timer, stage ambience, CPU, input buffers, and ordinary
   fighter logic during the sequence. Clear both fighters’ buffered actions at
   entry/exit so no buffered attack, breaker, or second METH leaks through.
9. Reuse the current METH banner object but extend its auto-remove to 210f while
   the driver owns it. Hide normal timer/meter clutter, leave the METH banner,
   and restore HUD visibility on the normal next-round/round-end path.
10. **Training:** play the same sequence without allowing KO/round flow, then
    restore the pre-METH positions, fighter states/resources, and full METH
    meter snapshot so the user can repeat it. Recommended skip: no skip in
    versus; training (and a future replay viewer) may skip after the first 30f
    using a dedicated UI confirm, never a buffered combat action.
11. **CPU:** no new AI plan; the CPU uses the existing METH input. A valid hit
    enters the same driver and blocks both CPU controllers until completion.
12. At frame 210, use the normal KO signal/phase. Existing 100f KO, round win,
    match end, and Results behavior remains authoritative.

**Phase C tests:** full-meter/METH-start regression; miss still drains meter and
does not start the driver; 30f opening freeze, 210f exact sequence length and
one final damage application; each beat/prop/mask/audio event on the expected
frame; both METHs, both facing sides, both stages, wall-clamped compositions;
no fighter art or gameplay-state change from FX; all victim families can run
with existing clips and disabled `throw_target` remains disabled; pause/hitstop
freeze; CPU completion; training no-KO/snapshot reset/skip; deterministic
serialize/load at every beat; normal 100f KO→round/match→Results; and rendered
review at native 320×180.

## 5. Design D — exact generation/review plan

> **Superseded (owner decision, 2026-11-23):** the FX and prop art was
> **drawn procedurally with palette locks by the PM**, not generated through
> PixelLab. The sections below (§5 reference aliases, tool fit, asset rows
> as *generation* jobs, batch caps, PixelLab balance) are retained as the
> historical proposal record. What actually shipped:
>
> - `art/source/FX/hit_fx/` (18 fx sheets + `fx_manifest.json`) and
>   `art/source/FX/meth_props/` (8 props + `props_manifest.json`) are the
>   owner-approved procedural batch; the PM's generator sources are kept at
>   `art/tools/fx_generators/` for regeneration and are never agent-run.
> - `art/tools/prepare_fx.sh` validates every sheet against its manifest
>   (exact `cell×frames` sizes) and copies byte-identical runtime copies to
>   `game/art/fx/`; PNGs are never edited or resampled.
> - `game/tools/gen_fx_sets.gd` builds the per-fighter
>   `FxSet` resources (`game/resources/fighters/{peggy,richard}_fx_set.tres`)
>   straight from `fx_manifest.json`, so the runtime metadata cannot drift
>   from the approved art; `fx_events_test` pins the sheets to the data and
>   the runtime copies to the sources byte-for-byte.
> - The PixelLab Batch 1 drafts (draft PR #101) are **abandoned**: closed
>   with a comment pointing at the Phase C PR, branch kept for the spend
>   record only (10 generations, 603/2000 remaining; see
>   `art/source/FX/Animations/generated/batch_01_metadata.json` on that
>   branch). No PixelLab asset is used anywhere in the runtime.

### Reference aliases (historical proposal)

- **`P-ID` / Peggy identity:** `art/source/Characters/Animations/generated/peggy_idle_review/peggy_idle_01.png`
- **`R-ID` / Richard identity:** `art/source/Characters/Animations/generated/richard_idle_review/richard_idle_01.png`

Both are the approved 96×80, screen-right idle cells. They are the primary
identity/start images on **every** job whose output contains that fighter,
including every pose and every frame where the peg leg or bottle is visible.
No cutout or poster PNG is an identity reference.

Pose aliases below refer to one cel from a current runtime clip strip
(`game/art/characters/<fighter>/clips/<key>.png`, cel numbers 1-based):
`P-L3` = Peggy `light` c3; `P-H3` = `heavy` c3; `P-CL2` = `crouch_light` c2;
`P-CH3` = `crouch_heavy` c3; `P-JL2` = `jump_light` c2; `P-JH3` =
`jump_heavy` c3; `P-N3` = `neutral` c3; `P-F3` = `forward` c3; `P-D3` =
`down` c3; `P-B3` = `back` c3; `P-A3` = `air` c3; `P-G2` = `grab` c2;
`P-CG3` = `command_grab` c3; `P-NX3` = `neutral_ex` c3; `P-FX3` =
`forward_ex` c3; `P-M2` = `meth` c2; `P-BS1` = `block_stand` c1.

Richard aliases are `R-L2` (`light` c2), `R-H3` (`heavy` c3), `R-CL3`
(`crouch_light` c3), `R-CH3` (`crouch_heavy` c3), `R-JL2` (`jump_light`
c2), `R-JH3` (`jump_heavy` c3), `R-N3` (`neutral` c3), `R-F3` (`forward`
c3), `R-D3` (`down` c3), `R-B3` (`back` c3), `R-A3` (`air` c3), `R-G2`
(`grab` c2), `R-CG3` (`command_grab` c3), `R-NX2` (`neutral_ex` c2),
`R-FX3` (`forward_ex` c3), `R-M2` (`meth` c2), and `R-BS1` (`block_stand`
c1). Full paths are under `game/art/characters/whiskey_richard/clips/`.

To satisfy PixelLab’s same-size start/end requirement, Phase B first pads
copies of `P-ID`/`R-ID` and the selected cel into 160×112 transparent cells,
aligning the existing feet/clip anchor. **Padding only; no scaling, pixel
resampling, or art modification.** For character animation, pass the padded
identity as `custom_start_frame_url` and the padded clip cel as `end_frame_url`
on each `animate_character` job. Keep the unpadded approved source paths in
metadata as well.

The palette references are exact source unions: `P-PAL = P-ID` +
`game/art/characters/peg_leg_peggy/clips/heavy.png` cel 3 +
`game/art/characters/peg_leg_peggy/clips/forward.png` cel 3; `R-PAL = R-ID` +
`game/art/characters/whiskey_richard/clips/heavy.png` cel 3 +
`game/art/characters/whiskey_richard/clips/neutral.png` cel 3 +
`game/art/characters/whiskey_richard/clips/meth.png` cel 2. These exact
opaque pixels were checked against all colors in `P-FX` / `R-FX`.
`create_image_pixflux` receives the matching VFX strip through
`color_image_url`; fighter jobs receive only the base palette. Every output is
rechecked in Pixelorama. Shared dust uses only the two base palettes’ common
dark-earth/cream colors.

**PixelLab tool fit and limits (read-only tool help, 2026-11-23):**

- Fighter motion: `create_character(mode="pro", view="side",
  reference_image_url=..., size=96, palette=...)`
  accepts the approved three-quarter screen-right reference and costs 15
  generations at size 96; Pro Rotate returns an 8-direction character id.
  `animate_character(mode="v3")` then animates one requested direction. v3
  allows even 4–16 frames, max 256×256 and
  `width×height×frames <= 8×256×256`; cost is
  `ceil(width×height×frames/65536)` per direction on the generated canvas.
  At 160×112×6 it is 2 generations. Set `keep_first_frame=false` when the sheet
  must contain exactly the requested frame count. A 160×112 start/end pair must
  be supplied at identical dimensions. `create_character` v3-with-reference
  would be cheaper (1 gen for 96×80), but treats the image as straight-on
  “south”; it would offset these 3/4-facing designs and is **not** the default
  here. Pro Rotate’s 8-view output and pixel scale must be checked; nothing is
  runtime-ready without Pixelorama cleanup. Pass the appropriate closed
  `P-FX`/`R-FX` palette and name to Pro Rotate and v3; do not leave it to text
  color hints.
- Transparent FX/props: `create_image_pixflux` is a loose-image tool (no rig),
  16–400px per side, area 1,024–160,000; true transparency is supported with
  `no_background=true` through 200×200. It accepts `color_image_url` and costs
  1 generation per base image. Selected sizes are at least 32×32 (the tool’s
  1,024px minimum total area) and under 200×200 for true alpha.
- FX animation: `animate_image` starts from a loose base image, accepts a
  matching optional last-frame target, supports even 4–16 generated frames up
  to 256×256 with `width×height×frame_count <= 524,288`, and costs
  `ceil(width×height×frame_count/65536)` (e.g. 64×64×8 = 1). It returns the
  unchanged first frame **plus** the generated `frame_count` frames; our
  prompts use 4/6/8 generated frames and metadata records 5/7/9 stored frames.
  The tool has no hard-palette parameter; every frame is re-palette-checked and
  fixed in Pixelorama before approval.
- `create_image_pixen` is a 1-generation alternative for small transparent
  sprites (multiple-of-4 sides, total area ≤262,144; transparency ≤65,536),
  but the chosen PixFlux route is preferred because it accepts an explicit
  palette image. No `vfx_workbench` or job is used in Phase A.

### Asset rows

Every table row is one planned final review asset. `ID: none` means the image is
FX/prop-only and must contain **no Peggy/Richard pixels**; this is the only
case where an identity reference is not an input. Every row still lists a pose
and palette reference for scale/style. Attack/METH actor jobs pass both the
approved identity and the closest pose cel as actual job images. Poster art is
not used; if later requested, posters under `art/source/Characters/` may only
be a secondary `style_image_url` on a mood-board/prop concept, never an
identity/start reference.

#### Character-independent effect sheets (16, separate per-fighter art)

Each animated effect has a base still generated with `create_image_pixflux`
(1 gen) and an `animate_image` job (1 gen at these sizes), assembled into the
named sheet in its review folder.
For each animated row, the source still is `<sheet_stem>_base.png` (for
example, `peggy_hit_light_base.png`), and raw `animate_image` frames are
`<sheet_stem>_f00.png` through `<sheet_stem>_fNN.png`; the table filename is the
review PNG sheet assembled from those frames. Static props use the literal
filename shown in the table.

| Output filename | Canvas; stored frames; ticks | FX-only identity ref | Pose ref | Palette ref | Draft prompt delta; generations |
|---|---|---|---|---|---|
| `peggy_hit_light_sheet.png` | 32×32; 5; 2 | none | `P-L3` | `P-VFX` | “tiny readable wrench impact: two warm wood chips, one bent nail, one single-pixel metal flash; no body, transparent” — 2 |
| `peggy_hit_heavy_sheet.png` | 32×32; 7; 2 | none | `P-H3` | `P-VFX` | “hardware-store heavy impact, broad splinter fan and two bent nails, blunt wood/metal read, no body” — 2 |
| `peggy_hit_counter_sheet.png` | 32×32; 7; 2 | none | `P-B3` | `P-VFX` | “counter-hit punctuation made from crossed nails and a sharp warm-metal star, not text, no body” — 2 |
| `peggy_block_sheet.png` | 32×32; 5; 2 | none | `P-BS1` (pose-only) | `P-VFX` | “dull defensive tap: duct-tape fleck and a small tool-on-tool spark, restrained brightness, no body” — 2 |
| `peggy_special_hit_sheet.png` | 48×32; 7; 2 | none | `P-F3` | `P-VFX` | “long peg poke impact: forward metal streak and a few short splinters, transparent, no body” — 2 |
| `peggy_ex_hit_sheet.png` | 48×48; 9; 2 | none | `P-FX3` | `P-VFX` | “largest Peggy impact: dense bent-nail spray, warm hardware flash, no colors outside P-VFX, no body” — 2 |
| `peggy_heavy_whoosh_sheet.png` | 48×24; 5; 2 | none | `P-H3` | `P-VFX` | “short horizontal duct-tape/wood scrape trail behind a heavy wrench/arm arc, no body” — 2 |
| `peggy_special_trail_sheet.png` | 64×32; 7; 2 | none | `P-F3` | `P-VFX` | “short forward peg-prosthetic streak with two separated pixel clusters, not a projectile, no body” — 2 |
| `richard_hit_light_sheet.png` | 32×32; 5; 2 | none | `R-L2` | `R-VFX` | “tiny whiskey splash with one amber droplet and one glass glint, no body, transparent” — 2 |
| `richard_hit_heavy_sheet.png` | 32×32; 7; 2 | none | `R-H3` | `R-VFX` | “barfly heavy impact: broad amber splash, two bottle-glass glints, one tiny warm-cream flame lick, no bottle redesign, no body” — 2 |
| `richard_hit_counter_sheet.png` | 32×32; 7; 2 | none | `R-B3` | `R-VFX` | “counter-hit punctuation: crossed dark-red/cream glass glints and amber burst, no body” — 2 |
| `richard_block_sheet.png` | 32×32; 5; 2 | none | `R-BS1` (pose-only) | `R-VFX` | “restrained block contact: small whiskey drop and one glass tick, lower contrast than a hit, no body” — 2 |
| `richard_special_hit_sheet.png` | 48×32; 7; 2 | none | `R-F3` | `R-VFX` | “short amber-red belch/special impact wisp, preserve silhouette clarity, no body” — 2 |
| `richard_ex_hit_sheet.png` | 48×48; 9; 2 | none | `R-FX3` | `R-VFX` | “largest Richard impact: amber/cream flare with dark-red bottle-glass shards, no new hue, no body” — 2 |
| `richard_heavy_whoosh_sheet.png` | 48×24; 5; 2 | none | `R-H3` | `R-VFX` | “short bottle/forearm swing streak, attached to the swing path, no bottle or body drawn” — 2 |
| `richard_special_trail_sheet.png` | 64×32; 7; 2 | none | `R-F3` | `R-VFX` | “brief amber whiskey ribbon behind the special’s leading limb, not a projectile, no body” — 2 |

Append this **global prompt tail** to every image prompt above:

> Sidewalk Showdown, fictional Sidewalk Florida, mature-rated retro 2D arcade
> fighting game, chunky readable pixels, bold dark outline, nearest-neighbor
> pixel edges, exact listed palette only, native 1:1 pixels, transparent
> background, no antialiasing, no watermark, no readable lettering, no logos,
> no real brand/town/person, no gore, no photorealism, no tiny clutter, no
> full fighter, no foreground block of the combatants.

Use these `animate_image.action` prompts on **both** character-specific
filenames for each class: `*_hit_light_sheet` = “brief two-chip/amber-droplet
pop”; `*_hit_heavy_sheet` = “impact expands, debris arcs out, then settles”;
`*_hit_counter_sheet` = “sharp cross-spark flashes then collapses”;
`*_block_sheet` = “small restrained defensive tick”; `*_special_hit_sheet` =
“forward streak expands and dissipates”; `*_ex_hit_sheet` = “larger flare
blooms then fades”; `*_heavy_whoosh_sheet` = “short horizontal swing streak”;
`*_special_trail_sheet` = “short directional arc.” Use the matching sheet’s
base frame as `first_frame_url`; do not add a character image.

#### Shared environment dust (one, not attack FX)

| Output filename | Canvas; frames; ticks | Identity ref | Pose ref | Palette ref | Draft prompt; generations |
|---|---|---|---|---|---|
| `landing_dust_sheet.png` | 64×32; 5; 3 | none | no character pose; floor-contact shape only | union of `P-PAL` / `R-PAL` dark-earth colors | “small side-view puff of dirt at floor level, 5-frame dissipating cloud, no fighter, no debris that reads as a hit spark” — PixFlux base 1 + Animate Image 1 = 2 |

Its `animate_image.action` is: “puff expands left/right at floor level, then
dissipates without rising over a fighter’s waist.”

#### Cinematic props (8)

Props are separate transparent images; no character pixels. Animated props use
the generated static base as `animate_image` first frame. Every prop is placed
relative to the attacker/victim group at runtime.

| Output filename | Canvas; frames; ticks | Identity ref | Pose ref | Palette ref | Draft prompt delta; generations |
|---|---|---|---|---|---|---|
| `plank_base.png` | 96×32; static | none | `P-H3` (scale/composition only) | `P-VFX` | “short broken scavenged plank, taped repair, splintered ends, blank wood, transparent, no text” — 1 |
| `plank_snap_sheet.png` | 96×32; 7; 3 | none | `P-CH3` | `P-VFX` | “same plank snapping into 3–4 large readable wood pieces, debris stays compact” — base + animate = 2 |
| `sewer_open_sheet.png` | 96×64; 7; 3 | none | `P-D3` | `P-VFX` | “cartoon sewer/channel aperture opening: dark oval and simple front rim, not a stage background” — 2 |
| `water_drop_mask_sheet.png` | 96×64; 7; 2 | none | `P-M2` | `P-VFX` | “small opaque foreground water/rim mask that covers a falling silhouette from the bottom up, no body” — 2 |
| `whiskey_fumes_sheet.png` | 128×96; 7; 3 | none | `R-M2` | `R-FX` (no accents) | “amber-brown cartoon whiskey-fume cloud, airy dithered opaque clusters and binary transparent gaps; no partial alpha, keep a clear hole around faces” — 3 (base 1 + 6-frame animation 2) |
| `fire_belch_sheet.png` | 96×64; 7; 2 | none | `R-N3` | `R-VFX` | “short absurd cone of warm fire/air, three broad pixel lobes, no background, no face” — 2 |
| `fictional_bar_sign_base.png` | 96×48; static | none | `R-FX3` (scale/composition only) | `R-VFX` | “generic blank roadside bar sign, fictional and unbranded, clean rectangular silhouette, no readable text” — 1 |
| `bar_sign_shatter_sheet.png` | 96×64; 7; 2 | none | `R-FX3` | `R-VFX` | “same blank sign breaks into a few large frame and panel fragments; foreground and rear shards must remain separable” — 2 |

The no-text sign gets a fictional hand-pixeled prop label only after review; the
PixelLab prompt never names or imitates a real business.

`animate_image.action` prompts for those prop sheets, in table order: “board
snaps once through the middle, two large ends move apart and settle”; “plank
cover pivots open and settles”; “water rim splashes up then falls back over the
opening”; “fume cloud slowly expands outward and thins in the middle”; “short
flame cone blooms forward then folds back”; and “blank sign breaks outward,
large frame and panel fragments separate and settle.” These motion prompts do
not add characters, a setting, text, or new palette colors.

#### Attacker-motion assets (6; 160×112 padded cells)

Every frame has the corresponding approved identity image as the start
reference and the listed closest current clip cel as the pose/end reference.
`create_character` uses Pro Rotate because the approved identity is already
three-quarter screen-right; v3 reference rotation assumes straight-on/south.
`animate_character` runs one screen-right direction at a time. Pass the
verified direction key (default `directions=["east"]` only if PixelLab’s
`view="side"` mapping confirms east is screen-right); never rely on custom-mode
default south. Create only the review identity object and these six animations;
its other Pro Rotate views remain marked **DO NOT USE** in the review folder
and never enter the runtime plan.

| Output filename / review asset | Frames; cell; per-cel use | Identity ref (passed) | Pose ref (passed as end target) | Palette ref | Motion-only draft `action_description`; generations |
|---|---|---|---|---|---|
| `peg_leg_peggy_meth_identity` | 96×80 identity source; resulting character id | `P-ID` | `P-ID` | `P-PAL` | “Pro Rotate a screen-right side-view identity from this sprite; preserve the pose, shape, face and peg leg.” Create Pro character, size 96: 15 |
| `meth_plank_slam_sheet.png` | 6; 160×112; 6 sim ticks/cel in beat | `P-ID` as custom start | `P-H3` c3 | `P-PAL` | “step in, drive the upper body forward, knock the target down, recover balanced” — animate 2 |
| `meth_prosthetic_pin_sheet.png` | 4; 160×112; 6 ticks/cel then hold 6 | `P-ID` as custom start | `P-CG3` c3 | `P-PAL` | “lower into a controlled pin, extend the rigid prosthetic downward, hold, rise” — animate 2 |
| `meth_plank_stomp_sheet.png` | 6; 160×112; 5 ticks/cel | `P-ID` as custom start | `P-CH3` c3 | `P-PAL` | “lift the rigid prosthetic, stomp straight down, recoil to a confident planted stance” — animate 2 |
| `whiskey_richard_meth_identity` | 96×80 identity source; resulting character id | `R-ID` | `R-ID` | `R-PAL` | “Pro Rotate a screen-right side-view identity from this sprite; preserve his face, body, and bottle hand.” Create Pro character, size 96: 15 |
| `meth_bottle_drench_sheet.png` | 6; 160×112; 5 ticks/cel | `R-ID` as custom start | `R-H3` c3 | `R-PAL` | “tilt the same-hand bottle, lean forward, recover while keeping the bottle hand unchanged” — animate 2 |
| `meth_belch_ignite_sheet.png` | 6; 160×112; 5 ticks/cel | `R-ID` as custom start | `R-N3` c3 | `R-PAL` | “draw breath, puff cheeks, belch forward, recoil; bottle remains in its reference hand” — animate 2 |
| `meth_sign_crash_sheet.png` | 6; 160×112; 5 ticks/cel | `R-ID` as custom start | `R-F3` c3 | `R-PAL` | “lunge through the follow-through, plant, cough once, finish in a powerful but embarrassed stance; bottle hand unchanged” — animate 2 |

Create-character rows are **identity setup jobs**, not runtime art: cost is 30
combined. The six animation jobs cost 12 at 160×112×4/6 with one direction.
The existing METH clip remains the opening pose; the broken Peggy cel is
repaired in its derived review copy before that clip is approved for any
playback beyond the connected hit.

### Generation total and review folders

Live `get_balance()` (read-only, 2026-11-23): Tier 1 Pixel Apprentice active,
**613/2000 subscription generations remaining**, 1387 used, **$0.00 credits**,
reset 2026-12-13. The displayed 10 daily-bonus generations are not additional
buffer while subscription generations remain; the balance tool says they count
down with the same charges. `PIXELLAB_ASSET_ORG.md` has a historical 700/2000
note after a 613/2000 note; this live balance is authoritative for planning.
The requested chronological balance-log reconciliation is reserved for Batch 5.

Base estimate: 16 character-specific hit sheets (32 generations), shared dust
(2), eight METH prop assets (15), two identity objects (30), and six attacker
clips (12) = **91 generations**. Add a 25% retry/Pixelorama correction margin
(23) for a planned cap of **114 generations**. On the live 613 balance that
would leave **499 subscription generations**; it uses no credit balance. This
estimate excludes unplanned extra views or full re-rotations; if Pro Rotate
does not preserve the reference scale/identity, stop and ask rather than
spending past the cap. Animation prices assume PixelLab uses the padded
160×112 canvas without silhouette-driven canvas growth; actual job receipts
are authoritative, and any quote that takes the cumulative plan past 114
requires fresh owner approval.

Review layout:

```text
art/source/FX/Animations/generated/peggy_hit_fx_review/
art/source/FX/Animations/generated/richard_hit_fx_review/
art/source/FX/Animations/generated/shared_landing_dust_review/
art/source/FX/Animations/generated/meth_walk_the_plank_review/
art/source/FX/Animations/generated/meth_flaming_belch_review/
art/source/Characters/Animations/generated/peg_leg_peggy_meth_review/
art/source/Characters/Animations/generated/whiskey_richard_meth_review/
```

Each folder retains the raw base and frame outputs, Pixelorama `.pxo` review
project, preview/contact sheet, and `metadata.json` with: tool/mode, every job
id and cost, exact prompt, output dimensions/frame count, start/pose/palette
reference paths (including the two required idle reference paths), palette hex
list, direction, timestamp, and any human Pixelorama fixes. No asset moves to
`art/exports/` or `game/art/` before explicit owner review.

### Identity checks and human Pixelorama work

Run these on **every generated actor frame before it leaves its review folder**:

1. Same identity and exact allowed palette. Peggy/Richard actor pixels use
   only `P-FX`/`R-FX`; no FX accent may appear on the fighter. Their FX/props
   use only `P-VFX`/`R-VFX`; Richard fumes use `R-FX` only. Replace any
   off-palette pixel in Pixelorama.
2. No resampling: actor content remains the approved native 96×80 pixel scale
   inside the 160×112 padded cell. PixelLab canvas growth is not permission to
   resize the figure.
3. Screen-right three-quarter orientation in every generated pose.
4. Peggy’s peg leg remains rigid and on the same side in all Peggy frames.
5. Richard’s bottle remains fully attached to the same reference hand; no
   hand-switch, bottle disappearance, or morph.
6. Face/eyes/mouth are fully opaque; outer area has true alpha, not checkerboard
   pixels or a flat keyed color.
7. Attack pose reads at 320×180, actor cell shares the established feet baseline,
   silhouette fits without cropping, and no prop/FX obscures the face or active
   strike point.

A failure is regenerated **or repaired/redrawn in Pixelorama**; it is never
resampled, auto-keyed, or wired into the game. Specifically repair Peggy’s
METH cel 4 and manually inspect Richard’s seven historically segmented raw
clips before accepting any derivative edits. Owner-run Pixelorama edits should
stay in the review `.pxo`; `art/source/` approved originals remain byte-for-byte
untouched.

## 6. Design E — risks and owner questions

| Risk / question | Recommended default |
|---|---|
| PixelLab’s Pro Rotate may output eight views and a different visible size even with the correct identity reference. | Use the approved idle as the actual reference input; generate review-only at size 96, keep only screen-right after owner review, pad without scaling, and hand-correct in Pixelorama. Stop if native scale cannot be retained. |
| `create_character` v3 treats its reference as straight-on/south, while these references are screen-right 3/4. | Do not use v3 reference rotation. Use Pro Rotate or stop for owner direction; never “fix” by flipping the source reference. |
| PixelLab’s direction label for screen-right in `view="side"` may be named `east`; this plan does not assume the mapping blindly. | Confirm the returned direction against the supplied screen-right identity preview before the first animation job; use only that direction, defaulting to `east` if confirmed. |
| `animate_character`’s generated canvas may grow around a silhouette. | Pass identical 160×112 padded start/end frames, set one direction and `keep_first_frame=false`; inspect output pixels and correct in Pixelorama. No engine rescale. |
| Richard fire colors are not a broad yellow/orange palette in his approved art. | Use `R-ACCENT` only on the FX/prop layer, never on Richard’s pixels; keep fumes amber/brown in `R-FX`. If the accent ramp is too weak, ask before adding colors. |
| The gator/stage art, bus-stop sign, or actual stage edge could make a stage-specific cinematic. | Keep all props owned by the cinematic and anchored to the fighter pair; do not edit either background or use a stage coordinate. |
| What exactly should the sewer/channel opening represent? | Default to a small cartoon manhole/water opening and clean splash; no gore, body damage imagery, or realistic sewer detail. |
| Does the 30f METH hitstop count inside the 3–4 seconds? | Yes: default 210 total sim frames (3.5s), including the current 30f opening freeze. |
| What should happen on a confirmed METH hit in training? | Play the same cinematic, suppress KO/round flow, then restore pre-cinematic fighter positions/resources and meter for repetition. |
| Can a cinematic be skipped? | No in versus. Allow a separate UI-confirm skip in training/replay after 30f; clear combat buffers so skipping cannot trigger another move. |
| Should unique beat sounds be authored in the same production pass? | Reuse current `meth` and `ko` cues first. Add the named impact cues only after the visual sequence is approved; no audio generation in Phase A. |
| Who approves PixelLab identity/scale and all 31 review assets before integration? | Owner approval is a hard gate. Nothing in this design authorizes a PixelLab job or runtime install. |

## 7. Phase gates and gated batch plan

> **Superseded (owner decision, 2026-11-23):** the five-batch PixelLab plan
> below was abandoned in favor of the PM's procedural palette-locked art
> (see the §5 note). Phase C then wired that approved art with **existing
> clips only**, amending the §3 storyboards' dedicated `meth_*` attacker
> animations (which were never drawn) with the beat maps below. The batch
> table is retained as the historical record of the plan and its caps.

### Phase C — as implemented

- **FX event system:** `game/scripts/fx/fx_layer.gd` (CanvasLayer 5,
  presentation-only) spawns the fighter-specific sheet from
  `FighterData.fx_set` at the hitbox/hurtbox overlap center, one primary
  impact per resolved contact, precedence EX > counter > special/launcher >
  heavy > light, block on blocked contacts; heavy whoosh and special trail
  spawn at move startup attached to the attacker; shared dust on LAND,
  grounded/airborne KNOCKDOWN floor contact, and a one-shot wall-contact
  event on clamp contact. Sheets advance on the sim clock with each sheet's
  `ticks_per_frame`, freezing in hitstop and pause, never serialized.
- **METH cinematic driver:** `game/scripts/fx/meth_cinematic_driver.gd`
  owns the serialized `METH_CINEMATIC` phase: 210 frames after the contact
  frame (frames 0-29 are the opening hold standing in for the authored
  30f contact hitstop), both fighters puppeted from `sequence_frame`,
  damage applied once on the boundary tick through the ordinary hit/KO
  path, then the normal KO/round/Results flow. Training restores the
  pre-METH snapshot (health, positions, full meter — the activation's
  spend) and adds the training-only UI-confirm skip after the opening
  hold. Serialize/load mid-sequence resumes on the exact frame.
- **Owner beat maps (existing clips only; cels 1-based in the tables
  below are what the driver plays):**
  - **Walk the Plank:** contact = `forward` (long peg-leg poke, active
    cel held, recovery cels for the knock onto the plank); pin =
    `crouch_heavy` cels 1-3 (peg-leg sweep); stomp = `crouch_heavy` cels
    3-5 (**placeholder** until a dedicated stomp pose exists); finish =
    `win`. Victim: `hitstun_stand` → `knockdown` → `ko_air` tumble →
    `ko_ground` below the front water rim.
  - **Flaming Belch:** contact = `neutral`; drench = `heavy` cels 1-3
    (bottle raised, same hand); belch/ignite = `neutral` cels 2-5;
    follow-through = `neutral` last cel; finish = `win`. Victim:
    `hitstun_stand` → `ko_air` toward the sign → `ko_ground` behind the
    front shatter layer.
  - Peggy's broken `meth.png` cel 4 is **unused** by the cinematic (the
    driver plays the `forward`/`crouch_heavy`/`win` clips above; the
    runtime `meth` clip only ever shows its opening contact cel).
- **Prop draw contract (visual-review fix, 2026-11-23):** the review of
  PR #102's own captures found the "behind the victim" props invisible and
  the fire cone misplaced. Root causes and the shipped contract:
  - *Layering:* back props (sewer, fumes, plank, snap, sign base, shatter
    back) draw on a dedicated root **inserted in MatchRoot's tree order
    between the stage and the fighters** — a negative z_index on a late
    sibling sorts behind the entire opaque stage, which is why the plank,
    snap, sewer and fumes vanished in the first captures. Front props
    (water mask, shatter front, fire cone) draw on a root appended after
    the fighters at z 5/6.
  - *Anchors/mirroring:* every prop uses its manifest anchor with
    centered=false and offset = -anchor; a mirrored sheet (fumes "grows
    up-right", the fire cone drawn facing right) must mirror the ANCHOR
    as well (offset x becomes cell_w - anchor.x together with flip_h),
    or the sprite lands one cell-width off target. The fire cone's mouth
    point is (3,36) in the 104x64 cell, placed at Richard's mouth
    (facing-shifted estimate; tuned via the review strips), straight out
    toward the victim, no rotation, no scaling, above the victim and
    fumes.
  - *Review strips:* `docs/assets/fx_meth/walk_the_plank_strip.png` and
    `flaming_belch_strip.png` (attacker LEFT) plus the `..._mirrored_`
    pair (attacker RIGHT near the right wall) — 4x3 grids of native
    320x180 frames at f0..f198 step 18, frame number in each cell — are
    the owner/PM visual sign-off; the README key-beat stills were
    regenerated from the fixed driver. `meth_cinematic_test`'s numeric
    visibility checks (sprite + texture + ordered layer + anchor within
    3px + viewport + mirroring, both facings) FAIL on the pre-fix
    driver and pin the contract.
- **Pass-2 choreography contract (PM frame-by-frame review, 2026-11-23):**
  - *Walk the Plank:* the plank slides in at f54 as the victim lands (never
    under the standing victim) and hands over to the snap sheet at f90. From
    the stomp (f108) the victim drops feet-first under gravity
    (`y = floor + round(0.5*0.075*t^2)`), centred on the sewer anchor; a
    `canvas_item` shader on his sprite (one reusable `ShaderMaterial`,
    parameters only per frame) discards every pixel below the front-rim arc
    (`y > floor + 12*(1-(dx/37)^2)`, measured from `water_drop_mask_sheet`),
    so by f160 the whole sprite is below the rim. The splash plays from f124
    as he goes under and settles; the open sewer stays to the end; Peggy
    plays `win` from f168.
  - *Flaming Belch:* the fire cone's mouth point (3,36) sits on Richard's
    measured mouth in the `neutral` belch cels (cel points 44,22/19/18/21,
    transformed through the fighter's own sprite offset/flip/scale), mirrored
    with the anchor, full size, in the front root above both fighters and the
    fumes, stepping all 7 frames over f97-117. The fumes' anchor (10,70) sits
    on the bottle mouth of the first `heavy` drench cel (68,26, the pour
    point), mirrored with facing, holding frame 7 until the belch hits them
    (warm tint flash f103-111) and consumed at f114. From f120 the victim
    flies a pixel-snapped ballistic arc away from Richard (vx 1.75, vy0 3.6,
    g 0.18: peak 36px, lands f160 in `ko_ground`, clamped with the prop
    group); the sign hangs on that arc 44px out at chest/head height and the
    shatter starts on the frame he reaches it (f145): back shards behind him,
    front shards in front, gone by f172.
  - *Banner:* centred through the 30f hold, then moved into the top band
    (y 10, below the 8px letterbox) over 12 frames so it never overlaps a
    fighter.
  - *Capture tooling:* `meth_capture.gd` pauses the tree during each grab
    (the old strips drifted up to ~6 frames per grab) and takes optional
    `<step> <start>` arguments for close-up review frames.
- **Tests:** `fx_events_test` (46 checks) and `meth_cinematic_test`
  (187 checks — pass 1 added the per-beat numeric prop
  visibility/anchor/mirroring checks; pass 2 added the per-frame contract: drop + rim clip, plank timing, cone/fume anchors, launch arc + sign shatter, banner clearance, both facings) pin the whole contract;
  `combo_adversarial_test`'s A2
  METH ruling now asserts the cinematic hold (no hitstun → no break, no
  ghost pair) and `training_test`'s landed-METH check pins the training
  cinematic + restore.

### The historical batch plan (abandoned)

Phase A is the audit/design PR. Phase B begins only after PR #100 is approved
and merged. It creates **review drafts only** under `art/source/..._review/`;
no `game/art/` wiring. Run one batch, report its exact costs/balance and
contact sheet, then stop until the owner explicitly replies **“batch N
approved”** (or sends fixes). Call `get_balance()` immediately before and
after each batch. A job that would cross its batch cap or the **114-generation
Phase B total cap including retries** is not submitted. If an asset is poor,
revise its prompt and retry at most twice; then stop and report it.

| Batch | Hard batch cap | Planned contents | Gate / stop condition |
|---|---:|---|---|
| 1 — style pilot | 10 | `peggy_hit_heavy_sheet`, `richard_hit_heavy_sheet`, `fire_belch_sheet` | Test P/R VFX ramps, native-pixel readability, transparency, and the 320×180 mock. Stop for owner style fixes. |
| 2 — Peggy identity | 22 | Pro Rotate identity from `P-ID`, then `meth_plank_stomp_sheet` | Inspect the screen-right identity preview first. If scale, face, or rigid peg side fails, stop after identity; do not queue animation. |
| 3 — Richard identity | 22 | Pro Rotate identity from `R-ID`, then `meth_belch_ignite_sheet` | Inspect the screen-right identity preview first. Bottle must stay in the same hand in every frame. Stop on any identity failure. |
| 4 — remaining hit FX | 34 | The other 13 per-character sheets named in §5 plus `landing_dust_sheet` | The §5 inventory currently has 16 per-character sheets; after Batch 1’s two heavy sheets, 14 remain. The request says 13. Do not silently drop one: stop for owner reconciliation before this batch (recommended candidate to defer is one optional trail). |
| 5 — remaining METH art | 30 | `meth_plank_slam_sheet`, `meth_prosthetic_pin_sheet`, `meth_bottle_drench_sheet`, `meth_sign_crash_sheet`, and all remaining props (`plank_base`, `plank_snap`, `sewer_open`, `water_drop_mask`, `whiskey_fumes`, `fictional_bar_sign_base`, `bar_sign_shatter`); repair Peggy’s `meth.png` cel 4 only in a derived review copy | One 320×180 mock for each METH key beat (plank stomp; belch ignition). Update this design with actual per-asset costs/status and append the balance log in `PIXELLAB_ASSET_ORG.md`. Stop; keep the generation PR draft and unmerged. |

The listed per-batch caps sum to 118, four above the global 114 cap. **The
global cap wins:** after each batch recompute remaining balance and remaining
global allowance; reduce the final batch ceiling as needed, never exceed 114.
With the requested 13 FX sheets in Batch 4, the scheduled subtotal is 89;
one of the 14 remaining sheets is unassigned. Including that one later would
make the full-inventory base 91 from §5. Reconcile it with the owner before
Batch 4; neither subtotal authorizes extra retries beyond the stated margin.

Every batch contact sheet is one composite: each output at its native 1:1
pixels and at 4× nearest-neighbor, plus one 320×180 mock showing the batch’s
FX next to both fighters at renderer scale `56 / h_ref`. Inspect only that
composite, not individual frames. After Batch 1, create one DRAFT
`art/fx-meth-drafts` PR and push each approved batch to that same branch/PR.
Do not merge it.
