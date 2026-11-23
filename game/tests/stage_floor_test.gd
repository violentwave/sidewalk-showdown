# Headless stage-floor guard test.
# Pins each roster stage's floor_y inside its walkable ground band and against
# the measured, art-verified values. floor_y is where the fighters' feet
# (their sprite origin IS the feet: see FighterBase.IDLE_ANCHOR and the
# `offset = -IDLE_ANCHOR` mapping), so it must match where the stage art's
# objects actually meet the ground — the base rows of sign poles, shelter
# posts, and bench legs in the foreground layer. A floor_y copied from
# another stage's convention floats the fighters above the art (buses and
# benches pass under their heels).
#   godot --headless --path game --script res://tests/stage_floor_test.gd
extends SceneTree

# Walkable ground band per stage, measured on the 320x180 foreground layer:
# rows where the stage's walkable surface starts (grass/sidewalk top edge)
# through the bottom of the screen. Objects (posts, pole bases, bench legs)
# meet the ground inside the band; floor_y must aim at that contact line, not
# just anywhere in the band — hence the pinned values below.
const BANDS := {
	"gas_n_go": {"top": 148, "bottom": 180, "pin": 158},
	"bus_stop_night": {"top": 148, "bottom": 180, "pin": 170},
}

# Widest authored fighter pose, in screen pixels from the fighter origin,
# mirrored for facing: Richard ko_air f2 = 40.78, Peggy knockdown f3 =
# 30.06 (measured 2026-11-23 with the runtime's own art math; see
# docs/KNOWN_ISSUES.md). Bounds keep this plus 3 px inside the screen.
const WIDEST_ART_HALF := 40.78

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

func _run() -> void:
	var roster: MatchRoster = MatchRoster.load_default()
	_check("roster loads", roster != null and not roster.stages.is_empty())

	for stage_data: StageData in roster.stages:
		var id := stage_data.id
		var band: Dictionary = BANDS.get(id, {})
		var scene: PackedScene = stage_data.scene
		var inst := scene.instantiate()
		var floor_y: float = inst.floor_y
		if band.is_empty():
			_check("stage %s has a floor band entry" % id, false, "add it to BANDS")
			inst.free()
			continue

		# The floor must sit in the walkable band and at the art's contact line.
		_check("stage %s floor_y within walkable band [%d, %d)" % [id, band.top, band.bottom],
			floor_y >= float(band.top) and floor_y < float(band.bottom), "floor_y=" + str(floor_y))
		_check("stage %s floor_y pinned to the art-measured contact value %d" % [id, int(band.pin)],
			is_equal_approx(floor_y, float(band.pin)),
			"floor_y=" + str(floor_y) + " (art contact rows are measured on the foreground layer; "
			+ "re-measure with a capture before pinning a new value)")

		# Bounds and spawns stay coherent around the floor.
		_check("stage %s left/right bounds frame the arena" % id,
			inst.left_bound < inst.right_bound and inst.left_bound >= 0.0 and inst.right_bound <= 320.0)
		# Owner playtest fix 2026-11-23: a fighter pinned at a bound must be
		# fully on screen in its WIDEST authored pose. Measured across every
		# enabled idle/clip/cutout cel of both fighters, mirrored for facing:
		# Richard's ko_air frame reaches 40.78 px from his origin (Peggy
		# 30.06), so the bounds keep 44 px margins (40.78 + 3 px slack,
		# rounded up to the next integer).
		_check("stage %s bounds keep the widest fighter pose on screen" % id,
			inst.left_bound >= WIDEST_ART_HALF + 3.0
				and inst.right_bound <= 320.0 - WIDEST_ART_HALF - 3.0,
			"bounds=%s..%s (widest pose half=%.2f)" % [inst.left_bound,
				inst.right_bound, WIDEST_ART_HALF])
		_check("stage %s spawns inside the bounds" % id,
			inst.spawn_p1_x > inst.left_bound and inst.spawn_p2_x < inst.right_bound)
		inst.free()

	print("==========")
	print("%d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)
