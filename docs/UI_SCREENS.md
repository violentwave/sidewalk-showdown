# UI Screens — Router, Screen List, and Settings (Phase 1)

**Status: implemented 2026-11-21 (UI Phase 1); polished 2026-11-21 from
owner playtest feedback** (cleaner typography via the Sidewalk Marker
font, no chat strip on the main menu, a press-required content warning).
This file documents what actually shipped: the router, the screen flow
with every back path, the **typography rules**, the Settings keys and
where each one is (or is not yet) consumed, and the UI art pipeline
command. Companion docs: `docs/UI_HUD_SCREENS_PLAN.md` (the original
plan), `docs/UI_ASSETS.md` (art manifest), `docs/PM_BRIEF.md`.

Screenshots of every polished screen live in `docs/assets/ui/`
(regenerate with the command under "Screenshots").

## The router

`game/scripts/ui/screen_router.gd` (`ScreenRouter`, owned by `main.gd`)
is a screen stack with `push`, `pop`, `replace`, and `clear_and_push`:

- **Every push is deferred** to the end of the frame. The input event that
  requested a transition is fully consumed before the new screen exists, so
  a confirm keypress can never leak into the next screen. This generalizes
  the `call_deferred` hand-offs the old `main.gd` did by hand.
- **Overlays** (`SettingsOverlay`, `QuitConfirm`) are pushed without
  freeing the screen below; `pop()` frees only the top.
- `main.gd` keeps named fields (`intro`, `title`, `main_menu`,
  `character_select`, `stage_select`, `match_root`, ...) so tests and tools
  can find the active screen the way they always have.
- `FlowState` (`game/scripts/ui/flow_state.gd`) holds the flow context:
  `solo_mode`, `cpu_level`, `last_p1_choice`, `last_p2_choice`,
  `last_stage_id`, and the pending fighter data between select screens.
  `main.gd` exposes them as property aliases.
- `ScreenRouter` also tracks the last input device (keyboard/mouse vs pad,
  a static flag noted from every screen's input) so prompt lines show pad
  glyphs after a pad was used.
- Nothing in the router touches the 60 Hz simulation or
  `MatchRoot.serialize()/load()`.

## The screen flow

```
boot -> ContentWarning -> The Clip -> Title -> MainMenu
                                        |  VERSUS -> ModeSelect (1P/2P)
                                        |             |  solo: Difficulty -> CharacterSelect
                                        |             |  versus: CharacterSelect
                                        |  SETTINGS (overlay)
                                        |  QUIT -> QuitConfirm
                                        `-- back -> Title -> back -> QuitConfirm
CharacterSelect <-> StageSelect -> VsScreen -> MatchRoot
   `-- back -> ModeSelect `-- back -> MainMenu
MatchRoot end -> ResultsScreen -> { REMATCH -> VsScreen -> MatchRoot
                                    | CHARACTER SELECT | STAGE SELECT
                                    | MAIN MENU }
MatchRoot pause: RESUME / SETTINGS (overlay) / RESTART MATCH /
   CHARACTER SELECT / MAIN MENU / QUIT TO DESKTOP (QuitConfirm)
```

| Screen | Enter | Back / exit |
| --- | --- | --- |
| ContentWarning (once per launch) | boot | confirm only (ignored for the first 30 frames so a held key cannot skip it) -> The Clip |
| The Clip (unchanged) | warning | Space advance, Esc skip -> Title |
| Title | Clip, MainMenu back | confirm -> MainMenu; back -> QuitConfirm |
| MainMenu | Title | back -> Title; items below |
| ModeSelect | MainMenu VERSUS | back -> MainMenu |
| Difficulty | ModeSelect 1P | Backspace -> ModeSelect |
| CharacterSelect | ModeSelect/Difficulty, StageSelect back | Backspace -> ModeSelect (drops restored picks) |
| StageSelect | CharacterSelect | Backspace -> CharacterSelect (deferred) |
| VsScreen | StageSelect confirm, Results REMATCH | auto after 150 frames, or confirm/back past the 20-frame guard -> MatchRoot |
| ResultsScreen | MatchRoot end | REMATCH -> VsScreen; CHARACTER SELECT / STAGE SELECT / MAIN MENU; input ignored for the first 30 frames |
| MatchRoot | StageSelect | pause menu |
| SettingsOverlay | MainMenu SETTINGS, pause SETTINGS | back -> whatever opened it |
| QuitConfirm | Title back, MainMenu QUIT, pause QUIT | NO/back -> what opened it; YES -> quit |

Pause-menu specifics: SETTINGS and QUIT TO DESKTOP open overlays **above the
still-paused match** (`match_root.modal_open` blocks the pause key and menu
input underneath; the overlays run `PROCESS_MODE_ALWAYS`); MAIN MENU
unpauses, frees the match, and shows the hub. QuitConfirm defaults to NO.

The MainMenu sign geometry is measured from `menu_price_sign.png`
(79x124, art space): cream board x 1..73, content rows 35-43, 46-51,
54-60, 63-69, dividers at 44-45, 52-53, 61-62, 70-71; the pole runs art
x 36..43 to the art bottom. The sign is centered horizontally
(`SIGN_POS` 120,34) with the pole bottom on the Gas-N-Go floor line
(158). Slats 1-4 carry VERSUS, TRAINING (greyed), SETTINGS, EXTRAS
(greyed) in m5x7 dark ink `#2A2418` (focused `#1C160D`, greyed
`#9C8F70`); the focused slat shows the lit overlay (66x7 at x 6, y
36/45/54/63). QUIT left the board in the polish pass: it is a 48x16
`ui_button.png` "taped" to the pole below the slats (screen 136,116),
labeled in Sidewalk Marker, yellow-modulated when focused. **The chat
strip is gone (owner decision, 2026-11-21 playtest): no chat panel, LIVE
tag, or fake chat lines — the menu is the price board only.** One m5x7
description line sits on a dark plate bottom-left (greyed items say
"Coming soon."); the prompt line is bottom-right. The constants live in
`game/scripts/ui/screens/main_menu.gd`.

