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
	["mode select", "res://scenes/menus/ModeSelect.tscn"],
	["difficulty select", "res://scenes/menus/DifficultySelect.tscn"],
	["character select", "res://scenes/menus/CharacterSelect.tscn"],
	["stage select", "res://scenes/menus/StageSelect.tscn"],
]
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")

var failures := 0
var cardboard_labels := 0
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
		# Every character exists in the label's font (no missing-glyph boxes).
		var text_value: String = node.text
		for i in text_value.length():
			var code := text_value.unicode_at(i)
			if code > 32 and not font.has_char(code):
				problems.append("%s: font has no glyph for '%s'" % [where, text_value[i]])
				break
		# Labels on a cardboard Panel fit inside it and use the dark inks.
		var panel := _panel_under(node)
		if panel != null and node.is_visible_in_tree() and not text_value.is_empty():
			cardboard_labels += 1
			var panel_rect := Rect2(panel.global_position, panel.size)
			var label_rect := Rect2(node.global_position, node.size)
			if not panel_rect.encloses(label_rect):
				problems.append("%s: %s spills out of its panel %s" % [where, str(label_rect), str(panel_rect)])
			var c: Color = node.get_theme_color("font_color")
			if not (c.is_equal_approx(UiText.INK) or c.is_equal_approx(UiText.INK_MUTED) or c.is_equal_approx(UiText.INK_DARK)):
				problems.append("%s: light text %s on cardboard" % [where, c.to_html(false)])
	return problems


func _panel_under(node: Control) -> Panel:
	# Panels are drawn as siblings behind their text, so a label belongs to
	# the visible Panel its center sits on (the smallest one, if nested).
	var center: Vector2 = node.global_position + node.size * 0.5
	var best: Panel = null
	for p in root.find_children("*", "Panel", true, false):
		if not p.is_visible_in_tree():
			continue
		var r := Rect2(p.global_position, p.size)
		if r.has_point(center) and (best == null or r.get_area() < best.size.x * best.size.y):
			best = p
	return best


func _ink_core(node: Control) -> Rect2:
	# The label's DRAWN ink band, not its rect: rows like the settings
	# label/value pairs share a row with rects that touch, so overlap is
	# measured on the text extents — horizontally the ink inside the rect
	# per alignment, vertically a centered 8 px core (m5x7/marker line boxes
	# are taller than the ink, and stacked wall text uses 10 px spacing).
	var label := node as Label
	var font: Font = label.get_theme_font("font")
	var size: int = label.get_theme_font_size("font_size")
	var ink_width := font.get_string_size(label.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := label.global_position.x
	match label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			x += (label.size.x - ink_width) / 2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			x += label.size.x - ink_width
	var height: float = minf(label.size.y, 8.0)
	var top: float = label.global_position.y + (label.size.y - height) / 2.0
	return Rect2(Vector2(x, top), Vector2(ink_width, height))


func _overlap_problems(labels: Array) -> Array[String]:
	# PM review fix-ups: no two visible, non-empty labels may overlap on any
	# screen. The two PR A bugs (ticket names wider than their columns
	# overlapping the neighbouring name, rap-sheet text overhanging into
	# neighbouring rows) both fail this on the old code.
	var problems: Array[String] = []
	var visible: Array = []
	for node in labels:
		if node.is_visible_in_tree() and not node.text.is_empty():
			visible.append(node)
	for i in visible.size():
		for j in range(i + 1, visible.size()):
			var a: Control = visible[i]
			var b: Control = visible[j]
			if _ink_core(a).intersects(_ink_core(b)):
				problems.append("'%s' overlaps '%s'" % [a.text, b.text])
	return problems


func _card_problems(labels: Array, scene: Node) -> Array[String]:
	# PM review fix-ups: every label drawn over a TextureRect card (the rap
	# sheet, the tickets, the taped button) must lie fully inside that card.
	# Full-screen background art is not a card.
	var problems: Array[String] = []
	var cards: Array = []
	for n in scene.find_children("*", "TextureRect", true, false):
		var card := n as TextureRect
		if not card.is_visible_in_tree():
			continue
		if card.size.x >= 320.0 and card.size.y >= 180.0:
			continue  # full-screen background art
		if card.size.y < 12.0:
			continue  # highlight strips (the lit price slat) are not cards
		cards.append(card)
	for node in labels:
		if not node.is_visible_in_tree() or node.text.is_empty():
			continue
		var label_rect := Rect2(node.global_position, node.size)
		for card in cards:
			var card_rect := Rect2(card.global_position, card.size)
			if card_rect.intersects(label_rect) and not card_rect.encloses(label_rect):
				problems.append("%s '%s' spills off its card %s" % [
					str(node.name), node.text, str(card_rect)])
				break
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
		var label_overlaps := _overlap_problems(labels)
		_check("no two visible labels overlap in the %s" % entry[0],
			label_overlaps.is_empty(), "; ".join(label_overlaps))
		var card_problems := _card_problems(labels, scene)
		_check("every label over a card in the %s lies inside it" % entry[0],
			card_problems.is_empty(), "; ".join(card_problems))
		scene.free()
		await process_frame

	# The prompt line's key/label pairs never overlap each other (PR #86
	# review: "[BKSP] BACK" was drawn on top of "[ENTER]").
	var menu: Node = load("res://scenes/menus/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var prompt_labels: Array = []
	for n in menu.find_children("*", "UiPromptLine", true, false):
		for c in n.get_children():
			if c is Label and c.visible and not c.text.is_empty():
				prompt_labels.append(c)
	var overlaps: Array[String] = []
	for i in prompt_labels.size():
		for j in range(i + 1, prompt_labels.size()):
			var a: Label = prompt_labels[i]
			var b: Label = prompt_labels[j]
			if Rect2(a.global_position, a.size).intersects(Rect2(b.global_position, b.size)):
				overlaps.append("'%s' overlaps '%s'" % [a.text, b.text])
	_check("the main menu prompt line has visible labels (%d)" % prompt_labels.size(),
		prompt_labels.size() >= 4, "found %d" % prompt_labels.size())
	_check("no two prompt-line labels overlap", overlaps.is_empty(), "; ".join(overlaps))
	menu.free()
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
	_check("the panel checks actually saw cardboard labels (%d)" % cardboard_labels,
		cardboard_labels >= 15, "only %d" % cardboard_labels)
	match_root.free()

	print("ui_typography_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)
