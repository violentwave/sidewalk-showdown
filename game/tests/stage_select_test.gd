# Headless tests for stage data, the stage-select screen, Gas-N-Go ambience,
# and MatchRoot's safe roster resolution.
extends SceneTree

const STAGE_SELECT_SCENE := preload("res://scenes/menus/StageSelect.tscn")
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")

var failures := 0
var _chosen_stage: StageData
var _chosen_id := ""
var _back_requests := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _press(target: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	target._unhandled_input(event)

func _press_key(target: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.device = -1
	target._unhandled_input(event)

func _on_stage_chosen(stage: StageData, stage_id: String) -> void:
	_chosen_stage = stage
	_chosen_id = stage_id

func _on_back_requested() -> void:
	_back_requests += 1

func _new_select(roster: MatchRoster, initial_id := "") -> Control:
	var select: Control = STAGE_SELECT_SCENE.instantiate()
	select.roster = roster
	select.initial_stage_id = initial_id
	select.stage_chosen.connect(_on_stage_chosen)
	select.back_requested.connect(_on_back_requested)
	root.add_child(select)
	await process_frame
	return select

func _run() -> void:
	var roster: MatchRoster = MatchRoster.load_default()
	_check("the roster has the two stage entries the selector needs",
		roster != null and roster.stages.size() == 2,
		"stages=%d" % (roster.stages.size() if roster != null else -1))
	if roster == null or roster.stages.size() < 2:
		await _finish()
		return

	for stage: StageData in roster.stages:
		_check("stage '%s' has a stable id" % stage.id, not stage.id.is_empty())
		_check("stage '%s' has an 80x45 thumbnail" % stage.id,
			stage.thumbnail != null
				and stage.thumbnail.get_size() == Vector2(80, 45),
			"thumbnail=%s" % (str(stage.thumbnail.get_size())
				if stage.thumbnail != null else "null"))
		_check("stage '%s' describes itself in the selector" % stage.id,
			not stage.description.is_empty())
		_check("stage '%s' has a scene" % stage.id, stage.scene != null)

	# ---- selector: ordering, thumbnails, stable-id restore, controls ----
	var select: Control = await _new_select(roster, "bus_stop_night")
	_check("RANDOM is the last entry",
		select.stage_count() == roster.stages.size() + 1
			and select.random_index() == select.stage_count() - 1,
		"count=%d random=%d" % [select.stage_count(), select.random_index()])
	_check("a stable stage id restores the cursor, not a stored index",
		select.index == 1 and select.selected_stage().id == "bus_stop_night",
		"index=%d id=%s" % [select.index,
			select.selected_stage().id if select.selected_stage() != null else "null"])
	_check("the selector shows the first stage's 80x45 thumbnail",
		roster.stages[0].thumbnail.get_size() == Vector2(80, 45))

	select.index = 0
	_press(select, "p1_left")
	_check("left from the first stage wraps to RANDOM",
		select.index == select.random_index(), "index=%d" % select.index)
	_press(select, "p1_right")
	_check("right from RANDOM wraps to the first stage",
		select.index == 0, "index=%d" % select.index)
	_press(select, "p2_right")
	_check("the controller moves the shared stage cursor",
		select.index == 1, "index=%d" % select.index)
	_press(select, "p2_light")
	_check("the controller confirms a concrete stage",
		_chosen_stage != null and _chosen_id == "bus_stop_night"
			and select.resolved_stage_id == "bus_stop_night",
		"stage=%s id=%s resolved=%s" % [
			_chosen_stage.id if _chosen_stage != null else "null",
			_chosen_id, select.resolved_stage_id])
	select.free()

	_chosen_stage = null
	_chosen_id = ""
	var missing: Control = await _new_select(roster, "no_such_stage")
	_check("an unknown stored id falls back to the first stage",
		missing.index == 0, "index=%d" % missing.index)
	_press_key(missing, KEY_BACKSPACE)
	_check("Backspace asks the flow for character select",
		_back_requests == 1, "back_requests=%d" % _back_requests)
	missing.free()

	# ---- RANDOM resolves before the match and records the concrete id ----
	_chosen_stage = null
	_chosen_id = ""
	var random_select: Control = await _new_select(roster)
	random_select.index = random_select.random_index()
	random_select.rng.seed = 7
	_press(random_select, "p1_light")
	_check("RANDOM emits a concrete roster stage",
		_chosen_stage != null and _chosen_stage.id == _chosen_id
			and random_select.resolved_stage_id == _chosen_id
			and roster.stages.has(_chosen_stage),
		"stage=%s id=%s resolved=%s" % [
			_chosen_stage.id if _chosen_stage != null else "null",
			_chosen_id, random_select.resolved_stage_id])
	_check("RANDOM never records the sentinel instead of a stage id",
		_chosen_id != "" and _chosen_id != "random"
			and _chosen_id != "RANDOM", "id=%s" % _chosen_id)
	random_select.free()

	# ---- Gas-N-Go scene: layer order, native scale, ambience ----
	var gas: StageData = roster.stages[0]
	var stage: Node2D = gas.scene.instantiate()
	root.add_child(stage)
	await process_frame
	_check("Gas-N-Go keeps the authored 320x180 arena",
		stage.floor_y == 158.0 and stage.left_bound == 24.0
			and stage.right_bound == 296.0
			and stage.spawn_p1_x == 110.0 and stage.spawn_p2_x == 210.0,
		"floor=%s bounds=%s..%s spawns=%s/%s" % [stage.floor_y,
			stage.left_bound, stage.right_bound,
			stage.spawn_p1_x, stage.spawn_p2_x])
	_check("the stage pauses with the tree instead of animating under the menu",
		stage.process_mode == Node.PROCESS_MODE_PAUSABLE,
		"process_mode=%d" % stage.process_mode)

	var order := ["Sky", "Clouds", "Foreground", "SignText", "Gator",
		"Mosquitoes", "StageAnimation"]
	var actual_order: Array[String] = []
	for child in stage.get_children():
		actual_order.append(str(child.name))
	_check("layers draw Sky -> Clouds -> Foreground -> SignText -> Gator -> Mosquitoes",
		actual_order == order, "order=%s" % str(actual_order))
	_check("mosquitoes draw above the fighters",
		stage.get_node("Mosquitoes").z_index > 0,
		"z=%d" % stage.get_node("Mosquitoes").z_index)

	var expected_sizes := {
		"Sky": Vector2(320, 180),
		"Foreground": Vector2(320, 180),
		"SignText": Vector2(105, 30),
		"Gator": Vector2(81, 18),
	}
	for node_name: String in expected_sizes:
		var sprite: Sprite2D = stage.get_node(node_name)
		_check("%s uses native pixels at scale 1" % node_name,
			sprite.scale == Vector2.ONE and sprite.rotation == 0.0
				and sprite.texture.get_size() == expected_sizes[node_name],
			"scale=%s rotation=%s size=%s" % [sprite.scale, sprite.rotation,
				sprite.texture.get_size()])
	var clouds: Sprite2D = stage.get_node("Clouds/CloudA")
	_check("the cloud strip is the authored 640x44 row",
		clouds.texture.get_size() == Vector2(640, 44)
			and clouds.scale == Vector2.ONE)
	for mosquito_name: String in ["Mosquitoes/Mosquito1", "Mosquitoes/Mosquito2"]:
		var mosquito: Sprite2D = stage.get_node(mosquito_name)
		var bottom := mosquito.position.y + mosquito.texture.get_height()
		_check("%s stays in the upper sky, clear of the fight" % mosquito_name,
			mosquito.scale == Vector2.ONE and bottom < 100.0,
			"bottom=%s" % bottom)

	var animation: Node = stage.get_node("StageAnimation")
	animation.set_process(false)
	_check("cloud drift stays in the readable 4-6 px/s band",
		animation.cloud_speed >= 4.0 and animation.cloud_speed <= 6.0,
		"speed=%s" % animation.cloud_speed)
	_check("mosquitoes flap at 8 fps",
		is_equal_approx(animation.MOSQUITO_FRAME_SECONDS, 0.125),
		"interval=%s" % animation.MOSQUITO_FRAME_SECONDS)

	animation._cloud_offset = 0.0
	animation._elapsed = 0.0
	animation._mosquito_clock = 0.0
	animation._mosquito_frame = 0
	animation._gator_breath_clock = 0.0
	animation._gator_breath_frame = 0
	animation._gator_blink_remaining = 0.0
	animation._gator_blink_timer = 100.0
	animation._apply_gator_frame(0)
	animation._process(1.0)
	_check("one second drifts both cloud copies by 5 whole pixels",
		animation.cloud_offset() == 5.0
			and clouds.position.x == -5.0
			and stage.get_node("Clouds/CloudB").position.x == 635.0,
		"offset=%s a=%s b=%s" % [animation.cloud_offset(), clouds.position.x,
			stage.get_node("Clouds/CloudB").position.x])
	_check("one second flips the wingbeat and breathing frames",
		animation.mosquito_frame() == 1 and animation.gator_frame() == 1,
		"mosquito=%d gator=%d" % [animation.mosquito_frame(),
			animation.gator_frame()])

	animation.freeze_ambient = true
	animation._process(1.0)
	_check("the debug freeze holds every ambient position",
		animation.cloud_offset() == 5.0 and animation.gator_frame() == 1,
		"offset=%s gator=%d" % [animation.cloud_offset(),
			animation.gator_frame()])
	animation.freeze_ambient = false

	animation._cloud_offset = 639.0
	animation._process(1.0)
	_check("the cloud strip wraps instead of running off screen",
		animation.cloud_offset() == 4.0, "offset=%s" % animation.cloud_offset())

	animation._gator_blink_timer = 0.0
	animation._gator_blink_remaining = 0.0
	animation._process(0.01)
	_check("the gator blinks onto f3 after the random wait",
		animation.gator_frame() == 2, "frame=%d" % animation.gator_frame())
	animation._process(0.13)
	_check("the blink returns to the breathing frame",
		animation.gator_frame() != 2, "frame=%d" % animation.gator_frame())

	animation._process(0.333)
	var snapped := true
	for sprite: Sprite2D in [clouds, stage.get_node("Clouds/CloudB"),
			stage.get_node("Gator"), stage.get_node("Mosquitoes/Mosquito1"),
			stage.get_node("Mosquitoes/Mosquito2")]:
		if not is_equal_approx(sprite.position.x, roundf(sprite.position.x)) \
				or not is_equal_approx(sprite.position.y, roundf(sprite.position.y)):
			snapped = false
	_check("every ambient sprite position lands on a whole pixel", snapped)
	stage.free()

	# ---- MatchRoot: stage fallback and safe failure ----
	var fallback: Node = MATCH_SCENE.instantiate()
	fallback.roster = roster
	root.add_child(fallback)
	await process_frame
	_check("MatchRoot falls back to roster.stages[0]",
		fallback.setup_failed == false and fallback.selected_stage != null
			and fallback.selected_stage.id == "gas_n_go"
			and fallback.stage != null and fallback.p1 != null,
		"failed=%s stage=%s" % [str(fallback.setup_failed),
			fallback.selected_stage.id if fallback.selected_stage != null else "null"])
	fallback.free()

	var bad_roster := MatchRoster.new()
	var broken: Node = MATCH_SCENE.instantiate()
	broken.roster = bad_roster
	root.add_child(broken)
	await process_frame
	_check("MatchRoot stops without instantiating on an empty roster",
		broken.setup_failed and broken.stage == null and broken.p1 == null
			and not broken.is_physics_processing(),
		"failed=%s stage=%s p1=%s" % [str(broken.setup_failed),
			str(broken.stage), str(broken.p1)])
	broken.free()

	var bad_stage: StageData = StageData.new()
	bad_stage.id = "broken"
	var broken_stage_match: Node = MATCH_SCENE.instantiate()
	broken_stage_match.roster = roster
	broken_stage_match.selected_stage = bad_stage
	root.add_child(broken_stage_match)
	await process_frame
	_check("MatchRoot rejects a StageData without a scene",
		broken_stage_match.setup_failed
			and broken_stage_match.stage == null
			and broken_stage_match.p1 == null,
		"failed=%s stage=%s" % [str(broken_stage_match.setup_failed),
			str(broken_stage_match.stage)])
	broken_stage_match.free()

	await _finish()

func _finish() -> void:
	for _frame in 10:
		await process_frame
	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
