# MatchHUD — flat pixel HUD built in code for reliable 320x180 layout.
class_name MatchHUD
extends CanvasLayer

const BAR_W := 126.0
const P1_X := 8.0
const P2_X := 186.0
const BAR_Y := 10.0
const BAR_H := 8.0
const METER_Y := 168.0
const METER_H := 5.0
const PIP_GAP := 7.0
const PAUSE_OPTIONS := ["RESUME", "SETTINGS", "RESTART MATCH",
	"BACK TO CHARACTER SELECT", "MAIN MENU", "QUIT TO DESKTOP"]
const UI_THEME := preload("res://resources/ui_theme.tres")

var p1_fill: ColorRect
var p2_fill: ColorRect
var p1_meter_fill: ColorRect
var p2_meter_fill: ColorRect
var timer_label: Label
var p1_name: Label
var p2_name: Label
var p1_combo: Label
var p2_combo: Label
var commentary_panel: Panel
var commentary_label: Label
var commentary_frames: int = 0
var message: Label
var tech_flash: Label
var tech_flash_frames: int = 0
var meth_banner: Label
var meth_banner_frames: int = 0
var counter_flash: Label
var counter_flash_frames: int = 0
var hud_root: Control
var pause_root: Control
var pause_options: Array[Label] = []
var pips_p1: Array[ColorRect] = []
var pips_p2: Array[ColorRect] = []

func _ready() -> void:
	_build()

