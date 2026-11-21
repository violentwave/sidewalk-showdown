# ScreenRouter — the front-end's screen stack (docs/UI_SCREENS.md).
#
# push() and replace() add the new screen DEFERRED, at the end of the frame:
# the input event that requested the transition is fully consumed before
# the new screen exists, so a confirm keypress can never leak into the next
# screen. This generalizes the call_deferred hand-offs main.gd used to do
# by hand (select -> stage, stage -> select, pause -> select).
#
# Overlays (Settings, QuitConfirm) are pushed without freeing the screen
# below; pop() frees only the top. Nothing here touches the simulation.
class_name ScreenRouter
extends Node

signal screen_pushed(screen: Node)
signal screen_popped(screen: Node)

# True when the most recent input event came from a gamepad; prompt lines
# show pad glyphs instead of keyboard glyphs for the rest of the session.
static var _pad_last := false

var stack: Array[Node] = []


func push(screen: Node) -> void:
	# Overlay semantics: the screen below stays alive and visible.
	stack.append(screen)
	call_deferred("_add_deferred", screen)


func pop() -> Node:
	if stack.is_empty():
		return null
	var screen: Node = stack.pop_back()
	if screen != null:
		screen.queue_free()
		screen_popped.emit(screen)
	return screen


func replace(screen: Node) -> void:
	# Forward flow: free the current screen, then deferred-add the next.
	pop()
	push(screen)


func clear_and_push(screen: Node) -> void:
	# Leave-everything transition (e.g. pause -> MAIN MENU): free the whole
	# stack without popping signals, then start fresh.
	for existing in stack:
		existing.queue_free()
	stack.clear()
	push(screen)


func top() -> Node:
	return stack.back() if not stack.is_empty() else null


func _add_deferred(screen: Node) -> void:
	if not is_instance_valid(screen):
		return
	add_child(screen)
	screen_pushed.emit(screen)


# ---- input-device tracking for prompt glyphs -------------------------------

static func note_input_device(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_pad_last = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_pad_last = false


static func last_device_was_pad() -> bool:
	return _pad_last
