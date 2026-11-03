# Sidewalk Showdown — Detailed Conversation Archive

**Archive type:** Recovered project-conversation archive  
**Prepared:** 2026-11-03  
**Project:** Sidewalk Showdown  
**Repository:** `/home/lch/projects/SidewalkShowdown`  
**Primary branch:** `main`  
**GitHub repository:** `violentwave/SidewalkShowdown` — private

---

## Important note about transcript fidelity

This document preserves the Sidewalk Showdown discussion as completely as the conversation context and project materials available for this archive allow.

It is **not a raw ChatGPT data export**. Some older turns in the available project history were represented only by compacted-history markers, attachments, or summaries. Where an exact message or assistant response was available, it is recorded directly or closely summarized. Where the exact wording was unavailable, the material is explicitly presented as a **recovered summary**, not as a verbatim quotation.

The archive distinguishes:
- **User decisions and constraints** — treated as project requirements unless later changed.
- **Assistant recommendations** — advice offered during the discussion, not automatically canon.
- **Implemented work** — supported by the supplied project status documents and closeout reports.
- **Planned work** — roadmap items that should not be mistaken for completed features.

The project files supplied with the November 3, 2026 request were used to refresh the latest technical and production status. Their contents are not reproduced wholesale here; this document archives the conversation and its decisions.

---

# 1. Project origin and core concept

## 1.1 Initial project-document work

The Sidewalk Showdown project began with the creation of a set of foundational design documents. The initial documents discussed and prepared included:

- `GameBible.md`
- `GDD.md`
- `CHARACTERS.md`
- `STAGES.md`
- `CAMPAIGN_STRUCTURE.md`
- `ART_DIRECTION.md`
- `AI_WORKFLOW.md`

The user wanted these files to form a durable source of truth for the game and to live alongside the project repository.

### File-delivery preference

The user gave an explicit instruction:

> when i ask you to give me files for this project, just give me a link to download it, don't paste the file contents in the chat, i want to save on tokens and theres no point in pasting it in chat if im downloading the contents of the file anyways.

This remains an important interaction requirement: when creating or updating Sidewalk Showdown project files, provide the downloadable file link and do not paste the entire file into chat.

### Initial document sequence

The documented sequence was:

1. Create `STAGES.md`, using the established game canon and research where needed.
2. Create `CAMPAIGN_STRUCTURE.md`.
3. Create `ART_DIRECTION.md`.
4. Discuss the purpose of `AI_WORKFLOW.md` before creating it.
5. Confirm that `AI_WORKFLOW.md` would be generalized enough to remain useful as the project evolved.
6. Create `AI_WORKFLOW.md` and provide it as a download.

The user approved the approach and the files were saved locally.

## 1.2 Game concept and tone

Sidewalk Showdown is a mature, raunchy-comedy 2D fighting game. Its core pitch was described as a Street Fighter-like game filtered through a deliberately rough, absurd Florida street-world sensibility, with an 8-bit/16-bit-inspired presentation.

The setting is fictional **Sidewalk Florida**. Stage names should describe recognizable locations or environments rather than use real town names. Examples discussed include:

- A bus stop
- A liquor store
- An under-bridge location
- A parking lot
- A gas station

The tone is intentionally irreverent and adult, with everyone subject to the joke. The stated comedic inspirations include *It's Always Sunny in Philadelphia* and *What We Do in the Shadows*. Despite the rough humor, the story should reach a wholesome ending.

### Story and tournament canon

- Tripp Vlogs is the antagonist and hidden final boss.
- Tripp is **not a playable roster character**.
- Tripp sets up and funds a winner-takes-all bracket contest involving the fictional Florida street characters.
- The tournament is the framework for the campaign and the eventual confrontation with Tripp.
- The term **METHtalities** was to be retained for now. Legal/parody naming could be reconsidered later rather than pre-emptively changing the concept.

### Roster discussed

The project roster discussed in the foundational character work includes:

- Peg Leg Peggy
- Racoon Randy
- Deputy Deranged
- Lt. Dan Hurricane
- Chuck Cheese Felon
- ShroomBoom Betty
- Python Paulie
- Soapless Joe
- Whiskey Richard
- Dogfood Debbie
- Burnout Bubba
- Garbage Gretchen
- Stub Stan
- Hairy Mary
- Stabatha Christie

Tripp Vlogs is the antagonist/hidden final boss and is not part of the playable roster.

The early asset directory also contained rough or exploratory references with names such as Maureen, Rex, and Rusty. The user later clarified that certain old reference files were not actual characters or relevant project material and instructed that they be removed. Those references must not be treated as canon roster additions.

## 1.3 Visual direction

The intended visual direction is:

- 2D pixel art with an 8-bit/16-bit-inspired presentation.
- Strong, bold dark outlines.
- No anti-aliasing in the pixel-art pipeline.
- Nearest-neighbor texture filtering and integer-friendly scaling.
- Gritty, sunbaked asphalt and dirty-neon atmosphere.
- Convenience-store and street-environment colors.
- Rough, humorous, expressive character silhouettes.
- Reusable Florida street/environment assets where possible.

The user had a collection of rough reference images for characters, game mechanics, levels, and UI mockups. These were organized as references, not automatically treated as final production assets.

---

# 2. Documentation and asset organization

