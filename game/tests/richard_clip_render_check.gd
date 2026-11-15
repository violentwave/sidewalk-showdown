# Disposable rendered-verification capture for Whiskey Richard's authored clip set.
# Run: DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tests/richard_clip_render_check.gd
# Writes PNG captures to /tmp/opencode/richard_clip_check/ and a contact sheet.
extends SceneTree

const OUT := "/tmp/opencode/richard_clip_check"
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
	var p2: FighterBase = scene.p2
	p2.input_enabled = false
	print("p2=", p2.data.id, " clip_lib=", p2._clip_library_valid,
		" lib=", p2._clip_lib.resource_path.get_file())
	await _grab("00_idle")

	# Walk cycle (authored for Richard, unlike Peggy's gated JPEGs), both dirs.
	p2._force_state(FighterBase.State.WALK_F)
	for i in 12:
		await physics_frame
	await _grab("01_walk_forward")
	p2._force_state(FighterBase.State.WALK_B)
	for i in 12:
		await physics_frame
	await _grab("02_walk_backward")

	# Crouch: authored crouch_hold clip
	p2._force_state(FighterBase.State.CROUCH)
	for i in 14:
		await physics_frame
	await _grab("03_crouch_hold_authored")

	# Crouch exit: authored stand-up transient
	p2._force_state(FighterBase.State.IDLE)
	await physics_frame
	await _grab("04_crouch_up_transient")
	for i in 20:
		await physics_frame
	await _grab("05_idle_after_transient")

	# Jump start/rise/fall
	p2._force_state(FighterBase.State.JUMP_START)
	for i in 2:
		await physics_frame
	await _grab("06_jump_start")
	p2._force_state(FighterBase.State.JUMP_RISE)
	p2.velocity.y = -260.0
	p2.grounded = false
	for i in 6:
		await physics_frame
	await _grab("07_jump_rise")
	p2._force_state(FighterBase.State.JUMP_FALL)
	for i in 6:
		await physics_frame
	await _grab("08_jump_fall")
	p2.grounded = true
	p2.position.y = 150.0
	p2.velocity = Vector2.ZERO

	# Light attack vs block, both facings
	var light: MoveData = p2.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p2._start_move(light)
	for i in 3:
		await physics_frame
	await _grab("09_light_startup")
	for i in 3:
		await physics_frame
	await _grab("10_light_active")

	# Heavy attack
	var heavy: MoveData = p2.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	p2._start_move(heavy)
	for i in 9:
		await physics_frame
	await _grab("11_heavy_active")

	# Crouch attack
	var crouch_light: MoveData = p2.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.CROUCH)
	p2._force_state(FighterBase.State.CROUCH)
	p2._start_move(crouch_light)
	for i in 5:
		await physics_frame
	await _grab("12_crouch_light")

	# Hit reaction (standing) with hit flash
	p2._force_state(FighterBase.State.HITSTUN)
	p2.hitstun_frames = 14
	p2.hit_flash_frames = 3
	for i in 4:
		await physics_frame
	await _grab("13_hitstun_stand_flash")
	for i in 10:
		await physics_frame

	# Blockstun + specials (richard_neutral, richard_forward_ex)
	var neutral: MoveData = p2.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	p2._start_move(neutral)
	for i in 11:
		await physics_frame
	await _grab("14_special_active")
	p2._force_state(FighterBase.State.BLOCKSTUN)
	p2.block_flash_frames = 2
	for i in 6:
		await physics_frame
	await _grab("15_blockstun")

	# Air special
	var air_move: MoveData = p2.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	p2.grounded = false
	p2._start_move(air_move)
	for i in 14:
		await physics_frame
	await _grab("16_air_special")
	p2.grounded = true

	# Grab + command grab
	var grab: MoveData = p2.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p2._start_move(grab)
	for i in 7:
		await physics_frame
	await _grab("17_grab")
	var cgrab: MoveData = p2.data.find_move(MoveData.InputType.COMMAND_GRAB, MoveData.Stance.STAND)
	p2._start_move(cgrab)
	for i in 7:
		await physics_frame
	await _grab("18_command_grab")

	# Knockdown -> wake up. Restore health first: the scripted attacks really
	# damage Peggy, and a real KO would race the round-end reset.
	p2.health = 1000.0
	p2._force_state(FighterBase.State.KNOCKDOWN)
	p2.knockdown_frames = 30
	for i in 22:
		await physics_frame
	await _grab("19_knockdown")
	p2._force_state(FighterBase.State.WAKE_UP)
	p2.wakeup_frames = p2.data.wakeup_frames
	for i in 10:
		await physics_frame
	await _grab("20_wake_up")

	# KO (air then grounded hold)
	p2._force_state(FighterBase.State.KO)
	p2.grounded = false
	for i in 12:
		await physics_frame
	await _grab("21_ko_air")
	p2.grounded = true
	for i in 26:
		await physics_frame
	await _grab("22_ko_ground_hold")

	# Win
	p2._force_state(FighterBase.State.WIN)
	for i in 30:
		await physics_frame
	await _grab("23_win")

	# Facing swap: Richard facing left through attack + crouch
	p2._force_state(FighterBase.State.IDLE)
	p2.position.x = 320.0
	scene.p1.position.x = 120.0
	await physics_frame
	var light2: MoveData = p2.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p2._start_move(light2)
	for i in 4:
		await physics_frame
	await _grab("24_attack_facing_left")
	p2._force_state(FighterBase.State.CROUCH)
	await physics_frame
	await _grab("25_crouch_facing_left")
	p2._force_state(FighterBase.State.IDLE)
	scene.p1._force_state(FighterBase.State.IDLE)
	await physics_frame
	await _grab("26_back_to_idle")

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
		var cy: int = (idx / cols) * (th + 18) + 18
		sheet.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), Vector2i(cx, cy))
	var out_path := OUT + "/contact_sheet.png"
	sheet.save_png(out_path)
	print("contact sheet: ", out_path)
