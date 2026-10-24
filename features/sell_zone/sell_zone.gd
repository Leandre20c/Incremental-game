class_name SellZone
extends Area3D

## Trigger volume: any world item entering it is sold.
## Detection only, the sale itself goes through SellItemCommand.

@export var currency_id: StringName = &"money"
## Player credited for the sale (host in multiplayer).
@export var player_id: int = 1

func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.has_meta(&"entity_id"):
		return # Not a world item (player, held item...)
	CommandService.dispatch(SellItemCommand.new(player_id, body.get_meta(&"entity_id"), currency_id))