## 2.1 Initial directory structure

The user shared an initial project tree under:

`/home/lch/projects/SidewalkShowdown/`

It included:

```text
SidewalkShowdown/
├── Assets/
│   └── Images/
│       ├── Characters/
│       ├── GameMechanics/
│       ├── Levels/
│       └── Mockups/
└── Docs/
    ├── AI_WORKFLOW.md
    ├── ART_DIRECTION.md
    ├── CAMPAIGN_STRUCTURE.md
    ├── CHARACTERS.md
    ├── GameBible.md
    ├── GDD.md
    └── STAGES.md
```

The original asset set contained character concepts, game-mechanic/UI references, stage concepts, and mockups. The user said the images were rough design aids.

## 2.2 Git initialization

The user initialized Git in the repository:

```bash
cd /home/lch/projects/SidewalkShowdown
git init
```

Git initialized an empty repository on `main`.

The user then requested simple OpenCode prompts to complete repository setup. An important requirement was that the GitHub repository could be online but **must remain 100% private**.

The project subsequently adopted Git LFS for binary image assets. The project audit later confirmed that all 54 PNG files were tracked by LFS and that the expected binary content was represented correctly.

## 2.3 Documentation organization

The documentation was later reorganized into a more structured layout with Core, Production, Technical, and related documentation areas. The current project documents reference locations such as:

```text
Docs/
├── Core/
├── Production/
├── Technical/
├── Templates/
└── ...
```

The exact contents of the current Docs tree should be taken from the live repository, because the structure evolved after the first directory-tree snapshot.

The project uses Markdown as its durable source of truth. Obsidian is a navigation and knowledge-management interface over those Markdown files, not a replacement for Git or the canonical documents.

---

# 3. GitHub, Git LFS, and repository safety

## 3.1 Private repository requirement

The user explicitly approved publishing the repository to GitHub only if it remained private.

The project status document supplied on November 3 identifies the remote as:

`violentwave/SidewalkShowdown` — **PRIVATE**

Remote pushes and publishing actions remain distinct from local commits. The agent should not assume that permission to work locally automatically authorizes every remote operation.

## 3.2 Git LFS

The setup audit confirmed:

- Git LFS was installed and active.
- 54 PNG assets were tracked.
- The expected LFS patterns were active.
- No project PNG assets were found outside the expected LFS tracking arrangement.

## 3.3 Git workflow expectations

The established workflow is:

- Use Git frequently enough to preserve recoverable project states.
- Check `git status` before and after substantial work.
- Run relevant validation before proposing a commit.
- Do not commit unless the task or user instruction authorizes committing.
- Do not push, publish, or create remote changes without explicit authorization.
- Keep the GitHub repository private.
- Treat the repository as the project boundary for normal implementation work.

The user repeatedly asked for issues to be fixed before moving on to the next batch of OpenCode prompts. This means the workflow should be sequential: inspect results, resolve blockers, validate, and only then continue.

---

# 4. Technology stack and local development environment

## 4.1 Godot

The user installed Godot through Bazaar and verified the installed version with:

```bash
flatpak list | grep -i godot
flatpak run org.godotengine.Godot --version
```

The verified engine was:

- Godot Engine 4.6.3 stable
- Flatpak app ID: `org.godotengine.Godot`

The supplied current-state document continues to identify Godot 4.6.3 as the project engine.

## 4.2 Art and documentation tools

The user reported that the following tools were already installed through Bazaar:

- Pixelorama
- Krita
- GIMP
- Obsidian

The user wanted OpenCode to be able to access and use these tools where practical.

The local tool inventory later recorded these detected invocations:

| Tool | Invocation |
|---|---|
| Godot 4.6.3 | `flatpak run org.godotengine.Godot` |
| Pixelorama 1.1.10 | `flatpak run com.orama_interactive.Pixelorama` |
| Krita 5.3.1 | `flatpak run org.kde.krita` |
| GIMP 3.2.4 | `flatpak run org.gimp.GIMP` |
| Obsidian 1.12.7 | `flatpak run md.obsidian.Obsidian` |

Pixelorama and Obsidian were treated as primarily GUI-driven tools. Krita and GIMP were also available through their Flatpak applications.

## 4.3 Obsidian

The project uses Markdown files in the repository as the source of truth. The intended Obsidian vault root was established as:

`/home/lch/projects/SidewalkShowdown/Docs`

The intent was to make the documentation easy to browse and link without creating a second, divergent knowledge base.

Obsidian workspace/cache files should be ignored where appropriate, but Markdown documentation must remain tracked by Git. The project should avoid unnecessary plugins, themes, or complex Obsidian configuration unless a clear need arises.

## 4.4 Antigravity IDE

The user wanted to use Google's Antigravity IDE alongside OpenCode.

The user supplied a list of installed Antigravity extensions, including:

- Godot Tools
- Python and Python debugging tools
- GitLens and Git Graph
- GitHub Pull Requests
- Markdown All in One and Markdown Preview
- markdownlint
- Mermaid
- Draw.io Integration
- Excalidraw
- ShellCheck and shell-format
- Semgrep
- YAML
- Docker and Container Tools
- Other language and editing extensions