## The select screens (PR A, 2026-11-22)

All four screens run on the same rules: dimmed Gas-N-Go art (or the
mugshot wall) behind a 55% `#1C160D` overlay, marker headers, ink-on-
cardboard rows with the yellow focus bar, descriptions on the prompt
plate, and unchanged input contracts (`select_screens_test` pins them).

Stage backdrops used behind UI screens are instantiated with `z_index = -20`, so the stage's ambient sprites (the z_index-10 mosquitoes) stay under panels and text.

| Screen | Layout |
| --- | --- |
| ModeSelect | dimmed Gas-N-Go; ui_panel (96,44) 128x76; "VERSUS" marker ink header; rows "1 PLAYER" / "2 PLAYERS" (full-width focus bars at y+26/46); description on the prompt plate's left. Defaults to 1 PLAYER. |
| Difficulty | dimmed Gas-N-Go; ui_panel (96,40) 128x88; "CPU LEVEL" header; EASY / NORMAL / HARD rows (order and names unchanged, default NORMAL) with code-drawn 1px ink tally marks (1/2/3) at each row's right; description on the prompt plate. |
| CharacterSelect | `select/select_mugshot_bg.png` wall; "BOOKING" outlined marker header; each fighter's 64x64 `select_portrait_<fighter>.png` on the height chart (columns x 44/148, y 30). The rap sheet `select/select_rap_sheet.png` at (236,42) carries NO text (PM review fix): the focused fighter's 22x22 `hud_portrait_<id>_normal.png` sits in the clipboard's photo box (art x 9-31 / y 18-41) with the tally marks in the blank lower-left (art x 6-30 / y 46-58); name, archetype and tagline live on the wall below (x 232-316, from y 112) — the name in outlined marker cream wrapped to two lines, archetype/tagline in m5x7 cream wrapped to 80 px with a 10 px row spacing (owner-editable `RAP_SHEETS` copy; no data fields exist for them; rival and home stage are omitted until they do). Cursors: code-drawn scribbles (P1 `#f29e26` lopsided circle, P2 `#e5473a` irregular box, fixed point lists, no RNG) framing the focused portraits; the rap sheet follows whoever moved last. Status (centered in x 8-228) and "STAGE: CHOOSE NEXT" are outlined marker lines over the wall. Every pick, lock, solo step, and restore behavior is unchanged; there is no palette cycling (none ever shipped). |
| StageSelect | dimmed Gas-N-Go; "PICK YOUR SPOT" outlined marker header; each stage is a `stage/stage_scratch_ticket.png` (72x44) at y 46 (x 28/124/220) with its 80x45 thumbnail **center-cropped** into the measured silver panel (36x16 at local x 18..53 / y 16..31, an AtlasTexture region — a crop, never a scale) and its name in outlined marker under it — a short label (`GAS-N-GO`, `BUS STOP`) only on this screen when the full name does not fit its 88 px column (PM review fix). The focused ticket lifts 2 px with a 1 px yellow frame. RANDOM stays covered ("?" over blank silver); confirming it plays an 18-frame integer-pixel scratch-off reveal (18 cover columns, one per physics frame) of the drawn stage's cropped thumbnail before the same hand-off as a concrete pick. The random source is the screen's own visual/meta RNG, unchanged. |

