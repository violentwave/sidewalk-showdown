# RichardClipLibrary — data-driven presentation-clip table for Whiskey Richard.
#
# GENERATED source of truth for the prepared clips: the table below mirrors
# art/source/Characters/Animations/generated/full_animation_batch_01/
# richard_prepared/richard_clips_manifest.json, produced by
# art/tools/prepare_richard_batch.py (component-based slicing; policy
# documented there). Only Richard resolves entries here; Peggy uses
# PeggyClipLibrary and every other fighter keeps the idle/fallback path.
#
# Per-clip fields:
#   path      runtime texture (res:// under game/art/characters/whiskey_richard/)
#   frames    cel count; cel size is texture size / frames horizontally
#   anchor    in-cel feet root (px) mapped onto the fighter origin
#   h_ref     source pixels that equal the standing reference height; the
#             renderer scales the cel by SILHOUETTE_HEIGHT / h_ref. Richard's
#             draft sheets are drawn at different art scales, so h_ref was
#             measured per sheet from the bandana (rigid feature) rather than
#             snapped to 74, keeping native pixels with no resampling.
#   enabled   false = prepared but gated off / unmapped; the resolver treats
#             it as missing and the approved fallback plays
class_name RichardClipLibrary
extends RefCounted

const STANDING_REFERENCE_H_REF := 74.0