Initially, many extensions reported incompatibility with the installed Code-compatible editor version (`2.0.6` versus extensions requiring `^1.101.0`). The user later launched Antigravity through a Fedora Distrobox wrapper, after which the extension compatibility errors disappeared.

## 4.5 Antigravity wrapper

The user created:

`~/.local/bin/antigravity`

with a wrapper that enters the `antigravity-fedora` Distrobox and launches:

`/usr/share/antigravity/antigravity`

The wrapper was executable and successfully launched Antigravity.

The user explicitly tested the `--goto` argument. OpenCode reported successful command execution, and the user visually confirmed that Antigravity opened `/tmp/antigravity_goto_test.txt` and positioned the cursor near line 17, column 20.

The verified Godot external-editor argument format is:

```text
--goto {file}:{line}:{col}
```

The user requested that the wrapper and flag be visually verified before updating project documentation. That verification succeeded, and the corresponding environment documentation was committed.

Warnings observed during launch included D-Bus, PCI/driver, GTK module, and VAAPI messages. They did not prevent the editor from opening or the tested `--goto` behavior from working.

---

# 5. OpenCode autonomy and permission model

## 5.1 Goal

The user wanted OpenCode to function as autonomously as practical within the Sidewalk Showdown project, rather than requiring approval for every ordinary repository operation.

The user emphasized that the operating system was immutable/atomic and that OpenCode must not interfere with `ostree`.

## 5.2 Permission changes requested by the user

The user explicitly revised the initial permission model as follows:

| Category | User's requested policy |
|---|---|
| Use `sudo` | Yes, with permission/authorization |
| Access unrelated home files | Yes for access; ask permission before changing anything |
| Read secrets/API keys/SSH keys | Yes, only for that session |
| Install packages | Yes, with permission |
| Immutable OS / `ostree` | Do not touch |
| Repository work | Broad read/write and normal development operations within project scope |

The project autonomy documentation was updated to reflect these choices.

## 5.3 Agent operating boundaries

The resulting operating model included:

- Read and write project files.
- Run project-scoped shell commands and development tools.
- Run Git, Git LFS, Flatpak, validation scripts, linters, and audits.
- Organize assets within the repository's approved asset/game directories.
- Use temporary files under `/tmp` when needed and clean them up.
- Read outside-repository files when relevant, but ask before modifying unrelated files.
- Access secrets only when explicitly authorized for the current session; do not retain or expose them.
- Ask before package installation.
- Ask before privileged operations.
- Do not alter the immutable host OS or use `ostree` operations.
- Do not push, publish, or perform other remote actions without explicit authorization.
- Do not use offensive security tooling or perform unrelated probing.

The exact current rules should be read from `AGENTS.md` and `Docs/Technical/OPENCODE_AUTONOMY.md` in the live repository.

## 5.4 Autonomy documentation

The user reported successful creation and commit of:

- `AGENTS.md`
- `Docs/Technical/LOCAL_TOOLS.md`
- `Docs/Technical/OPENCODE_AUTONOMY.md`
- Updated `.gitignore` entries for Obsidian workspace/cache patterns

The user committed the autonomy revision with:

```bash
git add -A
git commit -m "Revise OpenCode autonomy permissions"
```

The reported commit was:

`d808746`

The user also committed the Godot and Antigravity development environment documentation in an earlier commit:

`ba98efe`

That commit created `Docs/Technical/TECH_STACK.md` and added/updated editor/lint configuration files.

---

# 6. Godot project initialization

## 6.1 Initial audit findings

The Phase 0 readiness audit reported:

- The repository organization and expected setup files were in place.
- All 54 PNG assets were tracked by Git LFS.
- The Godot project had not yet been initialized in the correct `Game/` directory.
- `Game/project.godot` and `Game/Scenes/Main/Main.tscn` were initially missing.
- No GitHub remote was configured at the time of that earlier audit.
- `.vscode/` was ignored, so local IDE settings would not automatically be shared.

The audit identified Godot initialization as the next blocking setup step.

## 6.2 Correct project root

The user initialized the Godot project under:

`/home/lch/projects/SidewalkShowdown/Game/`

This is critical:

- The repository root is **not** the Godot project root.
- `Game/` is the Godot project root.
- `res://` resolves relative to `Game/`.
- `Game/project.godot` must remain in that directory.
- The main scene is `res://Scenes/Main/Main.tscn`.

The project uses a base resolution of 320×180 and nearest-neighbor/pixel-focused texture settings.

## 6.3 Main-scene troubleshooting

During setup, the user encountered:

`Error: Can't run project: no main scene defined in this project`

OpenCode later verified that:

- `Game/project.godot` existed.
- `config/main_scene` pointed to `res://Scenes/Main/Main.tscn`.
- `Game/Scenes/Main/Main.tscn` existed and had the expected root.
- Godot editor-mode validation loaded the project successfully.

The confusing runtime/headless message was attributed to the way the project was being launched, not to a missing main-scene setting. Editor-mode validation was accepted for headless project-load checks.

## 6.4 Accidental root-level initialization cleanup

The user encountered an initialization attempt that created root-level `project.godot` and `icon.svg` and modified `.editorconfig`.

The cleanup sequence removed the incorrect root-level Godot files and `.godot` cache and restored `.editorconfig`. OpenCode was then instructed to recreate the project setup correctly under `Game/`.

