# PeggyClipLibrary — data-driven presentation-clip table for Peg-Leg Peggy.
#
# GENERATED source of truth for the prepared clips: the table below mirrors
# art/source/Characters/Animations/generated/full_animation_batch_01/
# peggy_prepared/peggy_clips_manifest.json, produced by
# art/tools/prepare_peggy_batch.py (slicing/masking/anchor policy is documented
# there). Peggy uses this table; Richard has his own generated table
# (richard_clip_library.gd), and every fighter without a set keeps the
# approved idle/fallback path untouched.
#
# Per-clip fields:
#   path      runtime texture (res:// under game/art/characters/peg_leg_peggy/)
#   frames    cel count; cel size is texture size / frames horizontally
#   anchor    in-cel feet root (px) mapped onto the fighter origin
#   h_ref     source pixels that equal the standing reference height; the
#             renderer scales the cel by SILHOUETTE_HEIGHT / h_ref so every
#             clip matches the approved idle art's on-screen height with no
#             pixel resampling and no size jump
#   enabled   false = prepared but gated off pending owner review; the
#             resolver treats it as missing and the approved fallback plays
class_name PeggyClipLibrary
extends RefCounted

const STANDING_REFERENCE_H_REF := 74.0

const CLIPS := {
	"air": {"path": "res://art/characters/peg_leg_peggy/clips/air.png", "frames": 6, "anchor": Vector2(37, 86), "h_ref": 74.0, "enabled": true},
	"back": {"path": "res://art/characters/peg_leg_peggy/clips/back.png", "frames": 6, "anchor": Vector2(28, 76), "h_ref": 73.0, "enabled": true},
	"block_crouch": {"path": "res://art/characters/peg_leg_peggy/clips/block_crouch.png", "frames": 3, "anchor": Vector2(31, 89), "h_ref": 74.0, "enabled": true},
	"block_stand": {"path": "res://art/characters/peg_leg_peggy/clips/block_stand.png", "frames": 2, "anchor": Vector2(43, 116), "h_ref": 107.0, "enabled": true},
	"blockstun_crouch": {"path": "res://art/characters/peg_leg_peggy/clips/blockstun_crouch.png", "frames": 3, "anchor": Vector2(31, 75), "h_ref": 73.0, "enabled": true},
	"blockstun_stand": {"path": "res://art/characters/peg_leg_peggy/clips/blockstun_stand.png", "frames": 2, "anchor": Vector2(39, 119), "h_ref": 117.0, "enabled": true},
	"command_grab": {"path": "res://art/characters/peg_leg_peggy/clips/command_grab.png", "frames": 6, "anchor": Vector2(27, 77), "h_ref": 72.0, "enabled": true},
	"crouch_down": {"path": "res://art/characters/peg_leg_peggy/clips/crouch_down.png", "frames": 3, "anchor": Vector2(157, 559), "h_ref": 580.5, "enabled": false},
	"crouch_heavy": {"path": "res://art/characters/peg_leg_peggy/clips/crouch_heavy.png", "frames": 6, "anchor": Vector2(31, 78), "h_ref": 74.0, "enabled": true},
	"crouch_hold": {"path": "res://art/characters/peg_leg_peggy/clips/crouch_hold.png", "frames": 2, "anchor": Vector2(256, 614), "h_ref": 637.9, "enabled": true},
	"crouch_light": {"path": "res://art/characters/peg_leg_peggy/clips/crouch_light.png", "frames": 5, "anchor": Vector2(31, 76), "h_ref": 74.0, "enabled": true},
	"crouch_up": {"path": "res://art/characters/peg_leg_peggy/clips/crouch_up.png", "frames": 3, "anchor": Vector2(24, 76), "h_ref": 74.0, "enabled": true},
	"down": {"path": "res://art/characters/peg_leg_peggy/clips/down.png", "frames": 6, "anchor": Vector2(31, 78), "h_ref": 74.0, "enabled": true},
	"forward": {"path": "res://art/characters/peg_leg_peggy/clips/forward.png", "frames": 6, "anchor": Vector2(30, 91), "h_ref": 75.0, "enabled": true},
	"forward_ex": {"path": "res://art/characters/peg_leg_peggy/clips/forward_ex.png", "frames": 6, "anchor": Vector2(25, 93), "h_ref": 73.0, "enabled": true},
	"grab": {"path": "res://art/characters/peg_leg_peggy/clips/grab.png", "frames": 6, "anchor": Vector2(26, 76), "h_ref": 74.0, "enabled": true},
	"heavy": {"path": "res://art/characters/peg_leg_peggy/clips/heavy.png", "frames": 6, "anchor": Vector2(28, 76), "h_ref": 74.0, "enabled": true},
	"hitstun_air": {"path": "res://art/characters/peg_leg_peggy/clips/hitstun_air.png", "frames": 3, "anchor": Vector2(38, 94), "h_ref": 74.0, "enabled": true},
	"hitstun_crouch": {"path": "res://art/characters/peg_leg_peggy/clips/hitstun_crouch.png", "frames": 3, "anchor": Vector2(40, 95), "h_ref": 74.0, "enabled": true},
	"hitstun_stand": {"path": "res://art/characters/peg_leg_peggy/clips/hitstun_stand.png", "frames": 3, "anchor": Vector2(27, 82), "h_ref": 74.0, "enabled": true},
	"jump_fall": {"path": "res://art/characters/peg_leg_peggy/clips/jump_fall.png", "frames": 2, "anchor": Vector2(29, 105), "h_ref": 74.0, "enabled": true},
	"jump_heavy": {"path": "res://art/characters/peg_leg_peggy/clips/jump_heavy.png", "frames": 6, "anchor": Vector2(31, 76), "h_ref": 74.0, "enabled": true},
	"jump_light": {"path": "res://art/characters/peg_leg_peggy/clips/jump_light.png", "frames": 6, "anchor": Vector2(37, 80), "h_ref": 71.0, "enabled": true},
	"jump_rise": {"path": "res://art/characters/peg_leg_peggy/clips/jump_rise.png", "frames": 3, "anchor": Vector2(27, 76), "h_ref": 74.0, "enabled": true},
	"jump_start": {"path": "res://art/characters/peg_leg_peggy/clips/jump_start.png", "frames": 3, "anchor": Vector2(27, 76), "h_ref": 74.0, "enabled": true},
	"knockdown": {"path": "res://art/characters/peg_leg_peggy/clips/knockdown.png", "frames": 4, "anchor": Vector2(45, 78), "h_ref": 76.0, "enabled": true},
	"ko_air": {"path": "res://art/characters/peg_leg_peggy/clips/ko_air.png", "frames": 3, "anchor": Vector2(38, 80), "h_ref": 74.0, "enabled": true},
	"ko_ground": {"path": "res://art/characters/peg_leg_peggy/clips/ko_ground.png", "frames": 3, "anchor": Vector2(32, 80), "h_ref": 72.0, "enabled": true},
	"land": {"path": "res://art/characters/peg_leg_peggy/clips/land.png", "frames": 3, "anchor": Vector2(36, 88), "h_ref": 74.0, "enabled": true},
	"light": {"path": "res://art/characters/peg_leg_peggy/clips/light.png", "frames": 6, "anchor": Vector2(25, 76), "h_ref": 74.0, "enabled": true},
	"meth": {"path": "res://art/characters/peg_leg_peggy/clips/meth.png", "frames": 6, "anchor": Vector2(30, 82), "h_ref": 79.0, "enabled": true},
	"neutral": {"path": "res://art/characters/peg_leg_peggy/clips/neutral.png", "frames": 6, "anchor": Vector2(26, 76), "h_ref": 74.0, "enabled": true},
	"neutral_ex": {"path": "res://art/characters/peg_leg_peggy/clips/neutral_ex.png", "frames": 6, "anchor": Vector2(33, 76), "h_ref": 74.0, "enabled": true},
	"stage_intro": {"path": "res://art/characters/peg_leg_peggy/clips/stage_intro.png", "frames": 4, "anchor": Vector2(27, 92), "h_ref": 90.0, "enabled": false},
	"throw_target": {"path": "res://art/characters/peg_leg_peggy/clips/throw_target.png", "frames": 3, "anchor": Vector2(49, 82), "h_ref": 80.0, "enabled": false},
	"throw_tech": {"path": "res://art/characters/peg_leg_peggy/clips/throw_tech.png", "frames": 3, "anchor": Vector2(32, 77), "h_ref": 75.0, "enabled": true},
	"wake_up": {"path": "res://art/characters/peg_leg_peggy/clips/wake_up.png", "frames": 4, "anchor": Vector2(33, 76), "h_ref": 74.0, "enabled": true},
	"walk_backward": {"path": "res://art/characters/peg_leg_peggy/clips/walk_backward.png", "frames": 6, "anchor": Vector2(281, 418), "h_ref": 416.0, "enabled": false},
	"walk_forward": {"path": "res://art/characters/peg_leg_peggy/clips/walk_forward.png", "frames": 8, "anchor": Vector2(123, 433), "h_ref": 431.0, "enabled": false},
	"win": {"path": "res://art/characters/peg_leg_peggy/clips/win.png", "frames": 4, "anchor": Vector2(27, 86), "h_ref": 74.0, "enabled": true},
}

