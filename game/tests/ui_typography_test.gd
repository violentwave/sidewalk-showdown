# ui_typography_test.gd — Phase 1 typography rules as assertions
# (docs/UI_SCREENS.md "Typography rules"): every Label / RichTextLabel in
# the Phase 1 screens (content warning, title, main menu, settings
# overlay, quit confirm, and the pause menu) must use one of the two pixel
# fonts at its native size (Sidewalk Marker 10 / m5x7 16), carry no Godot
# theme outline or shadow, sit at an integer position, and never be
# scaled. Bangers is only allowed inside the logo art, not as live text.
extends SceneTree

const MARKER := preload("res://assets/fonts/sidewalk_marker.fnt")
const MARKER_OUTLINE := preload("res://assets/fonts/sidewalk_marker_outline.fnt")
const M5X7 := preload("res://assets/fonts/m5x7.ttf")

const SCREEN_SCENES := [
	["content warning", "res://scenes/menus/content_warning.tscn"],
	["title", "res://scenes/menus/title.tscn"],
	["main menu", "res://scenes/menus/main_menu.tscn"],
	["settings overlay", "res://scenes/menus/settings_overlay.tscn"],
	["quit confirm", "res://scenes/menus/quit_confirm.tscn"],
]
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _collect_labels(node: Node, labels: Array) -> void:
	if node is Label or node is RichTextLabel:
		labels.append(node)
	for child in node.get_children():
		_collect_labels(child, labels)


func _typography_problems(labels: Array) -> Array[String]:
	var problems: Array[String] = []
	for node in labels:
		var where := "%s (%s)" % [str(node.name), node.get_class()]
		var font: Font = node.get_theme_font("font")
		var size: int = node.get_theme_font_size("font_size")
		var native := false
		if font == MARKER or font == MARKER_OUTLINE:
			native = size == 10
		elif font == M5X7:
			native = size == 16
		if not native:
			problems.append("%s: not a pixel font at native size (size %d)" % [where, size])
		if node.get_theme_constant("outline_size") != 0:
			problems.append("%s: has a theme outline" % where)
		if node.get_theme_color("font_shadow_color").a != 0.0:
			problems.append("%s: has a shadow color" % where)
		if node.position.x != roundi(node.position.x) or node.position.y != roundi(node.position.y):
			problems.append("%s: fractional position %s" % [where, str(node.position)])
		if node.scale != Vector2.ONE:
			problems.append("%s: scaled %s" % [where, str(node.scale)])
	return problems


func _run() -> void:
	await process_frame

	var total_labels := 0
	for entry in SCREEN_SCENES:
		var scene: Node = load(entry[1]).instantiate()
		root.add_child(scene)
		await process_frame
		var labels: Array = []
		_collect_labels(scene, labels)
		total_labels += labels.size()
		var problems := _typography_problems(labels)
		_check("every label in the %s follows the typography rules" % entry[0],
			problems.is_empty(), "; ".join(problems))
		scene.free()
		await process_frame

	# The pause menu (match_hud.gd pause_root) through a real MatchRoot.
	var match_root: Node = MATCH_SCENE.instantiate()
	root.add_child(match_root)
	await process_frame
	await physics_frame
	match_root._toggle_pause()
	var pause_labels: Array = []
	_collect_labels(match_root.hud.pause_root, pause_labels)
	total_labels += pause_labels.size()
	var pause_problems := _typography_problems(pause_labels)
	_check("every label in the pause menu follows the typography rules",
		pause_problems.is_empty(), "; ".join(pause_problems))
	_check("the typography scan actually saw labels (%d)" % total_labels,
		total_labels >= 25, "only %d label(s) found" % total_labels)
	match_root.free()

	print("ui_typography_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)
