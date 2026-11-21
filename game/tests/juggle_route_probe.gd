# Temporary probe: can the authored §13 air juggle routes connect through
# real hitboxes with a jumping attacker? Searches jump/move timing.
extends SceneTree

const PEGGY := "res://resources/fighters/peg_leg_peggy.tres"
const RICHARD := "res://resources/fighters/whiskey_richard.tres"
const GAS_N_GO := "res://resources/stages/gas_n_go.tres"

var scene: Node

func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	scene.selected_p1_data = load(PEGGY)
	scene.selected_p2_data = load(RICHARD)
	scene.selected_stage = load(GAS_N_GO)
	scene.set_physics_process(false)
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	await process_frame
	scene.set_physics_process(false)
	scene.p1.set_physics_process(false)
	scene.p2.set_physics_process(false)
	scene.set("phase", 4)
	await _run()
	quit(0)

func _step() -> void:
	scene.p1._physics_process(1.0 / 60.0)
	scene.p2._physics_process(1.0 / 60.0)
	scene._physics_process(1.0 / 60.0)

func _reset() -> void:
	var stage = scene.stage
	scene.p1.position = Vector2(100.0, stage.floor_y)
	scene.p2.position = Vector2(140.0, stage.floor_y)
	scene.p1.velocity = Vector2.ZERO
	scene.p2.velocity = Vector2.ZERO
	scene.p1.facing = 1
	scene.p2.facing = -1
	scene.p1.health = 1000.0
	scene.p2.health = 1000.0
	scene.p1.reset_state()
	scene.p2.reset_state()
	scene.p1.input_enabled = false
	scene.p2.input_enabled = false

func _run() -> void:
	for atk_is_p1 in [true, false]:
		var atk: FighterBase = scene.p1 if atk_is_p1 else scene.p2
		var dfd: FighterBase = scene.p2 if atk_is_p1 else scene.p1
		var launcher: MoveData = atk.data.find_move(
			MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		var first: MoveData = atk.data.find_move(
			MoveData.InputType.LIGHT if atk_is_p1 else MoveData.InputType.HEAVY,
			MoveData.Stance.AIR)
		var second: MoveData = atk.data.find_move(
			MoveData.InputType.HEAVY if atk_is_p1 else MoveData.InputType.SPECIAL_AIR,
			MoveData.Stance.AIR)
		var launchers := [
			["base", launcher],
			["ex", atk.data.find_ex_move(
				MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)],
		]
		for l in launchers:
			var best := ""
			var best_hits := 0
			var rows := []
			var launcher_move: MoveData = l[1]
			for drift in [0.0, 90.0]:
				for jump_delay in range(0, 60):
					var row_hits := 0
					var row_desc := ""
					for move_delay in range(0, 24):
						_reset()
						atk._start_move(launcher_move)
						atk.state_frame = launcher_move.startup
						scene._resolve_hits()
						for i in jump_delay:
							_step()
						# Realistic: the attacker can only leave the ground from an
						# actionable state (launcher recovery + hitstop served).
						if atk.state not in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
								FighterBase.State.WALK_B, FighterBase.State.CROUCH]:
							break
						if dfd.grounded:
							continue # the juggle window is closed: the defender landed
						atk.grounded = false
						atk._force_state(FighterBase.State.JUMP_RISE)
						atk.velocity = Vector2(drift * atk.facing, -atk.jump_speed)
						for i in move_delay:
							_step()
						if dfd.grounded:
							continue
						atk._start_move(first)
						atk.state_frame = first.startup
						var before: float = dfd.health
						scene._resolve_hits()
						var hits := 1 if dfd.health < before else 0
						if hits == 0:
							continue
						for second_delay in range(0, 16):
							for i in second_delay:
								_step()
							if dfd.grounded:
								break
							atk._start_move(second)
							atk.state_frame = second.startup
							var before2: float = dfd.health
							scene._resolve_hits()
							if dfd.health < before2:
								hits = 2
							if hits == 2:
								break
						if hits > row_hits:
							row_hits = hits
							row_desc = "move=%d hp=%.1f points=%d" % [move_delay,
								dfd.health, dfd.juggle_points]
						if row_hits == 2:
							break
					if row_hits > 0:
						rows.append("jump=%d(%.0f): hits=%d %s" % [jump_delay, drift, row_hits, row_desc])
					if row_hits > best_hits:
						best_hits = row_hits
						best = "drift=%.0f jump=%d %s" % [drift, jump_delay, row_desc]
			print("%s %s: best_hits=%d best=%s rows=%d" % [atk.data.display_name, l[0], best_hits, best, rows.size()])
			for r in rows:
				print("   ", r)
