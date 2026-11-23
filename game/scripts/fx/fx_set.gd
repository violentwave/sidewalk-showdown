# FxSet — one fighter's presentation FX sheets (docs/FX_AND_METH_DESIGN.md §2).
#
# Referenced by FighterData.fx_set so the FX layer resolves a fighter's
# sheets from data, never from hardcoded paths: a future fighter plugs in by
# authoring its own FxSet .tres. Null fx_set simply means no hit FX — the
# engine's combat behavior is unchanged either way (presentation only).
#
# Kinds follow the design's precedence EX > counter > special/launcher >
# heavy > light, with block as the subdued blocked-contact set and the two
# startup-attached streaks (heavy whoosh, special trail).
class_name FxSet
extends Resource

@export_group("Contact (one primary impact per contact)")
@export var hit_light: FxSheetDef
@export var hit_heavy: FxSheetDef
@export var hit_counter: FxSheetDef
@export var block: FxSheetDef
@export var special_hit: FxSheetDef
@export var ex_hit: FxSheetDef

@export_group("Startup-attached (follow the attacker)")
@export var heavy_whoosh: FxSheetDef
@export var special_trail: FxSheetDef

@export_group("Shared environment")
# Landing/knockdown/wall dust: the same sheet for every fighter today, kept
# here so the spawn path stays pure data.
@export var landing_dust: FxSheetDef
