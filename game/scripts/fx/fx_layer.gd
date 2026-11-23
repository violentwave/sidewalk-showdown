# FxLayer — presentation-only contact/landing/wall FX
# (docs/FX_AND_METH_DESIGN.md §1.3 event map, §2, §4 items 5-6).
#
# CanvasLayer 5: above all stage/world pixels and fighters, below the match
# HUD (layer 10) and the router screens (layer 20). Everything here is
# presentation: FX advance only on the match's sim clock (MatchRoot calls
# sim_tick() next to the HUD tick), so pause and hitstop freeze them, and
# nothing here is serialized as gameplay state. No Tween, delta, wall-clock
# or RNG — one-shot cels are pure functions of elapsed sim ticks.
#
# Contact events come from MatchRoot._resolve_hits() (one primary impact per
# resolved contact, precedence EX > counter > special/launcher > heavy >
# light). Heavy whoosh and special trail spawn at move startup, attached to
# the attacker and mirrored by facing. Landing/knockdown dust and the one-shot
# wall contact are polled per sim frame off the fighters' own state.
class_name FxLayer
extends CanvasLayer

const LAYER_INDEX := 5
# Wall contact is one event per clamp contact: a fighter pushed into a bound
# spawns dust once; the latch resets only when the push ends.
const WALL_SPEED_MIN := 10.0

var p1: FighterBase
var p2: FighterBase
var stage: Node2D
# Tests disable spawning to hash-compare the serializable state; nothing
# else reads this.
var spawning_enabled := true

# Live one-shots: {sprite, def, elapsed, attach (FighterBase or null),
# offset (Vector2, attacker-local, x pre-mirrored by facing)}
var _oneshots: Array[Dictionary] = []
# Transition trackers for landing/knockdown dust (per fighter slot).
var _prev_state: Array[int] = [-1, -1]
var _prev_grounded: Array[bool] = [true, true]
# Wall-contact latch (per fighter slot).
var _wall_latched: Array[bool] = [false, false]
# Texture cache keyed by sheet path (loaded once per match).
var _tex_cache: Dictionary = {}
# Last contact spawn, for tests: {sheet, kind, position, facing, blocked}
var last_spawn: Dictionary = {}
var contact_spawn_count := 0


func setup(root: Node) -> void:
	layer = LAYER_INDEX
	p1 = root.p1
	p2 = root.p2
	stage = root.stage
	p1.attack_started.connect(_on_attack_started.bind(p1))
	p2.attack_started.connect(_on_attack_started.bind(p2))
	_prev_state = [p1.state, p2.state]
	_prev_grounded = [p1.grounded, p2.grounded]


# ---------------- per-tick presentation (MatchRoot calls this) ----------------

func sim_tick(root: Node) -> void:
	if p1 == null or p2 == null:
		return
	# The METH cinematic driver owns the whole screen while it is active.
	if root.phase == root.Phase.METH_CINEMATIC:
		return
	# Hitstop freezes the exchange; FX hold with it (design §2).
	if p1.hitstop_frames > 0 or p2.hitstop_frames > 0:
		return
	_poll_dust_transitions()
	_poll_wall_contact()
	_advance_oneshots()


# ---------------- contact spawn (from hit/block resolution) ----------------

# One primary impact per resolved contact. `blocked` contacts use the
# subdued block sheet; hit kinds resolve in precedence order from the move
# row and the counter flag, never stacked.
func spawn_contact(attacker: FighterBase, defender: FighterBase,
		move: MoveData, counter: bool, blocked: bool) -> void:
	if not spawning_enabled:
		return
	var set: FxSet = attacker.data.fx_set if attacker.data != null else null
	if set == null:
		return
	var def: FxSheetDef = null
	var kind := ""
	if blocked:
		def = set.block
		kind = "block"
	elif move.ex:
		def = set.ex_hit
		kind = "ex_hit"
	elif counter:
		def = set.hit_counter
		kind = "hit_counter"
	elif move.input in [MoveData.InputType.SPECIAL_NEUTRAL, MoveData.InputType.SPECIAL_FWD,
			MoveData.InputType.SPECIAL_DOWN, MoveData.InputType.SPECIAL_BACK,
			MoveData.InputType.SPECIAL_AIR]:
		def = set.special_hit
		kind = "special_hit"
	elif move.input == MoveData.InputType.HEAVY:
		def = set.hit_heavy
		kind = "hit_heavy"
	elif move.input == MoveData.InputType.LIGHT:
		def = set.hit_light
		kind = "hit_light"
	if def == null or not def.valid():
		return
	# Anchor: the hitbox/hurtbox overlap center (design §1.3); the hitbox
	# center is the fallback when the intersection is degenerate.
	var rect := attacker.get_hitbox_rect().intersection(defender.hurtbox_rect())
	var at := rect.get_center() if rect.size.x > 0.5 and rect.size.y > 0.5 \
		else attacker.get_hitbox_rect().get_center()
	_spawn(def, at, attacker.facing, null, Vector2.ZERO)
	contact_spawn_count += 1
	last_spawn = {
		"sheet": def.texture_path,
		"kind": kind,
		"position": at,
		"facing": attacker.facing,
		"blocked": blocked,
	}


# ---------------- startup-attached streaks ----------------

