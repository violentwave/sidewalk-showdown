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
# the PNGs against those manifests. z is relative to the fighters' 0/1 slots:
# back layers sit behind the victim, front masks cover them.
const PROPS := {
	"plank_base": {
		"path": "res://art/fx/plank_base.png", "frames": 1,
		"anchor": Vector2(8, 27), "z": -4,
	},
	"plank_snap_sheet": {
		"path": "res://art/fx/plank_snap_sheet.png", "frames": 7,
		"anchor": Vector2(48, 27), "z": -4,
	},
	"sewer_open_sheet": {
		"path": "res://art/fx/sewer_open_sheet.png", "frames": 7,
		"anchor": Vector2(48, 46), "z": -5,
	},
	"water_drop_mask_sheet": {
		"path": "res://art/fx/water_drop_mask_sheet.png", "frames": 7,
		"anchor": Vector2(48, 46), "z": 5,
	},
	"whiskey_fumes_sheet": {
		"path": "res://art/fx/whiskey_fumes_sheet.png", "frames": 7,
		"anchor": Vector2(10, 70), "z": -6,
	},
	"fictional_bar_sign_base": {
		"path": "res://art/fx/fictional_bar_sign_base.png", "frames": 1,
		"anchor": Vector2(48, 26), "z": -5,
	},
	"bar_sign_shatter_back_sheet": {
		"path": "res://art/fx/bar_sign_shatter_back_sheet.png", "frames": 7,
		"anchor": Vector2(48, 26), "z": -5,
	},
	"bar_sign_shatter_front_sheet": {
		"path": "res://art/fx/bar_sign_shatter_front_sheet.png", "frames": 7,
		"anchor": Vector2(48, 26), "z": 5,
	},
	"fire_belch_sheet": {
		"path": "res://art/fx/fire_belch_sheet.png", "frames": 7,
		"anchor": Vector2(12, 40), "z": 4,
	},
}

# Flaming Belch staging: how far the belch launches the victim toward the
# sign, and where the sign hangs relative to the victim's landing spot.
const BELCH_PUSH_PX := 56.0
const SIGN_AHEAD_PX := 8.0
const SIGN_HANG_Y := -60.0
# Walk the Plank: how far the victim sinks below the rim line once the
# front water mask owns the opening (fully behind the 64px mask cell).
const PLANK_SINK_MAX_PX := 16.0

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
var _cinematic_root: Node2D
var _props: Dictionary = {}
var _overlay: Array[Control] = []
var _tex_cache: Dictionary = {}
var _prev_freeze_ambient := false
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
	if _cinematic_root != null:
		_cinematic_root.queue_free()
		_cinematic_root = null
	_props.clear()
	for overlay_node in _overlay:
		overlay_node.queue_free()
	_overlay.clear()
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
	_cinematic_root = Node2D.new()
	root.add_child(_cinematic_root)
	_props.clear()
	var ids: Array = _prop_ids()
	for id in ids:
		_props[id] = _make_prop(id)
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


func _prop_ids() -> Array:
	if seq == SEQ_WALK_THE_PLANK:
		return ["plank_base", "plank_snap_sheet", "sewer_open_sheet",
			"water_drop_mask_sheet"]
	return ["whiskey_fumes_sheet", "fictional_bar_sign_base",
		"bar_sign_shatter_back_sheet", "bar_sign_shatter_front_sheet",
		"fire_belch_sheet"]


func _make_prop(id: String) -> Sprite2D:
	var prop: Dictionary = PROPS[id]
	var sprite := Sprite2D.new()
	sprite.texture = _texture(str(prop["path"]))
	sprite.hframes = int(prop["frames"])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Anchor convention shared with the fighter clip renderer: with
	# centered=false and offset=-anchor, node.position IS the manifest's
	# anchor point on screen. Native pixels, never scaled.
	sprite.centered = false
	sprite.offset = -prop["anchor"]
	sprite.z_index = int(prop["z"])
	sprite.visible = false
	_cinematic_root.add_child(sprite)
	return sprite


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
	elif f < 120:
		_set_pose(victim, "knockdown",
			0 if f < 60 else (1 if f < 90 else 3))
	elif f < 150:
		# ko_air tumbles into the opening
		_set_pose(victim, "ko_air", (f - 120) / 10)
		vic_y = floor_y - 8.0 + float(f - 120) * (8.0 / 30.0)
	else:
		# below the rim: the front water mask (z +5) owns the opening and
		# covers the sinking silhouette.
		_set_pose(victim, "ko_ground", 2)
		vic_y = floor_y + minf(float(f - 150) * 0.8, PLANK_SINK_MAX_PX)
	_place(victim, Vector2(_vic_x(), vic_y), cap_vic_facing)
	# --- props (anchored to the pair, frames are pure functions of f) ---
	var plank: Sprite2D = _props["plank_base"]
	plank.visible = f >= 30
	if plank.visible:
		var slide: float = -20.0 * clampf(float(40 - f) / 10.0, 0.0, 1.0)
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
	water.visible = f >= 120
	if water.visible:
		water.frame = mini((f - 120) / 2, 6)
		water.position = Vector2(_vic_x(), floor_y)


