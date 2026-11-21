> **Status (2026-11-21): Phase 1 is IMPLEMENTED** (router, Settings autoload,
> audio buses, content warning, title, main menu with the price board,
> quit confirm, the 6-item pause menu, and the approved art
> wired through `art/tools/prepare_ui.gd`) **and polished from owner
> playtest feedback the same day** (Sidewalk Marker + m5x7 typography
> rules, the chat strip removed so the main menu is the price board
> only, the content warning press-required with a 30-frame input guard).
> See `docs/UI_SCREENS.md` for what actually shipped — it supersedes this
> doc's Phase 1 section, and notes the deltas: The Clip runs right after
> the content warning (before the title), there is no attract demo, the
> main menu's slat rects are measured constants, QUIT rides a taped
> ui_button on the sign pole, and Settings has no Controls tab yet.
> Phases 2-5 below remain the plan. The Phase 1 prompt at the bottom is
> kept for history; it predates the "audience model" and pixel-font
> decisions in `docs/UI_DESIGN_RESEARCH.md`. Diagrams from the original
> doc are not included.

# Sidewalk Showdown — HUD & Screens Plan

2026-11-20 · @Logan Chad Hurley

## Summary

The game has 4 of the 14 screens GDD §10.2 requires (character select, stage select, HUD, pause), plus a partial main menu, and all are placeholder text on black. The plan: build a shared UI kit first (theme, fonts, 9-slice frames, transitions, a Settings autoload), then add the missing screens and reskin the HUD, in five phases that never touch combat code.

What exists on main (49dca36):

- **The Clip** intro comic, then **Mode Select** (1P/2P), **Difficulty**, **Character Select**, **Stage Select**, **Match**, all routed by `main.gd`.
- **MatchHUD** built in code from `ColorRect`s and outlined labels: health bars, meter bars, timer, 2 round pips, combo text, TECH / COUNTER HIT / METHtality banners, Tripp commentary box, and a 4-item pause overlay.
- Fonts already shipped: Bangers, Comic Neue (Regular/Bold), Share Tech Mono.
- UI concept art in `art/source/UI/` (health bar, METHtality meter, TIME box, a generic arcade HUD sheet). It is 1024–1536 px source art; none of it is wired into the game.

What's missing: no title screen, no main menu (mode select is the first stop and has no Settings, Training, Credits or Quit), no settings or saved preferences, no audio buses, no input remap, no VS screen, no results screen, no content warning, and quitting is only reachable from inside a match.

## Art direction

The UI reads as **Tripp's cheap livestream overlay hijacking a 1994 arcade cabinet**: GDD §10.1 already sets this ("corrupted retro arcade broadcast mixed with a cheap livestream overlay"). The rule that keeps it from being noise: the arcade layer carries the information, the stream layer carries the jokes, and jokes never sit on top of the fight.

**Two layers**

| Layer | Carries | Looks like | Where |
| --- | --- | --- | --- |
| Arcade cabinet | Health, meter, timer, rounds, menus you navigate | Chunky beveled frames, hard 1 px black outline, 2-tone shading, Bangers headers | Top strip and bottom strip of the HUD; every menu panel |
| Tripp's stream | Commentary, viewer count, fake chat, sponsor bugs, LIVE tag, lower-thirds | Flat "cheap OBS template" boxes, neon pink/cyan, a clipped corner, light scanline or compression glitch on enter/exit only | Corners and lower-third; title, VS and results screens |

**Palette for UI** (from GDD §11.7, pulled tighter so it reads on both stages):

- Frame: asphalt gray `#3a3540` with near-black outline `#0f0b12`
- P1: hot orange `#f29e26` (matches current HUD). P2: gas-station red `#e5473a`. Both also get a shape cue (P1 square pips, P2 diamond pips) so the sides don't depend on color alone.
- Meter / METHtality: liquor-store blue `#5ac8ff` filling, flips to neon pink `#ff3d9a` at full with the word READY.
- Warning accents: dirty yellow `#f2d13a` for timer under 10 and DECISIVE ROUND.
- Stream layer only: neon pink `#ff3d9a`, cyan `#3df0ff`, ring-light white `#fff7e8`.

