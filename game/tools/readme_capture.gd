# Dev tool: capture README/documentation screenshots of the three main screens.
# Captures go to /tmp/opencode/readme/ so nothing lands in the repo until the
# image is reviewed and copied deliberately.
#
# Usage:
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/readme_capture.gd -- <theclip|select|match>
#
# `match` poses a readable mid-round moment with debug boxes off; `theclip` and
# `select` capture the intro panel and the character-select screen.
extends SceneTree

const OUT := "/tmp/opencode/readme"

var _mode := "match"
var _scene: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_mode = str(args[0])
	match _mode:
		"theclip":
			_scene = load("res://scenes/menus/TheClip.tscn").instantiate()
		"select":
			_scene = load("res://scenes/menus/CharacterSelect.tscn").instantiate()
		_:
			_scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(_scene)
	_run.call_deferred()

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, tag])
	print("saved ", tag)

func _run() -> void:
	match _mode:
		"theclip":
			# First comic panel: needs a few frames for text/art layout.
			for i in 30:
				await physics_frame
			await _grab("theclip")
		"select":
			for i in 30:
				await physics_frame
			await _grab("select")
		_:
			await _run_match()
	quit()

func _run_match() -> void:
	for i in 60:
		await physics_frame
	while _scene.phase != 1:
		await physics_frame
	for i in 240:
		await physics_frame

	var p1: FighterBase = _scene.p1
	var p2: FighterBase = _scene.p2
	p1.input_enabled = false
	p2.input_enabled = false
	_scene.debug_overlay.show_boxes = false
	_scene.hud.commentary_panel.visible = false

	p1.position.x = 176.0
	p2.position.x = 264.0
	p1.facing = 1
	p2.facing = -1
	p1.health = 760.0
	p2.health = 430.0
	p1.meter = 62.0
	p2.meter = 38.0
	# HUD bars listen for these signals, so emit after posing the values.
	p1.health_changed.emit(p1.health, p1.max_health)
	p2.health_changed.emit(p2.health, p2.max_health)
	p1.meter_changed.emit(p1.meter, p1.max_meter)
	p2.meter_changed.emit(p2.meter, p2.max_meter)
	p1._force_state(FighterBase.State.IDLE)
	p2._force_state(FighterBase.State.IDLE)
	p1.state_frame = 0
	p2.state_frame = 0
	p1._sync_visuals()
	p2._sync_visuals()
	await _grab("gameplay")

	# Action variant: Peggy's heavy active against Richard's raised stand guard.
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	p1._force_state(FighterBase.State.ATTACK)
	p1.current_move = heavy
	p1.state_frame = heavy.startup + 1
	p1._sync_visuals()
	p2.input_enabled = true
	Input.action_press("p2_right") # p2 faces left: right is back
	p2.velocity.x = p2.walk_speed_back
	p2._force_state(FighterBase.State.WALK_B)
	p2._sync_visuals()
	await _grab("gameplay_action")
	Input.action_release("p2_right")
	p1.current_move = null
	_scene.debug_overlay.show_boxes = true
