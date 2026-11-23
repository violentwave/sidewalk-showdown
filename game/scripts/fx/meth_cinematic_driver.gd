# MethCinematicDriver — the deterministic METHtality sequence owner
# (docs/FX_AND_METH_DESIGN.md §3 storyboards, §4 engine work).
#
# MatchRoot starts this ONLY on a confirmed, unblocked METH contact. The
# full-meter gate, the meter spend at activation, the `meth_started` banner,
# whiff behavior and blocked handling all stay in FighterBase /
# MatchRoot._resolve_hits(); this driver never re-checks them.
#
# Sequence: exactly 210 sim frames (frames 0-209) after the contact frame.
# Frames 0-29 are the opening freeze (the authored 30f METH contact hitstop,
# expressed as the driver's hold instead of a second hitstop charge). The
# authored METH damage is applied ONCE on the boundary tick by
# MatchRoot._finish_meth_cinematic() through the ordinary hit/KO path, then
# the normal KO/round/Results flow is authoritative.
#
# Determinism: every pose, position, prop cel and shake offset below is a
# pure function of (captured pair state, sequence frame). No delta, no
# wall clock, no RNG, no Tween. The driver's serializable state is plain
# data (see serialize()); props/overlay are rebuilt from it and are never
# serialized themselves.
#
# Owner beat maps (2026-11-23, existing clips only — these amend the §3
# storyboards, whose dedicated meth_* clips were never drawn):
#   Walk the Plank: contact = `forward` (long peg-leg poke); knock onto
#     plank = `forward` recovery cels; pin = `crouch_heavy` cels 1-3;
#     stomp = `crouch_heavy` cels 3-5 (placeholder until a dedicated stomp
#     pose exists); finish = `win`.
#   Flaming Belch: contact = `neutral`; drench = `heavy` cels 1-3 (bottle
#     raised, same hand); belch/ignite = `neutral` cels 2-5; follow-through
#     = `neutral` last cel; finish = `win`.
#   Victims use only their existing hitstun_stand / knockdown / ko_air /
#     ko_ground clips, masked by props.
class_name MethCinematicDriver
extends Node

const SEQ_WALK_THE_PLANK := 0
const SEQ_FLAMING_BELCH := 1
# 210 frames total: the 30f opening hold plus 180 choreography frames.
const LENGTH := 210
const OPENING_HOLD := 30

# Letterbox/dim treatment (design §3 "shared cinematic treatment").
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const LETTERBOX_PX := 8
const VIEW_W := 320.0
const VIEW_H := 180.0

# Deterministic presentation-only shake lists (design §3: max 2-6px, short).
const SHAKE_SMALL: Array[int] = [2, 1, 0, -1, -2, -1]
const SHAKE_BIG: Array[int] = [4, 3, 2, 1, -1, -2, -3, -4]

# Prop table — mirrors art/source/FX/meth_props/props_manifest.json (and
# the fire belch row of fx_manifest.json); art/tools/prepare_fx.sh validates
# the PNGs against those manifests.
#
# Draw order is BY LAYER, not by z hack: "back" props (everything the
# storyboards draw BEHIND a fighter) live on a dedicated back root that is
# inserted in MatchRoot's tree order BETWEEN the stage and the fighters —
# negative z_index would push them behind the entire opaque stage, which is
# exactly the "invisible plank/sewer/fumes" review bug. "front" props
# (masks covering the victim, the fire cone) live on a front root appended
# AFTER the fighters, with z above the fighters' 0/1 slots. Inside a layer,
# the table order below is the draw order (sewer under the plank, fumes over
# the sewer, plank over the fumes' floor, sign base over the plank).
#
# `mirror: true` marks sheets drawn facing right whose anchor must mirror
# with the attacker's facing (offset AND flip_h together — a flipped
# Sprite2D mirrors its region inside the rect, so the anchor x becomes
# cell_w - anchor.x or the sprite lands one cell-width off target).
const PROPS := {
	"sewer_open_sheet": {
		"path": "res://art/fx/sewer_open_sheet.png", "frames": 7,
		"anchor": Vector2(48, 46), "layer": "back", "mirror": false,
	},
	"whiskey_fumes_sheet": {
		"path": "res://art/fx/whiskey_fumes_sheet.png", "frames": 7,
		"anchor": Vector2(10, 70), "layer": "back", "mirror": true,
	},
	"plank_base": {
		"path": "res://art/fx/plank_base.png", "frames": 1,
		"anchor": Vector2(8, 27), "layer": "back", "mirror": false,
	},
	"plank_snap_sheet": {
		"path": "res://art/fx/plank_snap_sheet.png", "frames": 7,
		"anchor": Vector2(48, 27), "layer": "back", "mirror": false,
	},
	"fictional_bar_sign_base": {
		"path": "res://art/fx/fictional_bar_sign_base.png", "frames": 1,
		"anchor": Vector2(48, 26), "layer": "back", "mirror": false,
	},
	"bar_sign_shatter_back_sheet": {
		"path": "res://art/fx/bar_sign_shatter_back_sheet.png", "frames": 7,
		"anchor": Vector2(48, 26), "layer": "back", "mirror": false,
	},
	"water_drop_mask_sheet": {
		"path": "res://art/fx/water_drop_mask_sheet.png", "frames": 7,
		"anchor": Vector2(48, 46), "layer": "front", "mirror": false,
	},
	"bar_sign_shatter_front_sheet": {
		"path": "res://art/fx/bar_sign_shatter_front_sheet.png", "frames": 7,
		"anchor": Vector2(48, 26), "layer": "front", "mirror": false,
	},
	"fire_belch_sheet": {
		# Mouth point per fx_manifest: near the cell's left edge, drawn
		# facing right; comes straight out of Richard's mouth, no rotation,
		# no scaling, above the victim and the fumes.
		"path": "res://art/fx/fire_belch_sheet.png", "frames": 7,
		"anchor": Vector2(3, 36), "layer": "front", "mirror": true,
	},
}