**Type at 320×180**

- Headers and banners: Bangers, 16 px and up, 1 px outline. Bangers at small sizes blurs into mush, so never under 12 px.
- Menu items and HUD labels: a true pixel font is needed. Comic Neue and Share Tech Mono anti-alias at 8–10 px and won't stay crisp under nearest-neighbor. Pick a free bitmap-style font (an 8 px and a 5 px cap height) and set it as the theme default; this is a licensing decision for you, so it's in the decisions list.
- Numbers (timer, damage, combo): one chunky digit set drawn as a sprite strip, so they can bounce and shake without font hinting.

**Rules every screen follows**

- Native 320×180, integer-scaled, nearest-neighbor, pixel-snapped; no fractional positions or scaling on UI nodes.
- Text over the stage always has an outline or a backing plate.
- Flashes: one flash per event, never more than 3 per second; the reduce-flashing setting swaps flashes for a tint.
- Every screen has a visible confirm and back prompt that shows keyboard or pad glyphs to match the last device used.
- Tone: the menu copy is where the jokes go (Tripp-voiced subtitles under plain labels), but the label itself is always plain: "SETTINGS", with "tweak your little settings" under it, never only the joke.

## Screens and routing

Nine screens are new and two change shape; the biggest structural change is that **Main Menu becomes the hub** that every exit returns to, and **Settings is one overlay scene** opened from both the menu and the pause menu.

| Screen | Status | Reached from | Back / exit goes to | Phase |
| --- | --- | --- | --- | --- |
| Content warning + photosensitivity notice | New | Boot | Title (confirm only, ignored for the first 30 frames; shown once per launch) | 1 |
| The Clip | Exists | Title (first launch auto; later via Extras or idle attract) | Title | 1 (reroute only) |
| Title ("PRESS START") | New | Boot, Main Menu back | Quit prompt | 1 |
| Main Menu | New (replaces Mode Select as the first stop) | Title, every exit | Title | 1 |
| Versus setup (1P vs CPU / 2P) | Exists as Mode Select, moves under VERSUS | Main Menu | Main Menu | 1 |
| Difficulty | Exists | Versus setup (1P) | Versus setup | — |
| Character Select | Exists, reskin | Versus setup / Difficulty, Results | Versus setup | 3 |
| Stage Select | Exists, reskin | Character Select, Results | Character Select | 3 |
| VS screen | New | Stage Select, Results (rematch) | none (non-interactive, about 2.5 s, skippable) | 3 |
| Match + HUD | Exists, reskin | VS screen | Pause menu | 2 |
| Pause menu | Exists, expand | Match | Match | 1 |
| Settings (overlay) | New | Main Menu, Pause | Whatever opened it | 1 |
| Results | New (today: Enter restarts) | Match end | Rematch / Character Select / Stage Select / Main Menu | 3 |
| Training mode + menu | New | Main Menu | Main Menu | after combo Phase 2 |
| Extras: Credits, The Clip, Gallery | New | Main Menu | Main Menu | 4 |
| Quit confirm | New | Main Menu, Title, Pause | Previous screen | 1 |
| Loading / tips | Skip for now | — | — | Only if load times appear |
| Arcade / Story ladder | Later | Main Menu (shown greyed "COMING SOON") | — | Campaign phase |

> *[Diagram not exported: screen routing · main flow, versus loop, overlays. See the original Claude Doc.]*

The versus loop runs left to right; Results feeds back to VS screen on rematch, and every other exit lands on the Main Menu.

