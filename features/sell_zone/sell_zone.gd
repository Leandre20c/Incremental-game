class_name SellZone
extends Area3D

## Trigger volume: sellable world items entering it are sold, the others are sent back.
## Detection only, the actions go through commands.

@export var currency_id: StringName = &"money"
## Player credited for the sale (host in multiplayer).
@export var player_id: int = 1
## Where unsellable items are sent back. Leave empty to leave them where they fell.
@export var return_point: Node3D

func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.has_meta(&"entity_id"):
		return # Not a world item (player, held item...)
	var entity_id: int = body.get_meta(&"entity_id")
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty():
		return

	var definition: ItemDefinition = ItemDatabase.get_definition(item["item_id"])
	if definition != null and definition.can_be_sold():
		CommandService.dispatch(SellItemCommand.new(player_id, entity_id, currency_id))
	elif return_point != null:
		CommandService.dispatch(TeleportWorldItemCommand.new(player_id, entity_id, return_point.global_position))
