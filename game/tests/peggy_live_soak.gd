# Long live-input soak: real Input actions across a 3000-frame session.
# Validates every frame that exactly one art sprite is visible, the sprite's
# world-space rect is centred on the fighter, and its on-screen size is sane.
extends SceneTree

var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var failures := 0
var checked := 0
var min_c := Vector2(1e9, 1e9)
var max_c := Vector2(-1e9, -1e9)
var samples := 0

func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()

func _run() -> void:
	for i in 20:
		await physics_frame
	p1 = scene.p1
	p2 = scene.p2
	var keys := ["p1_right", "p1_left", "p1_down", "p1_up", "p1_light",
		"p1_heavy", "p1_special", "p1_grab", "p1_jump", "p2_left", "p2_light"]
	# Deterministic mash: hold directions, tap attacks, alternate.
	for i in 3000:
		var k: int = (i / 9) % keys.size()
		if i % 5 == 0:
			Input.action_press(keys[k])
		if i % 5 == 3:
			Input.action_release(keys[k])
		if i % 37 == 0:
			Input.action_press("p1_light")
		if i % 37 == 2:
			Input.action_release("p1_light")
		if i % 53 == 0:
			Input.action_press("p2_light")
		if i % 53 == 2:
			Input.action_release("p2_light")
		await physics_frame
		_validate()
	for k in keys:
		Input.action_release(k)
	print("checked=%d failures=%d center_min=%s center_max=%s samples=%d" % [
		checked, failures, str(min_c), str(max_c), samples])
	quit()

func _validate() -> void:
	checked += 1
	if p1 == null:
		return
	var idle_vis := p1.idle_sprite.visible
	var cut_vis := p1.character_sprite.visible
	if int(idle_vis) + int(cut_vis) != 1:
		_fail("visible-count")
		return
	var sp: Sprite2D = p1.idle_sprite if idle_vis else p1.character_sprite
	var tex: Texture2D = sp.texture
	if tex == null:
		_fail("null-texture")
		return
	# Frame rect in sprite-local space (centered=false / offset).
	var fw: float = float(tex.get_width()) / maxf(sp.hframes, 1)
	var fh: float = float(tex.get_height()) / maxf(sp.vframes, 1)
	var local := Rect2(sp.offset, Vector2(fw, fh))
	if sp.centered:
		local.position -= local.size * 0.5
	var world: Rect2 = sp.global_transform * local
	var centre := world.get_center()
	var dx := centre.x - p1.global_position.x
	var dy := centre.y - (p1.global_position.y - fh * absf(sp.scale.y) * 0.5)
	var h := fh * absf(sp.scale.y)
	# Body centre may legitimately shift a little with pose, but not far.
	if absf(dx) > 90.0 or h < 18.0 or h > 420.0:
		_fail("misplaced dx=%.1f h=%.1f state=%d" % [dx, h, p1.state])
	samples += 1
	min_c.x = minf(min_c.x, dx)
	max_c.x = maxf(max_c.x, dx)

func _fail(what: String) -> void:
	failures += 1
	if failures <= 15:
		print("BAD %s | state=%d clip=%s tex=%s off=%s scale=%s hf=%d" % [
			what, p1.state, str(p1._active_clip.get("path", "-")),
			(p1.idle_sprite.texture.resource_path if p1.idle_sprite.texture else "null"),
			str(p1.idle_sprite.offset), str(p1.idle_sprite.scale), p1.idle_sprite.hframes])
