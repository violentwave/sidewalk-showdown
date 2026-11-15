# Rendered/traced jump-scale check for Whiskey Richard's authored jump clips.
# Run: godot --path game --script res://tests/richard_jump_check.gd (windowed)
# Prints per-frame clip/frame/scale and confirms the authored jump clips hold a
# constant art scale (no size pop) through the whole airborne arc.
extends SceneTree

const OUT := "/tmp/opencode/richard_jump"
var scene: Node2D
var p2: FighterBase
var n := 0
var seen_scales := {}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [OUT, n, tag])
	n += 1

func _run() -> void:
	for i in 400:
		await physics_frame
		if scene.phase == 1:
			break
	p2 = scene.p2
	Input.action_press("p2_up")
	await physics_frame
	Input.action_release("p2_up")
	for i in 40:
		await physics_frame
		var clip := str(p2._active_clip.get("path", "-")).get_file()
		if clip != "-" and not p2._active_clip.is_empty():
			seen_scales[clip] = p2.idle_sprite.scale.x
		if i % 2 == 0:
			print("f%02d state=%d clip=%s frame=%d scale=%.4f grounded=%s y=%.1f" % [
				i, p2.state, clip, p2.idle_sprite.frame, p2.idle_sprite.scale.x,
				str(p2.grounded), p2.position.y])
			await _grab("j%02d_s%d" % [i, p2.state])
	print("frames=", n, " scales=", str(seen_scales))
	quit()
