# ComboTracker — one per DEFENDER (COMBO_SYSTEM_DESIGN §9.5). Owns the
# observable combo record: hits, total damage, the moves used, and the
# active flag. Scaling, repeat penalties, variety bonuses, and the hit /
# damage caps are computed FROM this record plus the defender's
# ComboTuning; nothing about the current combo lives anywhere else, so
# save/restore of this object restores the combo exactly.
#
# Resets (mirroring the legacy combo_hits sites): block, the 40-frame
# neutral expiry, knockdown recovery, and round start.
class_name ComboTracker
extends RefCounted

# Public, for a later HUD: fires after every recorded hit and every reset.
signal changed(hits: int, total_damage: float)

var hits: int = 0
var total_damage: float = 0.0
var active: bool = false
# Full move-id history of this combo. Bounded by the hit cap in practice;
# hard-capped at 32 entries so a corrupted load cannot grow it forever.
var move_ids: Array[StringName] = []

const MAX_HISTORY := 32

func reset() -> void:
	hits = 0
	total_damage = 0.0
	active = false
	move_ids.clear()
	changed.emit(0, 0.0)

func count_of(id: StringName) -> int:
	var count := 0
	for entry in move_ids:
		if entry == id:
			count += 1
	return count

# True when `next` plus the previous two moves are three distinct ids.
func last_three_distinct(next: StringName) -> bool:
	if move_ids.size() < 2:
		return false
	return move_ids[move_ids.size() - 1] != next \
		and move_ids[move_ids.size() - 2] != next \
		and move_ids[move_ids.size() - 1] != move_ids[move_ids.size() - 2]

func record(id: StringName, damage: float) -> void:
	hits += 1
	total_damage += damage
	active = true
	if move_ids.size() < MAX_HISTORY:
		move_ids.append(id)
	changed.emit(hits, total_damage)

func serialize() -> Dictionary:
	return {
		"hits": hits,
		"total_damage": total_damage,
		"active": active,
		# Copy: a snapshot must stay stable while the live combo continues
		# (reset() clears the tracker's own array).
		"move_ids": move_ids.duplicate(),
	}

func load_state(d: Dictionary) -> void:
	hits = d.get("hits", 0)
	total_damage = d.get("total_damage", 0.0)
	active = d.get("active", false)
	move_ids.clear()
	var stored: Array = d.get("move_ids", [])
	for i in mini(stored.size(), MAX_HISTORY):
		move_ids.append(StringName(stored[i]))
	changed.emit(hits, total_damage)