## The match wrap screens (PR B, 2026-11-22)

**VsScreen** (`game/scripts/ui/screens/vs_screen.gd`) plays between stage
select and the match, and on every rematch. A code-drawn diagonal split
(P1 `#f29e26` left, P2 `#e5473a` right, darkened 40% toward the screen
edges), `vs/vs_matchup.png` (242x20) centred at y 6, both fighters'
`vs/vs_bust_<id>.png` (96x128) sliding in over **12 integer-pixel
frames** (P1 lands at x 12, P2 at x 212 flipped, bottoms at y 168),
`vs/vs_versus.png` (47x29) centred at y 76, names in outlined Marker
under each bust, and `stream/stream_sponsor_bug.png` (40x12) at
bottom-centre with "BROUGHT TO YOU BY" in m5x7 above it. It lasts 150
frames; any confirm/back skips it after a 20-frame input guard so the
stage-select hand-off cannot punch through. Pure presentation.

**ResultsScreen** (`game/scripts/ui/screens/results_screen.gd`) replaces
"Enter restarts": at match end MatchRoot emits `match_results_requested`
(the only match_root change — the MATCH_END Enter poll is gone), Main
pauses the tree and pushes Results above the **frozen match** —
`serialize()` is byte-identical while the screen is up. The screen draws
the match's own stage art behind the 55% overlay, `ui/results_winner.png`
(90x20) top-centre, the winner's bust (96x128) on the left, and one
cardboard ui_panel (168,34) 140x78 with dark-ink m5x7 stat rows (12 px apart):
rounds won, match-total damage, max combo, METH used (P1/P2/BOTH/NO),
time left. Stats come from `game/scripts/ui/match_stats_tracker.gd`, a
presentation-only reader (accumulates MatchRoot's per-round
`round_damage` into match totals, tracks `combo_changed` maxima and
`meth_started`, samples `wins`/`timer_frames` at the end). **Not
available: per-round win-type letters** — MatchRoot only distinguishes
the current round's KO/timeout, no history exists, so the panel shows
the plain rounds tally. Below the panel (from y 116, over stage art): REMATCH / CHARACTER SELECT /
STAGE SELECT / MAIN MENU in outlined cream Marker, the focused row in plain dark-ink Marker on the yellow focus bar; Results appears 90 physics frames after MATCH_END so the KO and the winner banner land first; input is
ignored for the first 30 frames. Every option unpauses and routes;
REMATCH goes back through the VsScreen with the same fighters and
stage.

## The match HUD (UI Phase 2, 2026-11-22)

`game/scripts/ui/match_hud.gd` (`MatchHUD`, art table in
`game/scripts/ui/hud/hud_art.gd`). The HUD **reads** match/fighter state
and signals and writes nothing back; it holds no state
`MatchRoot.serialize()` needs, and every timer counts **SIM frames**
through the presentation-only `hud.sim_tick()` hook in
`MatchRoot._physics_process` — so the whole HUD freezes with pause (the
hook's paused gate) and with hitstop (the HUD reads the two public
`hitstop_frames` counters, the same ones that hold the round clock). A
`sim_frame` discontinuity — a `serialize()/load()` restore or a debug
frame-step — makes the HUD resync from current state: ghosts snap,
banners and callouts clear.

