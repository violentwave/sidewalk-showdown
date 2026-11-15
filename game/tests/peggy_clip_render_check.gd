# Disposable rendered-verification capture for Peggy's authored clip set.
# Run: godot --path game --script res://tests/peggy_clip_render_check.gd (windowed)
# Writes PNG captures to /tmp/opencode/peggy_clip_check/ and a contact sheet.
extends SceneTree

const OUT := "/tmp/opencode/peggy_clip_check"
var captures := 0
var scene: Node2D

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred(scene)

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, tag]
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
	print("p1=", p1.data.id, " clip_lib=", p1._clip_library_valid,
		" p2=", p2.data.id, " clip_lib=", p2._clip_library_valid)
	await _grab("00_idle_both")

	# Walk (gated: approved static fallback) both directions
	p1._force_state(FighterBase.State.WALK_F)
	p2._force_state(FighterBase.State.WALK_B)
	await physics_frame
	await _grab("01_walk_fallback")

	# Crouch: authored crouch_hold clip
	p1._force_state(FighterBase.State.CROUCH)
	p2._force_state(FighterBase.State.CROUCH)
	for i in 14:
		await physics_frame
	await _grab("02_crouch_hold_authored")

	# Crouch exit: authored stand-up transient
	p1._force_state(FighterBase.State.IDLE)
	p2._force_state(FighterBase.State.IDLE)
	await physics_frame
	await _grab("03_crouch_up_transient")
	for i in 20:
		await physics_frame
	await _grab("04_idle_after_transient")

	# Jump start/rise/fall
	p1._force_state(FighterBase.State.JUMP_START)
	p2._force_state(FighterBase.State.JUMP_START)
	for i in 2:
		await physics_frame
	await _grab("05_jump_start")
	p1._force_state(FighterBase.State.JUMP_RISE)
	p1.velocity.y = -260.0
	p1.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	p2.grounded = false
	for i in 6:
		await physics_frame
	await _grab("06_jump_rise_fall")
	p1.grounded = true
	p2.grounded = true
	p1.position.y = 150.0
	p2.position.y = 150.0
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO

	# Light attack vs block, both facings
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	Input.action_press("p2_left") # Richard holds back (facing -1) => block
	p2._force_state(FighterBase.State.BLOCK_STAND)
	for i in 3:
		await physics_frame
	await _grab("07_light_startup")
	for i in 3:
		await physics_frame
	await _grab("08_light_active_vs_block")
	Input.action_release("p2_left")

	# Heavy attack
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	p1._start_move(heavy)
	for i in 9:
		await physics_frame
	await _grab("09_heavy_active")

	# Crouch attack
	var crouch_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.CROUCH)
	p1._force_state(FighterBase.State.CROUCH)
	p1._start_move(crouch_light)
	for i in 5:
		await physics_frame
	await _grab("10_crouch_light")

	# Hit reaction (standing) with hit flash
	p1._force_state(FighterBase.State.HITSTUN)
	p1.hitstun_frames = 14
	p1.hit_flash_frames = 3
	for i in 4:
		await physics_frame
	await _grab("11_hitstun_stand_flash")
	for i in 10:
		await physics_frame

	# Blockstun + special (peggy_neutral)
	var neutral: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	p1._start_move(neutral)
	p2._force_state(FighterBase.State.BLOCKSTUN)
	p2.block_flash_frames = 2
	for i in 11:
		await physics_frame
	await _grab("12_special_active_blockstun")

	# Air special
	var air_move: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	p1.grounded = false
	p1._start_move(air_move)
	for i in 14:
		await physics_frame
	await _grab("13_air_special")
	p1.grounded = true

	# Grab
	var grab: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p1._start_move(grab)
	for i in 7:
		await physics_frame
	await _grab("14_grab")

	# Knockdown -> wake up. Restore health first: the scripted attacks really
	# damage Richard, and a real KO would race the round-end reset and respawn
	# both fighters mid-capture.
	p1.health = 1000.0
	p2.health = 1000.0
	p1._force_state(FighterBase.State.KNOCKDOWN)
	p1.knockdown_frames = 30
	for i in 22:
		await physics_frame
	await _grab("15_knockdown")
	p1._force_state(FighterBase.State.WAKE_UP)
	p1.wakeup_frames = p1.data.wakeup_frames
	for i in 10:
		await physics_frame
	await _grab("16_wake_up")

	# KO (air then grounded hold)
	p1._force_state(FighterBase.State.KO)
	p1.grounded = false
	for i in 12:
		await physics_frame
	await _grab("17_ko_air")
	p1.grounded = true
	for i in 26:
		await physics_frame
	await _grab("18_ko_ground_hold")

	# Win
	p1._force_state(FighterBase.State.WIN)
	for i in 30:
		await physics_frame
	await _grab("19_win")

	# Facing swap: Peggy facing left through attack + crouch
	p1._force_state(FighterBase.State.IDLE)
	p1.position.x = 320.0
	p2.position.x = 120.0
	await physics_frame
	var light2: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light2)
	for i in 4:
		await physics_frame
	await _grab("20_attack_facing_left")
	p1._force_state(FighterBase.State.CROUCH)
	await physics_frame
	await _grab("21_crouch_facing_left")
	p1._force_state(FighterBase.State.IDLE)
	p2._force_state(FighterBase.State.IDLE)
	await physics_frame
	await _grab("22_back_to_idle_both")

	print("captures=", captures)
	_build_contact_sheet()
	quit()

func _build_contact_sheet() -> void:
	var dir := DirAccess.open(OUT)
	var names := []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".png") and not f.begins_with("contact"):
			names.append(f)
		f = dir.get_next()
	names.sort()
	var cols := 4
	var tw := 640
	var th := 360
	var rows := int(ceil(names.size() / float(cols)))
	var sheet := Image.create(cols * tw, rows * (th + 18), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.05, 0.05, 0.08))
	for idx in names.size():
		var img := Image.load_from_file(OUT + "/" + names[idx])
		if img == null:
			continue
		var s: float = min(float(tw) / img.get_width(), float(th) / img.get_height())
		var scaled: Image = img.duplicate()
		scaled.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_NEAREST)
		var cx: int = (idx % cols) * tw + int((tw - scaled.get_width()) / 2.0)
		var cy := (idx / cols) * (th + 18) + 18
		sheet.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), Vector2i(cx, cy))
	var out_path := OUT + "/contact_sheet.png"
	sheet.save_png(out_path)
	print("contact sheet: ", out_path)