# Flaming Belch staging. From BELCH_LAUNCH_FRAME the victim flies a
# pixel-snapped ballistic arc away from Richard (up, then down) and lands
# exactly ARC_FRAMES later. The bar sign hangs on that arc, SIGN_DIST px out
# at chest/head height; the shatter starts on the frame the victim reaches
# it (SIGN_HIT_FRAME).
const BELCH_LAUNCH_FRAME := 120
const ARC_VX := 1.75
const ARC_VY0 := 3.6
const ARC_G := 0.18
const ARC_FRAMES := 40
const BELCH_PUSH_PX := 70.0   # landing distance = ARC_VX * ARC_FRAMES
const SIGN_DIST_PX := 44.0
const SIGN_HANG_Y := -64.0
const SIGN_HIT_FRAME := 145
const SIGN_SHOW_FRAME := 116
const SHATTER_END_FRAME := 172
# Measured cel points (pixels from the cel's top-left; drawn facing right):
# Richard's mouth in the neutral belch cels 1-4 and the bottle mouth in the
# first `heavy` drench cel (the pour point the fumes start from).
const NEUTRAL_MOUTH_CEL := {1: Vector2(44, 22), 2: Vector2(44, 19),
	3: Vector2(44, 18), 4: Vector2(44, 21)}
const HEAVY_BOTTLE_MOUTH_CEL := Vector2(68, 26)
# Fire cone: 7 frames over the ignite beat; the fumes ignite (flash) as it
# reaches them and are consumed shortly after.
const FIRE_START_FRAME := 97
const FIRE_TICKS_PER_FRAME := 3
const IGNITE_FLASH_FRAME := 103
const IGNITE_FLASH_LEN := 9
const FUMES_END_FRAME := 114
const IGNITE_TINT := Color(1.0, 0.55, 0.15)
# Walk the Plank: the victim drops into the opening from DROP_FRAME under
# PLANK_DROP_G (px/frame^2), clipped below the front-rim arc (a shader
# discard — no per-frame image work). The arc sags RIM_DEPTH below the floor
# line at the centre and meets it RIM_HALF_W out (measured from
# water_drop_mask_sheet's front rim).
const DROP_FRAME := 108
const PLANK_DROP_G := 0.075
const RIM_DEPTH := 12.0
const RIM_HALF_W := 37.0
const PLANK_APPEAR_FRAME := 54
const SPLASH_FRAME := 124
# The METHTALITY banner centres for the opening hold, then rides the top
# band (below the 8px letterbox) so nothing in the action sits under it.
const BANNER_TOP_Y := 10.0
const BANNER_MOVE_FRAMES := 12
const CLIP_SHADER := """
shader_type canvas_item;
uniform float clip_on = 0.0;
uniform vec4 rim = vec4(0.0, 0.0, 37.0, 12.0);
varying vec2 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	if (clip_on > 0.5) {
		float dx = (world_pos.x - rim.x) / rim.z;
		float rim_y = rim.y + (abs(dx) < 1.0 ? rim.w * (1.0 - dx * dx) : 0.0);
		if (world_pos.y > rim_y) {
			discard;
		}
	}
}
"""

# --- serialized state ----------------------------------------------------------
var active := false
var seq := SEQ_WALK_THE_PLANK
var attacker_index := 0
var frame := 0
var cap_att_pos := Vector2.ZERO
var cap_vic_pos := Vector2.ZERO
var cap_att_facing := 1
var cap_vic_facing := -1
var floor_y := 150.0
var group_shift := 0.0
var training_snapshot: Dictionary = {}

# --- live (rebuilt from the above; never serialized) ---------------------------
var attacker: FighterBase
var victim: FighterBase
var meth_move: MoveData
# Prop roots (see _build_presentation): back = between stage and fighters,
# front = after the fighters, above their 0/1 z slots.
var _back_root: Node2D
var _front_root: Node2D
var _props: Dictionary = {}
var _overlay: Array[Control] = []
var _tex_cache: Dictionary = {}
var _prev_freeze_ambient := false
var _clip_material: ShaderMaterial
var _flash: ColorRect
var _shake_off := Vector2.ZERO
# Last applied clip keys (test introspection only).
var _att_pose_key := ""
var _vic_pose_key := ""


