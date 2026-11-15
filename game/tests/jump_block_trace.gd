# Disposable frame-by-frame trace of the jump and block presentation for P2.
# Run: DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tests/jump_block_trace.gd
# Prints state/state_frame/clip/cel/scale/y every frame and writes a filmstrip
# so presentation pops can be seen, not guessed.
extends SceneTree

const OUT := "/tmp/opencode/jump_block_trace"
var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var n := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%03d_%s.png" % [OUT, n, tag])
	n += 1

func _snap(tag: String, extra := "") -> void:
	var clip := str(p2._active_clip.get("path", "-")).get_file().replace(".png", "")
	print("%-22s st=%-2d f=%-3d clip=%-18s cel=%-2d scale=%.4f y=%6.1f gr=%s %s" % [
		tag, p2.state, p2.state_frame, clip, p2.idle_sprite.frame,
		p2.idle_sprite.scale.x, p2.position.y, str(p2.grounded), extra])

func _wait_phase() -> void:
	for i in 400:
		await physics_frame
		if scene.phase == 1:
			return

func _release_all() -> void:
	for k in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_light",
			"p2_left", "p2_right", "p2_up", "p2_down", "p2_light"]:
		Input.action_release(k)

func _run() -> void:
	await _wait_phase()
	p1 = scene.p1
	p2 = scene.p2
	print("p2=", p2.data.id, " facing=", p2.facing, " waiting 40f")
	for i in 40:
		await physics_frame
	_release_all()

	# ---- JUMP: one-frame press of p2_up, then free fall to landing ----
	print("\n=== JUMP ===")
	print("facing=", p2.facing, " x p1=", p1.position.x, " p2=", p2.position.x)
	Input.action_press("p2_up")
	await physics_frame
	Input.action_release("p2_up")
	for i in 55:
		await physics_frame
		_snap("jump%02d" % i)
		await _grab("jump%02d" % i)
		if p2.grounded and p2.state == FighterBase.State.IDLE and i > 5:
			break
	for i in 20:
		await physics_frame

	# ---- BLOCK: hold away from opponent inside light range, p1 attacks ----
	print("\n=== BLOCK ===")
	var away := "p2_right" if p2.facing < 0 else "p2_left"
	print("facing=", p2.facing, " away=", away)
	p2.position.x = p1.position.x + 46.0
	Input.action_press(away)
	for i in 4:
		await physics_frame
		_snap("guard_hold%02d" % i, "blocking=%s" % str(p2.is_blocking()))
		await _grab("guard_hold%02d" % i)
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	for i in 34:
		p2.position.x = p1.position.x + 44.0
		await physics_frame
		p2.position.x = p1.position.x + 44.0
		_snap("block%02d" % i, "blockstun=%d blocking=%s" % [
			p2.blockstun_frames, str(p2.is_blocking())])
		await _grab("block%02d" % i)
	Input.action_release(away)
	for i in 10:
		await physics_frame
		_snap("release%02d" % i)
		await _grab("release%02d" % i)
	print("frames=", n)
	quit()