# MoveData.id -> clip key. Verified against game/resources/fighters/peg_leg_peggy.tres.
const MOVE_CLIPS := {
	"light": "light",
	"heavy": "heavy",
	"crouch_light": "crouch_light",
	"crouch_heavy": "crouch_heavy",
	"jump_light": "jump_light",
	"jump_heavy": "jump_heavy",
	"peggy_neutral": "neutral",
	"peggy_forward": "forward",
	"peggy_down": "down",
	"peggy_back": "back",
	"peggy_air": "air",
	"grab": "grab",
	"peggy_command_grab": "command_grab",
	"peggy_neutral_ex": "neutral_ex",
	"peggy_forward_ex": "forward_ex",
	"peggy_meth": "meth",
}

# State -> clip keys (context resolved by FighterBase). Lists are tried in
# order so the first valid/enabled clip wins.
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

# Draft-strip playback order (see RichardClipLibrary for the rationale): the
# airborne sheet's last cel is a touchdown crouch, and the land sheet starts
# upright before its absorb. Presentation only; sim timing is untouched.
const PLAY_CELS := {
	"jump_fall": [0],
	"land": [1, 2],
}

# Authored guard poses are shown while holding back stationary or crouch-
# blocking; retreating still plays the walk cycle.
const GUARD_POSE := true

# Fighter ids carrying an authored clip set (Peggy, Richard).
static func has_clips(fighter_id: String) -> bool:
	return fighter_id == "peg_leg_peggy"


static func clip(key: String) -> Dictionary:
	var c: Dictionary = CLIPS.get(key, {})
	if c.is_empty() or not c.get("enabled", false):
		return {}
	if PLAY_CELS.has(key):
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