# ---------------- lifecycle ----------------

# Called by MatchRoot._resolve_hits() on a confirmed, unblocked METH contact.
func begin(start_attacker: FighterBase, start_victim: FighterBase,
		move: MoveData, root: Node) -> void:
	active = true
	attacker = start_attacker
	victim = start_victim
	meth_move = move
	attacker_index = attacker.player_index - 1
	seq = SEQ_FLAMING_BELCH if attacker.data != null \
		and attacker.data.id == "whiskey_richard" else SEQ_WALK_THE_PLANK
	cap_att_pos = attacker.position
	cap_vic_pos = victim.position
	cap_att_facing = attacker.facing
	cap_vic_facing = victim.facing
	floor_y = root.stage.floor_y
	frame = 0
	group_shift = _compute_group_shift(root)
	training_snapshot = {}
	if root.training_mode:
		_capture_training_snapshot(root)
	# Suspend both machines and clear every buffered action so nothing leaks
	# into or out of the sequence (design §4 item 8).
	for f: FighterBase in [attacker, victim]:
		f.cinematic_hold = true
		f.input_buffer.clear()
		f.breaker_pair_frames = 0
		f.velocity = Vector2.ZERO
	# The finisher connected: no further hit polls run for this move.
	attacker.on_attack_connected(true)
	_build_presentation(root)
	_apply(root)


# One METH_CINEMATIC sim tick. Frame 0 is the contact frame (applied by
# begin()); ticks 1..209 apply frames 1..209; the tick that would reach 210
# finishes the sequence, so exactly 210 frames are displayed and the damage
# lands once on the boundary.
func tick(root: Node) -> void:
	if not active:
		return
	frame += 1
	if frame > LENGTH - 1:
		root._finish_meth_cinematic()
		return
	_apply(root)


# Presentation teardown shared by every finish path (KO, training restore,
# training skip). Frees props/overlay, unholds both machines, clears
# buffers and the deferred hitstop, and hands the HUD back.
func end_presentation(root: Node) -> void:
	if _back_root != null:
		_back_root.queue_free()
		_back_root = null
	if _front_root != null:
		_front_root.queue_free()
		_front_root = null
	_props.clear()
	for overlay_node in _overlay:
		overlay_node.queue_free()
	_overlay.clear()
	_flash = null
	if victim != null and is_instance_valid(victim) and victim.idle_sprite != null:
		victim.idle_sprite.material = null
	_clip_material = null
	root.hud.banner_plate.position.y = MatchHUD.BANNER_POS.y
	if victim != null and is_instance_valid(victim) and victim.position.y > floor_y:
		victim.position.y = floor_y
	for f: FighterBase in [root.p1, root.p2]:
		f.cinematic_hold = false
		f.clear_cinematic_pose()
		f.input_buffer.clear()
		f.breaker_pair_frames = 0
		# The opening hold replaced the authored contact hitstop; nothing
		# may carry a stale freeze into the KO/training flow.
		f.hitstop_frames = 0
		f.visual_root.position = Vector2.ZERO
	root.hud.set_cinematic_mode(false)
	var anim: Node = root.stage.get_node_or_null("StageAnimation")
	if anim != null:
		anim.freeze_ambient = _prev_freeze_ambient


func reset() -> void:
	active = false
	attacker = null
	victim = null
	meth_move = null
	training_snapshot = {}


# ---------------- training restore ----------------

func _capture_training_snapshot(root: Node) -> void:
	training_snapshot = {
		"p1": root.p1.serialize(),
		"p2": root.p2.serialize(),
		"p1_pos": root.p1.position,
		"p2_pos": root.p2.position,
	}


# Training only (design §4 item 10): no KO/round flow; restore the
# pre-METH fighters, positions and resources — including the full meter the
# activation spent (a METH can only ever have activated from a full bar, so
# restoring max_meter restores exactly the pre-activation value) — so the
# sequence is repeatable.
func restore_training_snapshot(root: Node) -> void:
	if training_snapshot.is_empty():
		return
	root.p1.load(training_snapshot["p1"])
	root.p2.load(training_snapshot["p2"])
	root.p1.position = training_snapshot["p1_pos"]
	root.p2.position = training_snapshot["p2_pos"]
	# The snapshot was captured at the contact frame, with the finisher's
	# row already live on the attacker: neutralize that row so the restored
	# attacker cannot re-connect the same move one tick later and silently
	# restart the sequence. Every other restored state is the exact
	# pre-contact one (the victim was never touched by receive_hit).
	for f: FighterBase in [root.p1, root.p2]:
		if f.current_move != null and f.current_move.meth:
			f.current_move = null
			f.move_hit_confirmed = false
			f.move_already_hit = false
			f.move_was_blocked = false
			f.move_whiffed = false
			f.velocity = Vector2.ZERO
			f._force_state(FighterBase.State.JUMP_FALL if not f.grounded
				else FighterBase.State.IDLE)
		f.input_buffer.clear()
		f.breaker_pair_frames = 0
		f.hitstop_frames = 0
	# Hand the activation's meter spend back to the finisher's player.
	if attacker != null and attacker.data != null:
		attacker.meter = attacker.max_meter
	for f: FighterBase in [root.p1, root.p2]:
		f._emit_health()
		f.meter_changed.emit(f.meter, f.max_meter)
	root.hud.clear_banner()


