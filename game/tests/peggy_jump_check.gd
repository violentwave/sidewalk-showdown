extends SceneTree
const OUT := "/tmp/opencode/peggy_jump"
var scene: Node2D
var p1: FighterBase
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

func _run() -> void:
	for i in 400:
		await physics_frame
		if scene.phase == 1:
			break
	p1 = scene.p1
	Input.action_press("p1_up")
	await physics_frame
	Input.action_release("p1_up")
	for i in 34:
		await physics_frame
		if i % 3 == 0:
			print("f%02d state=%d clip=%s frame=%d scale=%.3f grounded=%s y=%.1f" % [
				i, p1.state, p1._active_clip.get("path", "-").get_file(),
				p1.idle_sprite.frame, p1.idle_sprite.scale.x, str(p1.grounded), p1.position.y])
			await _grab("j%02d_s%d" % [i, p1.state])
	print("frames=", n)
	quit()
