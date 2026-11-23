# FxSheetDef — one FX sheet reference plus its playback metadata
# (docs/FX_AND_METH_DESIGN.md §2). Pure presentation data: the runtime art
# under game/art/fx/ is copied byte-identical from art/source/FX/ by
# art/tools/prepare_fx.sh, which validates these values against
# fx_manifest.json / props_manifest.json.
class_name FxSheetDef
extends Resource

# res:// path of the runtime sheet PNG (frames laid out horizontally).
@export var texture_path: String = ""
# Cels in the sheet; drives Sprite2D.hframes and the one-shot lifetime.
@export var frames: int = 1
# Sim ticks each cel is held; one-shots freeze in hitstop and pause because
# they advance only on the match's sim clock.
@export var ticks_per_frame: int = 2
# Native cell size in pixels; the sprite is never scaled in engine.
@export var cell: Vector2i = Vector2i(32, 32)
# Directional sheets (whooshes, trails, forward bursts) mirror with the
# attacker's facing; radial bursts (light/heavy/counter/block) do not
# (design §1.5).
@export var mirror: bool = false


func valid() -> bool:
	return not texture_path.is_empty() and frames > 0 \
		and ticks_per_frame > 0 and cell.x > 0 and cell.y > 0