# ---------------- serialization ----------------

func serialize() -> Dictionary:
	return {
		"active": active,
		"seq": seq,
		"attacker_index": attacker_index,
		"frame": frame,
		"cap_att_x": cap_att_pos.x,
		"cap_att_y": cap_att_pos.y,
		"cap_vic_x": cap_vic_pos.x,
		"cap_vic_y": cap_vic_pos.y,
		"cap_att_facing": cap_att_facing,
		"cap_vic_facing": cap_vic_facing,
		"floor_y": floor_y,
		"group_shift": group_shift,
		"training_snapshot": training_snapshot,
	}


# Restore from serialize() output and re-enter the sequence on the exact
# frame: the presentation (props, overlay, HUD hold, poses) is rebuilt from
# the driver state, never serialized alongside it.
func load_state(root: Node, data: Dictionary) -> void:
	active = bool(data.get("active", false))
	seq = int(data.get("seq", SEQ_WALK_THE_PLANK))
	attacker_index = int(data.get("attacker_index", 0))
	frame = int(data.get("frame", 0))
	cap_att_pos = Vector2(data.get("cap_att_x", 0.0), data.get("cap_att_y", 0.0))
	cap_vic_pos = Vector2(data.get("cap_vic_x", 0.0), data.get("cap_vic_y", 0.0))
	cap_att_facing = int(data.get("cap_att_facing", 1))
	cap_vic_facing = int(data.get("cap_vic_facing", -1))
	floor_y = float(data.get("floor_y", 150.0))
	group_shift = float(data.get("group_shift", 0.0))
	training_snapshot = data.get("training_snapshot", {})
	attacker = root.p1 if attacker_index == 0 else root.p2
	victim = root.p2 if attacker_index == 0 else root.p1
	meth_move = attacker.data.meth_move if attacker.data != null else null
	if not active or meth_move == null:
		active = false
		return
	for f: FighterBase in [root.p1, root.p2]:
		f.cinematic_hold = true
		f.input_buffer.clear()
		f.breaker_pair_frames = 0
	_build_presentation(root, true)
	_apply(root)


# ---------------- presentation build ----------------

func _build_presentation(root: Node, reshow_banner := false) -> void:
	# Two world-space prop roots, ordered BY TREE POSITION (the review bug:
	# negative z_index on a late sibling draws behind the whole opaque
	# stage, so "back" props vanished):
	#   _back_root  — inserted in MatchRoot's child order right after the
	#                 stage: back props draw over the stage, under the
	#                 fighters ("sewer behind the victim", plank under him).
	#   _front_root — appended after the fighters: front masks draw over
	#                 the victim; its children sit at z 5/6, above the
	#                 fighters' 0/1 slots.
	_back_root = Node2D.new()
	root.add_child(_back_root)
	root.move_child(_back_root, root.stage.get_index() + 1)
	_front_root = Node2D.new()
	root.add_child(_front_root)
	_props.clear()
	for id: String in PROPS:
		_props[id] = _make_prop(id)
	# The victim's art is clipped by a single reusable shader material (the
	# Walk the Plank rim); parameters change per frame, nothing is allocated.
	var shader := Shader.new()
	shader.code = CLIP_SHADER
	_clip_material = ShaderMaterial.new()
	_clip_material.shader = shader
	if victim != null and victim.idle_sprite != null:
		victim.idle_sprite.material = _clip_material
	# Dim + letterbox live on the FX CanvasLayer (above the world, below
	# the HUD's banner) for the whole sequence.
	var fx: FxLayer = root.fx
	if fx != null:
		var dim := ColorRect.new()
		dim.color = DIM_COLOR
		dim.position = Vector2.ZERO
		dim.size = Vector2(VIEW_W, VIEW_H)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx.add_child(dim)
		_overlay.append(dim)
		# Ignition tint (Flaming Belch): a warm full-screen flash whose
		# alpha is a pure function of the sequence frame.
		_flash = ColorRect.new()
		_flash.color = Color(IGNITE_TINT.r, IGNITE_TINT.g, IGNITE_TINT.b, 0.0)
		_flash.position = Vector2.ZERO
		_flash.size = Vector2(VIEW_W, VIEW_H)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash.visible = false
		fx.add_child(_flash)
		_overlay.append(_flash)
		for top in [true, false]:
			var bar := ColorRect.new()
			bar.color = Color.BLACK
			bar.position = Vector2(0.0, 0.0 if top else VIEW_H - LETTERBOX_PX)
			bar.size = Vector2(VIEW_W, LETTERBOX_PX)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fx.add_child(bar)
			_overlay.append(bar)
	# HUD clutter hides; the METH banner stays and is held for the whole
	# sequence (its 120f auto-remove is retimed while the driver owns it).
	# begin() only retimes the already-showing banner; load_state() re-shows
	# it (the HUD resync hides it on a sim-frame discontinuity).
	root.hud.set_cinematic_mode(true)
	if reshow_banner:
		root.hud.show_banner("methtality",
			attacker.data.meth_name.to_upper() if attacker.data != null else "")
	root.hud.hold_meth_banner(LENGTH + maxi(attacker.state_frame, 0) - frame)
	# Stage ambience freezes for the sequence (design §4 item 8).
	var anim: Node = root.stage.get_node_or_null("StageAnimation")
	if anim != null:
		_prev_freeze_ambient = bool(anim.freeze_ambient)
		anim.freeze_ambient = true