func _apply_flaming_belch() -> void:
	var f := frame
	# --- attacker beat map (owner 2026-11-23, existing clips only) ---
	if f < OPENING_HOLD:
		_set_pose(attacker, "neutral", 2)
	elif f < 60:
		# drench: bottle raised, cels 1-3
		_set_pose(attacker, "heavy", (f - 30) / 10)
	elif f < 90:
		_set_pose(attacker, "heavy", 2)
	elif f < 120:
		# belch/ignite: neutral cels 2-5
		_set_pose(attacker, "neutral", 1 + mini((f - 90) / 7, 3))
	elif f < 180:
		# follow-through: the last neutral cel
		_set_pose(attacker, "neutral", 5)
	else:
		_set_pose(attacker, "win", ((f - 180) / 9) % 4)
	_place(attacker, Vector2(_att_x(), floor_y), cap_att_facing)
	# --- victim (existing clips only, masked by props) ---
	var push_dir := signf(_vic_x() - _att_x()) if _vic_x() != _att_x() \
		else float(cap_att_facing)
	var vic_x := _vic_x()
	var vic_y := floor_y
	if f < 120:
		_set_pose(victim, "hitstun_stand",
			0 if f < OPENING_HOLD else mini((f - 30) / 10, 2))
	elif f < 150:
		_set_pose(victim, "ko_air", (f - 120) / 10)
		vic_x = _vic_x() + push_dir * float(f - 120) * (BELCH_PUSH_PX / 30.0)
		vic_y = floor_y - 10.0 + float(f - 120) * (10.0 / 30.0)
	elif f < 160:
		_set_pose(victim, "ko_air", 2)
		vic_x = _vic_x() + push_dir * BELCH_PUSH_PX
	else:
		# behind the sign mask: the front shards (z +5) cover the landing.
		_set_pose(victim, "ko_ground", 2 if f >= 180 else 0)
		vic_x = _vic_x() + push_dir * BELCH_PUSH_PX
	_place(victim, Vector2(vic_x, vic_y), cap_vic_facing)
	# --- props ---
	var fumes: Sprite2D = _props["whiskey_fumes_sheet"]
	fumes.visible = f >= 30
	if fumes.visible:
		fumes.frame = mini((f - 30) / 3, 6)
		fumes.position = Vector2(_att_x() + float(cap_att_facing) * 10.0,
			floor_y - 44.0)
	var fire: Sprite2D = _props["fire_belch_sheet"]
	fire.visible = f >= 90 and f < 134
	if fire.visible:
		fire.frame = mini((f - 90) / 2, 6)
		fire.flip_h = cap_att_facing < 0
		fire.position = Vector2(_att_x() + float(cap_att_facing) * 16.0,
			floor_y - 42.0)
	# The sign hangs ahead of the victim's landing spot, pair-anchored.
	var sign_x := _vic_x() + push_dir * (BELCH_PUSH_PX + SIGN_AHEAD_PX)
	var sign_y := floor_y + SIGN_HANG_Y
	var sign: Sprite2D = _props["fictional_bar_sign_base"]
	sign.visible = f >= 120 and f < 150
	if sign.visible:
		sign.position = Vector2(sign_x, sign_y)
	var back: Sprite2D = _props["bar_sign_shatter_back_sheet"]
	back.visible = f >= 150
	if back.visible:
		back.frame = mini((f - 150) / 2, 6)
		back.position = Vector2(sign_x, sign_y)
	var front: Sprite2D = _props["bar_sign_shatter_front_sheet"]
	front.visible = f >= 150
	if front.visible:
		front.frame = mini((f - 150) / 2, 6)
		front.position = Vector2(sign_x, sign_y)


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
	if _cinematic_root != null:
		_cinematic_root.position = off
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
		var sign_x := cap_vic_pos.x + push_dir * (BELCH_PUSH_PX + SIGN_AHEAD_PX)
		hi = maxf(hi, sign_x + 48.0)
		lo = minf(lo, sign_x - 48.0)
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