The eventual audit confirmed:

- No root-level `project.godot`.
- No root-level `icon.svg`.
- No root-level `.godot`.
- `Game/project.godot` exists.
- `res://Scenes/Main/Main.tscn` is configured as the main scene.

---

# 7. Phase 0 — project setup and source of truth

The project roadmap supplied on November 3 marks Phase 0 as **closed**.

Its goal was to establish a clean repository, documented canon, and production infrastructure.

Completed setup items include:

- Docs reorganized into Core and supporting subdirectories.
- Images reorganized into a References structure.
- `.gitignore`, `.gitattributes`, `LICENSE`, `README`, and `CHANGELOG` created.
- Git LFS activated for the 54 PNG assets.
- Godot 4 project initialized in `Game/`.
- Production tracking documents created, including roadmap, task tracker, decisions, asset inventory, and templates.
- Agent autonomy rules documented.
- Technical tool-stack documents created.
- GitHub remote created and marked private.
- Phase 0 closeout and Phase 1 greybox plan created.

The Phase 0 exit condition was achieved: the project opens in Godot, documentation and asset conventions are established, and the repository is ready for gameplay prototyping.

---

# 8. Phase 1 — greybox combat prototype

## 8.1 Goal

Phase 1 was designed to prove the basic fighting-game foundation before investing in final art.

The user proceeded through a sequence of small implementation batches using OpenCode prompts. The user repeatedly requested that each batch report its results and that any blocking problems be fixed before the next batch was provided.

## 8.2 Implemented systems

The Phase 1 closeout report and current-state documentation identify these systems as complete:

- Main scene and match root.
- Greybox stage with floor, bounds, and spawn points.
- Two shared placeholder fighters.
- Movement.
- Jumping.
- Crouching.
- Facing direction.
- Debug hurtbox, hitbox, and pushbox overlays.
- Light and heavy attacks.
- Startup, active, and recovery timing.
- Hit detection.
- Prevention of self-hits.
- Prevention of repeated hits from the same swing.
- Directional blocking.
- Crouch blocking.
- Hitstun.
- Blockstun.
- Hitstop.
- Health bars and health numbers.
- Round timer.
- KO and round-over handling.
- Round reset.
- Best-of-three match flow.
- Data-driven universal light/heavy move definitions.
- Debug/training controls.

## 8.3 Move data

The project introduced:

`Game/Data/Moves/basic_attacks.json`

The data-driven move definitions include attack timing and other move properties. During the Phase 1 work, the move hitbox width and height fields were also wired into runtime behavior rather than left as informational-only metadata.

The Phase 1 move system remained intentionally limited to shared universal light/heavy attacks. It was not yet a complete per-character move system.

## 8.4 Debug/training controls

The Phase 1 prototype included these debug controls:

| Key | Purpose |
|---|---|
| `R` | Reset round |
| `F1` | Toggle debug collision boxes |
| `F2` | Refill health |
| `F3` | Toggle infinite timer |
| `F5` | Apply test damage to P1 |
| `F6` | Apply test damage to P2 |

The exact current keymap should be confirmed from `Game/project.godot` and the live scripts if it changes.

## 8.5 Phase 1 closeout

The Phase 1J audit returned **PASS** with no blocking issues.

It confirmed that the greybox prototype covered movement, jump, crouch, facing, collision overlays, light/heavy attacks, hit detection, health/HUD, hitstun, blocking/blockstun, KO, round/match flow, hitstop, data-driven moves, and debug/training controls.

The closeout documentation included:

- `Docs/Production/PHASE1_CLOSEOUT.md`
- `Docs/Production/CURRENT_STATE.md`
- `Docs/Production/PHASE2_VERTICAL_SLICE_PLAN.md`

No gameplay files were modified during the Phase 1J documentation closeout.

### Phase 1 limitations intentionally retained

At closeout, the project did not yet include:

- Final character art.
- Final stage art.
- Final UI/HUD skin.
- Audio or final VFX.
- Menus.
- Campaign implementation.
- AI opponent.
- Online play or rollback networking.
- Specials.
- Throws.
- Combos.
- Supers.
- METHtalities.
- Automated gameplay test suite.

These were deferred rather than treated as Phase 1 failures.

---

# 9. Fighting-game and Godot architecture research

The user supplied additional research tips about building a 2D fighting game and asked whether the project was aligned with them.

The assistant compared the research with the existing prototype and identified the following areas as aligned:

| Topic | Project direction/status |
|---|---|
| Finite State Machine | Fighter state logic already exists |
| `CharacterBody2D` | Used for fighter movement/collision foundation |
| `_physics_process()` | Used for movement and combat timing |
| `Area2D` hitboxes/hurtboxes | Used in the current collision model |
| Physics layers/masks | Used to distinguish collision roles |
| Startup / active / recovery | Implemented for attacks |
| Hitstop | Implemented |
| Git from the beginning | Established |
| Pixel-art scaling | Configured early |
| Debug tools | Implemented |

## 9.1 Decisions and recommendations

### Resolution

The project intentionally uses 320×180 internal resolution rather than designing around 720p. The intended integer upscale examples are:

- 1280×720: 4×
- 1920×1080: 6×

This matches the pixel-art direction.

### Hitstop