func _make_prop(id: String) -> Sprite2D:
	var prop: Dictionary = PROPS[id]
	var sprite := Sprite2D.new()
	sprite.texture = _texture(str(prop["path"]))
	sprite.hframes = int(prop["frames"])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	# Anchor convention shared with the fighter clip renderer: with
	# centered=false, node.position IS the manifest's anchor point on
	# screen. A mirrored sheet must mirror the ANCHOR too: flip_h mirrors
	# the cel inside its own rect, so the anchor's x becomes cell_w - x or
	# the sprite lands one cell-width off target (the misplaced fire cone).
	var anchor: Vector2 = prop["anchor"]
	var mirrored := bool(prop["mirror"]) and cap_att_facing < 0
	_apply_prop_anchor(sprite, anchor, mirrored)
	sprite.visible = false
	if str(prop["layer"]) == "front":
		sprite.z_index = 5 if id != "fire_belch_sheet" else 6
		_front_root.add_child(sprite)
	else:
		sprite.z_index = 0
		_back_root.add_child(sprite)
	return sprite


# Anchor math, isolated so tests can reuse it: with centered=false the
# drawn cel's top-left sits at position+offset, so the anchor pixel lands
# exactly on node.position when offset = -anchor (unmirrored) or
# -(cell_w - anchor.x) horizontally when the cel is flipped.
func _apply_prop_anchor(sprite: Sprite2D, anchor: Vector2, mirrored: bool) -> void:
	var cell_w := 0.0
	if sprite.texture != null and sprite.hframes > 0:
		cell_w = sprite.texture.get_width() / float(sprite.hframes)
	if mirrored:
		sprite.offset = Vector2(-(cell_w - anchor.x), -anchor.y)
		sprite.flip_h = true
	else:
		sprite.offset = -anchor
		sprite.flip_h = false