const CLIPS := {
	"air": {"path": "res://art/characters/whiskey_richard/clips/air.png", "frames": 6, "anchor": Vector2(45, 96), "h_ref": 71.0, "enabled": true},
	"back": {"path": "res://art/characters/whiskey_richard/clips/back.png", "frames": 6, "anchor": Vector2(31, 59), "h_ref": 60.0, "enabled": true},
	"block_crouch": {"path": "res://art/characters/whiskey_richard/clips/block_crouch.png", "frames": 2, "anchor": Vector2(36, 76), "h_ref": 71.0, "enabled": true},
	"block_stand": {"path": "res://art/characters/whiskey_richard/clips/block_stand.png", "frames": 2, "anchor": Vector2(40, 75), "h_ref": 74.0, "enabled": true},
	"blockstun_crouch": {"path": "res://art/characters/whiskey_richard/clips/blockstun_crouch.png", "frames": 2, "anchor": Vector2(43, 75), "h_ref": 74.0, "enabled": true},
	"blockstun_stand": {"path": "res://art/characters/whiskey_richard/clips/blockstun_stand.png", "frames": 2, "anchor": Vector2(43, 75), "h_ref": 74.0, "enabled": true},
	"command_grab": {"path": "res://art/characters/whiskey_richard/clips/command_grab.png", "frames": 6, "anchor": Vector2(32, 59), "h_ref": 53.0, "enabled": true},
	"crouch_down": {"path": "res://art/characters/whiskey_richard/clips/crouch_down.png", "frames": 3, "anchor": Vector2(44, 83), "h_ref": 74.0, "enabled": true},
	"crouch_heavy": {"path": "res://art/characters/whiskey_richard/clips/crouch_heavy.png", "frames": 6, "anchor": Vector2(32, 58), "h_ref": 57.0, "enabled": true},
	"crouch_hold": {"path": "res://art/characters/whiskey_richard/clips/crouch_hold.png", "frames": 2, "anchor": Vector2(43, 75), "h_ref": 74.0, "enabled": true},
	"crouch_light": {"path": "res://art/characters/whiskey_richard/clips/crouch_light.png", "frames": 6, "anchor": Vector2(34, 65), "h_ref": 59.0, "enabled": true},
	"crouch_up": {"path": "res://art/characters/whiskey_richard/clips/crouch_up.png", "frames": 3, "anchor": Vector2(39, 89), "h_ref": 74.0, "enabled": true},
	"down": {"path": "res://art/characters/whiskey_richard/clips/down.png", "frames": 6, "anchor": Vector2(29, 55), "h_ref": 50.0, "enabled": true},
	"forward": {"path": "res://art/characters/whiskey_richard/clips/forward.png", "frames": 6, "anchor": Vector2(34, 82), "h_ref": 72.0, "enabled": true},
	"forward_ex": {"path": "res://art/characters/whiskey_richard/clips/forward_ex.png", "frames": 6, "anchor": Vector2(34, 101), "h_ref": 75.0, "enabled": true},
	"grab": {"path": "res://art/characters/whiskey_richard/clips/grab.png", "frames": 6, "anchor": Vector2(39, 60), "h_ref": 62.0, "enabled": true},
	"heavy": {"path": "res://art/characters/whiskey_richard/clips/heavy.png", "frames": 5, "anchor": Vector2(38, 79), "h_ref": 70.0, "enabled": true},
	"hitstun_air": {"path": "res://art/characters/whiskey_richard/clips/hitstun_air.png", "frames": 3, "anchor": Vector2(49, 92), "h_ref": 74.0, "enabled": true},
	"hitstun_crouch": {"path": "res://art/characters/whiskey_richard/clips/hitstun_crouch.png", "frames": 3, "anchor": Vector2(41, 79), "h_ref": 68.0, "enabled": true},
	"hitstun_stand": {"path": "res://art/characters/whiskey_richard/clips/hitstun_stand.png", "frames": 3, "anchor": Vector2(43, 82), "h_ref": 73.0, "enabled": true},
	"jump_fall": {"path": "res://art/characters/whiskey_richard/clips/jump_fall.png", "frames": 2, "anchor": Vector2(51, 94), "h_ref": 71.0, "enabled": true},
	"jump_heavy": {"path": "res://art/characters/whiskey_richard/clips/jump_heavy.png", "frames": 6, "anchor": Vector2(34, 98), "h_ref": 70.0, "enabled": true},
	"jump_light": {"path": "res://art/characters/whiskey_richard/clips/jump_light.png", "frames": 6, "anchor": Vector2(38, 79), "h_ref": 65.0, "enabled": true},
	"jump_rise": {"path": "res://art/characters/whiskey_richard/clips/jump_rise.png", "frames": 2, "anchor": Vector2(51, 99), "h_ref": 74.0, "enabled": true},
	"jump_start": {"path": "res://art/characters/whiskey_richard/clips/jump_start.png", "frames": 2, "anchor": Vector2(52, 98), "h_ref": 74.0, "enabled": true},
	"knockdown": {"path": "res://art/characters/whiskey_richard/clips/knockdown.png", "frames": 4, "anchor": Vector2(38, 73), "h_ref": 63.0, "enabled": true},
	"ko_air": {"path": "res://art/characters/whiskey_richard/clips/ko_air.png", "frames": 3, "anchor": Vector2(48, 92), "h_ref": 67.0, "enabled": true},
	"ko_ground": {"path": "res://art/characters/whiskey_richard/clips/ko_ground.png", "frames": 3, "anchor": Vector2(44, 81), "h_ref": 74.0, "enabled": true},
	"land": {"path": "res://art/characters/whiskey_richard/clips/land.png", "frames": 3, "anchor": Vector2(43, 84), "h_ref": 81.0, "enabled": true},
	"light": {"path": "res://art/characters/whiskey_richard/clips/light.png", "frames": 5, "anchor": Vector2(42, 76), "h_ref": 74.0, "enabled": true},
	"meth": {"path": "res://art/characters/whiskey_richard/clips/meth.png", "frames": 6, "anchor": Vector2(29, 58), "h_ref": 56.0, "enabled": true},
	"neutral": {"path": "res://art/characters/whiskey_richard/clips/neutral.png", "frames": 6, "anchor": Vector2(32, 60), "h_ref": 58.0, "enabled": true},
	"neutral_ex": {"path": "res://art/characters/whiskey_richard/clips/neutral_ex.png", "frames": 5, "anchor": Vector2(39, 75), "h_ref": 73.0, "enabled": true},
	"stage_intro": {"path": "res://art/characters/whiskey_richard/clips/stage_intro.png", "frames": 4, "anchor": Vector2(40, 81), "h_ref": 73.0, "enabled": false},
	"throw_target": {"path": "res://art/characters/whiskey_richard/clips/throw_target.png", "frames": 3, "anchor": Vector2(47, 79), "h_ref": 51.0, "enabled": false},
	"throw_tech": {"path": "res://art/characters/whiskey_richard/clips/throw_tech.png", "frames": 3, "anchor": Vector2(47, 75), "h_ref": 74.0, "enabled": true},
	"wake_up": {"path": "res://art/characters/whiskey_richard/clips/wake_up.png", "frames": 4, "anchor": Vector2(42, 74), "h_ref": 73.0, "enabled": true},
	"walk_backward": {"path": "res://art/characters/whiskey_richard/clips/walk_backward.png", "frames": 6, "anchor": Vector2(33, 72), "h_ref": 65.0, "enabled": true},
	"walk_forward": {"path": "res://art/characters/whiskey_richard/clips/walk_forward.png", "frames": 6, "anchor": Vector2(43, 81), "h_ref": 78.0, "enabled": true},
	"win": {"path": "res://art/characters/whiskey_richard/clips/win.png", "frames": 4, "anchor": Vector2(35, 75), "h_ref": 74.0, "enabled": true},
}