| Element | Position / art | Behavior |
| --- | --- | --- |
| Portraits | `hud_portrait_frame.png` 24x24 at (4,4)/(292,4); a 16x15 crop (x 3, y 1) of the 22x22 `hud_portrait_<id>_<state>.png` in the photo window at +4,+3, drawn ABOVE the opaque frame art | normal / **hurt** below 25% health / **ko** after losing the round (an opponent pip that grew while yours didn't; a refill clears it). Missing art = empty frame, no crash. |
| Health | `hud_health_frame.png` 118x10 at (30,8)/(172,8); code-drawn 98x6 fill on the cardboard strip between the tape caps (+10,+2), drawn ABOVE the opaque frame art, whole-pixel widths, P1 `#f29e26` / P2 `#e5473a`, draining toward the timer | a `#ff6b5a` ghost segment remembers the combo's damage point and drains to match **20 sim frames after the combo clears**; one flash per hit (never strobing); a gentle pulse under 20%. `reduce_flashing` makes the flash a 1-frame tint. |
| Names | outlined Marker cream at y 19 (P1 left from x 30, P2 right to x 290) | static per fighter |
| Round pips | y 31 from each bar's outer end; P1 `hud_pip_square_*`, P2 `hud_pip_diamond_*` | grow with double-KO pips. **No win-type letters: MatchRoot keeps no per-round win history** (TODO: the K/T/M/D pip art is approved and waits on a sim-side decision). |
| Timer | `hud_timer_box.png` at (148,3); two 8x12 cells from `hud_timer_digits.png` (0-9, cell 10 = infinity), centered | under 10 s the box tints dirty yellow and the digits tick one shade per 15 sim frames |
| Meter | `hud_meter_frame.png` 106x8 at (4,170)/(210,170); 90x4 fill `#5ac8ff` between the tape caps (+7,+2) above the frame art, tick marks at 25 and 50 | at full the fill turns `#ff3d9a`, "METH READY" in outlined Marker pink sits beside the bar (P1 edge x 114, P2 edge x 206) and the 8x8 skull frames alternate every **15 sim frames** |
| Banners | 160x32 `hud_banner_plate.png` centered (y 74) with the word sprite: round_1-5, decisive, fight, ko, time, double_ko, methtality | stamp in over **6 sim frames** from 8 px above in integer steps; spriteless messages (TAKES THE ROUND, WINS THE MATCH, DRAW, SUDDEN DEATH, ROUND 6+) render in outlined Marker cream on the plate. FIGHT auto-removes after 30 sim frames, METH after 120; round/KO banners persist until replaced (today's timing). |
| Callouts | outlined Marker cream on the attacker's side at y 80 | COUNTER HIT / TECH, one at a time, **30 sim frames** each |
| Combo counter | today's position (attacker's side, y 64), "<n> HITS" in outlined Marker `#f2d13a` | combo damage under it in m5x7 cream only while `gameplay.show_combo_damage` is on (reads `combo_tracker.total_damage`) |
| Commentary | `stream_commentary_box.png` 240x16 at (40,44), m5x7 dark ink on the tape | `gameplay.commentary`: full = as today, minimal = round lines only, off = hidden; `stream.hide_tripp_text` hides it. |
| Accessibility | — | `reduce_flashing`: every flash becomes a 1-frame tint. `high_contrast_hud`: solid `#1C160D` plates behind bars, names and timer. Screen shake and hold-to-confirm have no HUD-side hook yet (see KNOWN_ISSUES). |

The pause menu, the Results hand-off and the 90-frame Results delay are
untouched. `match_root.gd` is touched only in the banner call swaps and
the one-line hook; `serialize()/load()` and every combat number are
unchanged (pinned by `hud_test`).

## Settings

Autoload `Settings` (`game/scripts/ui/settings.gd`), stored in
`user://settings.cfg` as a ConfigFile with `[meta] version = 1`.
Missing keys are filled from defaults on load; loading never writes;
`set_value` applies, saves, and emits `changed`; the overlay writes values
with `set_values_silently` (blocked from applying/saving) when opening, so
opening the screen can never save; `reset_to_defaults` resets, applies,
refreshes, and saves. Audio sliders are 0-10 with the default at exactly
0 dB (`value / default` linear), so default settings never change the mix;
0 mutes the bus. No Controls tab yet (Phase 4).

| Section | Key | Default | Consumed by |
| --- | --- | --- | --- |
| video | `window_mode` | `windowed` | DisplayServer window mode |
| video | `integer_scale` | `4` | window size 320x180 * scale |
| video | `vsync` | `true` | DisplayServer vsync |
| audio | `master` | `8` | Master bus |
| audio | `music` | `6` | Music bus |
| audio | `sfx` | `8` | SFX bus |
| audio | `voice` | `8` | Voice bus (no players yet) |
| audio | `ui` | `6` | UI bus |
| audio | `mute_when_unfocused` | `true` | mutes Master on focus loss |
| gameplay | `input_display` | `off` | **stored, not yet consumed** |
| gameplay | `commentary` | `full` | **consumed by the HUD (UI Phase 2)**: full = as today, minimal = round lines only, off = hidden |
| gameplay | `show_combo_damage` | `true` | **consumed by the HUD (UI Phase 2)**: the m5x7 damage total under the combo counter |
| accessibility | `reduce_flashing` | `false` | **consumed by the HUD (UI Phase 2)**: every flash becomes a 1-frame tint |
| accessibility | `screen_shake` | `full` | **stored, not yet consumed** (no camera-shake hook yet) |
| accessibility | `high_contrast_hud` | `false` | **consumed by the HUD (UI Phase 2)**: solid `#1C160D` plates behind bars, names, timer |
| accessibility | `readable_font` | `false` | **stored, not yet consumed** |
| accessibility | `hold_to_confirm_meth` | `false` | **stored, not yet consumed** (input-side, not HUD-side) |
| stream | `streamer_safe_music` | `false` | **stored, not yet consumed** (music rights pending) |
| stream | `hide_tripp_text` | `false` | **consumed by the HUD (UI Phase 2)**: hides Tripp's commentary tape |

The overlay itself is `game/scenes/menus/settings_overlay.tscn`
(`game/scripts/ui/screens/settings_overlay.gd`): five tabs (Video, Audio,
Gameplay, Accessibility, Stream) plus a RESET TO DEFAULTS row, one-line
plain descriptions at the bottom, up/down moves, left/right adjusts or
switches tabs.

## Typography and contrast rules (every Phase 1 screen)

- **Two fonts.** Sidewalk Marker (`game/assets/fonts/sidewalk_marker.fnt`,
  `sidewalk_marker_outline.fnt` where text sits over art) at its native
  size **10** for headers, menu items, button labels and short labels.
  m5x7 at its native size **16** for body text and descriptions. Bangers
  appears only inside the logo art. The shared helpers live in
  `game/scripts/ui/ui_text.gd` (`UiText`), and
  `game/tests/ui_typography_test.gd` enforces the rules in CI.
- **BMFont import**: both Marker pages are nearest-filtered, no
  mipmaps (project-wide `default_texture_filter=0`). The plain page PNG
  must be **RGBA8** — Godot's BMFont loader rejects grayscale+alpha pages
  ("Unsupported BMFont texture format"); it was re-encoded on this branch
  and `art/tools/font/build.js` should emit PNG32 going forward.
- **Contrast (PR #86 review).** Text on a cardboard panel (ui_panel /
  ui_button) is always dark ink: `#2A2418` normal, `#7A6A48` inactive or
  greyed, and the focused item is `#1C160D` on a full-row-width
  `#F2D13A` highlight bar with 1 px padding top and bottom (the lit price
  slat look) — never cream or white on cardboard. Text drawn directly
  over stage art uses `sidewalk_marker_outline`. Cream `#F4EEDC` and
  muted `#9C8F70` are only for text on dark plates.
- **Declutter.** Title and MainMenu draw the Gas-N-Go art, then a
  `#1C160D` overlay at 55% alpha, then the UI. The pause menu dims the
  match behind it with the same overlay.
- **Key prompts (PR #86 review).** Keyboard prompts show the bracketed
  key name as text — "[ENTER]", "[BKSP]" — in m5x7 (Sidewalk Marker now
  ships `[` and `]`); pad prompts keep the A/B glyph sprites. The prompt
  line rides a full-width `#1C160D` plate at 80% alpha, 12 px tall, flush
  with the bottom of the 320x180 frame, so it never collides with stage
  art. The main menu's description line shares that plate on the left.
- **Never a Godot theme outline or shadow on a pixel font.** For
  contrast use the `_outline` font or a plate behind the text. Recolor
  with `font_color`; the baked dark outline stays dark.
- **Integer positions only**, no scaling on text nodes, and 1 px letter
  spacing exactly as each font defines it (no extra tracking).
- **No clipping and no overflow.** A control's theme overrides only
  reach its cached metrics on `NOTIFICATION_THEME_CHANGED`, so
  `UiText._make_label` refreshes that cache before any position/size is
  set and pins `custom_minimum_size` to the ink box — the rect set at
  build time is the rect that renders, and every label fits inside its
  container (`ui_typography_test` enforces it).
- **Spacing:** 8 px screen margins, a 4 px grid, fixed line heights
  (Sidewalk Marker 12, m5x7 16), body text left-aligned, at most about
  36 characters per m5x7 line.
- **At most one panel per screen;** no empty decorative boxes and no
  boxes nested inside boxes.
- **Prompt line:** one row on the bottom plate
  (`UiPromptLine.new(confirm, back, left_text = "")`), right-aligned.

Per-screen layouts (positions are 320x180 screen space):

| Screen | Layout |
| --- | --- |
| ContentWarning | dim; ui_panel (40,42) 240x96; "HEADS UP" Marker ink; two m5x7 ink lines; "PRESS [ENTER] TO CONTINUE" centered inside the panel (pad shows the A glyph). No auto-advance; confirm ignored for the first 30 frames. |
| Title | Gas-N-Go art; 55% #1C160D overlay; logo (90,16) 139x74; "PRESS START" Marker-outline yellow centered y140, 60f on / 60f off. Nothing else — PRESS START is the prompt, no prompt line. |
| MainMenu | Gas-N-Go art; 55% overlay; sign in the left third at (24,34) — pole base on the stage floor line — with a white outlined "MENU" in the sign's measured orange header band (art x 5..72 / y 5..29); slats per the geometry above in dark ink; QUIT button (40,116) 48x16 taped to the pole, focused = yellow bar + darkest ink; description on the bottom plate's left, prompt on its right. |
| SettingsOverlay | ui_panel (20,16) 280x148; tab row Marker at y22 (active tab on a small yellow bar, inactive `#7A6A48`); rows m5x7 ink label left / ink value right (step 14, max 7 visible, scrolls if ever needed); focused row = full-width yellow bar + `#1C160D`; RESET in `#7A6A48`; description `#7A6A48` inside the panel bottom (32,144). |
| Pause | 55% #1C160D dim; ui_panel centered on the longest item + 8 px padding each side, (24) 116 tall; "PAUSED" Marker ink; items Marker ink centered, focused on a full-width yellow bar + `#1C160D`; "BACK TO CHARACTER SELECT" is "CHARACTER SELECT" now. No per-item buttons. |
| QuitConfirm | dim; ui_panel (66,54) sized to the question; "LEAVE THE SIDEWALK?" Marker ink; YES / NO one row on 40x12 slots, focused slot = yellow bar + `#1C160D`, default NO. |

## Screenshots

`docs/assets/ui/` holds one 320x180 PNG per polished screen:
`content_warning`, `title`, `main_menu`, `main_menu_settings` (SETTINGS
focused), `main_menu_quit` (QUIT focused), `settings_video`,
`settings_audio`, `settings_gameplay`, `pause`, `quit_confirm`, the
PR A select screens: `mode_select`, `difficulty`,
`character_select_p1` (solo), `character_select_both` (versus),
`stage_select`, `stage_select_random` (RANDOM focused), the PR B
match wrap: `vs_screen` (after the slide-in), `results`,
`results_rematch_focus`, and the PR C HUD: `hud_round_start`,
`hud_fight`, `hud_midfight`, `hud_low_health`, `hud_meth_ready`,
`hud_ko`, `hud_high_contrast`.
Regenerate by driving the real scenes:

```bash
DISPLAY=:0 godot --path game --resolution 1280x720 \
    --script res://tools/ui_polish_capture.gd
DISPLAY=:0 godot --path game --resolution 1280x720 \
    --script res://tools/ui_select_capture.gd
DISPLAY=:0 godot --path game --resolution 1280x720 \
    --script res://tools/ui_match_capture.gd
DISPLAY=:0 godot --path game --resolution 1280x720 \
    --script res://tools/ui_hud_capture.gd
```

(`game/tools/ui_polish_capture.gd` and `ui_select_capture.gd` capture
the window and nearest-resize to 320x180.)

## Fonts and theme (background)

- **m5x7** (Daniel Linssen, CC0) remains the theme default at its native
  size 16, one game pixel per font pixel, antialiasing and subpixel
  positioning disabled in the import. **Sidewalk Marker is the project's
  own BMFont** (`art/tools/font/`, uppercase-only with lowercase mapped,
  line height 12). Bangers stays inside the logo art only.
- `game/resources/ui_theme.tres`: panel = 9-slice `ui/ui_panel.png`
  (8 px corners); button = 9-slice `ui/ui_button.png` with focus (warm
  yellow), pressed (darker), and disabled (50% grey) as modulate tints.
- Every screen shows a confirm/back prompt line (UiPromptLine,
  `game/scripts/ui/ui_prompt_line.gd`) with keyboard or pad glyphs
  matching the last device used.

## Art pipeline command

Runtime UI art is generated, never hand-edited:

```bash
godot --headless --path game --import
godot --headless --path game --script res://tools/prepare_ui.gd
godot --headless --path game --import   # generate .import files for new art
```

The canonical tool is `art/tools/prepare_ui.gd` (the size table from
`docs/UI_ASSETS.md`); the game-side shim `game/tools/prepare_ui.gd`
compiles and runs it because Godot only executes scripts under `res://`.
It copies every `art/source/UI/approved/<group>/*.png` unchanged to
`game/art/ui/<group>/`, verifies each size, fails loudly on a mismatch or
on an approved file missing from the table, and exits non-zero.
`game/tests/ui_assets_test.gd` re-runs the same table in verify-only mode.

## Tests

- `game/tests/ui_flow_test.gd` — 53 checks: router semantics, every
  forward/back path, the confirm-leak guard, pause overlay flow, greyed
  items, QuitConfirm default, the press-required warning (no
  auto-advance, 30-frame guard), the chat-free main menu, wrap order,
  the stage -> VS -> match hand-off, title pulse.
- `game/tests/settings_test.gd` — 16 checks: defaults, fill-in, round
  trip, opening never saves, reset applies + saves, 0 dB defaults.
- `game/tests/ui_assets_test.gd` — 4 checks: sizes + byte identity.
- `game/tests/ui_typography_test.gd` — 42 checks: every label in the
  eleven UI surfaces (screens + the pause menu) uses a pixel font at
  its native size with every glyph present, no theme outline/shadow,
  integer positions, no scaling; labels on cardboard (ui_panel /
  ui_button) fit their container and use the dark inks; over-art
  lettering uses the outlined marker; the pause panel sizes itself to
  its longest item plus padding; no two visible labels overlap
  (measured on drawn ink extents) and every label over a TextureRect
  card (rap sheet, tickets) lies inside it — the PM review's two bugs
  both fail these checks on the pre-fix code — and the HUD labels pass
  the same rules at round start and mid-fight.
- `game/tests/select_screens_test.gd` — 24 checks (PR A): the Mode and
  Difficulty choices are unchanged (names, order, defaults, emits, back
  paths); the difficulty rows draw 1/2/3 tally marks; the rap sheet
  shows the focused fighter's roster name, booking photo and
  owner-editable wall copy; cursors are per-player scribbles in the side
  accents and solo hides P2 until lock; RANDOM starts covered; the
  focused ticket lifts 2 px with a yellow frame; concrete stages hand
  off immediately; the RANDOM scratch-off holds the hand-off for 18
  frames, then hands off the stage the RNG picked with its own
  thumbnail revealed; Backspace still leaves after the reveal.
- `game/tests/results_flow_test.gd` — 20 checks (PR B): the VS busts
  slide in over 12 integer steps and land at their marks (P2 flipped);
  the 20-frame VS skip guard; the full 150-frame duration; Results
  appears at match end above the frozen (paused) match with the real
  winner and rounds tally; serialize() is identical while Results is
  up; the 30-frame Results guard; REMATCH routes through the VS bumper
  and keeps fighters and stage; CHARACTER SELECT / STAGE SELECT /
  MAIN MENU all route correctly and unpause.
- `game/tests/hud_test.gd` — 47 checks (UI Phase 2, against a scratch
  settings.cfg): portrait states; health and the 20-frame ghost drain;
  the HUD tick frozen while paused; pip sprites; timer digit cells and
  the under-10 tint; meter width, the METH-pink full state and the
  15-frame skull alternation; banner sprites per message with the text
  fallback, stamp settle and auto-remove timing; attacker-side callouts
  for 30 sim frames; the combo counter with its gated damage total;
  commentary full/minimal/off and hide_tripp_text; reduce_flashing and
  high-contrast; the serialize/load resync; and serialize() identical
  with the HUD bound and unbound.
- All seven run in CI (`tests.yml`) alongside the existing suites.