func _texture(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex := load(path) as Texture2D
	if tex != null:
		_tex_cache[path] = tex
	return tex


# ---------------- per-frame application ----------------

func _apply(root: Node) -> void:
	if seq == SEQ_WALK_THE_PLANK:
		_apply_walk_the_plank()
	else:
		_apply_flaming_belch()
	_apply_shake()
	_update_clip()
	_apply_banner(root)


# The METHTALITY banner stays centred through the opening hold, then slides
# up into the top band so it never sits over the action.
func _apply_banner(root: Node) -> void:
	var t := clampf(float(frame - OPENING_HOLD) / float(BANNER_MOVE_FRAMES), 0.0, 1.0)
	if frame >= OPENING_HOLD:
		root.hud.banner_plate.position.y = roundf(
			lerpf(MatchHUD.BANNER_POS.y, BANNER_TOP_Y, t))


# Rim clip for the victim's art (Walk the Plank only). The rim is expressed
# in the same shaken canvas space as the front mask prop.
func _update_clip() -> void:
	if _clip_material == null:
		return
	var on := seq == SEQ_WALK_THE_PLANK and frame >= DROP_FRAME
	_clip_material.set_shader_parameter("clip_on", 1.0 if on else 0.0)
	_clip_material.set_shader_parameter("rim", Vector4(
		_vic_x() + _shake_off.x, floor_y + _shake_off.y, RIM_HALF_W, RIM_DEPTH))


# World point of a cel pixel (measured from the cel's top-left, drawn facing
# right) of `clip_key` on fighter `f`: mirrors the fighter renderer's own
# transform (offset = -anchor, flip_h mirroring inside the cel rect, scale
# derived from the displayed clip's scale and the two clips' h_ref).
func _clip_point_world(f: FighterBase, clip_key: String, p: Vector2) -> Vector2:
	var clip: Dictionary = f.cinematic_clip(clip_key)
	var cur: Dictionary = f.cinematic_clip(_att_pose_key if f == attacker else _vic_pose_key)
	if clip.is_empty() or cur.is_empty():
		return f.position
	var tex := _texture(str(clip.path))
	var cell_w: float = tex.get_width() / float(int(clip.frames)) if tex != null else 64.0
	var s: float = f.idle_sprite.scale.x * float(cur.h_ref) / float(clip.h_ref)
	var anchor: Vector2 = clip.anchor
	var lx := (cell_w - p.x) if f.facing < 0 else p.x
	return f.position + Vector2((-anchor.x + lx) * s, (-anchor.y + p.y) * s)


# Anchors after the one-group clamp: the whole composition (fighters and
# props) slides inward together; it is never scaled (design §3).
func _att_x() -> float:
	return cap_att_pos.x + group_shift


func _vic_x() -> float:
	return cap_vic_pos.x + group_shift


func _set_pose(f: FighterBase, clip_key: String, cel: int) -> void:
	if f == attacker:
		_att_pose_key = clip_key
	else:
		_vic_pose_key = clip_key
	var clip: Dictionary = f.cinematic_clip(clip_key)
	if clip.is_empty():
		# A fighter without that clip keeps its existing fallback/static art
		# (future-victim rule, design §3).
		f.clear_cinematic_pose()
		return
	f.set_cinematic_pose(clip, cel)


func _place(f: FighterBase, pos: Vector2, facing: int) -> void:
	f.position = pos
	f.facing = facing


func _apply_walk_the_plank() -> void:
	var f := frame
	# --- attacker beat map (owner 2026-11-23, existing clips only) ---
	if f < OPENING_HOLD:
		_set_pose(attacker, "forward", 2)
	elif f < 60:
		# knock onto plank: the poke's recovery cels
		_set_pose(attacker, "forward", 3 + (f - 30) / 10)
	elif f < 90:
		# pin: peg-leg sweep cels 1-3
		_set_pose(attacker, "crouch_heavy", (f - 60) / 10)
	elif f < 120:
		# stomp: crouch_heavy cels 3-5 (placeholder stomp pose)
		_set_pose(attacker, "crouch_heavy", 2 + (f - 90) / 10)
	elif f < 168:
		_set_pose(attacker, "crouch_heavy", 4)
	else:
		# finish: the confident win loop
		_set_pose(attacker, "win", ((f - 168) / 9) % 4)
	_place(attacker, Vector2(_att_x(), floor_y), cap_att_facing)
	# --- victim (existing clips only, masked by props) ---
	var vic_y := floor_y
	if f < 45:
		_set_pose(victim, "hitstun_stand", 0 if f < OPENING_HOLD else 2)
	elif f < DROP_FRAME:
		_set_pose(victim, "knockdown",
			0 if f < 48 else (1 if f < 54 else (2 if f < 60 else 3)))
	else:
		# The stomp snaps the plank and the victim drops DOWN into the
		# opening, feet first, centred on the sewer anchor, under gravity
		# (pixel-snapped). Everything below the front-rim arc is clipped by
		# the victim sprite's rim shader; by ~f160 the whole sprite rect is
		# beneath the rim.
		var t := float(f - DROP_FRAME)
		_set_pose(victim, "knockdown" if f < DROP_FRAME + 4 else "ko_air",
			2 if f < DROP_FRAME + 4 else (0 if f < DROP_FRAME + 20 else 2))
		vic_y = floor_y + roundf(0.5 * PLANK_DROP_G * t * t)
	_place(victim, Vector2(_vic_x(), vic_y), cap_vic_facing)
	# --- props (anchored to the pair, frames are pure functions of f) ---
	# The plank is brought in only as the victim lands on it (f45): a short
	# slide from the attacker's side, never under the standing victim.
	var plank: Sprite2D = _props["plank_base"]
	plank.visible = f >= PLANK_APPEAR_FRAME and f < 90  # the snap sheet takes over
	if plank.visible:
		var slide: float = -24.0 * float(cap_att_facing) * clampf(
			float(PLANK_APPEAR_FRAME + 8 - f) / 8.0, 0.0, 1.0)
		plank.position = Vector2(_vic_x() - 44.0 + slide, floor_y)
	var snap: Sprite2D = _props["plank_snap_sheet"]
	snap.visible = f >= 90 and f < 111
	if snap.visible:
		snap.frame = (f - 90) / 3
		snap.position = Vector2(_vic_x(), floor_y)
	var sewer: Sprite2D = _props["sewer_open_sheet"]
	sewer.visible = f >= 96
	if sewer.visible:
		sewer.frame = mini((f - 96) / 3, 6)
		sewer.position = Vector2(_vic_x(), floor_y)
	var water: Sprite2D = _props["water_drop_mask_sheet"]
	water.visible = f >= 100
	if water.visible:
		# Rim only until the victim reaches it, then the splash plays as he
		# goes under and settles on its last cel.
		water.frame = 0 if f < SPLASH_FRAME else mini((f - SPLASH_FRAME) / 2, 6)
		water.position = Vector2(_vic_x(), floor_y)


func _apply_flaming_belch() -> void:
	var f := frame
	# --- attacker beat map (owner 2026-11-23, existing clips only) ---
	var neutral_cel := 2
	if f < OPENING_HOLD:
		_set_pose(attacker, "neutral", 2)
	elif f < 60:
		# drench: bottle raised, cels 1-3
		_set_pose(attacker, "heavy", (f - 30) / 10)
	elif f < 90:
		_set_pose(attacker, "heavy", 2)
	elif f < 120:
		# belch/ignite: neutral cels 2-5
		neutral_cel = 1 + mini((f - 90) / 7, 3)
		_set_pose(attacker, "neutral", neutral_cel)
	elif f < 180:
		# follow-through: the last neutral cel
		_set_pose(attacker, "neutral", 5)
	else:
		_set_pose(attacker, "win", ((f - 180) / 9) % 4)
	_place(attacker, Vector2(_att_x(), floor_y), cap_att_facing)
	# --- victim (existing clips only) ---
	var push_dir := belch_push_dir()
	var vic_x := _vic_x()
	var vic_y := floor_y
	if f < BELCH_LAUNCH_FRAME:
		_set_pose(victim, "hitstun_stand",
			0 if f < OPENING_HOLD else mini((f - 30) / 10, 2))
	else:
		# Ballistic launch away from Richard: pixel-snapped, up then down,
		# landing exactly ARC_FRAMES later in ko_ground.
		var t := mini(f - BELCH_LAUNCH_FRAME, ARC_FRAMES)
		vic_x = _vic_x() + push_dir * roundf(ARC_VX * float(t))
		vic_y = floor_y - roundf(ARC_VY0 * float(t) - 0.5 * ARC_G * float(t) * float(t))
		if f - BELCH_LAUNCH_FRAME < ARC_FRAMES:
			_set_pose(victim, "ko_air", mini((f - BELCH_LAUNCH_FRAME) / 10, 2))
		else:
			_set_pose(victim, "ko_ground",
				mini((f - BELCH_LAUNCH_FRAME - ARC_FRAMES) / 12, 2))
	_place(victim, Vector2(vic_x, vic_y), cap_vic_facing)
	# --- props ---
	# Fumes: the anchor (manifest [10,70], bottle mouth) sits at the bottle
	# mouth of Richard's first drench cel — the pour point — and the cloud
	# billows across the pair at head/torso height, mirrored with facing.
	# It holds its last frame until the belch ignites it, then is consumed.
	var fumes: Sprite2D = _props["whiskey_fumes_sheet"]
	fumes.visible = f >= 30 and f < FUMES_END_FRAME
	if fumes.visible:
		fumes.frame = mini((f - 30) / 3, 6)
		fumes.position = fume_anchor_point()
	# Fire cone: 7 frames over the ignite beat from the mouth point of the
	# current belch cel (manifest [3,36]), full size, no rotation, no scale,
	# in the front root (above both fighters and the fumes).
	var fire: Sprite2D = _props["fire_belch_sheet"]
	var fire_frame := (f - FIRE_START_FRAME) / FIRE_TICKS_PER_FRAME
	fire.visible = f >= FIRE_START_FRAME and fire_frame <= 6
	if fire.visible:
		fire.frame = fire_frame
		fire.position = mouth_point(clampi(neutral_cel, 1, 4))
	# The ignition flash as the cone reaches the fumes.
	if _flash != null:
		var ft := f - IGNITE_FLASH_FRAME
		_flash.visible = ft >= 0 and ft < IGNITE_FLASH_LEN
		if _flash.visible:
			_flash.color.a = 0.4 * (1.0 - float(ft) / float(IGNITE_FLASH_LEN))
	# The sign hangs on the victim's arc at chest/head height; the shatter
	# starts on the frame he reaches it. Back shards draw behind him, front
	# shards in front.
	var sign_pos := sign_point()
	var sign: Sprite2D = _props["fictional_bar_sign_base"]
	sign.visible = f >= SIGN_SHOW_FRAME and f < SIGN_HIT_FRAME
	if sign.visible:
		sign.position = sign_pos
	var shatter := f >= SIGN_HIT_FRAME and f < SHATTER_END_FRAME
	var back: Sprite2D = _props["bar_sign_shatter_back_sheet"]
	back.visible = shatter
	var front: Sprite2D = _props["bar_sign_shatter_front_sheet"]
	front.visible = shatter
	if shatter:
		var sf := mini((f - SIGN_HIT_FRAME) / 2, 6)
		back.frame = sf
		back.position = sign_pos
		front.frame = sf
		front.position = sign_pos


# --- Flaming Belch geometry (also used by the test suite) ----------------------

func belch_push_dir() -> float:
	return signf(cap_vic_pos.x - cap_att_pos.x) \
		if cap_vic_pos.x != cap_att_pos.x else float(cap_att_facing)


# Richard's mouth in the given neutral cel, in world space.
func mouth_point(neutral_cel: int) -> Vector2:
	return _clip_point_world(attacker, "neutral",
		NEUTRAL_MOUTH_CEL[clampi(neutral_cel, 1, 4)])


# The fume emission point: the bottle mouth of the first drench cel.
func fume_anchor_point() -> Vector2:
	return _clip_point_world(attacker, "heavy", HEAVY_BOTTLE_MOUTH_CEL)


# The sign's anchor: on the victim's arc, chest/head height.
func sign_point() -> Vector2:
	return Vector2(_vic_x() + belch_push_dir() * SIGN_DIST_PX, floor_y + SIGN_HANG_Y)


# The victim's arc position at launch tick t (pure function; mirrors _apply).
func arc_point(t: int) -> Vector2:
	var tt := float(clampi(t, 0, ARC_FRAMES))
	return Vector2(_vic_x() + belch_push_dir() * roundf(ARC_VX * tt),
		floor_y - roundf(ARC_VY0 * tt - 0.5 * ARC_G * tt * tt))


# Presentation-only shake on the prop group and both fighters' visual roots
# (never the collision roots). Deterministic offset lists, fired on the
# storyboard's contact beats.
func _apply_shake() -> void:
	var offsets: Array = []
	if seq == SEQ_WALK_THE_PLANK:
		offsets = _shake_at([[30, SHAKE_SMALL], [90, SHAKE_BIG],
			[120, SHAKE_SMALL]])
	else:
		offsets = _shake_at([[90, SHAKE_SMALL], [150, SHAKE_SMALL]])
	var off := Vector2(float(offsets[0]) if not offsets.is_empty() else 0.0, 0.0)
	_shake_off = off
	if _back_root != null:
		_back_root.position = off
	if _front_root != null:
		_front_root.position = off
	for f: FighterBase in [attacker, victim]:
		if f != null:
			f.visual_root.position = off


func _shake_at(beats: Array) -> Array:
	for beat in beats:
		var start: int = beat[0]
		var list: Array = beat[1]
		if frame >= start and frame < start + list.size():
			return [list[frame - start]]
	return []


# ---------------- the one-group wall clamp ----------------

# The pair composition's horizontal extent (captured positions plus every
# prop's reach in both directions), slid inward as ONE group so it fits the
# arena bounds. Never scaled; if it cannot fit, it centers deterministically.
func _composition_bounds() -> Vector2:
	var lo := minf(cap_att_pos.x, cap_vic_pos.x) - 33.0
	var hi := maxf(cap_att_pos.x, cap_vic_pos.x) + 33.0
	if seq == SEQ_WALK_THE_PLANK:
		lo = minf(lo, cap_vic_pos.x - 52.0)
		hi = maxf(hi, cap_vic_pos.x + 56.0)
	else:
		var push_dir := signf(cap_vic_pos.x - cap_att_pos.x) \
			if cap_vic_pos.x != cap_att_pos.x else float(cap_att_facing)
		var sign_x := cap_vic_pos.x + push_dir * SIGN_DIST_PX
		hi = maxf(hi, sign_x + 48.0)
		lo = minf(lo, sign_x - 48.0)
		var land_x := cap_vic_pos.x + push_dir * BELCH_PUSH_PX
		hi = maxf(hi, land_x + 33.0)
		lo = minf(lo, land_x - 33.0)
	return Vector2(lo, hi)


func _compute_group_shift(root: Node) -> float:
	var bounds := _composition_bounds()
	var left_bound: float = root.stage.left_bound
	var right_bound: float = root.stage.right_bound
	# Fits as captured: no shift at all.
	if bounds.x >= left_bound and bounds.y <= right_bound:
		return 0.0
	if bounds.x < left_bound:
		var shift := left_bound - bounds.x
		if bounds.y + shift <= right_bound:
			return shift
	if bounds.y > right_bound:
		var shift := right_bound - bounds.y
		if bounds.x + shift >= left_bound:
			return shift
	# Wider than the arena (not reachable with today's data): center it
	# deterministically instead of scaling it.
	return (left_bound + right_bound) * 0.5 - (bounds.x + bounds.y) * 0.5


# ---------------- test introspection ----------------

func attacker_pose_key() -> String:
	return _att_pose_key


func victim_pose_key() -> String:
	return _vic_pose_key


func prop_visible(id: String) -> bool:
	var sprite: Sprite2D = _props.get(id, null)
	return sprite != null and sprite.visible


func prop_frame(id: String) -> int:
	var sprite: Sprite2D = _props.get(id, null)
	return sprite.frame if sprite != null else -1


func prop_scale(id: String) -> Vector2:
	var sprite: Sprite2D = _props.get(id, null)
	return sprite.scale if sprite != null else Vector2.ONE


# --- numeric visibility checks (meth_cinematic_test) --------------------------

func prop_sprite(id: String) -> Sprite2D:
	return _props.get(id, null)


# "back" props draw between the stage and the fighters (tree order), never
# behind the stage; "front" props draw above the fighters.
func prop_layer(id: String) -> String:
	var prop: Dictionary = PROPS.get(id, {})
	return str(prop.get("layer", "back"))


# The world point the prop's manifest anchor currently sits on. With
# centered=false and the (possibly mirrored) offset convention above, the
# anchor pixel always lands exactly on the sprite's global position, shake
# offsets included.
func prop_anchor_point(id: String) -> Vector2:
	var sprite: Sprite2D = _props.get(id, null)
	if sprite == null:
		return Vector2(-9999.0, -9999.0)
	return sprite.global_position


func back_root_index(root: Node) -> int:
	return _back_root.get_index() if _back_root != null else -1


func presentation_roots_cleared() -> bool:
	return _back_root == null and _front_root == null
