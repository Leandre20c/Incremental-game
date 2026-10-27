class_name SecondaryAction
extends Node

## Child of an object's body, next to its Interactable. Adds actions on the interact_secondary key:
## - tap: on the focused object, and on the held object if usable_while_held
## - long press (optional): on the focused object only (e.g. open a settings menu)
## Override create_command() for a gameplay action, or perform() / perform_long() for local ones (UI).

@export var usable_while_held: bool = true

## The action attached to a body, or null.
static func find_on(body: Node) -> SecondaryAction:
	if body == null:
		return null
	for child in body.get_children():
		if child is SecondaryAction:
			return child
	return null

# --- Tap -------------------------------------------------------------------

## False hides and disables the action.
func is_available() -> bool:
	return true

func get_prompt_text() -> String:
	return ""

func create_command(_player_id: int) -> Command:
	return null

## Default: send the command to the simulation.
func perform(player_id: int) -> void:
	var cmd: Command = create_command(player_id)
	if cmd:
		CommandService.dispatch(cmd)

# --- Long press ------------------------------------------------------------

func has_long_action() -> bool:
	return false

func get_long_prompt_text() -> String:
	return ""

func perform_long(_player_id: int) -> void:
	pass
