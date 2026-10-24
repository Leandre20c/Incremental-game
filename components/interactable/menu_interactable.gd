class_name MenuInteractable
extends Interactable

## Opens a local UI menu. Never mutates the game state:
## actions inside the menu must dispatch their own commands.

@export var menu_id: StringName = &"computer"

func interact(player_id: int) -> void:
	EventBus.menu_requested.emit(player_id, menu_id)
