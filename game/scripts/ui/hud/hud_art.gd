# HudArt — the approved street-junk HUD art table and the tiny helpers the
# reskinned HUD needs (docs/UI_SCREENS.md "The match HUD", UI Phase 2).
# Art ids follow the fighter id -> file-name mapping; a fighter without a
# table entry gets the empty frame instead of a crash.
class_name HudArt

const PORTRAIT_FRAME := preload("res://art/ui/hud/hud_portrait_frame.png")
const HEALTH_FRAME := preload("res://art/ui/hud/hud_health_frame.png")
const METER_FRAME := preload("res://art/ui/hud/hud_meter_frame.png")
const TIMER_BOX := preload("res://art/ui/hud/hud_timer_box.png")
const TIMER_DIGITS := preload("res://art/ui/hud/hud_timer_digits.png")
const COMMENTARY_BOX := preload("res://art/ui/stream/stream_commentary_box.png")
const SKULL_F1 := preload("res://art/ui/hud/hud_meth_skull_f1.png")
const SKULL_F2 := preload("res://art/ui/hud/hud_meth_skull_f2.png")
const BANNER_PLATE := preload("res://art/ui/hud/hud_banner_plate.png")

# 5x5 pips: P1 squares, P2 diamonds. The K/T/M/D letter variants stay
# unused until MatchRoot keeps a per-round win-type history (it does not —
# see docs/UI_SCREENS.md).
const PIP_SQUARE_EMPTY := preload("res://art/ui/hud/hud_pip_square_empty.png")
const PIP_SQUARE_FILLED := preload("res://art/ui/hud/hud_pip_square_filled.png")
const PIP_DIAMOND_EMPTY := preload("res://art/ui/hud/hud_pip_diamond_empty.png")
const PIP_DIAMOND_FILLED := preload("res://art/ui/hud/hud_pip_diamond_filled.png")

# Banner word sprites per message id (all ride the 160x32 plate).
const BANNERS := {
	"round_1": preload("res://art/ui/hud/hud_banner_round_1.png"),
	"round_2": preload("res://art/ui/hud/hud_banner_round_2.png"),
	"round_3": preload("res://art/ui/hud/hud_banner_round_3.png"),
	"round_4": preload("res://art/ui/hud/hud_banner_round_4.png"),
	"round_5": preload("res://art/ui/hud/hud_banner_round_5.png"),
	"decisive": preload("res://art/ui/hud/hud_banner_decisive.png"),
	"fight": preload("res://art/ui/hud/hud_banner_fight.png"),
	"ko": preload("res://art/ui/hud/hud_banner_ko.png"),
	"time": preload("res://art/ui/hud/hud_banner_time.png"),
	"double_ko": preload("res://art/ui/hud/hud_banner_double_ko.png"),
	"methtality": preload("res://art/ui/hud/hud_banner_methtality.png"),
}

# Fighter-id -> portrait file stem (files are hud_portrait_<stem>_<state>).
const PORTRAITS := {
	"peg_leg_peggy": "pegleg_peg",
	"whiskey_richard": "whiskey_richard",
}

# Timer digit strip: 8x12 cells, 0-9 then infinity at cell 10.
const DIGIT_CELL := Vector2(8.0, 12.0)
const DIGIT_INFINITY := 10

# Timer digits are drawn as one AtlasTexture per digit.
static func digit_texture(digit: int) -> AtlasTexture:
	var cell := clampi(digit, 0, DIGIT_INFINITY)
	var crop := AtlasTexture.new()
	crop.atlas = TIMER_DIGITS
	crop.region = Rect2i(cell * int(DIGIT_CELL.x), 0,
		int(DIGIT_CELL.x), int(DIGIT_CELL.y))
	return crop


static func portrait_path(fighter_id: String, state: String) -> String:
	# "" when the fighter has no portrait table entry (or the art is
	# missing) — the caller shows the empty frame.
	var stem := str(PORTRAITS.get(fighter_id, ""))
	if stem.is_empty():
		return ""
	var path := "res://art/ui/hud/hud_portrait_%s_%s.png" % [stem, state]
	return path if ResourceLoader.exists(path) else ""


static func banner_texture(message_id: String) -> Texture2D:
	# null when the message has no sprite (rendered as Marker text on the
	# plate instead).
	return BANNERS.get(message_id, null)
