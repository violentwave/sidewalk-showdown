# UI Screens — Router, Screen List, and Settings (Phase 1)

**Status: implemented 2026-11-21 (UI Phase 1).** This file documents what
actually shipped: the router, the screen flow with every back path, the
Settings keys and where each one is (or is not yet) consumed, and the UI
art pipeline command. Companion docs: `docs/UI_HUD_SCREENS_PLAN.md` (the
original plan), `docs/UI_ASSETS.md` (art manifest), `docs/PM_BRIEF.md`.

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
CharacterSelect <-> StageSelect -> MatchRoot
   `-- back -> ModeSelect `-- back -> MainMenu
MatchRoot pause: RESUME / SETTINGS (overlay) / RESTART MATCH /
   BACK TO CHARACTER SELECT / MAIN MENU / QUIT TO DESKTOP (QuitConfirm)
```

| Screen | Enter | Back / exit |
| --- | --- | --- |
| ContentWarning (once per launch) | boot | confirm or 180 frames -> The Clip |
| The Clip (unchanged) | warning | Space advance, Esc skip -> Title |
| Title | Clip, MainMenu back | confirm -> MainMenu; back -> QuitConfirm |
| MainMenu | Title | back -> Title; items below |
| ModeSelect | MainMenu VERSUS | back -> MainMenu |
| Difficulty | ModeSelect 1P | Backspace -> ModeSelect |
| CharacterSelect | ModeSelect/Difficulty, StageSelect back | Backspace -> ModeSelect (drops restored picks) |
| StageSelect | CharacterSelect | Backspace -> CharacterSelect (deferred) |
| MatchRoot | StageSelect | pause menu |
| SettingsOverlay | MainMenu SETTINGS, pause SETTINGS | back -> whatever opened it |
| QuitConfirm | Title back, MainMenu QUIT, pause QUIT | NO/back -> what opened it; YES -> quit |

Pause-menu specifics: SETTINGS and QUIT TO DESKTOP open overlays **above the
still-paused match** (`match_root.modal_open` blocks the pause key and menu
input underneath; the overlays run `PROCESS_MODE_ALWAYS`); MAIN MENU
unpauses, frees the match, and shows the hub. QuitConfirm defaults to NO.

The five MainMenu slats are measured from `menu_price_sign.png`
(79x124, art space): cream board x 1..73, content rows 35-43, 46-51,
54-60, 63-69, 72-73, dividers at 44-45, 52-53, 61-62, 70-71; the lit
slat (66x7) sits at x 6, y 36/45/54/63/69. The constants live in
`game/scripts/ui/screens/main_menu.gd`. The chat strip cycles the five
owner-seed lines on a 75-frame counter in a fixed order — no RNG.

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
| gameplay | `commentary` | `full` | **stored, not yet consumed** (Phase 2 HUD pass) |
| gameplay | `show_combo_damage` | `true` | **stored, not yet consumed** (Phase 2 HUD pass) |
| accessibility | `reduce_flashing` | `false` | **stored, not yet consumed** |
| accessibility | `screen_shake` | `full` | **stored, not yet consumed** |
| accessibility | `high_contrast_hud` | `false` | **stored, not yet consumed** (Phase 2 HUD pass) |
| accessibility | `readable_font` | `false` | **stored, not yet consumed** |
| accessibility | `hold_to_confirm_meth` | `false` | **stored, not yet consumed** |
| stream | `streamer_safe_music` | `false` | **stored, not yet consumed** (music rights pending) |
| stream | `hide_tripp_text` | `false` | **stored, not yet consumed** (Phase 2 HUD pass) |

The overlay itself is `game/scenes/menus/settings_overlay.tscn`
(`game/scripts/ui/screens/settings_overlay.gd`): five tabs (Video, Audio,
Gameplay, Accessibility, Stream) plus a RESET TO DEFAULTS row, one-line
plain descriptions at the bottom, up/down moves, left/right adjusts or
switches tabs.

## Fonts and theme

- **m5x7** (Daniel Linssen, CC0) is the default theme font at its native
  size 16 — 1 game pixel per font pixel, antialiasing and subpixel
  positioning disabled in the import. Bangers remains for big headers,
  applied per label.
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

- `game/tests/ui_flow_test.gd` — 48 checks: router semantics, every
  forward/back path, the confirm-leak guard, pause overlay flow, greyed
  items, QuitConfirm default, warning auto-continue, title pulse.
- `game/tests/settings_test.gd` — 16 checks: defaults, fill-in, round
  trip, opening never saves, reset applies + saves, 0 dB defaults.
- `game/tests/ui_assets_test.gd` — 4 checks: sizes + byte identity.
- All three run in CI (`tests.yml`) alongside the existing twelve suites.
