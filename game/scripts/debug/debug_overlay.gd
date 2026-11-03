# DebugOverlay — F1 boxes, F2 frame state, F3 input history, F4 slow motion.
class_name DebugOverlay
extends Node2D

var p1: FighterBase
var p2: FighterBase

var show_boxes := true
var show_state := false
var show_input := false
var slow_motion := false

var _layer: CanvasLayer
var _text: Label
var _inputs: Label

func _ready() -> void:
	z_index = 100
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)

	_text = _make_label(Vector2(4, 40), Vector2(220, 50))
	_inputs = _make_label(Vector2(4, 156), Vector2(312, 22))
	_text.visible = false
	_inputs.visible = false

func bind(a: FighterBase, b: FighterBase) -> void:
	p1 = a
	p2 = b

func _make_label(pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var settings := LabelSettings.new()
	settings.font_size = 8
	settings.font_color = Color(1, 1, 1, 0.9)
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0, 1)
	l.label_settings = settings
	_layer.add_child(l)
	return l

func _process(_delta: float) -> void:
	queue_redraw()
	if _text.visible:
		_text.text = _state_text()
	if _inputs.visible:
		_inputs.text = "P1: %s\nP2: %s" % [
			" ".join(p1.input_history.slice(-8)),
			" ".join(p2.input_history.slice(-8)),
		]

func _draw() -> void:
	if not show_boxes or p1 == null:
		return
	for f: FighterBase in [p1, p2]:
		draw_rect(f.pushbox_rect(), Color(0.25, 0.55, 1.0, 0.9), false, 1.0)
		draw_rect(f.hurtbox_rect(), Color(0.2, 1.0, 0.35, 0.9), false, 1.0)
		if f.state == FighterBase.State.ATTACK:
			var hb := f.get_hitbox_rect()
			if hb.size != Vector2.ZERO:
				draw_rect(hb, Color(1.0, 0.2, 0.2, 1.0), false, 1.0)

func _state_text() -> String:
	return "P1 %s f%d\nP2 %s f%d\nFPS %d" % [
		_state_name(p1), p1.state_frame,
		_state_name(p2), p2.state_frame,
		Engine.get_frames_per_second(),
	]

func _state_name(f: FighterBase) -> String:
	return FighterBase.State.keys()[f.state]

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			show_boxes = not show_boxes
		KEY_F2:
			show_state = not show_state
			_text.visible = show_state
		KEY_F3:
			show_input = not show_input
			_inputs.visible = show_input
		KEY_F4:
			slow_motion = not slow_motion
			Engine.time_scale = 0.25 if slow_motion else 1.0