The project uses per-fighter hitstop timers. The recommendation was to keep that approach for normal hitstop rather than use `Engine.time_scale`, because global time scaling can interfere with timers, UI, and unrelated state transitions.

### State-machine architecture

The current fighter state logic is acceptable for the small prototype. A modular collection of separate state classes was identified as a possible future refactor, but not something to introduce prematurely.

The guidance was to avoid rewriting `FighterBase` without a concrete need.

### Collision architecture

- Continue using `Area2D` for the current hitbox/hurtbox model.
- Do not introduce custom AABB collision prematurely.
- Custom AABB collision is a much-later option only if the current collision model proves insufficient.

### Facing and scaling

An immediate architecture rule was identified:

- Do not use negative scaling on physics/collision nodes to turn fighters.
- Use `facing_dir`, hitbox offsets, and visual flip logic instead.

## 9.2 Roadmap additions from the research

The user explicitly asked to incorporate these additions into the roadmap:

| Item | Planned timing | Reason |
|---|---|---|
| Input buffering | Phase 2 or early Phase 3 | Needed before specials/combos feel good |
| AnimationPlayer sync | Phase 2 | Needed when placeholder animations begin |
| Variable jump height | Optional Phase 2 polish | Improves movement feel |
| Static typing pass | Soon | Helps Godot and AI agents catch errors |
| Camera shake/zoom hooks | Phase 2 | Impact feedback, kept subtle |
| God mode/debug invulnerability | Optional debug extension | Makes repeated playtesting easier |
| Avoid negative scaling | Immediate architecture rule | Use visual flipping and facing offsets |
| Custom AABB collision | Much later, if needed | Current Area2D approach is adequate |

These were then reflected in the Phase 2 plan and later implementation status. Input buffering, camera feedback, static typing, and variable jump height were subsequently completed.

---

# 10. Documentation closeout and Obsidian work

## 10.1 Documentation update request

After Phase 1 completion, the user requested a comprehensive documentation pass before moving further into implementation.

The requested goals were:

- Finalize Phase 1 documentation.
- Make Phase 2 fully planned.
- Add the Godot fighting-game architecture guidance.
- Add all roadmap recommendations from the research.
- Keep documents generalized enough to remain useful as the project changes.
- Ensure Obsidian is up to date afterward.

## 10.2 Planned documentation work

The proposed documentation batch included:

- `Docs/Technical/GODOT_FIGHTING_GAME_ARCHITECTURE.md`
- Updates to `ROADMAP.md`
- Updates to `TASKS.md`
- Updates to `CURRENT_STATE.md`
- Updates to `PHASE1_CLOSEOUT.md`
- Updates to `PHASE2_VERTICAL_SLICE_PLAN.md`
- Updates to `TECH_STACK.md`
- Updates to `MOVE_DATA_V0.md`
- A short pointer in `AGENTS.md`
- README/index updates as appropriate

The architecture guide was intended to describe:

- The current Phase 1 scene/script architecture.
- Match and fighter state machines.
- Fighter movement and physics processing.
- Hitbox, hurtbox, and pushbox roles.
- Physics layers and masks.
- Move-data loading.
- Hitstun, blockstun, hitstop, KO, and round flow.
- Debug controls.
- Immediate architecture rules.
- Future Phase 2 architecture goals.
- AI-agent instructions to avoid unnecessary rewrites.

## 10.3 Obsidian navigation

The proposed Obsidian work used `Docs/` as the vault root and called for:

- `Docs/START_HERE.md`
- `Docs/DOC_INDEX.md`
- Optional `Docs/Production/PHASE_INDEX.md`

The index was intended to link to the core canon, production planning, technical documents, templates, expansion folders, and current phase.

The user prefers ordinary Markdown links that work both in GitHub and Obsidian. The project should not duplicate full documents just to make Obsidian navigation easier.

---

# 11. Phase 2 — vertical slice

## 11.1 Overall goal

Phase 2 is the vertical slice: one representative sample of the real game, built on the Phase 1 combat foundation.

The original target pairing was:

- Burnout Bubba
- Peg Leg Peggy

The initial stage target was Parking Lot or Bus Stop. The project later selected **The Parking Lot** for the current stage blockout.

The phase is intentionally not a full game-production pass. It focuses on making one match look, feel, and behave more like Sidewalk Showdown.

## 11.2 Original Phase 2 plan

The initial plan included:

- Character data stubs.
- Placeholder identity and palettes.
- One stage blockout/style pass.
- Animation synchronization.
- Input buffering.
- Camera shake/zoom hooks.
- Static typing.
- Optional variable jump height.
- Optional debug god mode/invulnerability.
- Vertical-slice playtest and closeout.

## 11.3 Current Phase 2 status from supplied project documents

The latest `ROADMAP.md`, `TASKS.md`, `CURRENT_STATE.md`, and Phase 2 closeout documents supplied on November 3 identify the following status:

| Subphase | Focus | Latest recorded status |
|---|---|---|
| 2A | Character data stubs and test matchup | Complete |
| 2B | Placeholder identity/palettes | Complete |
| 2C | Parking Lot stage blockout/style pass | Complete |
| 2D | Placeholder animation-state synchronization | Complete |
| 2E | Input buffering v0 | Complete |
| 2F | Camera shake/zoom hooks | Complete |
| 2G | Static typing pass | Complete |
| 2H | Variable jump height | Complete |
| 2I | Debug god mode/invulnerability | Planned/optional |
| 2J | Vertical-slice playtest and closeout | Planned |

