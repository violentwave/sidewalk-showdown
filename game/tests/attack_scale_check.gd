# Disposable size-consistency capture for the attack/air clips whose measured
# h_ref differs most from the idle art scale.
extends SceneTree

const OUT := "/tmp/opencode/attack_scale_check"
var scene: Node2D
var n := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [OUT, n, tag])
	n += 1
	print("saved ", tag)

func _run() -> void:
	for i in 70:
		await physics_frame
	var p2: FighterBase = scene.p2
	p2.input_enabled = false
	p2.position.x = 400.0
	scene.p1.position.x = 120.0
	p2._force_state(FighterBase.State.IDLE)
	p2._sync_visuals()
	await _grab("idle")
	for spec in [
		["forward", MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND],
		["forward_ex", MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND],
		["jump_heavy", MoveData.InputType.HEAVY, MoveData.Stance.AIR],
		["meth", MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND],
		["air", MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR],
	]:
		var tag := str(spec[0])
		var mv: MoveData = null
		if tag == "meth":
			mv = p2.data.meth_move
		elif tag == "forward_ex":
			for m: MoveData in p2.data.moves:
				if m.id == "richard_forward_ex":
					mv = m
		else:
			mv = p2.data.find_move(spec[1], spec[2])
		if mv == null:
			print("missing ", tag)
			continue
		p2.grounded = mv.stance != MoveData.Stance.AIR
		p2._force_state(FighterBase.State.ATTACK)
		p2.current_move = mv
		p2.state_frame = mv.startup
		p2._sync_visuals()
		await _grab(tag + "_active")
		p2.current_move = null
		p2._force_state(FighterBase.State.IDLE)
		p2.grounded = true
	print("captures=", n)
	quit()
