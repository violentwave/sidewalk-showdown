# VsScreen — the "TONIGHT'S MATCHUP" bumper between stage select and the
# match (UI Phase 3b, docs/UI_SCREENS.md). A code-drawn diagonal split —
# P1 orange #f29e26 left, P2 red #e5473a right, darkened 40% toward the
# screen edges — with the matchup lettering at the top, both fighters'
# busts sliding in over 12 integer-pixel frames, the VERSUS mark between
# them, names in outlined Marker under each bust, and Tripp's sponsor bug
# bottom-center. Pure presentation: it lasts 150 frames, any confirm/back
# skips it after a 20-frame input guard, and it never touches the match.
# Rematch goes through it too.
extends Control

signal vs_done

const MATCHUP := preload("res://art/ui/vs/vs_matchup.png")
const VERSUS := preload("res://art/ui/vs/vs_versus.png")
const SPONSOR := preload("res://art/ui/stream/stream_sponsor_bug.png")

const P1_COLOR := Color("f29e26")
const P2_COLOR := Color("e5473a")
const EDGE_DARKEN := 0.4

const MATCHUP_POS := Vector2(39, 6)   # 242x20 centred
const VERSUS_POS := Vector2(136, 76)  # 47x29 centred

const BUST_SIZE := Vector2(96, 128)
const BUST_BOTTOM_Y := 168.0
const P1_BUST_X := 12.0
const P2_BUST_X := 212.0
const SLIDE_FRAMES := 12

const SPONSOR_POS := Vector2(140, 154)  # 40x12 bottom-centre

const DURATION_FRAMES := 150
const INPUT_GUARD_FRAMES := 20

# Bust art per fighter id; a fighter without art skips the bust.
const BUSTS := {
	"peg_leg_peggy": "res://art/ui/vs/vs_bust_pegleg_peg.png",
	"whiskey_richard": "res://art/ui/vs/vs_bust_whiskey_richard.png",
}

# Set by main before the screen is pushed.
var p1_data: FighterData
var p2_data: FighterData

var _frame := 0
var _done := false
var _p1_bust: TextureRect
var _p2_bust: TextureRect


# The diagonal split, drawn once: 1 px columns, each side's color darkened
# toward its screen edge by EDGE_DARKEN, boundary skewing from x 170 (top)
# to x 150 (bottom).
class DiagonalSplit extends Control:
	func _draw() -> void:
		for x in 320:
			var edge := absf(x - 160.0) / 160.0
			var boundary_y: float = 90.0 + (x - 160.0) * 0.125
			var left := P1_COLOR.lerp(Color.BLACK, EDGE_DARKEN * edge)
			var right := P2_COLOR.lerp(Color.BLACK, EDGE_DARKEN * edge)
			draw_rect(Rect2(x, 0, 1, boundary_y), left)
			draw_rect(Rect2(x, boundary_y, 1, 180.0 - boundary_y), right)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var split := DiagonalSplit.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(split)

	_add_art(MATCHUP, MATCHUP_POS, Vector2(242, 20))
	_add_art(VERSUS, VERSUS_POS, Vector2(47, 29))

	_p1_bust = _add_bust(p1_data, false)
	_p2_bust = _add_bust(p2_data, true)

	_add_art(SPONSOR, SPONSOR_POS, Vector2(40, 12))
	var sponsor_note := UiText.body("BROUGHT TO YOU BY", Vector2(102, 138),
		UiText.CREAM_TEXT)
	sponsor_note.size = Vector2(116, UiText.M5X7_LINE_HEIGHT)
	sponsor_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sponsor_note)

	if p1_data != null:
		var p1_name := UiText.marker(p1_data.display_name.to_upper(),
			Vector2(P1_BUST_X, BUST_BOTTOM_Y + 1), Color.WHITE, true)
		p1_name.size = Vector2(BUST_SIZE.x, UiText.MARKER_LINE_HEIGHT)
		p1_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(p1_name)
	if p2_data != null:
		var p2_name := UiText.marker(p2_data.display_name.to_upper(),
			Vector2(P2_BUST_X, BUST_BOTTOM_Y + 1), Color.WHITE, true)
		p2_name.size = Vector2(BUST_SIZE.x, UiText.MARKER_LINE_HEIGHT)
		p2_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(p2_name)

	_layout_busts()


func _add_art(texture: Texture2D, at: Vector2, dimensions: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = at
	rect.size = dimensions
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(rect)
	return rect


func _add_bust(fighter: FighterData, flip: bool) -> TextureRect:
	var rect := TextureRect.new()
	var art_path := str(BUSTS.get(fighter.id, "")) if fighter != null else ""
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		rect.texture = load(art_path)
	rect.flip_h = flip
	rect.size = BUST_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(rect)
	return rect


func _layout_busts() -> void:
	# Slide in over SLIDE_FRAMES frames: each bust moves its full distance
	# in integer per-frame steps, starting fully off its own side.
	var progress: float = clampf(float(_frame) / SLIDE_FRAMES, 0.0, 1.0)
	var bust_y := BUST_BOTTOM_Y - BUST_SIZE.y
	var p1_from := -BUST_SIZE.x
	var p2_from := 320.0
	_p1_bust.position = Vector2(
		roundi(lerpf(p1_from, P1_BUST_X, progress)), bust_y)
	_p2_bust.position = Vector2(
		roundi(lerpf(p2_from, P2_BUST_X, progress)), bust_y)


func _physics_process(_delta: float) -> void:
	_frame += 1
	_layout_busts()
	if _frame >= DURATION_FRAMES:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	if _done:
		return
	if _frame < INPUT_GUARD_FRAMES:
		# A confirm from the stage hand-off must not skip the bumper.
		if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light") \
				or event.is_action_pressed("ui_back"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light") \
			or event.is_action_pressed("ui_back"):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	vs_done.emit()
