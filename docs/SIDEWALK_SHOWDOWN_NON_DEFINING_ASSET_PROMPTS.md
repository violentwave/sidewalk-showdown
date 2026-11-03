# Sidewalk Showdown — Non-Defining Asset Prompt Pack

**File:** `SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md`  
**Version:** v0.1  
**Status:** Production prompt pack / proposal  
**Date:** 2026-05-31  
**Purpose:** Generate supporting assets and sprites while holding off on defining assets like final playable characters, final level backgrounds, final METHtalities, and final campaign scenes.

## 0. Scope

This pack focuses on **non-defining** asset generation:

- reusable props
- floor decals
- fake sponsor/signage concepts
- UI and broadcast overlay pieces
- VFX sprites and overlays
- generic background extras
- stage-specific minor dressing
- production helper icons

It intentionally avoids:

- final playable character sprites
- final character portraits
- full stage/level backgrounds
- final Tripp boss art
- final METHtality cinematics
- real towns, real brands, real businesses, real logos, real public figures, or copyrighted characters

## 1. Naming and Folder Rule

All asset file names in this pack use **lowercase snake_case** and `.png` output names. This matches the current art-direction naming pattern.

Recommended workflow:

1. Generate the asset with the listed filename.
2. Save the raw AI output under `art/source/` or an experimental/source folder.
3. Clean up / pixel-correct manually.
4. Export runtime-ready versions under `art/exports/` or `game/assets/` only after review.

## 2. Global Style Guardrail

Use this style direction for every prompt in the pack:

```text
Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art
```

## 3. Global Negative Prompt

Use this negative prompt for every image generation request unless your tool does not support negative prompts:

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 4. Suggested Batch Order

- **Batch 1:** reusable props, floor decals, and VFX. These are safest and immediately useful during greybox-to-vertical-slice work.
- **Batch 2:** UI/broadcast overlays and fake sponsor pieces. These support the corrupted arcade livestream identity.
- **Batch 3:** generic background extras. Keep them non-roster and low-detail.
- **Batch 4:** stage-specific minor dressing. Use only as pieces, not full-stage lock-ins.
- **Batch 5:** production helper icons and tracking stickers.

## 5. Prompt Index

- `reusable_prop`: 58 prompts
- `floor_decal`: 35 prompts
- `fake_signage_sponsor`: 41 prompts
- `ui_broadcast`: 41 prompts
- `vfx_particle`: 35 prompts
- `background_extra`: 35 prompts
- `stage_specific_minor_dressing`: 60 prompts
- `production_helper_icon`: 10 prompts

**Total prompt count:** 315

## 6. Start-Here Priority A List

- `prop_folding_chair_sunburned.png` — reusable_prop
- `prop_folding_chair_collapsing.png` — reusable_prop
- `prop_sacred_milk_crate_blue.png` — reusable_prop
- `prop_milk_crate_cracked_orange.png` — reusable_prop
- `prop_cooler_mystery_red.png` — reusable_prop
- `prop_cooler_do_not_open.png` — reusable_prop
- `prop_traffic_cone_sad.png` — reusable_prop
- `prop_traffic_cone_crushed.png` — reusable_prop
- `prop_busted_shopping_cart.png` — reusable_prop
- `prop_shopping_cart_wheel_loose.png` — reusable_prop
- `prop_busted_scooter_tire.png` — reusable_prop
- `prop_scooter_handlebar_bent.png` — reusable_prop
- `prop_oil_stained_toolbox.png` — reusable_prop
- `prop_socket_wrench_loose.png` — reusable_prop
- `prop_duct_tape_roll_gray.png` — reusable_prop
- `prop_extension_cord_tangle.png` — reusable_prop
- `prop_power_strip_overloaded.png` — reusable_prop
- `prop_ring_light_busted_small.png` — reusable_prop
- `prop_tripod_wobbly.png` — reusable_prop
- `prop_drone_crashed.png` — reusable_prop
- `prop_drone_flying_silhouette.png` — reusable_prop
- `prop_tarp_blue_bundle.png` — reusable_prop
- `prop_tarp_tied_wall.png` — reusable_prop
- `prop_sandbag_stack_dirty.png` — reusable_prop
- `prop_busted_umbrella_insideout.png` — reusable_prop
- `prop_lawn_chair_throne.png` — reusable_prop
- `prop_lawn_chair_sagging.png` — reusable_prop
- `prop_plastic_bucket_cracked.png` — reusable_prop
- `prop_mop_bucket_suspicious.png` — reusable_prop
- `prop_broken_tv_static.png` — reusable_prop
- `prop_vhs_tape_blank_label.png` — reusable_prop
- `prop_boombox_cracked.png` — reusable_prop
- `prop_radio_emergency_old.png` — reusable_prop
- `prop_cardboard_sign_blank.png` — reusable_prop
- `prop_cardboard_sign_bad_deal.png` — reusable_prop
- `prop_plastic_bag_flutter.png` — reusable_prop
- `prop_trash_bag_tied_black.png` — reusable_prop
- `prop_trash_bag_blue_leaking.png` — reusable_prop
- `prop_pallet_broken.png` — reusable_prop
- `prop_crate_plastic_mixed.png` — reusable_prop
- `prop_fire_extinguisher_empty.png` — reusable_prop
- `prop_payphone_dead.png` — reusable_prop
- `prop_newspaper_box_empty.png` — reusable_prop
- `prop_bicycle_frame_no_wheels.png` — reusable_prop
- `prop_cigarette_bucket.png` — reusable_prop
- `prop_ashtray_overflow.png` — reusable_prop
- `prop_chain_link_fence_panel.png` — reusable_prop
- `prop_tire_stack_small.png` — reusable_prop
- `prop_bottle_brown_broken_safe.png` — reusable_prop
- `prop_can_crushed_blank.png` — reusable_prop
- `prop_foam_cup_straw.png` — reusable_prop
- `prop_lottery_ticket_fake_stack.png` — reusable_prop
- `prop_grill_broken_portable.png` — reusable_prop
- `prop_cooler_nachos_table.png` — reusable_prop
- `prop_missing_sock_shrine.png` — reusable_prop
- `prop_wax_strip_box_blank.png` — reusable_prop
- `prop_snake_warning_sign_blank.png` — reusable_prop
- `prop_raccoon_clipboard.png` — reusable_prop
- `decal_asphalt_crack_long_01.png` — floor_decal
- `decal_asphalt_crack_spider_01.png` — floor_decal

---

# Reusable Prop