func _process(_delta: float) -> void:
	if commentary_frames > 0:
		commentary_frames -= 1
		if commentary_frames == 0:
			commentary_panel.visible = false
	if tech_flash_frames > 0:
		tech_flash_frames -= 1
		if tech_flash_frames == 0:
			tech_flash.visible = false
	if meth_banner_frames > 0:
		meth_banner_frames -= 1
		if meth_banner_frames == 0:
			meth_banner.visible = false
	if counter_flash_frames > 0:
		counter_flash_frames -= 1
		if counter_flash_frames == 0:
			counter_flash.visible = false

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hud_root = root

	_rect(root, Vector2(P1_X, BAR_Y), Vector2(BAR_W, BAR_H), Color(0.06, 0.05, 0.05, 0.9))
	_rect(root, Vector2(P2_X, BAR_Y), Vector2(BAR_W, BAR_H), Color(0.06, 0.05, 0.05, 0.9))
	p1_fill = _rect(root, Vector2(P1_X, BAR_Y), Vector2(BAR_W, BAR_H), Color(0.95, 0.62, 0.15))
	p2_fill = _rect(root, Vector2(P2_X, BAR_Y), Vector2(BAR_W, BAR_H), Color(0.9, 0.28, 0.2))

	_rect(root, Vector2(P1_X, METER_Y), Vector2(BAR_W, METER_H), Color(0.06, 0.05, 0.05, 0.9))
	_rect(root, Vector2(P2_X, METER_Y), Vector2(BAR_W, METER_H), Color(0.06, 0.05, 0.05, 0.9))
	p1_meter_fill = _rect(root, Vector2(P1_X, METER_Y), Vector2(0, METER_H), Color(0.35, 0.8, 1.0))
	p2_meter_fill = _rect(root, Vector2(P2_X, METER_Y), Vector2(0, METER_H), Color(0.35, 0.8, 1.0))

	timer_label = _label(root, "99", Vector2(140, 2), Vector2(40, 14), HORIZONTAL_ALIGNMENT_CENTER, 10, Color(1, 0.95, 0.85))
	p1_name = _label(root, "PEG LEG PEGGY", Vector2(P1_X, 20), Vector2(140, 12), HORIZONTAL_ALIGNMENT_LEFT, 10, Color(0.95, 0.8, 0.55))
	p2_name = _label(root, "WHISKEY RICHARD", Vector2(172, 20), Vector2(140, 12), HORIZONTAL_ALIGNMENT_RIGHT, 10, Color(0.95, 0.7, 0.65))

	for i in 2:
		pips_p1.append(_rect(root, Vector2(P1_X + i * PIP_GAP, 34), Vector2(4, 4), Color(0.2, 0.2, 0.2)))
		pips_p2.append(_rect(root, Vector2(P2_X + BAR_W - 4 - i * PIP_GAP, 34), Vector2(4, 4), Color(0.2, 0.2, 0.2)))

	p1_combo = _label(root, "", Vector2(P1_X, 64), Vector2(110, 14), HORIZONTAL_ALIGNMENT_LEFT, 10, Color(1, 0.9, 0.4))
	p2_combo = _label(root, "", Vector2(202, 64), Vector2(110, 14), HORIZONTAL_ALIGNMENT_RIGHT, 10, Color(1, 0.9, 0.4))

	commentary_panel = Panel.new()
	commentary_panel.position = Vector2(40, 45)
	commentary_panel.size = Vector2(240, 16)
	commentary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var commentary_style := StyleBoxFlat.new()
	commentary_style.bg_color = Color(0.045, 0.035, 0.045, 0.88)
	commentary_style.border_color = Color(0.98, 0.64, 0.18, 0.95)
	commentary_style.set_border_width_all(1)
	commentary_panel.add_theme_stylebox_override("panel", commentary_style)
	commentary_panel.visible = false
	root.add_child(commentary_panel)
	commentary_label = _label(commentary_panel, "", Vector2(4, 1), Vector2(232, 14),
		HORIZONTAL_ALIGNMENT_CENTER, 8, Color(1.0, 0.87, 0.61))

	message = _label(root, "", Vector2(40, 76), Vector2(240, 34), HORIZONTAL_ALIGNMENT_CENTER, 14, Color(1, 0.95, 0.8))
	message.visible = false

	# TECH flash (PROPOSALS §2): both fighters' teched signals go here.
	tech_flash = _label(root, "TECH", Vector2(110, 60), Vector2(100, 14),
		HORIZONTAL_ALIGNMENT_CENTER, 12, Color(0.45, 0.95, 1.0))
	tech_flash.visible = false

	# Counter-hit text indicator (GDD §5.6 / §10.3). Plain text, so it reads the
	# same on the current silhouettes.
	counter_flash = _label(root, "COUNTER HIT", Vector2(90, 46), Vector2(140, 14),
		HORIZONTAL_ALIGNMENT_CENTER, 12, Color(1.0, 0.5, 0.2))
	counter_flash.visible = false

	# METHtality banner (PROPOSALS §4): phase-1 presentation while the finisher's
	# long hitstop freezes the exchange.
	meth_banner = _label(root, "", Vector2(20, 84), Vector2(280, 30),
		HORIZONTAL_ALIGNMENT_CENTER, 16, Color(1.0, 0.82, 0.25))
	meth_banner.visible = false

	pause_root = Control.new()
	pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.visible = false
	pause_root.theme = UI_THEME
	root.add_child(pause_root)
	_rect(pause_root, Vector2.ZERO, Vector2(320, 180), Color(0, 0, 0, 0.65))
	# Phase 1 polish: one small centered ui_panel, items in Sidewalk
	# Marker, the focused item yellow with a ">" marker, no per-item
	# buttons and no Godot outline on the pixel font (docs/UI_SCREENS.md).
	var pause_panel := Panel.new()
	pause_panel.position = Vector2(80, 24)
	pause_panel.size = Vector2(160, 116)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_root.add_child(pause_panel)
	var header := UiText.marker("PAUSED", Vector2(80, 30), Color(0.96, 0.91, 0.83))
	header.size = Vector2(160, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_root.add_child(header)
	for i in PAUSE_OPTIONS.size():
		var option := _pause_option_label(PAUSE_OPTIONS[i], Vector2(88, 48 + i * 14))
		pause_root.add_child(option)
		pause_options.append(option)
	pause_root.add_child(UiPromptLine.new("SELECT", ""))
	set_pause_selection(0)

func bind(p1: FighterBase, p2: FighterBase) -> void:
	p1_name.text = p1.data.display_name.to_upper()
	p2_name.text = p2.data.display_name.to_upper()
	p1.health_changed.connect(_on_p1_health)
	p2.health_changed.connect(_on_p2_health)
	p1.meter_changed.connect(_on_p1_meter)
	p2.meter_changed.connect(_on_p2_meter)
	p1.combo_changed.connect(_on_p1_combo)
	p2.combo_changed.connect(_on_p2_combo)
	p1.teched.connect(_on_teched)
	p2.teched.connect(_on_teched)
	p1.counter_hit_landed.connect(_on_counter_hit)
	p2.counter_hit_landed.connect(_on_counter_hit)
	_on_p1_health(p1.health, p1.max_health)
	_on_p2_health(p2.health, p2.max_health)
	_on_p1_meter(p1.meter, p1.max_meter)
	_on_p2_meter(p2.meter, p2.max_meter)

func _rect(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _label(parent: Control, text: String, pos: Vector2, size: Vector2,
		align: HorizontalAlignment, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 1
	settings.outline_color = Color(0, 0, 0, 0.95)
	l.label_settings = settings
	parent.add_child(l)
	return l

func _on_p1_health(value: float, max_value: float) -> void:
	var w := BAR_W * clampf(value / max_value, 0.0, 1.0)
	p1_fill.size.x = w

func _on_p2_health(value: float, max_value: float) -> void:
	var w := BAR_W * clampf(value / max_value, 0.0, 1.0)
	p2_fill.size.x = w
	p2_fill.position.x = P2_X + BAR_W - w

func _on_p1_meter(value: float, max_value: float) -> void:
	p1_meter_fill.size.x = BAR_W * clampf(value / max_value, 0.0, 1.0)

func _on_p2_meter(value: float, max_value: float) -> void:
	var w := BAR_W * clampf(value / max_value, 0.0, 1.0)
	p2_meter_fill.size.x = w
	p2_meter_fill.position.x = P2_X + BAR_W - w

func _on_p1_combo(count: int) -> void:
	p1_combo.text = "%d HITS" % count if count >= 2 else ""

func _on_p2_combo(count: int) -> void:
	p2_combo.text = "%d HITS" % count if count >= 2 else ""

# Both fighters emit teched on the same frame; showing once per emission is
# harmless (the label simply restarts its 20-frame flash).
func _on_teched() -> void:
	tech_flash.visible = true
	tech_flash_frames = 20

func _on_counter_hit() -> void:
	counter_flash.visible = true
	counter_flash_frames = 30

func show_meth_message(text: String) -> void:
	meth_banner.text = text
	meth_banner.visible = true
	meth_banner_frames = 120

func set_timer(seconds: float) -> void:
	timer_label.text = "%d" % int(ceilf(seconds))

func set_pips(p1_wins: int, p2_wins: int) -> void:
	# Double KOs award both fighters a pip, so a score can pass 2-2; grow the
	# rows instead of hiding wins.
	var count := maxi(2, maxi(p1_wins, p2_wins))
	while pips_p1.size() < count:
		var i := pips_p1.size()
		pips_p1.append(_rect(hud_root, Vector2(P1_X + i * PIP_GAP, 34),
			Vector2(4, 4), Color(0.2, 0.2, 0.2)))
		pips_p2.append(_rect(hud_root, Vector2(P2_X + BAR_W - 4 - i * PIP_GAP, 34),
			Vector2(4, 4), Color(0.2, 0.2, 0.2)))
	for i in pips_p1.size():
		var slot_visible := i < count
		pips_p1[i].visible = slot_visible
		pips_p2[i].visible = slot_visible
		pips_p1[i].color = Color(0.95, 0.62, 0.15) if i < p1_wins else Color(0.2, 0.2, 0.2)
		pips_p2[i].color = Color(0.9, 0.28, 0.2) if i < p2_wins else Color(0.2, 0.2, 0.2)

func show_message(text: String) -> void:
	message.text = text
	message.visible = true

func show_commentary(text: String, duration_frames := 180) -> void:
	commentary_label.text = text
	commentary_panel.visible = true
	commentary_frames = duration_frames

func clear_message() -> void:
	message.visible = false

func set_paused(paused: bool) -> void:
	pause_root.visible = paused
	if paused:
		set_pause_selection(0)

func pause_option_count() -> int:
	return PAUSE_OPTIONS.size()

# One pause-menu row: a plain Sidewalk Marker label. Selection is the
# yellow text plus a ">" marker; input stays in match_root's hands.
func _pause_option_label(text: String, at: Vector2) -> Label:
	var option := UiText.marker(text, at, Color(0.96, 0.91, 0.83))
	option.size = Vector2(144, UiText.MARKER_LINE_HEIGHT)
	return option

func set_pause_selection(index: int) -> void:
	# Selection rides the ui_button focus stylebox (warm yellow modulate)
	# so the button art itself shows the choice; input stays in
	# match_root's hands.
	# The focused item turns yellow and gains a ">" marker; the rest stay
	# cream. match_root owns the selection index.
	for i in pause_options.size():
		var selected := i == index
		pause_options[i].text = "> %s" % PAUSE_OPTIONS[i] if selected else PAUSE_OPTIONS[i]
		pause_options[i].add_theme_color_override("font_color",
			Color(0.949, 0.816, 0.227) if selected else Color(0.96, 0.91, 0.83))
