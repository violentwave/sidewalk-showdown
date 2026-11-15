# Long live-input soak for Whiskey Richard's authored clip set.
# Mirrors peggy_live_soak.gd but validates p2 (Richard) every frame: exactly one
# art sprite visible, its world-space rect centred on the fighter, and a sane
# on-screen size, across 3000 frames of mashed real input.
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
	var keys := ["p2_right", "p2_left", "p2_down", "p2_up", "p2_light",
		"p2_heavy", "p2_special", "p2_grab", "p2_meth", "p1_left", "p1_light"]
	for i in 3000:
		var k: int = (i / 9) % keys.size()
		if i % 5 == 0:
			Input.action_press(keys[k])
		if i % 5 == 3:
			Input.action_release(keys[k])
		if i % 37 == 0:
			Input.action_press("p2_light")
		if i % 37 == 2:
			Input.action_release("p2_light")
		if i % 53 == 0:
			Input.action_press("p1_light")
		if i % 53 == 2:
			Input.action_release("p1_light")
		await physics_frame
		_validate()
	for k in keys:
		Input.action_release(k)
	print("checked=%d failures=%d center_min=%s center_max=%s samples=%d" % [
		checked, failures, str(min_c), str(max_c), samples])
	quit()

func _validate() -> void:
	checked += 1
	if p2 == null:
		return
	var idle_vis := p2.idle_sprite.visible
	var cut_vis := p2.character_sprite.visible
	if int(idle_vis) + int(cut_vis) != 1:
		_fail("visible-count")
		return
	var sp: Sprite2D = p2.idle_sprite if idle_vis else p2.character_sprite
	var tex: Texture2D = sp.texture
	if tex == null:
		_fail("null-texture")
		return
	var fw: float = float(tex.get_width()) / maxf(sp.hframes, 1)
	var fh: float = float(tex.get_height()) / maxf(sp.vframes, 1)
	var local := Rect2(sp.offset, Vector2(fw, fh))
	if sp.centered:
		local.position -= local.size * 0.5
	var world: Rect2 = sp.global_transform * local
	var centre := world.get_center()
	var dx := centre.x - p2.global_position.x
	var h := fh * absf(sp.scale.y)
	if absf(dx) > 90.0 or h < 18.0 or h > 420.0:
		_fail("misplaced dx=%.1f h=%.1f state=%d" % [dx, h, p2.state])
	samples += 1
	min_c.x = minf(min_c.x, dx)
	max_c.x = maxf(max_c.x, dx)

func _fail(what: String) -> void:
	failures += 1
	if failures <= 15:
		print("BAD %s | state=%d clip=%s tex=%s off=%s scale=%s hf=%d" % [
			what, p2.state, str(p2._active_clip.get("path", "-")),
			(p2.idle_sprite.texture.resource_path if p2.idle_sprite.texture else "null"),
			str(p2.idle_sprite.offset), str(p2.idle_sprite.scale), p2.idle_sprite.hframes])