## 001 — `prop_folding_chair_sunburned.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** stage dressing, background crowd seating, menu prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a rusty folding chair prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: sun-bleached metal frame, cracked vinyl seat, one bent leg, tiny duct-tape patch, Florida parking-lot grime, readable side angle. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 002 — `prop_folding_chair_collapsing.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** background gag, round-transition prop, throwable-looking but cosmetic
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a collapsing folding chair prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: folding chair halfway buckled like it has seen too many parking-lot arguments, exaggerated angular silhouette, one missing foot cap. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 003 — `prop_sacred_milk_crate_blue.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** bus stop dressing, encampment furniture, background joke
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sacred blue milk crate prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: old plastic crate treated like a throne, scratched corners, sticker residue, subtle shine on worn plastic, no real dairy logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 004 — `prop_milk_crate_cracked_orange.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** stage prop, UI inventory icon, background clutter
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cracked orange milk crate prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: orange crate with cracked rim, zip-tie repair, dirt in grid holes, strong readable crate silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 005 — `prop_cooler_mystery_red.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** encampment dressing, food gag, background joke
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a beat-up red cooler prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: faded red cooler with white lid, dented corner, questionable tape seal, blank label space, suspicious puddle underneath. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 006 — `prop_cooler_do_not_open.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** encampment prop, loading screen gag, dialogue background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a locked cooler prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: old cooler with crude hand-lettered warning space, padlock, melting ice puddle, flies indicated with a few pixels. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 007 — `prop_traffic_cone_sad.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x64`
- **Priority:** `A`
- **Use cases:** parking lot dressing, stage boundary visual, UI marker
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sad traffic cone prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x64, transparent background unless the asset is explicitly a tile or panel. Asset details: sun-faded orange traffic cone, warped rubber base, handwritten fake warning sticker, asphalt scuffs, slightly leaning pose. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 008 — `prop_traffic_cone_crushed.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** parking lot dressing, hit impact debris, background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a crushed traffic cone prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: flattened cone with tire marks, grimy orange color, torn reflective bands, comic squash silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 009 — `prop_busted_shopping_cart.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** flea market, parking lot, alley dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a busted shopping cart prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: wireframe cart with one wobbly wheel, bent handle, trash bag tied to side, no store branding, readable cart outline. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 010 — `prop_shopping_cart_wheel_loose.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** floor clutter, VFX debris, icon detail
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a loose shopping cart wheel prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small caster wheel with rust, bent bracket, thick outline, useful as detail sprite. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 011 — `prop_busted_scooter_tire.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** parking lot dressing, Bubba-related prop without drawing Bubba
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a busted scooter tire prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small scooter tire with worn tread, cracked rim, grease smears, hazard-orange reflection, no vehicle logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 012 — `prop_scooter_handlebar_bent.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** parking lot dressing, background repair station, prop pile
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bent scooter handlebar prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: crooked handlebar with dangling cable, taped grip, small mirror cracked, greasy metal highlights. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 013 — `prop_oil_stained_toolbox.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** encampment repair station, parking lot, prop UI icon
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an oil-stained toolbox prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: cheap metal toolbox with latch, grease stains, sticker residue, worn red/orange paint, no brand marks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 014 — `prop_socket_wrench_loose.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x24`
- **Priority:** `A`
- **Use cases:** generic tool prop, UI icon, debris
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a loose socket wrench prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x24, transparent background unless the asset is explicitly a tile or panel. Asset details: oversized pixel wrench, scuffed chrome, one taped handle, clear readable shape from side view. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 015 — `prop_duct_tape_roll_gray.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `40x40`
- **Priority:** `A`
- **Use cases:** prop piles, UI crafting icon, stage dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a duct tape roll prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 40x40, transparent background unless the asset is explicitly a tile or panel. Asset details: gray duct tape roll with torn strip, inner cardboard ring, dirty edge pixels, clear circular silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 016 — `prop_extension_cord_tangle.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** encampment, livestream arena dressing, safety gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tangled extension cord prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: orange extension cord knot with plug ends, dangerous loops, grimy highlights, readable as cable mess. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 017 — `prop_power_strip_overloaded.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x48`
- **Priority:** `A`
- **Use cases:** Tripp production dressing, encampment, UI warning icon
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an overloaded power strip prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x48, transparent background unless the asset is explicitly a tile or panel. Asset details: power strip with too many plugs, tiny sparks, tape repair, no real certification marks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 018 — `prop_ring_light_busted_small.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x80`
- **Priority:** `A`
- **Use cases:** background livestream prop, Tripp-related non-character asset
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a small busted ring light prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x80, transparent background unless the asset is explicitly a tile or panel. Asset details: cheap ring light on thin tripod, one segment broken, taped wire, white glow ring, pathetic influencer gear vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 019 — `prop_tripod_wobbly.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x80`
- **Priority:** `A`
- **Use cases:** stage dressing, fake broadcast setup, prop layer
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a wobbly camera tripod prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: thin black tripod, one leg shorter with tape, no camera brand, readable silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 020 — `prop_drone_crashed.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** Tripp arena debris, background prop, VFX debris
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a crashed drone prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small broken quadcopter on ground, cracked propellers, blinking red pixel, no brand marks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 021 — `prop_drone_flying_silhouette.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** background animation, livestream overlay, boss-stage dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny flying drone silhouette sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small quadcopter shape with blinking light, side view, simple enough for loop animation. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 022 — `prop_tarp_blue_bundle.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x48`
- **Priority:** `A`
- **Use cases:** encampment, drainage canal, generic Florida storm prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blue tarp bundle prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x48, transparent background unless the asset is explicitly a tile or panel. Asset details: folded blue tarp tied with rope, wet highlights, dirty wrinkles, storm-prep feel. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 023 — `prop_tarp_tied_wall.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** encampment background, stage divider, hub dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tied tarp wall prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: improvised tarp panel with rope corners, patches, wind-wrinkled folds, no text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 024 — `prop_sandbag_stack_dirty.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x56`
- **Priority:** `A`
- **Use cases:** drainage canal, hurricane gag, background cover
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dirty sandbag stack prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x56, transparent background unless the asset is explicitly a tile or panel. Asset details: stacked tan sandbags with damp stains, simple readable block mass, storm-prep mood. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 025 — `prop_busted_umbrella_insideout.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** drainage canal, bus stop, background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an inside-out umbrella prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: broken umbrella flipped inside out, bent ribs, wet cloth, comic storm damage. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 026 — `prop_lawn_chair_throne.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x80`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, encampment, background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an improvised lawn chair throne prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x80, transparent background unless the asset is explicitly a tile or panel. Asset details: old lawn chair with duct tape, cup holder, tiny junk crown charm, trashy local royalty vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 027 — `prop_lawn_chair_sagging.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** crowd seating, encampment, flea market dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sagging lawn chair prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: woven outdoor chair, frayed strips, one low-slung seat, sunburned plastic colors. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 028 — `prop_plastic_bucket_cracked.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** prop piles, food gag, stage dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cracked plastic bucket prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: old bucket with handle, dirt ring, faded warning-color plastic, no branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 029 — `prop_mop_bucket_suspicious.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `56x56`
- **Priority:** `A`
- **Use cases:** laundromat dressing, alley prop, gross-out gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a suspicious mop bucket prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x56, transparent background unless the asset is explicitly a tile or panel. Asset details: yellow mop bucket with dark grimy water, cracked wheel, blocky warning panel with no real brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 030 — `prop_broken_tv_static.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** background gag, menu prop, campaign UI reference
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broken CRT television prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: old CRT showing chunky static blocks, cracked casing, antenna bent, no brand, cheap livestream playback energy. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 031 — `prop_vhs_tape_blank_label.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** gallery UI, campaign evidence board, prop clutter
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a VHS tape prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: black tape with blank white label, scuffed corners, retro archive evidence vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 032 — `prop_boombox_cracked.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** stage dressing, audio icon, encampment
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cracked boombox prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: old portable boombox, missing knob, taped speaker, no brand marks, grimy street music vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 033 — `prop_radio_emergency_old.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** drainage canal, encampment, UI icon
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an old emergency radio prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: hand-crank style radio, dirty yellow/orange, bent antenna, storm-prep but fictional. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 034 — `prop_cardboard_sign_blank.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x48`
- **Priority:** `A`
- **Use cases:** stage signage base, UI mockups, crowd prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank cardboard protest/sign prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x48, transparent background unless the asset is explicitly a tile or panel. Asset details: ragged cardboard sign on stick, dirty edges, blank center for hand-added jokes. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 035 — `prop_cardboard_sign_bad_deal.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x48`
- **Priority:** `A`
- **Use cases:** background crowd gag, campaign scene prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cardboard sign with fake warning blocks for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x48, transparent background unless the asset is explicitly a tile or panel. Asset details: ragged cardboard sign with blocky illegible fake text bars, marker strokes, greasy fingerprints. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 036 — `prop_plastic_bag_flutter.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** background animation, floor clutter, wind VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fluttering plastic bag prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: white-gray grocery-style plastic bag caught on edge, no logo, wind-twisted readable silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 037 — `prop_trash_bag_tied_black.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, encampment, stage clutter
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tied black trash bag prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: shiny black trash bag, tied knot, subtle leaks, strong lumpy silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 038 — `prop_trash_bag_blue_leaking.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, alley, background prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a leaking blue trash bag prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: blue-black trash bag with tiny puddle, mystery stains, fly pixels, no gore. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 039 — `prop_pallet_broken.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** flea market, alley, encampment platform prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broken wooden pallet prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: wooden pallet with cracked slats, nails indicated safely, rough brown pixels. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 040 — `prop_crate_plastic_mixed.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x48`
- **Priority:** `A`
- **Use cases:** flea market tables, encampment, background storage
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a stack of mixed plastic crates prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x48, transparent background unless the asset is explicitly a tile or panel. Asset details: two or three crates stacked, faded colors, no brand, asymmetric but readable. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 041 — `prop_fire_extinguisher_empty.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `40x64`
- **Priority:** `A`
- **Use cases:** liquor store, gas station, boss arena prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an empty fire extinguisher prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 40x64, transparent background unless the asset is explicitly a tile or panel. Asset details: red extinguisher with missing pin and blank label, scratched metal, no real safety markings. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 042 — `prop_payphone_dead.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x80`
- **Priority:** `A`
- **Use cases:** bus stop/under bridge dressing, background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dead payphone prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: old public payphone shell with dangling receiver, blank coin panel, grimy metal, fictional. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 043 — `prop_newspaper_box_empty.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** bus stop, sidewalk prop, UI lore asset
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an empty newspaper box prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: street newspaper vending box with cracked window, blank fake headline area, sun-faded plastic. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 044 — `prop_bicycle_frame_no_wheels.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x48`
- **Priority:** `A`
- **Use cases:** under bridge, bus stop, alley clutter
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bike frame missing wheels prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x48, transparent background unless the asset is explicitly a tile or panel. Asset details: old bicycle frame chained to nothing, rusted, no brand, readable side silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 045 — `prop_cigarette_bucket.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `40x48`
- **Priority:** `A`
- **Use cases:** liquor store, alley behind bar, background prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cigarette butt bucket prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 40x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small sand bucket with many tiny butts, dirty rim, no text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 046 — `prop_ashtray_overflow.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** bar alley, liquor store, prop dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an overflowing outdoor ashtray prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small metal ashtray with ash clumps and stub shapes, low-contrast, readable at small scale. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 047 — `prop_chain_link_fence_panel.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x96`
- **Priority:** `A`
- **Use cases:** background layer insert, stage boundary dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a chain-link fence panel prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: partial chain-link fence rectangle, bent top rail, subtle holes, transparent gaps, no signs. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 048 — `prop_tire_stack_small.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x64`
- **Priority:** `A`
- **Use cases:** parking lot, drainage canal, under bridge
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a small stack of worn tires prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x64, transparent background unless the asset is explicitly a tile or panel. Asset details: three worn tires with dirt and sun cracks, no brand text, strong dark outline. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 049 — `prop_bottle_brown_broken_safe.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `32x48`
- **Priority:** `A`
- **Use cases:** bar alley, floor clutter, prop icon
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a brown broken bottle prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x48, transparent background unless the asset is explicitly a tile or panel. Asset details: cartoonish broken bottle shape, no sharp gore focus, blank label, readable silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 050 — `prop_can_crushed_blank.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `32x24`
- **Priority:** `A`
- **Use cases:** floor clutter, debris, VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a crushed blank aluminum can prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x24, transparent background unless the asset is explicitly a tile or panel. Asset details: flattened can with no logo, faded silver/red color blocks, readable trash detail. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 051 — `prop_foam_cup_straw.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `32x40`
- **Priority:** `A`
- **Use cases:** bus stop, parking lot, gas station
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a stained foam cup prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x40, transparent background unless the asset is explicitly a tile or panel. Asset details: foam cup with straw, no logo, condensation and grime pixels, comedic forgotten drink vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 052 — `prop_lottery_ticket_fake_stack.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** liquor store, UI icon, floor clutter
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake scratch-ticket stack prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small stack of fictional scratch tickets with blank blocks and garish colors, no real lottery branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 053 — `prop_grill_broken_portable.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `80x64`
- **Priority:** `A`
- **Use cases:** encampment, parking lot, flea market
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broken portable grill prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x64, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny rusty grill with smoke stains, missing wheel, questionable food silhouettes but no gore. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 054 — `prop_cooler_nachos_table.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** parking lot vendor gag, encampment, background prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cooler nachos table prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small folding table with cooler and messy snack tray, fictional labels, greasy but readable. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 055 — `prop_missing_sock_shrine.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** laundromat background, UI lore asset
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a missing sock shrine prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny shrine of mismatched socks, candles as simple pixels, absurd laundromat folklore. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 056 — `prop_wax_strip_box_blank.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** laundromat/salon gag, background prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank wax-strip box prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small salon supply box with blank label, pink/white color blocks, no real brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 057 — `prop_snake_warning_sign_blank.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** under bridge, drainage canal, Python Paulie adjacent prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank snake warning sign prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: weathered sign with snake silhouette icon and blank text space, funny but not realistic danger sign. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 058 — `prop_raccoon_clipboard.png`

- **Category:** `reusable_prop`
- **Recommended folder:** `art/props/reusable/`
- **Suggested canvas:** `32x40`
- **Priority:** `A`
- **Use cases:** Dumpster Alley gag, Randy-adjacent background prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny raccoon-sized clipboard prop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x40, transparent background unless the asset is explicitly a tile or panel. Asset details: small clipboard with illegible bylaws, claw marks, brown board, no readable real text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Floor Decal