The roadmap labels Phase 2H complete and identifies Phase 2I or Phase 2J as the next action. The task tracker identifies Phase 2I as the optional active next subphase, with Phase 2J as the alternative if the optional task is skipped.

## 11.4 Phase 2A — character data and test matchup

Completed work recorded in the current-state document:

- Character roster/index data for Burnout Bubba and Peg Leg Peggy.
- Individual character data stubs.
- Movement, health, and move-list fields.
- Debug matchup config `test_matchup.json`.
- Character data loading in `FighterBase.gd`.
- Matchup loading in `MatchRoot.gd`.
- Fallbacks for missing/unknown data.
- JSON validation and Godot editor validation.
- Commits `60885c8` and `f874387` were recorded as pushed to `origin/main` and CI-verified.

## 11.5 Phase 2B — placeholder identity and palettes

Completed work:

- Bubba and Peggy have distinct placeholder palettes.
- Visual-only silhouette hints were added under `VisualRoot`.
- HUD name labels were added.
- `MatchHUD.gd` exposes `set_fighter_names()`.
- `MatchRoot.gd` sends fighter display names to the HUD during round setup.
- A reality audit confirmed that the identity layer did not change collision, hurtboxes, hitboxes, pushboxes, timing, damage, or move behavior.

No final sprites or final HUD skin were included.

## 11.6 Phase 2C — Parking Lot stage blockout

The selected stage is **The Parking Lot**.

Completed work recorded in `CURRENT_STATE.md`:

- Created `Game/Scenes/Stages/ParkingLotStage.tscn`.
- Reused `GreyboxStage.gd` to preserve the expected stage API.
- Preserved the floor, wall, and spawn geometry.
- Switched `MatchRoot.tscn` to use `ParkingLotStage.tscn`.
- Preserved the test matchup and fighter properties.
- Fixed a latent Godot `.tscn` resource forward-reference ordering issue across runtime scenes.
- Completed a source-level readability audit.

Known limitation: the stage remains a placeholder using simple visual nodes. It does not yet have final art, parallax, gameplay hazards, or stage-specific combat behavior. A screenshot was not captured because of the headless/Flatpak viewport-capture limitations described in the status document.

## 11.7 Phase 2D — animation synchronization

The initial plan discussed AnimationPlayer synchronization and placeholder animation stubs.

The actual implementation recorded in the task tracker is more specific:

- An `AnimPlayer` node was added to `FighterBase` as a reserved node for future sprite animation.
- Placeholder visual state feedback was implemented with Tween-based modulate/lerp behavior.
- States covered include idle, walk, jump, crouch, block, light attack, heavy attack, hitstun, and blockstun.
- The current implementation is **Tween-based**, not a full AnimationPlayer animation-state-machine implementation.
- An animation state machine or transition table remains a later candidate.

Do not describe the current implementation as a completed full AnimationPlayer state machine.

## 11.8 Phase 2E — input buffering

Completed implementation recorded in the current-state and task documents:

- A per-fighter `InputBuffer.gd` ring buffer.
- Approximately four-frame window (`WINDOW_SEC = 0.067` seconds).
- Frame-rate-independent timing using `delta`.
- Buffered light/heavy attacks.
- Buffer execution is state-gated to eligible states such as idle, walking, crouching, and jumping.
- Existing direct-input behavior remains intact.

Not included:

- Jump buffering.
- Special-move buffering.
- Throws/grabs.
- Combos/cancels.
- Supers.
- Dash/backdash.
- AI.
- Campaign, menus, online/rollback, or METHtalities.

## 11.9 Phase 2F — camera feedback

Completed camera feedback is cosmetic and subtle.

Recorded hooks include:

- Light hit: approximately 0.05 seconds and 1-pixel shake.
- Heavy hit: approximately 0.08 seconds and 3-pixel shake.
- Block impact: approximately 0.04 seconds and 1-pixel shake.
- KO/round end: approximately 0.14 seconds and 4-pixel shake, with a small zoom pulse.

A `CAMERA_FEEDBACK_ENABLED` kill switch and configurable intensity/decay values were added.

The implementation does not use `Engine.time_scale` and does not change hitstop or core combat behavior.

## 11.10 Phase 2G — static typing

The Phase 2G closeout report records a PASS.

Changes were annotation-focused:

- `MatchHUD.gd`: eight `-> void` annotations.
- `MatchRoot.gd`: sixteen `-> void` annotations.
- `FighterBase.gd`: typed `hit_targets` as `Array[Fighter]` and added 31 `-> void` annotations.
- `InputBuffer.gd` and `GreyboxStage.gd` were already typed sufficiently and did not require changes.

Dynamic JSON dictionaries remained generic where appropriate and guarded parsing was preserved.

No gameplay behavior, timing, collision, input, camera, or round-flow behavior was intentionally changed.

The closeout records commits:

- `0603101` — Static type MatchHUD
- `c0b1166` — Static type MatchRoot
- `718f754` — Static type FighterBase