# MoveData.id -> clip key. Verified against game/resources/fighters/whiskey_richard.tres.
const MOVE_CLIPS := {
	"light": "light",
	"heavy": "heavy",
	"crouch_light": "crouch_light",
	"crouch_heavy": "crouch_heavy",
	"jump_light": "jump_light",
	"jump_heavy": "jump_heavy",
	"richard_neutral": "neutral",
	"richard_forward": "forward",
	"richard_down": "down",
	"richard_back": "back",
	"richard_air": "air",
	"grab": "grab",
	"richard_command_grab": "command_grab",
	"richard_neutral_ex": "neutral_ex",
	"richard_forward_ex": "forward_ex",
	"richard_meth": "meth",
}

# State -> clip keys (context resolved by FighterBase). Lists are tried in
# order so the first valid/enabled clip wins. `crouch_down` is prepared but
# has no dedicated crouch-entry state (crouch is instant), so it stays unmapped
# exactly like the approved fallback path.
const STATE_CLIPS := {
	"walk_f": ["walk_forward"],
	"walk_b": ["walk_backward"],
	"crouch": ["crouch_hold"],
	"jump_start": ["jump_start"],
	"jump_rise": ["jump_rise"],
	"jump_fall": ["jump_fall"],
	"land": ["land"],
	"block_stand": ["block_stand"],
	"block_crouch": ["block_crouch"],
	"hitstun_stand": ["hitstun_stand"],
	"hitstun_crouch": ["hitstun_crouch"],
	"hitstun_air": ["hitstun_air"],
	"blockstun_stand": ["blockstun_stand"],
	"blockstun_crouch": ["blockstun_crouch"],
	"knockdown": ["knockdown"],
	"wake_up": ["wake_up"],
	"tech": ["throw_tech"],
	"ko_air": ["ko_air"],
	"ko_ground": ["ko_ground"],
	"win": ["win"],
	"crouch_up_transient": ["crouch_up"],
}

# Presentation cadence (sim ticks per cel) for state clips whose length is not
# bound to an authored duration. Holds loop; one-shots hold their last cel.
const LOOP_CEL_TICKS := {"crouch": 12, "win": 9, "block_stand": 10, "block_crouch": 10, "blockstun_stand": 10, "blockstun_crouch": 10, "crouch_up": 5, "walk_f": 6, "walk_b": 6}
const ONESHOT_CEL_TICKS := {"jump_start": 1, "jump_rise": 5, "jump_fall": 5, "ko_air": 10, "ko_ground": 12}

# Draft-strip playback order, applied by the renderer instead of the default
# 0..frames-1 sequence. Two draft sheets are ordered for a previous pose (or
# include the touchdown absorb): `jump_fall` ends on the crouched landing cel,
# which reads as "standing in mid-air" when played during the descent, so the
# airborne cel is held for the whole fall; `land` starts with the upright cel
# and only then the absorb, so the two-cel landing state is re-ordered to
# absorb-then-recover. Presentation only: sim timing/boxes are untouched.
const PLAY_CELS := {
	"jump_fall": [0],
	"land": [1, 2],
}

# Richard owns authored guard poses; the renderer shows them while holding back
# stationary (pinned at a wall) or crouch-blocking. Set false to fall back to
# the walk/crouch clips for those moments.
const GUARD_POSE := true


static func has_clips(fighter_id: String) -> bool:
	return fighter_id == "whiskey_richard"


static func clip(key: String) -> Dictionary:
	var c: Dictionary = CLIPS.get(key, {})
	if c.is_empty() or not c.get("enabled", false):
		return {}
	if PLAY_CELS.has(key):
		# Copy so the shared CLIPS table is never mutated by the extra field.
		var out: Dictionary = c.duplicate()
		out["cels"] = PLAY_CELS[key]
		return out
	return c


static func move_clip(move_id: String) -> Dictionary:
	return clip(str(MOVE_CLIPS.get(move_id, "")))


static func state_clip(state_key: String) -> Dictionary:
	for key in STATE_CLIPS.get(state_key, []):
		var c := clip(str(key))
		if not c.is_empty():
			return c
	return {}