## 059 — `decal_asphalt_crack_long_01.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `96x32`
- **Priority:** `A`
- **Use cases:** floor detail, stage dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a long cracked asphalt decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x32, transparent background unless the asset is explicitly a tile or panel. Asset details: thin jagged crack line with chipped edges, transparent background, useful over parking lot floor, low contrast around fighter feet. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 060 — `decal_asphalt_crack_spider_01.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** floor detail
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a spiderweb asphalt crack decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small spiderweb crack cluster, dark gray linework, subtle highlights, not too busy. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 061 — `decal_oil_slick_small_rainbow.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** parking lot, gas station, VFX ground detail
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a small oil slick floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: subtle rainbow sheen on dark puddle, low saturation, transparent feathered pixel edge. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 062 — `decal_oil_slick_wide.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x48`
- **Priority:** `A`
- **Use cases:** gas station floor dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a wide oil slick floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x48, transparent background unless the asset is explicitly a tile or panel. Asset details: flat stylized black puddle with slight rainbow edge, readable but not bright enough to confuse hit sparks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 063 — `decal_gum_spots_cluster.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** bus stop, sidewalk floor
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a gum spots floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: several pink/gray gum circles stuck to concrete, tiny comedy detail, low contrast. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 064 — `decal_receipt_scraps_cluster.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** gas station, liquor store, parking lot
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cluster of receipt scraps decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny white receipt fragments, curled ends, fake barcode blocks, no readable real brands. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 065 — `decal_cigarette_butts_cluster.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** liquor store, alley
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cigarette butts floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small scattered cigarette butts and ash pixels, warm gray/brown palette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 066 — `decal_broken_glass_sparkle_safe.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** bar alley, liquor store
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cartoon broken glass sparkle decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small non-gory glass shards with a few white highlights, safe stylized arcade look. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 067 — `decal_puddle_dirty_round.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x40`
- **Priority:** `A`
- **Use cases:** alley, under bridge, drainage canal
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a round dirty puddle decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x40, transparent background unless the asset is explicitly a tile or panel. Asset details: brown-gray puddle with small reflection, transparent edge, not too glossy. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 068 — `decal_puddle_neon_reflect.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `96x32`
- **Priority:** `A`
- **Use cases:** liquor store, bar alley
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a neon reflection puddle decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x32, transparent background unless the asset is explicitly a tile or panel. Asset details: thin puddle reflecting magenta/cyan neon as broken pixel streaks, low enough contrast for readability. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 069 — `decal_puddle_storm_long.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x40`
- **Priority:** `A`
- **Use cases:** drainage canal, bus stop rain variant
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a long storm-water puddle decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x40, transparent background unless the asset is explicitly a tile or panel. Asset details: wet concrete reflection, storm gray/green, small ripple pixels. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 070 — `decal_parking_line_faded_yellow.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x24`
- **Priority:** `A`
- **Use cases:** parking lot floor, stage boundary marking
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a faded yellow parking line decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x24, transparent background unless the asset is explicitly a tile or panel. Asset details: single worn stripe with chipped paint and tire grime, transparent around it. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 071 — `decal_parking_line_crossed.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** parking lot floor blockout
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a crossed parking line decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: faded diagonal parking lot hatch lines, cracked asphalt gaps, not too busy. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 072 — `decal_sidewalk_stain_tea.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x48`
- **Priority:** `A`
- **Use cases:** bus stop, sidewalk
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sidewalk drink stain decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: old spilled sweet tea or soda stain, amber/brown ring, no cup logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 073 — `decal_mystery_stain_green.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, gas station
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a weird green stain decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small toxic-green comedy stain, controlled saturation, looks suspicious but non-gory. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 074 — `decal_tire_skid_curve.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** parking lot, Bubba-adjacent dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a curved tire skid decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: black curved skid mark, burnout texture, transparent background, readable sweep shape. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 075 — `decal_tire_tracks_stop_edge.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** drainage canal, parking lot
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create tire tracks ending abruptly decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: two faint tire tracks that stop suddenly, comic bad-decision implication, transparent background. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 076 — `decal_spray_paint_border_line.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x32`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, under bridge
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a spray-painted territory border decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: rough paint line with arrows/dots, no real text, dirty green/orange palette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 077 — `decal_chalk_arrow_wrong_way.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** under bridge, encampment
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a chalk arrow floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: white chalk arrow pointing the wrong way, worn and dusty, no text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 078 — `decal_chalk_body_outline_fake.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** Stabatha-adjacent gag, bar alley
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake chalk outline decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: cartoonish chalk outline shaped like someone tripped, non-gory and absurd, no realistic crime detail. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 079 — `decal_raccoon_pawprints.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `96x32`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, under bridge
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create raccoon pawprint trail decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x32, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny muddy pawprints in a curved trail, low contrast, transparent background. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 080 — `decal_snake_slither_mark.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x24`
- **Priority:** `A`
- **Use cases:** under bridge, drainage canal
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a snake slither trail decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x24, transparent background unless the asset is explicitly a tile or panel. Asset details: subtle S-shaped dirt trail, faint scale-like texture, transparent background. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 081 — `decal_flies_swarm_small.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** gross props, Dumpster Alley, food gags
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny fly swarm sprite/decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small cluster of black fly pixels in a loose animated-looking pattern, transparent background. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 082 — `decal_heat_shimmer_strip.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x32`
- **Priority:** `A`
- **Use cases:** bus stop, parking lot, hot day overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a heat shimmer overlay sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: transparent wavering heat lines, light distortion look, pixel-art readable, no blur. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 083 — `decal_dust_poof_ground.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** movement VFX, landing, dash
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dust poof ground decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small tan dust cloud at foot level, 3-frame-ready shape, transparent background. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 084 — `decal_sandbag_dust_scatter.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** drainage canal, encampment
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sand/dirt scatter decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small tan grit pile with a few grains, storm-prep and parking-lot dirt mood. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 085 — `decal_leaking_pipe_drip_line.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `48x64`
- **Priority:** `A`
- **Use cases:** under bridge, Dumpster Alley, drainage canal
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a wet drip line decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x64, transparent background unless the asset is explicitly a tile or panel. Asset details: vertical water stain under pipe, moss tint, transparent edge. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 086 — `decal_rust_stain_wall.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x96`
- **Priority:** `A`
- **Use cases:** liquor store, under bridge, alley
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a rust stain wall decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: vertical rusty streak, orange/brown, transparent edge, meant for walls not floor. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 087 — `decal_poster_residue_rectangle.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x96`
- **Priority:** `A`
- **Use cases:** stage walls, menu backgrounds
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a torn poster residue decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: rectangular glue residue and paper scraps, no readable text, useful on walls/signs. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 088 — `decal_sticker_bomb_generic.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** props, UI edges, stage signs
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a generic sticker cluster decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small fictional sticker shapes and warning icons, no logos, no legible real references. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 089 — `decal_cracked_tile_cluster.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** laundromat floor
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cracked laundromat tile decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: off-white floor tile cracks and grime, low contrast, transparent edge. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 090 — `decal_laundry_soap_spill.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** laundromat, Soapless Joe-adjacent stage dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a soap spill floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: slippery blue-white soap spill with bubbles, comic and readable, not too bright. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 091 — `decal_flea_market_dust_patch.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** flea market floor
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dusty market ground patch decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: tan dusty patch with footprints and tiny wrapper bits, transparent edge. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 092 — `decal_canal_moss_edge.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `96x32`
- **Priority:** `A`
- **Use cases:** drainage canal
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a mossy canal edge decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x32, transparent background unless the asset is explicitly a tile or panel. Asset details: green moss streak along concrete edge, wet grime, low saturation. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 093 — `decal_livestream_cable_shadow.png`

- **Category:** `floor_decal`
- **Recommended folder:** `art/decals/floor/`
- **Suggested canvas:** `128x32`
- **Priority:** `A`
- **Use cases:** Tripp arena, encampment, UI stage overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cable shadow floor decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: dark looping cable shadow on floor, no actual collision implied, low contrast. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Fake Signage Sponsor

## 094 — `sign_probably_legal_energy_can.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `64x96`
- **Priority:** `A`
- **Use cases:** fake sponsor, UI, vending prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake energy drink can prop/icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional label area with jagged lightning motif, dirty yellow/red colors, funny bootleg energy drink vibe, no similarity to real cans. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 095 — `sign_probably_legal_energy_banner.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `192x64`
- **Priority:** `A`
- **Use cases:** stage banner, livestream overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake sponsor banner for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x64, transparent background unless the asset is explicitly a tile or panel. Asset details: banner for fictional Probably Legal Energy with blocky unreadable slogan space, peeling tape corners, dirty neon colors. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 096 — `sign_crankape_energy_poster.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** Gas-N-Go sponsor gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fictional energy drink poster for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: fake CrankApe-style sponsor poster using abstract ape-like roar symbol but not real mascot, garish red/green, ripped edge. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 097 — `sign_no_credit_no_crying.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** liquor store wall gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a hand-painted shop sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional liquor-store style sign reading suggestion 'NO CREDIT NO CRYING' as chunky pixel text or blank text blocks if unreliable, stained paper. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 098 — `sign_open_nope_neon.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** liquor store background animation
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a flickering neon sign sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: two-state neon sign concept: OPEN/NOPE idea, magenta/cyan glow, no real business branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 099 — `sign_out_of_morals_bathroom.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** Gas-N-Go background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a grimy bathroom sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional gas-station restroom sign with crude humor text space, scratched plastic, greenish fluorescent palette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 100 — `sign_delayed_bus_arrival.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** bus stop background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bus arrival delay sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: generic transit display with blocky fake text bars and one large delayed indicator, no town names, no real transit logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 101 — `sign_route_map_fake.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** bus stop shelter dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake bus route map sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: abstract unreadable route lines, sun-faded paper behind scratched glass, no real place names. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 102 — `sign_dumpster_alley_rent.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** Dumpster Alley wall prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a trash kingdom sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: handmade sign for Dumpster Alley territory rules, aggressive local joke vibe, blank space for hand-pixel text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 103 — `sign_not_evidence_pile_label.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `80x40`
- **Priority:** `A`
- **Use cases:** Dumpster Alley, Stabatha gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a small evidence pile label sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x40, transparent background unless the asset is explicitly a tile or panel. Asset details: cardboard label with fake block text, stained tape, comedy crime/noir hint without real legal details. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 104 — `sign_bridge_remembers_graffiti.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** under bridge wall decal
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fictional graffiti wall tag for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: spray-painted phrase concept with abstract letters/symbols, concrete texture, no real gang symbols or public references. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 105 — `sign_reserved_by_committee.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** under bridge, Dumpster Alley
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny reserved sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: handwritten chair-reservation sign, official-looking but pathetic, clipped to chair/lawn throne. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 106 — `sign_do_not_enter_weather_args.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** drainage canal background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a storm canal warning sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional warning sign about weather and arguments, yellow/black caution style without real agency logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 107 — `sign_low_ground_high_stakes.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** campaign card art, stage dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a drainage canal flavor sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: weathered stage flavor sign with storm-gray grime, readable title-card style, no real location. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 108 — `sign_laundromat_rules_too_many.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** laundromat background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a laundromat rules poster for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: generic rules board with too many fake lines, blue-white fluorescent palette, no real brand or phone number. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 109 — `sign_missing_sock_board.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** laundromat background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a missing sock notice board for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: corkboard full of mismatched sock notes and fake Polaroid blocks, absurd shrine vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 110 — `sign_flea_market_booth_blank.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** flea market reusable signage
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank flea market booth sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: dusty tarp-hung sign with blank center for future vendor name, colorful but worn. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 111 — `sign_bootleg_merch_no_refunds.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** flea market, Tripp merch gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bootleg merch sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional bootleg merch sign with 'NO REFUNDS' idea in chunky pixels or blank bars, crooked taped corners. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 112 — `sign_alley_backdoor_neon.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** alley behind bar background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a neon backdoor bar sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional bar backdoor neon glow panel, no real bar name, sticky night palette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 113 — `sign_karaoke_closed_forever.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** bar alley gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake karaoke sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small sign implying karaoke is closed forever, funny bar alley vibe, worn neon border, no real business. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 114 — `sign_tripp_sponsor_wall_blank.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `192x96`
- **Priority:** `A`
- **Use cases:** Tripp arena, campaign UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank fake sponsor wall panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x96, transparent background unless the asset is explicitly a tile or panel. Asset details: rectangular sponsor backdrop with many empty logo boxes, cheap press-conference look, no real marks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 115 — `sign_tripp_apology_loading.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `160x96`
- **Priority:** `A`
- **Use cases:** final boss arena, menu gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake apology video screen panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x96, transparent background unless the asset is explicitly a tile or panel. Asset details: livestream panel with generic apology thumbnail layout, crying-face placeholder silhouette not a real person, no readable platform brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 116 — `sign_viewer_count_panel.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x48`
- **Priority:** `A`
- **Use cases:** HUD overlay, campaign UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake livestream viewer counter panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x48, transparent background unless the asset is explicitly a tile or panel. Asset details: pixel UI panel with changing number blocks, cheap broadcast look, red/blue/white palette, no platform logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 117 — `sign_chat_popup_generic_01.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x48`
- **Priority:** `A`
- **Use cases:** campaign overlay, UI testing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake chat popup panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small livestream chat bubble with colorful username blocks and unreadable joke text bars, no real usernames. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 118 — `sign_chat_popup_angry_02.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x48`
- **Priority:** `A`
- **Use cases:** campaign overlay, Tripp escalation
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an angry fake chat popup panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x48, transparent background unless the asset is explicitly a tile or panel. Asset details: red-tinted chat bubble with emoji-like block icons and illegible toxic-comment bars, not readable slurs. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 119 — `sign_fake_contract_clause.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** campaign evidence UI, story prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a suspicious contract prop graphic for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: paper document with many fake clauses, red stamps, tiny unreadable blocks, no legal real-world identifiers. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 120 — `sign_fake_medical_clearance.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** campaign evidence, Tripp scam prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake clearance form prop graphic for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: clipboard-style form with checkboxes, red exclamation stamp, fictional, no real medical agency branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 121 — `sign_folding_table_registration.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** campaign intro props
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tournament registration table sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: handmade Sidewalk Showdown signup sign style, trashy folding-table event vibe, no real sponsors. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 122 — `sign_sidewalk_showdown_flyer_blank.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** promo prop, UI lore
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank tournament flyer base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: grimy flyer layout with empty name/date boxes, fake combat brackets, no real locations, can be hand-edited later. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 123 — `sign_winner_takes_all_suspicious.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** campaign prop, gallery unlock
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a suspicious prize flyer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: flyer promising vague prize package, fine-print blocks, torn corners, fake sponsor stamps. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 124 — `sign_fake_charity_meter_panel.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** campaign overlay, sponsor/stunt scene
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake charity meter UI sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: livestream donation meter style with suspicious fine-print area, no platform branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 125 — `sign_donation_goal_busted.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** Tripp UI, menu gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a busted donation goal panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: cracked digital donation goal panel, numbers glitching, cheap stream overlay design. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 126 — `sign_no_filming_unless_profitable.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** stage wall gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a humorous no filming sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fake property sign with sarcastic filming rule concept, no real legal text, weathered plastic. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 127 — `sign_fake_security_badge_icon.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** UI icon, Deputy-adjacent prop, crowd volunteer
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake security badge icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: generic law-adjacent badge shape, intentionally fake and silly, no real insignia, bold outline. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 128 — `sign_arcade_tokens_accepted.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** flea market, Chuck-adjacent prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake arcade tokens sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: retro sign suggesting tokens are accepted, no real arcade references, ticket-strip colors. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 129 — `sign_mystery_meat_menu_blank.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** Dogfood Debbie-adjacent but non-character prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank mystery menu board for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: food-truck menu board with blank price blocks, greasy red/tan palette, no actual real food chain branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 130 — `sign_mushroom_jerky_table_blank.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** Betty-adjacent non-character prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank roadside product sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: handmade product sign with mushroom shape motif and blank label space, roadside vendor energy, no drug-instructional visuals. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 131 — `sign_storm_prep_dojo_flyer.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** Lt. Dan-adjacent non-character prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a storm-prep class flyer prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional preparedness flyer with tarp/sandbag icons and fake class blocks, no real agency logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 132 — `sign_bench_naming_petition.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** Stub Stan-adjacent prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a public petition sign prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: clipboard/poster about naming a bench, fake signatures as scribbles, no real names. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 133 — `sign_waxing_revenge_cards.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** Hairy Mary-adjacent prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a small stack of business cards prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional mobile salon/revenge service card stack with blank readable blocks, pink/black palette, no real phone number. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 134 — `sign_case_board_red_string.png`