The closeout document notes a pre-existing, non-blocking phase-gate warning: the script expects a particular Phase 1 closeout commit to be the latest commit, so it warns after later commits. The Phase 2G validation otherwise passed.

## 11.11 Phase 2H — variable jump height

The Phase 2H closeout report records a PASS.

Implementation:

- `JUMP_CUT_MULTIPLIER = 0.5`.
- `_jump_cut_used` ensures only one cut per jump.
- If the player releases the jump key while airborne and still rising, upward velocity is multiplied by 0.5.
- The jump-cut flag resets on a new jump and on full reset.
- P1 and P2 are both supported through the existing input-prefix mechanism.

The closeout report describes full-height jumps around 67 pixels and short hops around 30–40% of full height.

The feature does not intentionally change attack timing, hitboxes, blocking, health, round flow, move data, or stage behavior.

Validation recorded:

- `git diff --check` — PASS.
- JSON validation — PASS.
- Godot editor load — PASS.
- Headless match boot — PASS.
- Doc-drift script — 25/25 PASS.
- Phase gate — 22/22 PASS, with one pre-existing warning.

The closeout document records the implementation commit as pending/local-only at the time it was written. The current repository should be checked before assuming that the commit was pushed.

## 11.12 Phase 2I — optional debug god mode

Latest recorded status: planned, not complete.

Planned tasks:

- Add an invulnerability toggle for playtesting.
- Wire it to a debug keybind or HUD toggle.

This phase is optional. The project can skip it and proceed to the Phase 2J playtest/closeout if the team decides it is not worth the added scope.

## 11.13 Phase 2J — vertical-slice playtest and closeout

Latest recorded status: planned, not complete.

Planned tasks:

- Create a repeatable playtest checklist.
- Run the checklist.
- Fix blocking issues.
- Write Phase 2 closeout documentation.
- Update `ROADMAP.md`, `CURRENT_STATE.md`, and `TASKS.md`.

Phase 2 should not be declared closed until the playtest and closeout work is completed or explicitly scoped out.

---

# 12. Phase 3 and later planning

The supplied roadmap identifies Phase 3–11 as planned future work. The current task tracker identifies Phase 3 as the next major block after Phase 2 vertical-slice closeout.

## 12.1 Phase 3 — core systems buildout

Planned topics include:

- Special moves.
- Data-driven special-move frame data.
- Basic AI opponent behavior.
- Throws/grabs, including tech windows and whiff recovery.
- Per-fighter HUD portrait/name display.
- Placeholder audio hooks.
- Basic title and character-select screen.
- Round-start, KO, and victory animations.

The roadmap also describes broader data-driven fighter systems, stage loading, and match management.

## 12.2 Later phases

The supplied roadmap lists these broad phases:

| Phase | Focus |
|---|---|
| 3 | Core systems buildout |
| 4 | Art direction lock |
| 5 | Playable roster expansion |
| 6 | Stage expansion |
| 7 | Campaign implementation |
| 8 | Audio, UI, and juice pass |
| 9 | Testing, balance, optimization |
| 10 | Release preparation |
| 11 | Post-launch support |

The GDD is identified by the roadmap as the source for fuller phase detail.

## 12.3 Deferred/future systems

The task tracker includes future/backlog candidates such as:

- Hype Meter prototype.
- Input-buffer visualization.
- Camera feedback controls.
- Hitbox/hurtbox angle or priority system.
- Combo system with cancel windows, juggle state, and combo counter.

Other intentionally deferred systems include specials, throws, supers, METHtalities, more advanced AI, online play, and custom collision approaches.

---

# 13. Current project facts from the November 3, 2026 file set

The user supplied updated project documents for this archive. The most recent supplied status materials identify the following:

## 13.1 Repository and engine

| Field | Latest supplied value |
|---|---|
| Repository | `/home/lch/projects/SidewalkShowdown` |
| Branch | `main` |
| GitHub remote | `violentwave/SidewalkShowdown` — private |
| Engine | Godot 4.6.3 stable |
| Godot Flatpak ID | `org.godotengine.Godot` |
| Godot project root | `Game/` |
| Main scene | `res://Scenes/Main/Main.tscn` |
| Base viewport | 320×180 |
| Texture filtering | Nearest/pixel-focused |

## 13.2 Latest supplied roadmap status

- Phase 0: closed.
- Phase 1: closed.
- Phase 2: Phase 2H complete.
- Phase 2I: optional debug god mode/invulnerability, planned.
- Phase 2J: vertical-slice playtest and closeout, planned.
- Phase 3: next major block after Phase 2 closeout.

## 13.3 Latest supplied validation

The Phase 2G and 2H closeout reports record successful Godot editor validation and headless match boot. The Phase 2H report records doc-drift validation at 25/25 and phase-gate validation at 22/22 with one pre-existing warning.

The exact live Git state, latest commit, and push status should always be checked in the repository rather than inferred from an older closeout document.

## 13.4 Documentation date drift to watch

The `CURRENT_STATE.md` file supplied for this archive is dated 2026-05-31 even though the archive is being prepared on 2026-11-03. Its content includes Phase 2G and 2H completion, so it is more current than its date header suggests, but the date field itself should be reviewed during the next documentation closeout.

The Phase 2G and 2H closeout documents also contain historical commit/push statements from the time they were written. Verify the live Git history before relying on those statements.

