extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var bg: Sprite2D = scene.stage.get_node("Background")
	print("root.size=", root.size, " content_scale_size=", root.content_scale_size,
		" mode=", root.content_scale_mode, " aspect=", root.content_scale_aspect,
		" factor=", root.content_scale_factor)
	print("texture=", bg.texture.get_size(), " scale=", bg.scale, " global_scale=", bg.global_scale)
	print("viewport.get_visible_rect=", root.get_visible_rect())
	quit()