- **Category:** `fake_signage_sponsor`
- **Recommended folder:** `art/ui/fake_sponsors/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** Stabatha-adjacent prop
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake detective case board for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: small corkboard with red string, wrong clues, blank photo rectangles, no real people. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Ui Broadcast

## 135 — `ui_health_bar_frame_grimy.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `256x32`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a grimy pixel-art health bar frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x32, transparent background unless the asset is explicitly a tile or panel. Asset details: wide chunky HUD frame with cracked arcade cabinet edge, dark backing, dirty yellow accents, no player names yet. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 136 — `ui_health_bar_fill_green.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `256x16`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a health bar fill sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x16, transparent background unless the asset is explicitly a tile or panel. Asset details: flat segmented green/yellow fill strip, pixel clean, readable against dark HUD frame. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 137 — `ui_hype_meter_frame.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x24`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a Hype Meter frame UI asset for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x24, transparent background unless the asset is explicitly a tile or panel. Asset details: cheap livestream meter frame with small sticker edges, distinct from health, dark base with neon accents. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 138 — `ui_hype_meter_fill_orange.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x12`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a Hype Meter fill sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x12, transparent background unless the asset is explicitly a tile or panel. Asset details: orange/red energetic segmented fill, arcade power look, not confused with health. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 139 — `ui_round_marker_empty.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an empty round marker icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small dirty circular marker, arcade screw/rivet feel, dark outline. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 140 — `ui_round_marker_win.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a won round marker icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: filled round marker with cracked star/bottle-cap shape, readable at tiny scale. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 141 — `ui_timer_frame_busted_arcade.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fight timer frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: center HUD timer housing, cracked arcade plastic, cheap broadcast label space, dark readable interior. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 142 — `ui_combo_counter_pop.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** combat UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a combo counter popup frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: bold comic pixel burst panel for combo count, bright but not obscuring, transparent background. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 143 — `ui_counter_hit_stamp.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** combat UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a counter-hit stamp graphic for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: impact stamp reading concept 'COUNTER' or blank block letters, red/orange warning style, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 144 — `ui_meth_ready_badge.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x48`
- **Priority:** `A`
- **Use cases:** match HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a METHtality ready badge UI asset for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: crude arcade finisher readiness badge, dangerous red/yellow, no drug-instruction imagery, readable icon-first. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 145 — `ui_finish_prompt_panel.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** METHtality prompt
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a finish prompt panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: big arcade-style finish window frame, gritty sticker corners, blank center for text, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 146 — `ui_pause_panel_background.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `256x160`
- **Priority:** `A`
- **Use cases:** pause/options UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a pause menu panel background for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x160, transparent background unless the asset is explicitly a tile or panel. Asset details: cleaner dark panel with subtle grime, readable border, minimal jokes, no heavy clutter. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 147 — `ui_menu_selector_arrow.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** menus
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a menu selector arrow sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: chunky pixel arrow made from taped cardboard/neon accent, readable focus indicator. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 148 — `ui_button_prompt_keyboard_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** controls UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank keyboard button prompt for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small rectangular keycap with grime/shadow, blank center for letter overlay, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 149 — `ui_button_prompt_gamepad_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** controls UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank gamepad button prompt for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: round button icon with thick outline and blank center, dirty arcade plastic feel. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 150 — `ui_dialogue_box_frame_grimy.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `256x64`
- **Priority:** `A`
- **Use cases:** story dialogue
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dialogue box frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x64, transparent background unless the asset is explicitly a tile or panel. Asset details: wide dialogue panel with cheap stream lower-third edges, readable dark interior, empty portrait slot optional. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 151 — `ui_dialogue_nameplate_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `128x32`
- **Priority:** `A`
- **Use cases:** story dialogue
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank dialogue nameplate for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small lower-third nameplate, bold outline, fake broadcast look, blank interior. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 152 — `ui_livestream_lower_third_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x48`
- **Priority:** `A`
- **Use cases:** Tripp commentary UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a livestream lower-third panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x48, transparent background unless the asset is explicitly a tile or panel. Asset details: cheap broadcast lower-third with sponsor corner and text bars, no platform logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 153 — `ui_tripp_commentary_popup_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `160x64`
- **Priority:** `A`
- **Use cases:** campaign overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a Tripp commentary popup frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: annoying influencer-style pop-up panel, red/white/blue glare, blank avatar circle, no likeness. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 154 — `ui_fake_chat_window_small.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `160x128`
- **Priority:** `A`
- **Use cases:** campaign overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a small fake chat window panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x128, transparent background unless the asset is explicitly a tile or panel. Asset details: transparent-ish chat window with stacked unreadable message bars, optional scrollbar, no real platform branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 155 — `ui_viewer_counter_widget.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x32`
- **Priority:** `A`
- **Use cases:** campaign HUD
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a viewer counter widget for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small eye icon-like abstract symbol and number block space, no platform logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 156 — `ui_sponsor_bug_corner_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** stream overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a corner sponsor bug asset for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small square broadcast sponsor bug frame with blank logo area, peeling sticker edge. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 157 — `ui_stage_card_frame.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `256x144`
- **Priority:** `A`
- **Use cases:** stage intro cards
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a stage title card frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x144, transparent background unless the asset is explicitly a tile or panel. Asset details: location card frame with taped corners and faded postcard energy, blank center for stage name. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 158 — `ui_character_select_slot_empty.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x96`
- **Priority:** `A`
- **Use cases:** character select UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an empty character select slot for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: mugshot-thumbnail slot frame with grime, warning tape corner, no character image. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 159 — `ui_character_select_locked_boss_absent.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `96x96`
- **Priority:** `A`
- **Use cases:** character select guardrail
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a non-selectable boss absence slot for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: host/boss absence marker that clearly does not look selectable, blank silhouette/blocked icon, no Tripp portrait. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 160 — `ui_stage_select_card_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `128x72`
- **Priority:** `A`
- **Use cases:** stage select UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank stage select card for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x72, transparent background unless the asset is explicitly a tile or panel. Asset details: small 16:9 card frame with fake location stamp area, no stage art inside. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 161 — `ui_gallery_evidence_card_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `128x96`
- **Priority:** `A`
- **Use cases:** gallery/extras
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank evidence/gallery card for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: fake evidence board card frame with tape, staple holes, empty image area. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 162 — `ui_contract_stamp_suspicious.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** campaign UI evidence
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a suspicious contract stamp icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: red rubber-stamp style icon with illegible block text, not real legal wording. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 163 — `ui_warning_flash_frame.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `256x64`
- **Priority:** `A`
- **Use cases:** boss warning UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a warning overlay frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x64, transparent background unless the asset is explicitly a tile or panel. Asset details: transparent warning stripe frame with black/yellow stripes and glitch pixels, no epilepsy-heavy flashing implied. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 164 — `ui_training_hitbox_toggle_icon.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** training/debug UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a training mode hitbox icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: debug-style icon showing rectangles around a tiny generic shape, clean and readable. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 165 — `ui_training_reset_icon.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** training/debug UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a reset icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: circular arrow made from chunky pixels, slightly grimy, readable at small size. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 166 — `ui_options_accessibility_icon.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** options UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an accessibility options icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: generic readable gear/eye/speaker hybrid icon, no real accessibility organization logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 167 — `ui_audio_slider_knob.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** options UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an audio slider knob UI sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small knob resembling worn arcade dial, dark outline, metal highlight. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 168 — `ui_video_slider_knob.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** options UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a video slider knob UI sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small knob with tiny screen icon motif, pixel clean. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 169 — `ui_input_remap_panel.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x96`
- **Priority:** `A`
- **Use cases:** controls UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an input remap panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x96, transparent background unless the asset is explicitly a tile or panel. Asset details: clean readable settings panel with row slots and button spaces, minimal grime. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 170 — `ui_loading_tip_card_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x96`
- **Priority:** `A`
- **Use cases:** loading screens
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a loading tip card for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x96, transparent background unless the asset is explicitly a tile or panel. Asset details: fake local legend card frame, blank text area, small sticker space, readable. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 171 — `ui_fake_ad_card_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x96`
- **Priority:** `A`
- **Use cases:** loading screens, menus
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake ad card base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x96, transparent background unless the asset is explicitly a tile or panel. Asset details: retro fake sponsor ad card with blank central art area, exaggerated sticker border, no real brands. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 172 — `ui_ko_burst_letters_base.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `160x80`
- **Priority:** `A`
- **Use cases:** match end UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a KO burst graphic base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x80, transparent background unless the asset is explicitly a tile or panel. Asset details: large chunky impact burst for KO letters, transparent, red/orange/white with cracked outline. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 173 — `ui_round_start_banner_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x48`
- **Priority:** `A`
- **Use cases:** match intro UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a round start banner for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x48, transparent background unless the asset is explicitly a tile or panel. Asset details: wide grungy banner frame for ROUND text, cheap livestream overlay accents, blank center. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 174 — `ui_winner_panel_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `192x96`
- **Priority:** `A`
- **Use cases:** results screen
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a winner panel frame for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 192x96, transparent background unless the asset is explicitly a tile or panel. Asset details: victory panel with arcade cabinet screws and fake broadcast tape, blank winner name area. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 175 — `ui_unlock_badge_blank.png`

- **Category:** `ui_broadcast`
- **Recommended folder:** `art/ui/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** gallery unlocks
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an unlock badge icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small sticker badge with star/lock motif, blank interior, dirty gold accent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Vfx Particle

