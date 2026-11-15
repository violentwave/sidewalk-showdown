# Disposable rendered check for the jump / landing / guard playback fixes.
# Run: DISPLAY=:0 godot --path game --resolution 1280x720 --script res://tests/jump_block_render_check.gd
# Drives exact state frames (deterministic) and writes crops to
# /tmp/opencode/jump_block_check/ so the ordered poses can be eyeballed.
extends SceneTree

const OUT := "/tmp/opencode/jump_block_check"
var captures := 0
var scene: Node2D

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [OUT, captures, tag])
	captures += 1
	print("saved ", tag)

func _pose(f: FighterBase, st: int, frame: int, tag: String) -> void:
	f._force_state(st)
	f.state_frame = frame
	f._sync_visuals()
	await _grab(tag)

func _run() -> void:
	for i in 70:
		await physics_frame
	var p2: FighterBase = scene.p2
	var p1: FighterBase = scene.p1
	p1.input_enabled = false
	p2.input_enabled = false
	p2.position.x = 400.0
	p1.position.x = 120.0

	# Jump arc in authored order: crouch -> launch -> tuck -> airborne -> absorb.
	await _pose(p2, FighterBase.State.JUMP_START, 0, "jump_start_c0")
	await _pose(p2, FighterBase.State.JUMP_START, 1, "jump_start_c1")
	await _pose(p2, FighterBase.State.JUMP_RISE, 0, "jump_rise_c0")
	await _pose(p2, FighterBase.State.JUMP_RISE, 6, "jump_rise_c1")
	await _pose(p2, FighterBase.State.JUMP_FALL, 0, "jump_fall_early")
	await _pose(p2, FighterBase.State.JUMP_FALL, 14, "jump_fall_late")
	await _pose(p2, FighterBase.State.LAND, 0, "land_absorb")
	await _pose(p2, FighterBase.State.LAND, 1, "land_recover")

	# Walk wrap: the cycle must keep moving instead of freezing on cel 5.
	await _pose(p2, FighterBase.State.WALK_B, 0, "walk_b_c0")
	await _pose(p2, FighterBase.State.WALK_B, 18, "walk_b_c3")
	await _pose(p2, FighterBase.State.WALK_B, 36, "walk_b_wrap")
	await _pose(p2, FighterBase.State.WALK_F, 12, "walk_f_c2")

	# Guard presentation at the wall, crouch guard, and the two blockstun poses.
	p2._force_state(FighterBase.State.IDLE)
	p2._sync_visuals()
	await _grab("idle_reference")
	p2.input_enabled = true
	Input.action_press("p2_right") # p2 faces left, so right is back
	p2.position.x = p2.stage.right_bound
	p2.velocity.x = p2.walk_speed_back
	p2._force_state(FighterBase.State.WALK_B)
	p2._sync_visuals()
	await _grab("guard_stand_wall")
	await _pose(p2, FighterBase.State.CROUCH, 0, "guard_crouch")
	Input.action_release("p2_right")
	p2.input_enabled = false
	p2.position.x = 400.0
	await _pose(p2, FighterBase.State.BLOCKSTUN, 0, "blockstun_stand_c0")
	await _pose(p2, FighterBase.State.BLOCKSTUN, 7, "blockstun_stand_c1")
	await _pose(p2, FighterBase.State.CROUCH, 0, "crouch_hold")
	print("captures=", captures)
	_build_sheet()
	quit()

func _build_sheet() -> void:
	var dir := DirAccess.open(OUT)
	var names := []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".png") and not f.begins_with("sheet"):
			names.append(f)
		f = dir.get_next()
	names.sort()
	var cols := 4
	var tw := 560
	var th := 420
	var rows := int(ceil(names.size() / float(cols)))
	var sheet := Image.create(cols * tw, rows * (th + 16), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.05, 0.05, 0.08))
	for idx in names.size():
		var img := Image.load_from_file(OUT + "/" + names[idx])
		if img == null:
			continue
		var cw := img.get_width()
		var crop := img.get_region(Rect2i(int(cw * 0.55), int(img.get_height() * 0.18),
			int(cw * 0.30), int(img.get_height() * 0.76)))
		var s: float = min(float(tw) / crop.get_width(), float(th) / crop.get_height())
		crop.resize(maxi(1, int(crop.get_width() * s)), maxi(1, int(crop.get_height() * s)),
			Image.INTERPOLATE_NEAREST)
		var x: int = (idx % cols) * tw + int((tw - crop.get_width()) / 2.0)
		var y: int = (idx / cols) * (th + 16) + 16
		sheet.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(x, y))
	sheet.save_png(OUT + "/sheet.png")
	print("sheet: ", OUT + "/sheet.png")