---

# 14. Interaction and workflow preferences established by the user

These preferences should continue to guide future Sidewalk Showdown work.

## 14.1 Project-file delivery

- When the user asks for a project file, create the file and provide a download link.
- Do not paste the entire file contents into chat.
- Keep the chat response concise when the downloadable artifact is the requested deliverable.

## 14.2 OpenCode prompt workflow

- Provide simple, actionable prompts that can be pasted into OpenCode.
- Break larger work into sequential batches where useful.
- Make each prompt project-aware and scoped.
- Require OpenCode to inspect current files before editing.
- Require validation after implementation.
- Ask OpenCode to report files changed, checks run, issues, known limitations, and Git status.
- Fix blockers before moving on to the next prompt batch.
- Avoid unnecessary changes to canon or unrelated systems.

## 14.3 Git workflow

- Keep the GitHub repository private.
- Check status and review diffs.
- Do not assume a commit or push occurred unless the command/result confirms it.
- Do not perform remote operations without authorization.

## 14.4 Operating-system safety

- The user's Linux installation is immutable/atomic.
- Do not touch `ostree` or perform host OS mutations.
- Ask before package installation or privileged operations.
- Ask before modifying unrelated home-directory files.
- Secrets may only be accessed for the explicitly authorized session and must not be retained or exposed.

## 14.5 Development philosophy

- Build the game in small, validated steps.
- Preserve the working combat foundation.
- Prefer data-driven expansion where appropriate.
- Avoid premature architecture rewrites.
- Keep placeholder/greybox work distinct from final art.
- Treat design documents and implementation as separate sources that must be reconciled, not assumed to match automatically.
- Do not continue to the next batch while blocking issues remain.

---

# 15. Important architecture rules to preserve

These rules were discussed or recorded in the architecture guidance and should remain in force unless deliberately revised.

1. `Game/` is the Godot project root. Never initialize a second Godot project at the repository root.
2. The main scene is `res://Scenes/Main/Main.tscn`.
3. Do not use negative scaling on physics or collision nodes to change fighter facing.
4. Use `facing_dir`, collision/hitbox offsets, and visual flip logic.
5. Continue using `Area2D` for the current hitbox/hurtbox approach unless a demonstrated limitation requires a change.
6. Custom AABB collision is future-only.
7. Keep normal hitstop on the current per-fighter timer approach; do not introduce global `Engine.time_scale` hitstop without explicit design approval.
8. Keep combat timing in the physics-driven systems.
9. Avoid rewriting `FighterBase` or the state-machine architecture without a concrete reason and explicit approval.
10. Prefer data-driven move and character expansion over hardcoding character-specific behavior throughout shared scripts.
11. Keep final art and final UI out of greybox systems until intentionally promoted.
12. Validate Godot after script/scene changes.
13. Validate JSON data after data-file changes.
14. Revert harmless Godot editor reformat noise in `Game/project.godot` if no semantic change was intended.
15. Keep debug controls useful for development but distinguish them from production-facing game systems.

---

# 16. Current next steps

Based on the latest supplied roadmap and task tracker:

1. Check the live repository status and commit history.
2. Verify whether Phase 2H's implementation and closeout documentation have been committed and pushed.
3. Decide whether optional Phase 2I debug god mode is worth implementing.
4. If Phase 2I is skipped, proceed to Phase 2J.
5. Build a repeatable Phase 2 playtest checklist.
6. Run the full vertical-slice playtest and fix blockers.
7. Complete Phase 2 closeout documentation.
8. Update `ROADMAP.md`, `TASKS.md`, and `CURRENT_STATE.md`, including their dates and commit/push state.
9. Only then begin Phase 3 planning/implementation.

---

# 17. Source files consulted for this archive

The following files were available in the November 3, 2026 conversation context and were used to verify the current project state:

- `GameBible.md`
- `GDD.md`
- `CHARACTERS.md`
- `STAGES.md`
- `CAMPAIGN_STRUCTURE.md`
- `ART_DIRECTION.md`
- `AI_WORKFLOW.md`
- `CURRENT_STATE.md`
- `ROADMAP.md`
- `TASKS.md`
- `PHASE1_CLOSEOUT.md`
- `PHASE2G_STATIC_TYPING_CLOSEOUT.md`
- `PHASE2H_VARIABLE_JUMP_HEIGHT_CLOSEOUT.md`
- `SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md`
- `sidewalk_showdown_non_defining_asset_prompts.json`
- `sidewalk_showdown_non_defining_asset_prompts.csv`

These project documents are supporting sources for the archive. The live repository remains authoritative if any status statement here conflicts with later commits or updated documentation.

---

# 18. Archive maintenance

Update this archive when a major milestone changes the project's history or current state. Do not use it as a substitute for the living documents:

- `Docs/Production/CURRENT_STATE.md` — current implementation snapshot.
- `Docs/Production/ROADMAP.md` — phase-level plan.
- `Docs/Production/TASKS.md` — actionable task tracking.
- `Docs/Production/DECISIONS.md` — durable project decisions.
- `Docs/Technical/GODOT_FIGHTING_GAME_ARCHITECTURE.md` — technical architecture rules.
- `AGENTS.md` — repository-wide agent operating instructions.

**End of recovered conversation archive.**