## 176 — `vfx_hit_light_spark_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** combat hit VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a light hit spark VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small yellow-white impact burst with 3 or 4 chunky rays, transparent, readable over dark/light stages. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 177 — `vfx_hit_heavy_spark_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `96x96`
- **Priority:** `A`
- **Use cases:** combat hit VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a heavy hit spark VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: larger orange/red impact burst, jagged arcade star shape, dark outline fragments, not covering whole body. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 178 — `vfx_hit_counter_spark_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `96x96`
- **Priority:** `A`
- **Use cases:** counter hit VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a counter-hit spark VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: sharp angular impact burst with red accent and white center, slightly more dramatic than heavy hit. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 179 — `vfx_block_blue_shield_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** block VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a block impact VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: blue/cyan guard flash arc, transparent, compact crescent shape, does not hide fighter pose. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 180 — `vfx_block_low_dust_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** low block VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a low block dust VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small ground-level dust and shield chip effect, tan/blue pixels, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 181 — `vfx_throw_impact_ring.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `96x96`
- **Priority:** `A`
- **Use cases:** throw VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a throw impact ring VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: circular shock ring made from chunky pixels, tan/white burst, transparent center. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 182 — `vfx_landing_dust_small.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** jump landing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a landing dust puff VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: tan dust cloud with 2-frame-ready silhouette, transparent, low to ground. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 183 — `vfx_dash_dust_back.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** dash movement VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dash dust trail sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small horizontal dust smear with dirty asphalt particles, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 184 — `vfx_jump_start_pop.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `48x32`
- **Priority:** `A`
- **Use cases:** jump VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a jump-start dust pop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x32, transparent background unless the asset is explicitly a tile or panel. Asset details: compact dust burst under feet, readable and low opacity. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 185 — `vfx_knockdown_star_daze.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** knockdown/dizzy placeholder
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cartoon daze stars VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small orbiting star/squiggle symbols, dirty yellow/white, not too childish, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 186 — `vfx_meter_gain_spark.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** meter feedback
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a Hype Meter gain sparkle sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small neon orange/yellow spark icon, useful near meter or fighter, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 187 — `vfx_meth_ready_flame.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** METHtality readiness
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a finisher-ready flame VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small red/yellow dirty flame lick with black outline, arcade menace, no realism. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 188 — `vfx_neon_glitch_pixel_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** UI transition, Tripp overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a neon glitch pixel burst for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small cyan/magenta rectangular glitch fragments, transparent, cheap broadcast feeling. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 189 — `vfx_stream_static_noise_tile.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `128x128`
- **Priority:** `A`
- **Use cases:** livestream overlay texture
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tilable stream static noise tile for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x128, transparent or alpha texture background unless the asset is explicitly a tile or panel. Asset details: subtle pixel static pattern, transparent/low opacity version, not full-screen harsh. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 190 — `vfx_screen_scanline_overlay.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `256x144`
- **Priority:** `A`
- **Use cases:** menus, livestream UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a scanline overlay asset for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x144, transparent overlay background unless the asset is explicitly a tile or panel. Asset details: subtle horizontal scanlines and corner grime, transparent, 16:9 overlay, low opacity. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 191 — `vfx_heat_shimmer_loop_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `128x64`
- **Priority:** `A`
- **Use cases:** bus stop, parking lot
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a heat shimmer VFX strip for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: wavy transparent pixel lines for sunbaked air, designed as loopable strip. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 192 — `vfx_neon_flicker_glow_magenta.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `96x64`
- **Priority:** `A`
- **Use cases:** liquor store/bar alley lighting
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a magenta neon flicker glow sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: soft pixel glow ring/edge, transparent, no text, can be placed behind signs. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 193 — `vfx_fluorescent_buzz_glow.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `128x32`
- **Priority:** `A`
- **Use cases:** Gas-N-Go, laundromat
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fluorescent buzz glow sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: cold white-green light band, transparent, subtle flicker-ready shape. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 194 — `vfx_storm_lightning_flash_shape.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `128x128`
- **Priority:** `A`
- **Use cases:** drainage canal final-round VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a stylized lightning flash VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x128, transparent background unless the asset is explicitly a tile or panel. Asset details: white/yellow angular lightning shape, not full-screen, accessibility-friendly if reduced. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 195 — `vfx_rain_splash_tiny.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** storm stage VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny rain splash VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small white/blue splash star at ground level, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 196 — `vfx_puddle_ripple_ring.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x32`
- **Priority:** `A`
- **Use cases:** wet stages
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a puddle ripple VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: elliptical ripple rings on transparent background, low contrast. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 197 — `vfx_trash_flutter_leaf.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** wind/background VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fluttering trash scrap VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: single paper/trash bit, dirty white, transparent, animation-ready. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 198 — `vfx_fly_loop_cluster.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `48x48`
- **Priority:** `A`
- **Use cases:** food/trash props
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fly swarm loop sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: three to five tiny black fly positions, transparent, subtle gross ambience. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 199 — `vfx_raccoon_eye_blink_pair.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `32x16`
- **Priority:** `A`
- **Use cases:** Dumpster Alley/under bridge background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a pair of raccoon eye blink sprites for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x16, transparent background unless the asset is explicitly a tile or panel. Asset details: small glowing eye pair, black background optional transparent, loop-ready. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 200 — `vfx_spark_from_power_strip.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** Tripp gear, encampment cord gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an electrical spark VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny yellow/white spark shape with red pixel, transparent, cartoon safe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 201 — `vfx_smoke_puff_grill.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** parking lot/encampment
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a grill smoke puff sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: soft gray pixel smoke puff, transparent, three-frame-ready shape, not photoreal. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 202 — `vfx_bottle_clink_star.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `32x32`
- **Priority:** `A`
- **Use cases:** bar/liquor ambience
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bottle clink sparkle VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny white/yellow star impact for glass clink, no shards/gore. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 203 — `vfx_camera_flash_ring.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** Tripp/phone crowd VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a camera flash ring VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: white ring flash with slight blue edge, transparent, quick readable burst. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 204 — `vfx_phone_recording_dot.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `16x16`
- **Priority:** `A`
- **Use cases:** livestream overlay
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a recording dot UI/VFX sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 16x16, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny red recording dot with subtle glow, no platform branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 205 — `vfx_sponsor_sting_wipe.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `256x64`
- **Priority:** `A`
- **Use cases:** campaign transitions
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sponsor sting transition wipe for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x64, transparent background unless the asset is explicitly a tile or panel. Asset details: horizontal glitchy ad-break wipe with fake tape and neon blocks, no text/logo. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 206 — `vfx_round_transition_dust.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `256x64`
- **Priority:** `A`
- **Use cases:** round transitions
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a round transition dust sweep for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x64, transparent background unless the asset is explicitly a tile or panel. Asset details: wide low dust sweep with paper scraps, transparent, arcade wipe shape. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 207 — `vfx_boss_arena_cable_spark.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** Tripp arena dressing
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a boss arena cable spark VFX for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small electric spark near exposed cable, cheap production danger, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 208 — `vfx_confetti_trashy_01.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `64x64`
- **Priority:** `A`
- **Use cases:** victory/results
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a trashy confetti burst for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny receipt scraps and coupon bits bursting like confetti, no real coupons, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 209 — `vfx_impact_ground_crack_temp.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `96x32`
- **Priority:** `A`
- **Use cases:** heavy impact VFX
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a temporary ground crack impact effect for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small cartoon crack burst under heavy hit, fades visually, not actual collision. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 210 — `vfx_ko_screen_crack_overlay.png`

- **Category:** `vfx_particle`
- **Recommended folder:** `art/vfx/exports/`
- **Suggested canvas:** `256x144`
- **Priority:** `A`
- **Use cases:** KO UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a KO screen crack overlay for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 256x144, transparent background unless the asset is explicitly a tile or panel. Asset details: transparent cracked-screen overlay for dramatic KO, 16:9, subtle enough not to obscure results. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Background Extra

## 211 — `bg_extra_phone_filmer_01.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** crowd loop sprite
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a generic background spectator sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: non-playable local filming vertically on a phone, simple silhouette, street-worn clothes, no real person likeness, not a fighter. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 212 — `bg_extra_phone_filmer_02.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** crowd loop sprite
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a second generic phone-filmer spectator for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: different pose with phone raised too high, cheap sunglasses, no logo clothing, low animation complexity. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 213 — `bg_extra_folding_chair_heckler_01.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** background crowd
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a folding-chair heckler background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic seated heckler in lawn chair, pointing and yelling, no roster resemblance, simple looping mouth/arm pose. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 214 — `bg_extra_cooler_vendor_01.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `64x80`
- **Priority:** `B`
- **Use cases:** parking lot/flea market crowd
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a background cooler vendor sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic person selling questionable snacks from a cooler, street-worn outfit, no branding, not a playable character. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 215 — `bg_extra_fake_security_volunteer.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** crowd/security gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake security volunteer background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic volunteer with orange vest and clipboard, no real law enforcement insignia, nervous stance. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 216 — `bg_extra_unpaid_intern_ringlights.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `64x80`
- **Priority:** `B`
- **Use cases:** Tripp production background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a production intern background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic overworked intern carrying ring lights, tangled cables, no identifiable likeness. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 217 — `bg_extra_old_timer_watch.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** bus stop crowd
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a waiting local background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic older local checking broken watch, bus-stop patience, no real person likeness. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 218 — `bg_extra_route_map_arguer.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** bus stop gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a background local arguing with a route map for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic figure pointing at map/sign, annoyed posture, low-detail face. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 219 — `bg_extra_loiterer_about_to_leave.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** liquor store crowd
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a liquor-store loiterer sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic local leaning like they have been about to leave forever, no brand clothing. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 220 — `bg_extra_window_yeller_silhouette.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `64x48`
- **Priority:** `B`
- **Use cases:** liquor store/bar alley background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a silhouette yelling from behind window for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: shadowy figure behind barred window with open mouth shape, no detail, loop-ready. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 221 — `bg_extra_bridge_lawn_chair_guard.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** under bridge background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an under-bridge chair guardian sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic seated figure guarding a stolen lawn chair, shadowy concrete palette, not a fighter. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 222 — `bg_extra_bridge_shadow_listener.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** under bridge mood
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a quiet under-bridge listener sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic silhouette in hoodie-like layers but not threatening, listens to traffic, no real identity. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 223 — `bg_extra_bathroom_line_01.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** Gas-N-Go background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a gas station bathroom-line extra for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic annoyed person waiting with key object, fluorescent lighting, not a main character. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 224 — `bg_extra_sample_table_customer.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** Gas-N-Go/flea market
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake sample-table customer sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic cautious customer leaning away from sample table, comedic distrust, no clear character identity. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 225 — `bg_extra_raccoon_tiny_clipboard.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `32x32`
- **Priority:** `B`
- **Use cases:** Dumpster Alley background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny raccoon background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small raccoon with clipboard silhouette, cartoon non-realistic, loopable, readable at tiny size. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 226 — `bg_extra_raccoon_trash_carry.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `32x32`
- **Priority:** `B`
- **Use cases:** Dumpster Alley/under bridge
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny raccoon carrying trash sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small raccoon carrying a scrap, cute but grimy, no focus-stealing detail. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 227 — `bg_extra_rat_bettor_pair.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `32x24`
- **Priority:** `B`
- **Use cases:** Dumpster Alley gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a pair of tiny rat bettor sprites for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 32x24, transparent background unless the asset is explicitly a tile or panel. Asset details: two tiny rats facing each other over small scrap, comic background scale, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 228 — `bg_extra_parking_lot_griller.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** parking lot/encampment
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bad parking-lot griller sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic local near tiny grill, smoke, no real clothes branding, background only. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 229 — `bg_extra_cone_guardian.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** parking lot crowd
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a traffic-cone guardian spectator for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic person standing proudly near traffic cone, folded arms, absurd seriousness. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 230 — `bg_extra_encampment_argument_pair.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `96x80`
- **Priority:** `B`
- **Use cases:** encampment background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create two background fighters arguing silhouettes for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic non-roster silhouettes arguing at camp, no distinctive character props, low animation detail. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 231 — `bg_extra_encampment_cord_tripper.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `64x80`
- **Priority:** `B`
- **Use cases:** encampment gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a background person tripping over extension cord for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic slapstick silhouette, safe non-injury pose, not a fighter. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 232 — `bg_extra_canal_weather_watcher.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** drainage canal
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a storm watcher background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic person staring at clouds with cheap poncho, no military/law uniforms, not a main character. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 233 — `bg_extra_canal_cooler_floater.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `64x32`
- **Priority:** `B`
- **Use cases:** drainage canal gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a floating cooler background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: cooler floating in canal water, readable tiny prop animation, no brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 234 — `bg_extra_laundromat_sock_worshipper.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** laundromat gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a laundromat sock-shrine background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic odd local kneeling by missing sock shrine, comedic, not a playable fighter. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 235 — `bg_extra_laundromat_machine_kicker.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** laundromat background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a laundromat machine-kicker background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic figure kicking broken washer, loop-ready, no roster resemblance. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 236 — `bg_extra_flea_market_bootleg_vendor.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `64x80`
- **Priority:** `B`
- **Use cases:** flea market crowd
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bootleg vendor background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic flea market seller behind table, fake shirts as blank shapes, no real logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 237 — `bg_extra_flea_market_haggler.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** flea market background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a haggler background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic person dramatically bargaining, pointing finger, dusty market colors. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 238 — `bg_extra_bar_backdoor_smoker.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** bar alley background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bar alley smoker silhouette for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic silhouette near backdoor, no face detail, no real brand clothing. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 239 — `bg_extra_bar_crate_sitter.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** bar alley background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a crate sitter background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic person sitting on crate outside bar, unimpressed posture, no detail. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 240 — `bg_extra_tripp_crowd_sponsor_handler.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** Tripp arena background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sponsor handler background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic production person holding blank sponsor cards, panicked pose, no Tripp likeness. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 241 — `bg_extra_tripp_drone_operator.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** Tripp arena background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a drone operator background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic headset operator hunched over controller, no real logo headset, not Tripp. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 242 — `bg_extra_folding_table_referee_fake.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `56x80`
- **Priority:** `B`
- **Use cases:** campaign background
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake referee at folding table sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 56x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic official-looking person with clipboard but no real uniform/logo, comedic uncertainty. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 243 — `bg_extra_local_with_blank_sign.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** crowd reusable
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a crowd member holding blank sign for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic spectator with blank sign, leaves space for hand-pixeled jokes. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 244 — `bg_extra_confused_tourist_wrong_game.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** stage background gag
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a confused outsider background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic confused tourist-like figure with map, no real location names, not central. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 245 — `bg_extra_food_line_waiter.png`

- **Category:** `background_extra`
- **Recommended folder:** `art/background_extras/`
- **Suggested canvas:** `48x80`
- **Priority:** `B`
- **Use cases:** flea market/gas station
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a food-line background sprite for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x80, transparent background unless the asset is explicitly a tile or panel. Asset details: generic person waiting in line with plate/tray, no brand, skeptical expression. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Stage Specific Minor Dressing

## 246 — `stage_bus_stop_props_bent_sign_detail.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/bus_stop/props/`
- **Suggested canvas:** `64x96`
- **Priority:** `B`
- **Use cases:** bus_stop supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bus stop bent sign detail for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: generic bent bus stop sign with no town or agency name, sun-faded metal, route blocks unreadable, strong silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 247 — `stage_bus_stop_props_broken_bench_slats.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/bus_stop/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** bus_stop supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broken bench prop layer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: bus shelter bench with cracked slats, gum spots, one missing board, no real ads. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 248 — `stage_bus_stop_props_faded_route_board.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/bus_stop/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** bus_stop supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a faded route board prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: abstract transit map with fake colored lines and no real places, scratched plexiglass. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 249 — `stage_bus_stop_props_sacred_crate_marker.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/bus_stop/props/`
- **Suggested canvas:** `64x64`
- **Priority:** `B`
- **Use cases:** bus_stop supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a milk crate throne marker prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: blue crate with tiny chalk circle around it, absurd ceremonial vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 250 — `stage_bus_stop_anim_heat_birds.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/bus_stop/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** bus_stop supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny background birds/heat loop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny bird silhouettes and heat shimmer marks for harsh sun, low distraction. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 251 — `stage_liquor_store_props_ice_machine_taped.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/liquor_store/props/`
- **Suggested canvas:** `96x96`
- **Priority:** `B`
- **Use cases:** liquor_store supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a taped ice machine prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: white outdoor ice machine with duct tape, blank label area, grime, no real brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 252 — `stage_liquor_store_props_barred_window_insert.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/liquor_store/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** liquor_store supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a barred window insert for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: storefront window with metal bars, warm neon glow, fake poster blocks behind glass. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 253 — `stage_liquor_store_props_security_camera_wrong_way.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/liquor_store/props/`
- **Suggested canvas:** `48x48`
- **Priority:** `B`
- **Use cases:** liquor_store supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a wrong-way security camera prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 48x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small camera pointed away from action, no logo, comic uselessness. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 254 — `stage_liquor_store_props_fake_lottery_poster.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/liquor_store/props/`
- **Suggested canvas:** `64x96`
- **Priority:** `B`
- **Use cases:** liquor_store supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake lottery poster for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: bright fake poster with abstract symbols and blank prize blocks, no real lottery branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 255 — `stage_liquor_store_anim_neon_open_nope.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/liquor_store/props/`
- **Suggested canvas:** `96x48`
- **Priority:** `B`
- **Use cases:** liquor_store supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a flickering neon sign animation base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x48, transparent background unless the asset is explicitly a tile or panel. Asset details: two-frame-ready OPEN/NOPE concept sign, magenta/cyan glow, no business name. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 256 — `stage_under_bridge_props_stolen_couch.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/under_the_bridge/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** under_the_bridge supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a stolen couch prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: old sagging couch under bridge, torn fabric, no foreground clutter, readable silhouette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 257 — `stage_under_bridge_props_chalk_arrows_wall.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/under_the_bridge/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** under_the_bridge supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a chalk arrows wall decal for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: concrete wall marks and arrows that imply local rules, no real symbols/gangs. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 258 — `stage_under_bridge_props_drainage_culvert_eyes.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/under_the_bridge/props/`
- **Suggested canvas:** `96x64`
- **Priority:** `B`
- **Use cases:** under_the_bridge supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a culvert with tiny eyes prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: dark drainage opening with small raccoon eye pairs, subtle and funny. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 259 — `stage_under_bridge_props_reserved_chair.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/under_the_bridge/props/`
- **Suggested canvas:** `64x80`
- **Priority:** `B`
- **Use cases:** under_the_bridge supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a reserved lawn chair prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x80, transparent background unless the asset is explicitly a tile or panel. Asset details: weathered chair with tiny reserved tag, local-ritual vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 260 — `stage_under_bridge_anim_traffic_light_streaks.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/under_the_bridge/props/`
- **Suggested canvas:** `160x48`
- **Priority:** `B`
- **Use cases:** under_the_bridge supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create overhead traffic light streak layer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x48, transparent background unless the asset is explicitly a tile or panel. Asset details: horizontal orange/white light streaks from traffic above, loopable, low distraction. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 261 — `stage_gas_n_go_props_pump_nozzle_blank.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/gas_n_go/props/`
- **Suggested canvas:** `64x96`
- **Priority:** `B`
- **Use cases:** gas_n_go supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fuel pump nozzle prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: generic fuel pump nozzle/hose detail, no brand, greasy highlights, background only. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 262 — `stage_gas_n_go_props_roller_food_window.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/gas_n_go/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** gas_n_go supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a roller food window prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: store window showing hot food rollers, greasy glow, no real chain references. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 263 — `stage_gas_n_go_props_bathroom_key_absurd.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/gas_n_go/props/`
- **Suggested canvas:** `64x64`
- **Priority:** `B`
- **Use cases:** gas_n_go supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create an absurd bathroom key prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: oversized bathroom key attached to ridiculous object silhouette, no text needed. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 264 — `stage_gas_n_go_props_sample_table_blank.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/gas_n_go/props/`
- **Suggested canvas:** `128x80`
- **Priority:** `B`
- **Use cases:** gas_n_go supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a product sample table prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x80, transparent background unless the asset is explicitly a tile or panel. Asset details: folding table with blank sample trays and fake product cards, no real brands. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 265 — `stage_gas_n_go_anim_pump_beep_lights.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/gas_n_go/props/`
- **Suggested canvas:** `64x32`
- **Priority:** `B`
- **Use cases:** gas_n_go supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create small pump beep light loop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x32, transparent background unless the asset is explicitly a tile or panel. Asset details: tiny red/green pump indicator lights, loopable UI-like stage detail. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 266 — `stage_dumpster_alley_props_trash_throne.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/dumpster_alley/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** dumpster_alley supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a trash throne prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: improvised throne of crates, bags, and scrap crown, no character present. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 267 — `stage_dumpster_alley_props_leaking_pipe.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/dumpster_alley/props/`
- **Suggested canvas:** `64x96`
- **Priority:** `B`
- **Use cases:** dumpster_alley supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a leaking pipe prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: rusty pipe with greenish drip and wall stain, loop-ready drip points. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 268 — `stage_dumpster_alley_props_border_spray_line.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/dumpster_alley/props/`
- **Suggested canvas:** `128x32`
- **Priority:** `B`
- **Use cases:** dumpster_alley supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a spray-painted border line prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: rough territory line and arrows, no real gang symbols, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 269 — `stage_dumpster_alley_props_stolen_merch_box.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/dumpster_alley/props/`
- **Suggested canvas:** `80x64`
- **Priority:** `B`
- **Use cases:** dumpster_alley supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a stolen merch box prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x64, transparent background unless the asset is explicitly a tile or panel. Asset details: cardboard box full of blank bootleg shirts, crossed-out fake tag shapes. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 270 — `stage_dumpster_alley_anim_raccoon_parade.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/dumpster_alley/props/`
- **Suggested canvas:** `128x32`
- **Priority:** `B`
- **Use cases:** dumpster_alley supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny raccoon parade animation strip for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: three small raccoons walking in a line, low detail, background scale. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 271 — `stage_parking_lot_props_broom_banner_pole.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/parking_lot/props/`
- **Suggested canvas:** `64x96`
- **Priority:** `B`
- **Use cases:** parking_lot supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broom banner pole prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: broom handle holding a cheap event banner corner, taped together, no text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 272 — `stage_parking_lot_props_scooter_memorial.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/parking_lot/props/`
- **Suggested canvas:** `128x80`
- **Priority:** `B`
- **Use cases:** parking_lot supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a scooter-parts memorial prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x80, transparent background unless the asset is explicitly a tile or panel. Asset details: small arrangement of busted scooter parts and candle-like pixels, comic not solemn. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 273 — `stage_parking_lot_props_cooler_nachos.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/parking_lot/props/`
- **Suggested canvas:** `96x64`
- **Priority:** `B`
- **Use cases:** parking_lot supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cooler nachos vendor prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: cooler with snack tray, greasy orange/yellow details, no brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 274 — `stage_parking_lot_props_faded_lines_chunk.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/parking_lot/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** parking_lot supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a faded parking line chunk for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: paint stripe chunk with tire marks and cracks, transparent edges. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 275 — `stage_parking_lot_anim_scooter_backfire_puff.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/parking_lot/props/`
- **Suggested canvas:** `64x48`
- **Priority:** `B`
- **Use cases:** parking_lot supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a scooter backfire puff animation base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: small smoke/flame puff for background gag, controlled size. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 276 — `stage_encampment_props_bracket_board_wrong.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/encampment/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** encampment supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a wrong bracket board prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: folding strategy board labeled with arrows/blank blocks, intentionally confusing, no real names. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 277 — `stage_encampment_props_repair_table.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/encampment/props/`
- **Suggested canvas:** `128x80`
- **Priority:** `B`
- **Use cases:** encampment supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a repair table prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x80, transparent background unless the asset is explicitly a tile or panel. Asset details: folding table with tools, tape, cables, and junk, no character-specific final gear. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 278 — `stage_encampment_props_tarp_shelter_corner.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/encampment/props/`
- **Suggested canvas:** `160x96`
- **Priority:** `B`
- **Use cases:** encampment supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tarp shelter corner layer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x96, transparent background unless the asset is explicitly a tile or panel. Asset details: blue tarp corner with ropes, stakes, warm camp light, no people. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 279 — `stage_encampment_props_bad_food_station.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/encampment/props/`
- **Suggested canvas:** `128x80`
- **Priority:** `B`
- **Use cases:** encampment supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bad food station prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x80, transparent background unless the asset is explicitly a tile or panel. Asset details: small grill/cooler/table combo, suspicious steam, fictional labels only. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 280 — `stage_encampment_anim_string_lights.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/encampment/props/`
- **Suggested canvas:** `160x32`
- **Priority:** `B`
- **Use cases:** encampment supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a string-light animation strip for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x32, transparent background unless the asset is explicitly a tile or panel. Asset details: warm bulbs on drooping cord, loop-ready subtle flicker. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 281 — `stage_drainage_canal_props_warning_sign.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/drainage_canal/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** drainage_canal supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a canal warning sign prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: fictional warning sign with storm icon and blank text blocks, no agency logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 282 — `stage_drainage_canal_props_runoff_pipe.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/drainage_canal/props/`
- **Suggested canvas:** `96x96`
- **Priority:** `B`
- **Use cases:** drainage_canal supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a runoff pipe prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: round concrete pipe opening with dark interior and water drip, background layer. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 283 — `stage_drainage_canal_props_floating_debris.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/drainage_canal/props/`
- **Suggested canvas:** `128x32`
- **Priority:** `B`
- **Use cases:** drainage_canal supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create floating debris prop strip for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: small debris pieces floating along water layer, no recognizable brands. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 284 — `stage_drainage_canal_props_emergency_tarp_shrine.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/drainage_canal/props/`
- **Suggested canvas:** `96x80`
- **Priority:** `B`
- **Use cases:** drainage_canal supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a storm-prep supply shrine prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x80, transparent background unless the asset is explicitly a tile or panel. Asset details: tarp, sandbags, flashlight shapes arranged oddly, no character present. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 285 — `stage_drainage_canal_anim_lightning_far.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/drainage_canal/props/`
- **Suggested canvas:** `160x96`
- **Priority:** `B`
- **Use cases:** drainage_canal supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create distant lightning layer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x96, transparent background unless the asset is explicitly a tile or panel. Asset details: small distant lightning forks behind storm clouds, accessibility-friendly and non-flashing as static frame. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 286 — `stage_laundromat_props_broken_washer.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/laundromat/props/`
- **Suggested canvas:** `96x96`
- **Priority:** `B`
- **Use cases:** laundromat supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broken washer prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: front-load washer with cracked round door, no real appliance brand, buzzing fluorescent palette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 287 — `stage_laundromat_props_soap_vending_blank.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/laundromat/props/`
- **Suggested canvas:** `64x96`
- **Priority:** `B`
- **Use cases:** laundromat supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a blank soap vending machine prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x96, transparent background unless the asset is explicitly a tile or panel. Asset details: generic vending machine for soap boxes, blank labels, no real products. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 288 — `stage_laundromat_props_folding_table_tile.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/laundromat/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** laundromat supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a folding table prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: laundromat folding table with worn tile reflection and scattered socks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 289 — `stage_laundromat_props_missing_sock_board.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/laundromat/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** laundromat supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a missing sock board prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: notice board with sock silhouettes, blank notes, absurd shrine energy. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 290 — `stage_laundromat_anim_machine_shake.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/laundromat/props/`
- **Suggested canvas:** `96x96`
- **Priority:** `B`
- **Use cases:** laundromat supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a washer shake animation base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x96, transparent background unless the asset is explicitly a tile or panel. Asset details: two-frame-ready broken washer shaking, safe readable movement. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 291 — `stage_flea_market_props_bootleg_shirt_table.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/flea_market/props/`
- **Suggested canvas:** `128x80`
- **Priority:** `B`
- **Use cases:** flea_market supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bootleg shirt table prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x80, transparent background unless the asset is explicitly a tile or panel. Asset details: folding table with blank colorful shirts, no real logos or copyrighted images. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 292 — `stage_flea_market_props_tarp_booth_corner.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/flea_market/props/`
- **Suggested canvas:** `160x96`
- **Priority:** `B`
- **Use cases:** flea_market supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tarp booth corner layer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x96, transparent background unless the asset is explicitly a tile or panel. Asset details: dusty colorful tarp shade, poles, ropes, no storefront brand. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 293 — `stage_flea_market_props_illegal_trophy_display.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/flea_market/props/`
- **Suggested canvas:** `96x80`
- **Priority:** `B`
- **Use cases:** flea_market supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a suspicious trophy display prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x80, transparent background unless the asset is explicitly a tile or panel. Asset details: weird trophies with blank plaques and crooked stands, no official logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 294 — `stage_flea_market_props_broken_electronics_box.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/flea_market/props/`
- **Suggested canvas:** `96x64`
- **Priority:** `B`
- **Use cases:** flea_market supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a broken electronics box prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: box of cables, old remotes, cracked devices, no brands. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 295 — `stage_flea_market_anim_cash_haggle_hands.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/flea_market/props/`
- **Suggested canvas:** `64x48`
- **Priority:** `B`
- **Use cases:** flea_market supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a tiny haggling hands animation base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x48, transparent background unless the asset is explicitly a tile or panel. Asset details: two hands exchanging fake bills over table, background-scale sprite. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 296 — `stage_alley_behind_bar_props_crate_stack.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/alley_behind_the_bar/props/`
- **Suggested canvas:** `96x80`
- **Priority:** `B`
- **Use cases:** alley_behind_the_bar supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a sticky crate stack prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x80, transparent background unless the asset is explicitly a tile or panel. Asset details: stacked blank beverage crates with no logos, neon spill, dirty alley grime. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 297 — `stage_alley_behind_bar_props_backdoor_glow.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/alley_behind_the_bar/props/`
- **Suggested canvas:** `96x128`
- **Priority:** `B`
- **Use cases:** alley_behind_the_bar supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a glowing backdoor prop layer for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x128, transparent background unless the asset is explicitly a tile or panel. Asset details: bar backdoor with warm light leaking, no real bar name, sticky pavement reflection. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 298 — `stage_alley_behind_bar_props_bottle_bin.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/alley_behind_the_bar/props/`
- **Suggested canvas:** `80x64`
- **Priority:** `B`
- **Use cases:** alley_behind_the_bar supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a bottle bin prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 80x64, transparent background unless the asset is explicitly a tile or panel. Asset details: overflowing bin of blank bottles, safe stylized glass, no labels. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 299 — `stage_alley_behind_bar_props_karaoke_sign_dead.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/alley_behind_the_bar/props/`
- **Suggested canvas:** `128x64`
- **Priority:** `B`
- **Use cases:** alley_behind_the_bar supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a dead karaoke sign prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x64, transparent background unless the asset is explicitly a tile or panel. Asset details: flickering fictional karaoke sign, no real establishment name. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 300 — `stage_alley_behind_bar_anim_neon_drip_reflect.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/alley_behind_the_bar/props/`
- **Suggested canvas:** `128x32`
- **Priority:** `B`
- **Use cases:** alley_behind_the_bar supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a neon drip reflection strip for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x32, transparent background unless the asset is explicitly a tile or panel. Asset details: wet pavement reflection of neon as shimmering pixel streaks. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 301 — `stage_tripps_livestream_arena_props_led_wall_tile.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/tripps_livestream_arena/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** tripps_livestream_arena supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a generic LED wall tile for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: modular LED panel with abstract fake sponsor blocks, red/blue glare, no logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 302 — `stage_tripps_livestream_arena_props_ring_light_cluster.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/tripps_livestream_arena/props/`
- **Suggested canvas:** `128x96`
- **Priority:** `B`
- **Use cases:** tripps_livestream_arena supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a cluster of ring lights for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x96, transparent background unless the asset is explicitly a tile or panel. Asset details: multiple cheap ring lights on stands, tangled cables, expensive-and-pathetic vibe. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 303 — `stage_tripps_livestream_arena_props_subscriber_counter.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/tripps_livestream_arena/props/`
- **Suggested canvas:** `128x48`
- **Priority:** `B`
- **Use cases:** tripps_livestream_arena supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a subscriber counter panel for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 128x48, transparent background unless the asset is explicitly a tile or panel. Asset details: digital counter with block numbers, downward arrow space, no platform branding. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 304 — `stage_tripps_livestream_arena_props_exposed_cables.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/tripps_livestream_arena/props/`
- **Suggested canvas:** `160x64`
- **Priority:** `B`
- **Use cases:** tripps_livestream_arena supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create exposed cable mess prop for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: mess of black/orange cables crossing floor edge, safe background/foreground strip, no collision implied. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 305 — `stage_tripps_livestream_arena_anim_sponsor_banner_peel.png`

- **Category:** `stage_specific_minor_dressing`
- **Recommended folder:** `art/stages/tripps_livestream_arena/props/`
- **Suggested canvas:** `160x64`
- **Priority:** `B`
- **Use cases:** tripps_livestream_arena supporting dressing, not a full stage or level
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a peeling sponsor banner animation base for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 160x64, transparent background unless the asset is explicitly a tile or panel. Asset details: cheap fake sponsor banner peeling from wall, blank logo zones, loop-ready. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

# Production Helper Icon

## 306 — `icon_asset_placeholder_missing.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** dev placeholder
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a missing asset placeholder icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: chunky warning placeholder with cracked checkerboard center and fake tape, no real logos. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 307 — `icon_palette_test_swatch_card.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `96x64`
- **Priority:** `C`
- **Use cases:** art QA
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a palette test swatch card for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 96x64, transparent background unless the asset is explicitly a tile or panel. Asset details: small card with dirty yellow, neon, asphalt, swamp sample blocks, no text. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 308 — `icon_grayscale_readability_check.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** QA tool UI
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a grayscale readability check icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: simple eye/checker icon in grayscale, useful for art checklist UI. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 309 — `icon_folder_fake_sponsors.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** asset tracker
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a fake sponsors folder icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: folder icon with sticker-like blank ad bug, grimy yellow/red. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 310 — `icon_folder_vfx.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** asset tracker
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a VFX folder icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: folder icon with tiny impact spark and dust symbols, orange/white. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 311 — `icon_folder_ui.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** asset tracker
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a UI folder icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: folder icon with tiny HUD bars, arcade cabinet grime. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 312 — `icon_folder_props.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** asset tracker
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a props folder icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: folder icon with tiny cone/crate shapes, dirty orange/blue. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 313 — `icon_folder_decals.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** asset tracker
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a decals folder icon for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: folder icon with crack/stain symbols, gray/green palette. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 314 — `icon_batch_done_sticker.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** production tracking
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a batch complete sticker for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: round sticker badge reading concept DONE or checkmark, scuffed edge, dirty gold. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

