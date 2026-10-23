class_name Pickupable
extends Interactable

func create_command(player_id: int) -> Command:
	if not _body.has_meta(&"entity_id"):
		return null
	return PickupItemCommand.new(player_id, _body.get_meta(&"entity_id"))
