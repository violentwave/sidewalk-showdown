# CpuDifficulty — tuning numbers for one CPU difficulty level.
# Every knob the AI reads lives here, so balance edits never touch code.
# Levels are data: cpu_easy.tres / cpu_normal.tres / cpu_hard.tres under
# resources/ai/. All rates are probabilities per opportunity; all delays are
# simulation frames at the fixed 60 Hz tick.
class_name CpuDifficulty
extends Resource

# Frames of latency between an observable event (opponent attack startup,
# jump start) and the CPU being allowed to act on it. Fairness knob: the CPU
# never reacts on the same frame it observes.
@export var reaction_delay_frames: int = 14

# Probability the CPU actually blocks when an observed attack is coming in.
# 1 - block_rate is the deliberate mistake rate.
@export var block_rate: float = 0.65

# Probability the CPU anti-airs an opponent who jumps into range.
@export var anti_air_rate: float = 0.5

# Probability the CPU presses grab to tech when it is being thrown (per tick
# inside the tech window, so even low rates land sometimes).
@export var tech_rate: float = 0.4

# Probability per opportunity to throw an opponent that keeps blocking at
# close range.
@export var throw_rate: float = 0.2

# Probability per opportunity to poke with a light when inside light reach.
@export var poke_rate: float = 0.5

# Chance the chosen poke is the heavy instead of the light.
@export var heavy_mix: float = 0.35

# Probability per opportunity to use a special at special reach.
@export var special_rate: float = 0.1

# When a special is chosen and meter covers the EX cost, chance to take the
# EX route (special + heavy held). The engine still refuses unpayable EX.
@export var ex_rate: float = 0.4

# When the meter is full and the opponent is in finisher range, chance to use
# the METHtality.
@export var meth_rate: float = 0.7

# Chance to continue pressure (press an attack) while the opponent is in
# hitstun or getting up and inside reach.
@export var combo_rate: float = 0.45

# Chance to press a reversal attack on leaving wake-up.
@export var reversal_rate: float = 0.3

# Chance to jump out when pinned at a stage wall with the opponent closing.
@export var corner_jump_rate: float = 0.35

# Chance per tick, while standing inside the opponent's own poke reach, to
# pre-block for a few frames. This is how real players block unreactable
# jabs: the difficulty levels scale it, and reaction delay alone never lets
# any level block a 3-frame light on sight.
@export var preblock_rate: float = 0.01

# Chance to walk backward a beat when the CPU is well inside its own poke
# range (spacing instinct).
@export var retreat_rate: float = 0.1

# Watchdog: consecutive idle frames allowed before the CPU forces action.
@export var idle_limit: int = 60

# Loaded by menu index: 0 EASY, 1 NORMAL, 2 HARD. Falls back to built-in
# NORMAL defaults when a .tres is missing so a bad resource path can never
# break the flow.
static func load_level(level: int) -> CpuDifficulty:
	var path := "res://resources/ai/cpu_easy.tres" if level <= 0 \
			else "res://resources/ai/cpu_hard.tres" if level >= 2 \
			else "res://resources/ai/cpu_normal.tres"
	if ResourceLoader.exists(path):
		return load(path) as CpuDifficulty
	return CpuDifficulty.new()