**Router change.** `main.gd` today hand-wires each screen with its own instance variable and free/show pair. With 15+ screens that becomes the main bug source. Phase 1 replaces it with a small `ScreenRouter`: a stack of screens with `push`, `pop` and `replace`, deferred transitions (keeping the existing guard against a confirm key leaking into the next screen), and one `FlowState` object holding mode, CPU level, picks and last stage. Overlays (Settings, Quit confirm) are pushed on top without freeing the screen below. All of this is presentation; nothing enters the 60 Hz sim or `MatchRoot.serialize()`.

## Match HUD

The HUD keeps the genre's fixed grammar (P1 left, P2 right, bars draining toward the center timer, rounds under the bars, meter at the bottom) and puts all the personality into the frames, portraits, callouts and Tripp's stream layer. Everything stays inside two bands: **top 0–40 px** and **bottom 164–180 px**; the fight space between them stays clear except for short callouts.

> *[Diagram not exported: match HUD layout · 320×180 drawn at 2×. See the original Claude Doc.]*

| Element | Position at 320×180 (x, y, w×h) | Behavior |
| --- | --- | --- |
| Portrait | P1 4, 4, 24×24; P2 mirrored at 292 | Face mug in a beveled frame. Swaps to a hurt face under 25% health and a KO face on loss. |
| Health bar | P1 30, 8, 118×8; P2 172, 8, 118×8 | Drains toward the timer. A red "ghost" segment shows damage from the current combo and drains to match about 20 frames after the combo ends. Bar flashes once (not repeatedly) and pulses gently under 20%. |
| Name plate | Under each bar, y 18 | Pixel font, plain caps. 2P versus can show a player tag later. |
| Round pips | y 30, outer edge in | P1 squares, P2 diamonds, so the sides read without color. Win type letter inside a won pip (K = KO, T = time, M = METHtality, D = double KO), like the SF4 letters. |
| Timer | 148, 3, 24×20 | Sprite digits in the TIME box from `art/source/UI/Time.png`. Turns dirty yellow and ticks under 10. ∞ in training. |
| Hype Meter | P1 4, 170, 104×6; P2 212, 170 | Tick marks at 25 (Clip Cancel) and 50 (EX) of 100. At full it turns neon pink, shows METH READY, and a small skull icon wobbles; no strobing. |
| Combo counter | Attacker's side, y 64 (today's spot) | Big sprite number + HITS, damage total under it. Bumps once per hit. Folds in the planned combo HUD (Prompt 5): scaling indicator and counter-hit color. |
| Callouts | Attacker's side, y 80 | COUNTER, TECH, REVERSAL style tags from the side that earned them, as SF4's status line does. One at a time, 30 frames. |
| Round banners | Center, y 70–110 | ROUND 1, DECISIVE ROUND, FIGHT!, K.O., TIME, DOUBLE K.O., and the METHtality banner. Bangers 24 px with a stamp-in animation. |
| Tripp layer | Top center under the timer (LIVE + viewer count), commentary box below the bars | Viewer count ticks up on big hits, drops on timeouts. Commentary stays in its current spot (40, 45). Setting: Full / Minimal / Off. |
| Pause | Full-screen dim + center panel | Expanded list in the per-screen section. |

