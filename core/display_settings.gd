extends Node
## Owns the window mode (windowed / fullscreen) and its toggle input.
## The PSX look is unaffected: PsxViewportContainer recomputes its
## shrink factor whenever the window size changes.

const ACTION_TOGGLE_FULLSCREEN := &"toggle_fullscreen"
## Exported builds start in fullscreen; runs from the editor stay windowed.
const START_FULLSCREEN_IN_BUILDS := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if START_FULLSCREEN_IN_BUILDS and not OS.has_feature("editor"):
		set_fullscreen(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_TOGGLE_FULLSCREEN):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func set_fullscreen(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())