## 315 — `icon_batch_review_sticker.png`

- **Category:** `production_helper_icon`
- **Recommended folder:** `art/ui/icons/`
- **Suggested canvas:** `64x64`
- **Priority:** `C`
- **Use cases:** production tracking
- **Production note:** Use as AI concept/reference first, then clean up to match the final pixel scale and palette.

**Prompt:**

```text
Create a review needed sticker for Sidewalk Showdown. Style and rules: Sidewalk Showdown, fictional Sidewalk Florida, Mature-rated retro 2D arcade fighting game, 8-bit / 16-bit-inspired pixel art, chunky readable shapes, bold dark outline, no anti-aliasing, nearest-neighbor style, grimy sunbaked asphalt, dirty neon, sticky convenience-store color, raunchy arcade-comedy attitude, visually funny but combat-readable, transparent PNG unless noted, no real brands, no real town names, no real logos, no real public figures, no copyrighted characters, not photorealistic, not clean superhero art, not fantasy armor, not final character or full level art. Canvas/output: 64x64, transparent background unless the asset is explicitly a tile or panel. Asset details: round sticker badge with eye/check icon and red mark, not harsh, transparent. Keep the silhouette readable at small game scale. Leave any complex written text as blocky fake markings or blank space for hand-pixeling if needed.
```

**Negative prompt:**

```text
no real logos, no recognizable brand labels, no real city names, no copyrighted mascots, no photorealism, no smooth vector art, no anime glamor, no fantasy armor, no full character design, no full stage background unless the asset type explicitly says layer, no gore, no readable slurs, no tiny unreadable clutter that would obscure fighters, no foreground blocking active combat space
```

---

## Final Review Checklist

Before importing any generated result into the repo:

- filename remains lowercase snake_case
- no real brand/logo/town/person slipped in
- silhouette reads at small size
- pixel scale can be cleaned consistently
- asset does not define or contradict final characters/levels
- asset supports combat readability
- source and runtime exports stay separate
