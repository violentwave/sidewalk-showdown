# Disposable rendered-verification capture for the idle sheet integration.
# Run: godot --path game --script res://tests/idle_render_check.gd  (windowed)
extends SceneTree

var captures := 0

func _initialize() -> void:
	var scene: Node2D = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred(scene)

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "/tmp/opencode/idle_check/%s.png" % tag
	img.save_png(path)
	captures += 1
	print("saved ", path)

func _run(scene: Node2D) -> void:
	for i in 70:
		await physics_frame
	var p1: FighterBase = scene.p1
	var p2: FighterBase = scene.p2
	p1.input_enabled = false
	p2.input_enabled = false
	print("phase=", scene.phase, " p1=", p1.data.id, " p2=", p2.data.id)
	# One idle cel for reference
	await _grab("00_idle")
	# Idle -> walk (both fighters)
	p1._force_state(FighterBase.State.WALK_F)
	p2._force_state(FighterBase.State.WALK_B)
	await physics_frame
	await _grab("01_walk")
	# Crouch
	p1._force_state(FighterBase.State.CROUCH)
	p2._force_state(FighterBase.State.CROUCH)
	await physics_frame
	await _grab("02_crouch")
	# Jump
	p1._force_state(FighterBase.State.JUMP_RISE)
	p1.velocity.y = -260.0
	p1.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	p2.grounded = false
	await physics_frame
	await _grab("03_jump")
	p1.grounded = true
	p2.grounded = true
	# Attack
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	p2._force_state(FighterBase.State.BLOCK_STAND)
	for i in 6:
		await physics_frame
	await _grab("04_attack")
	# Hit reaction on p1 (light, no knockdown), block feedback on p2
	p1._force_state(FighterBase.State.HITSTUN)
	p1.hitstun_frames = 30
	p1.hit_flash_frames = 3
	p1._update_silhouette_flash()
	p2.block_flash_frames = 2
	p2._update_silhouette_flash()
	await physics_frame
	await _grab("05_hit_block_flash")
	# Back to idle, both facings
	p1._force_state(FighterBase.State.IDLE)
	p2._force_state(FighterBase.State.IDLE)
	await physics_frame
	await _grab("06_back_to_idle")
	p1.position.x = 320.0
	p2.position.x = 120.0
	await physics_frame
	await _grab("07_idle_facing_swapped")
	print("captures=", captures)
	quit()