func _on_attack_started(move: MoveData, fighter: FighterBase) -> void:
	if not spawning_enabled or move == null or fighter.data == null:
		return
	# The finisher's presentation belongs to the banner/cinematic; throws
	# have no authored streak.
	if move.meth or move.level == MoveData.Level.THROW:
		return
	var set: FxSet = fighter.data.fx_set
	if set == null:
		return
	var def: FxSheetDef = null
	var offset := Vector2.ZERO
	if move.input == MoveData.InputType.HEAVY:
		# Beside the moving hand/tool/bottle, behind the strike direction
		# (§1.4 landmarks put the active limb tip at upper-mid reach).
		def = set.heavy_whoosh
		offset = Vector2(14, -40)
	elif move.input in [MoveData.InputType.SPECIAL_NEUTRAL, MoveData.InputType.SPECIAL_FWD,
			MoveData.InputType.SPECIAL_DOWN, MoveData.InputType.SPECIAL_BACK,
			MoveData.InputType.SPECIAL_AIR]:
		def = set.special_trail
		offset = Vector2(18, -40)
	if def == null or not def.valid():
		return
	_spawn(def, _attached_position(fighter, offset), fighter.facing,
		fighter, offset)


func _attached_position(fighter: FighterBase, offset: Vector2) -> Vector2:
	return fighter.position + Vector2(offset.x * fighter.facing, offset.y)


# ---------------- landing / knockdown / wall ----------------

func _poll_dust_transitions() -> void:
	for i in 2:
		var f := p1 if i == 0 else p2
		var dust := false
		if _prev_state[i] != FighterBase.State.LAND and f.state == FighterBase.State.LAND:
			# One-shot per landing transition.
			dust = true
		elif _prev_state[i] != FighterBase.State.KNOCKDOWN \
				and f.state == FighterBase.State.KNOCKDOWN and f.grounded:
			# Grounded knockdown: dust at the moment of the slam.
			dust = true
		elif not _prev_grounded[i] and f.grounded \
				and f.state == FighterBase.State.KNOCKDOWN:
			# Airborne knockdown: dust when the feet actually reach the floor.
			dust = true
		_prev_state[i] = f.state
		_prev_grounded[i] = f.grounded
		if dust:
			_spawn_dust(f)


func _poll_wall_contact() -> void:
	for i in 2:
		var f := p1 if i == 0 else p2
		var into_wall := false
		if f.position.x <= stage.left_bound and f.velocity.x < -WALL_SPEED_MIN:
			into_wall = true
		elif f.position.x >= stage.right_bound and f.velocity.x > WALL_SPEED_MIN:
			into_wall = true
		if into_wall and not _wall_latched[i]:
			_wall_latched[i] = true
			_spawn_dust_at(Vector2(
				stage.left_bound if f.velocity.x < 0.0 else stage.right_bound,
				stage.floor_y))
		elif not into_wall:
			_wall_latched[i] = false


func _spawn_dust(f: FighterBase) -> void:
	if not spawning_enabled or f.data == null:
		return
	var set: FxSet = f.data.fx_set
	if set == null or set.landing_dust == null or not set.landing_dust.valid():
		return
	_spawn_dust_at(Vector2(f.position.x, stage.floor_y))


func _spawn_dust_at(at: Vector2) -> void:
	# The shared dust sheet is identical in both fighters' sets; the acting
	# slot resolves it, a future fighter without a set simply spawns nothing.
	var set: FxSet = p1.data.fx_set if p1.data != null else null
	if set == null or set.landing_dust == null or not set.landing_dust.valid():
		return
	_spawn(set.landing_dust, at, 1, null, Vector2.ZERO)


# ---------------- one-shot lifecycle ----------------

func _spawn(def: FxSheetDef, at: Vector2, facing: int,
		attach: FighterBase, offset: Vector2) -> void:
	var tex := _texture(def.texture_path)
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.hframes = def.frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The anchor point is the overlap center: draw the current cel centered
	# on it. Native 1:1 pixels, never scaled (design §1.5).
	sprite.centered = false
	sprite.offset = Vector2(-def.cell.x * 0.5, -def.cell.y * 0.5)
	sprite.position = at
	sprite.flip_h = def.mirror and facing < 0
	add_child(sprite)
	_oneshots.append({
		"sprite": sprite,
		"def": def,
		"elapsed": 0,
		"attach": attach,
		"offset": offset,
	})


func _advance_oneshots() -> void:
	var expired: Array[int] = []
	for i in _oneshots.size():
		var entry: Dictionary = _oneshots[i]
		var def: FxSheetDef = entry["def"]
		entry["elapsed"] = int(entry["elapsed"]) + 1
		var elapsed: int = entry["elapsed"]
		if entry["attach"] != null:
			var fighter: FighterBase = entry["attach"]
			if fighter != null and is_instance_valid(fighter):
				var offset: Vector2 = entry["offset"]
				entry["sprite"].position = _attached_position(fighter, offset)
		if elapsed >= def.frames * def.ticks_per_frame:
			expired.append(i)
			var sprite: Sprite2D = entry["sprite"]
			sprite.queue_free()
		else:
			entry["sprite"].frame = mini(elapsed / def.ticks_per_frame, def.frames - 1)
	for j in range(expired.size() - 1, -1, -1):
		_oneshots.remove_at(expired[j])


func _texture(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	_tex_cache[path] = tex
	return tex


# ---------------- test introspection (presentation only) ----------------

func active_oneshot_count() -> int:
	return _oneshots.size()


func oneshot_frame(index: int) -> int:
	if index < 0 or index >= _oneshots.size():
		return -1
	return _oneshots[index]["sprite"].frame


func oneshot_sprite(index: int) -> Sprite2D:
	if index < 0 or index >= _oneshots.size():
		return null
	return _oneshots[index]["sprite"]
