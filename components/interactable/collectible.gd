class_name Collectible
extends Interactable

## Collecting removes the item from the world and gives its tool to the player.

func create_command(player_id: int) -> Command:
	var entity_id: int = _body.get_meta(&"entity_id", -1)
	if entity_id < 0:
		return null
	return CollectItemCommand.new(player_id, entity_id)