Timing rules: every HUD counter (ghost bar, flashes, callouts) counts **simulation frames** so it freezes with pause and hitstop and replays identically (today's HUD counts its flash timers in _process, render frames; Phase 2 moves them onto the sim tick per PM_BRIEF rule 1). The HUD only reads fighter signals; it never writes match state.

## Settings

Settings is one overlay scene with six tabs, backed by a `Settings` autoload that loads `user://settings.cfg` on boot, applies it, and saves on every change. Nothing in it touches the simulation; match rules (rounds, timer) live on the Versus setup screen instead, because they change the match and must go through `MatchRoot` config and serialization.

| Tab | Options (first pass) | Default | Notes |
| --- | --- | --- | --- |
| Video | Window mode (windowed / borderless fullscreen); window scale 2×–6×; VSync; CRT scanline filter | Windowed 4×, VSync on, filter off | Keep integer scaling; the filter is a post-process shader on the final 320×180 image only. |
| Audio | Master, Music, SFX, Voice, UI sliders 0–10; mute when window unfocused | 8 / 6 / 8 / 8 / 6 | Needs a bus layout (`default_bus_layout.tres`); today `audio_manager.gd` sets `volume_db` per player with no buses. |
| Controls | Per-player remap of left/right/up/down, light, heavy, special, grab, METH, pause; keyboard and pad columns; button check / test; reset to default | Current map | Rebinds go to `user://input.cfg` at runtime. Never regenerate `project.godot` from the menu (it drops `physics_ticks_per_second=60`). Conflict check: one key can't hold two actions for the same player. |
| Gameplay | Input display (off / P1 / both); Tripp commentary (full / minimal / off); show combo damage | Off / full / on | Presentation only. |
| Accessibility | Reduce flashing; screen shake (off / low / full); high-contrast HUD; readable font (swaps the pixel font for a larger one in menus); hold-to-confirm for METHtality | Off / full / off / off / off | Covers the GDD §10.5 list. Subtitles join when voice lines exist. |
| Stream | Streamer-safe music (mutes licensed tracks); hide Tripp layer; hide viewer count | Off | Ties to the open music-rights item. Matters for your own Twitch streams before the rights are settled. |

Rules for the agent building it:

- Version the config file (`[meta] version = 1`) and fill missing keys with defaults, so later additions don't break old saves.
- Opening the screen must not save: loading values into sliders fires the same signals as a player moving them, so set values with signals blocked.
- "Reset to defaults" resets the variables, applies them to the engine, refreshes the screen, then saves.
- Every option shows a one-line description at the bottom, so the joke copy never hides what an option does.

## Screen ideas

Each screen borrows one real object from the world (a gas-station sign, a scratch-off, a mugshot board) so the menus feel like Florida, not like a template. The main menu has three directions for you to pick from; the rest are a single proposal each.

**Main menu: pick one direction**

| Direction | What it is | Strength | Cost |
| --- | --- | --- | --- |
| A. Gas-N-Go price board | Menu items are the slats of the station's price sign (VERSUS, TRAINING, SETTINGS, EXTRAS, QUIT), the selected slat flips and lights up; Gas-N-Go night art behind, a fighter idling by the pump | Uses the stage we have; instantly reads as "place" | One sign sprite + flip animation |
| B. Tripp's stream deck | The menu is Tripp's OBS scene list; a fake chat scrolls on the right reacting to the highlighted item; LIVE tag and a viewer count | Sets up Tripp as the antagonist from the first screen | Most UI pieces; chat lines to write |
| C. Bus Stop route board | Destinations on a transit schedule board; selection ticks over like a split-flap display | Strong motion, cheap art | Less tie-in to Tripp |

My pick was **A with B's chat strip**; the owner later removed the chat
strip in the 2026-11-21 polish pass — the main menu is the price board
only (decision recorded).

**The other screens**

| Screen | Concept | Details |
| --- | --- | --- |
| Content warning | A sun-faded gas-station NOTICE sticker | One Tripp line ("my lawyer made me put this here"), then a plain, sober photosensitivity sentence. Confirm or 3 s to continue. |
| Title | Logo over the night sidewalk | SIDEWALK SHOWDOWN in Bangers with a spray-paint underline; PRESS START pulses once per second. After 30 s idle, an **attract demo** plays a CPU vs CPU match using the existing AI-vs-AI soak flag with a DEMO stamp, then The Clip. |
| Versus setup | The current 1P / 2P choice, restyled | Adds a RULES row: rounds (1/3/5), timer (60/99/∞), METHtality on/off. Passed into `MatchRoot` as config. |
| Character select | Booking-room mugshot board | Portrait against a height chart; a "rap sheet" card shows archetype, difficulty, tagline, rival and home stage (GDD §10.4). P1 and P2 cursors are marker scribbles; a button cycles palettes. Tripp never shows. |
| Stage select | Scratch-off lottery tickets | Each stage is a ticket with its thumbnail; RANDOM is a ticket you scratch. Uses `ScratchOff.png` from `art/source/Items/` as reference. |
| VS screen | Tripp's "TONIGHT'S MATCHUP" bumper | Diagonal split, both portraits slam in, names, one trash-talk line per matchup, a fake sponsor bug ("brought to you by Swamp Juice"). About 2.5 s, any button skips. |
| Pause | VHS pause | "▌▌ PAUSE" with faint tracking lines (static, no flicker). Resume, Move List (later), Settings, Restart Match, Character Select, Main Menu, Quit to Desktop (with confirm). |
| Results | Tripp's clip of the match | Winner pose and win quote; stats: damage, max combo, METHtality yes/no, time left; viewer count change. Rematch, Character Select, Stage Select, Main Menu. Replaces today's "Enter restarts". |
| Credits | Stream end card | "Thanks for watching" layout; real credits and font licenses from `docs/ART_CREDITS.md`. |
| Quit confirm | Small modal | "Leave the sidewalk?" YES / NO, defaults to NO. |

## What the genre standard is

The big fighters agree on a fixed HUD grammar and differ mainly in how much they put in training mode and accessibility, so matching them is mostly about completeness, not novelty.

| Standard | What it means for us | Source |
| --- | --- | --- |
| P1 left, P2 right; health on top; timer between; round markers by the bars; 99 s default timer | Keep the grammar; spend originality on frames and the stream layer | [RoFighters HUD](https://wiki.gbl.gg/w/RoFighters/HUD), [Tekken 8 layout](https://bushy2.itch.io/a1-skill-development/devlog/812196/other-games-uis) |
| Health drains toward the center | Already true in `match_hud.gd`; keep it | [r/gamedev HUD critique](https://redlib.hackliberty.org/r/gamedev/comments/1ld624o/how_would_you_improve_this_hud) |
| A trailing "ghost" bar shows recent damage | Red ghost segment on combo damage | [HUD health bar guide](https://www.abratabia.com/game-ui-design/health-bars-indicators.php) |
| Round-win letters and status text on the side of the player who earned it | Win-type letters in pips; callouts on the attacker's side | [USF4 HUD](https://srk.shib.live/w/Ultra_Street_Fighter_IV/HUD) |
| Training mode: input display, frame data, hitbox view, record/playback, frame step | Training mode scope; the debug overlay already has some of this | [Fantasy Strike training](https://wiki.gbl.gg/w/Fantasy_Strike/Training), [Rivals practice mode](https://wiki.gbl.gg/w/Rivals_of_Aether/Practice_Mode) |
| SF6's frame meter is now the bar every reviewer cites | Plan a frame meter strip for training (it fits our frame-counted sim well) | [Infil SF6 review](https://words.infil.net/w04-sf6review-p6.html) |
| Button check and side select at rematch reduce controller-swap friction | Button test in Controls; side select on Results | [FGC feature checklist](https://toptier.gg/the-definitive-list-of-features-that-every-fighting-game-should-have) |
| SF6 and MK1 set the accessibility bar with deep audio and accessibility menus | Our Accessibility tab is the floor, not the ceiling; audio cues come later | [SF6 audio accessibility](https://www.thegamer.com/street-fighter-6-audio-accessibility-options/), [MK1 settings](https://dashfight.com/news/mortal-kombat-1-settings-accessibility-options-explained-3322) |
| No more than 3 flashes per second; removing triggers beats warning screens | One flash per event; reduce-flashing option; still show the notice | [Xbox XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118), [WCAG 2.3.1](https://www.disabilityworld.org/toolkit/standards/wcag/2-3-1-three-flashes-or-below-threshold/) |
| Godot settings: ConfigFile in `user://`, versioned input config replayed from an autoload | The Settings autoload design above | [Godot save practices](https://bugnet.io/blog/game-save-best-practices-godot), [InputMap persistence](https://bugnet.io/blog/fix-godot-inputmap-action-exhausted-after-restart), [settings menu pitfalls](https://uhiyama-lab.com/en/notes/godot/settings-menu-configfile/) |

## Art production

Figma holds the layout at true 320×180; PixelLab makes the pixel pieces; the repo pipeline turns them into runtime art. Figma never ships pixels into the game, because its exports smooth when scaled.

**Pipeline**

1. **Figma** (the Sidewalk Showdown file): one 320×180 frame per screen, 1 unit = 1 game pixel, pixel grid on. Pages: Tokens (palette, type), HUD, Menus, Select screens, Components (panel, button, bar, pip, glyph). Placeholder boxes first; I can build these frames for you once you send the file link.
2. **PixelLab** "Create UI elements": generate each piece with a reference image so the set stays consistent. Use the existing `art/source/UI/HealthFull.png`, `MethtalityMeter.png` and `Time.png` as the style anchor. Expect wrong canvas sizes, as noted in PROJECT_STATE.
3. **Source**: drop raw outputs into `art/source/UI/<Screen>/` (read-only after that).
4. **Prep**: a headless Godot script in `art/tools/` (`prepare_ui.gd`, so agents can run it without Python) crops, nearest-neighbor resizes to the exact native size below, and writes `game/art/ui/`. Never hand-edit the output.
5. **Theme**: one `game/resources/ui_theme.tres` with 9-slice StyleBoxTextures, the pixel font, and focus styles; every screen uses it.

**Asset list (native pixel sizes)**

| Asset | Size | Count / states |
| --- | --- | --- |
| Panel 9-slice | 24×24, 8 px corners | Normal, focused |
| Button 9-slice | 48×16 | Normal, focus, pressed, disabled |
| Health bar frame + fill strips | 120×10; fills 1×8 | P1, P2, ghost red, low-health |
| Meter frame + READY skull | 106×8; skull 8×8 | Skull 2 frames |
| Timer box + digits | 24×20; digits 8×12 | 0–9 and ∞ |
| HUD portrait | 24×24 | 3 per fighter (normal, hurt, KO) |
| Select portrait | 64×64 | 1 per fighter |
| VS bust | 96×128 | 1 per fighter |
| Round pips | 5×5 | Square and diamond, empty and filled, + K/T/M/D |
| Banner words | about 160×32 | ROUND 1–5, FIGHT!, K.O., TIME, DOUBLE K.O., DECISIVE ROUND, METHtality |
| Logo | about 200×60 | 1 |
| Price-board sign + slats | sign about 120×100; slats 96×14 | 5 slats, normal and lit |
| Mugshot board background, rap-sheet card | 320×180; 120×80 | 1 each |
| Scratch-off ticket | 72×44 | Covered, 3 scratch frames, revealed |
| Input glyphs | 9×9 | Keyboard keys, pad face buttons, d-pad |
| Stream layer | LIVE tag 24×7; chat panel 80×100; sponsor bug 40×12 | 1 each |
| Pixel font | 8 px and 5 px cap height | Free license, your pick |

**Starter PixelLab prompts** (paste with the reference image attached)

- "Fighting game health bar frame, 120x10 pixels, chunky beveled asphalt-gray frame with 1 px black outline, empty interior, grimy retro arcade style, transparent background."
- "Pixel art gas station price sign, 120x100, night, neon edge glow, five empty horizontal slats for text, sun-faded Florida convenience store style, transparent background."
- "Pixel art scratch-off lottery ticket, 72x44, silver scratch area, garish Florida lottery colors, no text, transparent background."

## Build phases and decisions

Phase 1 (router, settings, title, main menu) can start now in its own worktree, in parallel with the combo test fixes, because it doesn't touch combat files. Art can be generated alongside; screens ship with placeholder styling first and get reskinned in Phase 5.

| Phase | Scope | Model | Depends on |
| --- | --- | --- | --- |
| 1. Foundation | `ScreenRouter` + `FlowState`; Settings autoload, audio buses, `settings.cfg`; Settings overlay (all tabs but Controls); content warning, Title, Main Menu, Quit confirm; pause gains Settings and Main Menu | GLM-5.3 | Nothing; avoids combat files |
| 2. HUD pass | Ghost bar, shape-coded pips with win letters, timer warning, meter ticks and READY state, side callouts, Tripp layer toggle; HUD timers onto the sim tick; folds in combo HUD (Prompt 5) | GLM-5.3 | Phase 1; combo Phase 2 merged first, since both touch HUD signals |
| 3. Match wrap | VS screen, Results screen, Versus RULES row (rounds, timer, METHtality) through `MatchRoot` config + `serialize()` | GLM-5.3 | Phase 1; your rules decision |
| 4. Controls + extras | Remap tab with `user://input.cfg`, button test, conflict check; Credits; The Clip in Extras | GLM-5.3 (remap), DeepSeek V4.1 Flash (credits) | Phase 1 |
| 5. Art wiring | `art/tools/prepare_ui.gd`, `ui_theme.tres`, PixelLab assets into every screen | DeepSeek V4.1 Flash | Assets from you |
| Later | Training mode (needs its own plan), Gallery, Arcade ladder | — | Combo Phase 2 |

**Decisions for you**

- [x] Main menu direction: A (price board) — chosen, shipped, and the chat strip removed in the 2026-11-21 polish (owner decision).
- [ ] Pixel font and its license (an OFL bitmap font keeps it simple).
- [ ] Content warning every launch, or first launch only.
- [ ] The Clip auto-plays on first launch only, or every launch as today.
- [ ] Attract demo (CPU vs CPU on the title screen): yes or no.
- [ ] Versus RULES row: which round and timer options, and whether METHtality can be turned off. These change matches, so they're design calls.
- [ ] Send the Figma file link so I can build the 320×180 frames.

**Phase 1 agent prompt**

```text
MODEL: GLM-5.3

Read docs/AGENT_RULES.md and docs/PM_BRIEF.md first.

SETUP
cd /home/lch/Projects/sidewalk-showdown && git fetch origin
git worktree add ../sidewalk-showdown-ui -b feat/ui-foundation origin/main
cd ../sidewalk-showdown-ui
Other agents may be working on combat/CPU/serialization tests and doc cleanup in parallel. Do NOT edit game/scripts/combat/, game/scripts/ai/, fighter data, or test files you did not create. If you must touch a doc another agent is likely editing (README.md, docs/KNOWN_ISSUES.md), keep the edits small and rebase on origin/main before the PR.

GOAL
Build the UI foundation: a screen router, a persistent Settings system, and the missing front-end screens. Placeholder styling is fine (existing fonts, flat panels); final art comes later. Presentation only: nothing you add may enter the 60 Hz simulation or MatchRoot.serialize()/load().

STEP 1 - INVESTIGATE AND REPORT BEFORE CHANGING
- Map how main.gd routes today (instances, deferred hand-offs that stop a confirm key leaking into the next screen, back paths, music switching).
- Map how MatchRoot and MatchHUD drive the pause menu (PAUSE_OPTIONS, _confirm_pause_selection, Quit to Desktop).
- List every input action and how ui_confirm/ui_back are used. Note whether gamepad P2 can drive menus.
- Run every headless suite (~/.local/bin/godot --headless --path game --script res://tests/<name>.gd) and record counts. serialization_test never quits: run it with a timeout. Report pre-existing failures separately.
Post this report, then continue.

STEP 2 - BUILD
A. ScreenRouter (game/scripts/ui/screen_router.gd) with push/pop/replace, deferred transitions, and the existing confirm-leak guard. FlowState holds solo/versus, cpu_level, last picks, last stage. Port main.gd to use it with identical behavior for the existing flow.
B. Settings autoload (game/scripts/ui/settings.gd): user://settings.cfg, [meta] version = 1, defaults for missing keys, apply on boot, save on change, reset-to-defaults that resets, applies, refreshes, then saves. Opening the screen must not save.
C. Audio buses: default_bus_layout.tres with Master, Music, SFX, Voice, UI. Route audio_manager players to them without changing current loudness at default settings.
D. Settings overlay scene with tabs Video (window mode, scale 2x-6x integer, VSync), Audio (5 sliders 0-10, mute when unfocused), Gameplay (input display placeholder toggle, Tripp commentary full/minimal/off, show combo damage), Accessibility (reduce flashing, screen shake off/low/full, high-contrast HUD, readable font, hold-to-confirm METHtality), Stream (streamer-safe music, hide Tripp layer). Store every option and apply the ones that have a target today; list the stored-but-not-yet-consumed ones in your report. No Controls tab yet.
E. New screens: ContentWarning (once per launch, confirm or 3 s), Title (PRESS START, pulses at most once per second), MainMenu (VERSUS, TRAINING greyed COMING SOON, SETTINGS, EXTRAS greyed, QUIT), QuitConfirm modal (defaults to NO). Flow: boot -> ContentWarning -> The Clip (keep current behavior for now) -> Title -> MainMenu -> VERSUS -> existing ModeSelect (1P/2P) -> existing flow. Back from ModeSelect returns to MainMenu.
F. Pause menu becomes: RESUME, SETTINGS (opens the overlay above the paused match), RESTART MATCH, BACK TO CHARACTER SELECT, MAIN MENU, QUIT TO DESKTOP (through QuitConfirm). Touch match_root.gd only in the pause handling.
G. Every screen shows a confirm/back prompt line. UI runs with the 320x180 integer-scaled viewport, pixel-snapped, no fractional positions.

RULES
- No Python. Shell or headless Godot only. At most 1 image open at a time, fewer than 5 per session.
- Determinism: no global RNG, delta, or wall-clock time anywhere that affects simulation. UI timers may count frames.
- Don't change combat numbers, meter rules, movement speeds, input mappings, or the 60 Hz sim. If you edit project.godot (autoload, bus layout), confirm [physics] common/physics_ticks_per_second=60 is still present.
- Stop and ask if a change would alter match behavior.

TESTS
- Run every headless suite before and after; report pre-existing failures separately; never weaken assertions.
- Add game/tests/ui_flow_test.gd (router push/pop, every forward and back path in the diagram, no confirm leak across a hand-off, pause -> settings -> back to pause, main menu reachable from pause) and game/tests/settings_test.gd (defaults on missing file, round-trip save/load, version fill-in, opening does not save, reset applies and saves). Add both to CI.

DOCS
Update docs/PM_BRIEF.md (flow, new files, test counts), README.md (controls and menus), docs/KNOWN_ISSUES.md, GDD.md §10.2 status notes, and test counts everywhere they appear. Add docs/UI_SCREENS.md describing the router, the screen list, and the Settings keys.

DELIVERY
Small commits, open a PR, get CI green, squash-merge, then confirm main's CI and the linux/windows export artifacts.

FINISH WITH A REPORT
1. Step 1 findings. 2. Files added and changed. 3. The final flow, screen by screen, including back paths. 4. Settings keys with defaults, and which ones are stored but not yet consumed. 5. Test counts before and after, per suite, with pre-existing failures listed separately. 6. PR number, merge commit, main CI status, artifact names. 7. Anything you were unsure about or deferred.
```

