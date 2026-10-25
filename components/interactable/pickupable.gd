class_name Pickupable
extends Interactable

func _ready() -> void:
	super()
	EventBus.item_grabbed.connect(_on_item_grabbed)
	EventBus.items_released.connect(_on_items_released)

func create_command(player_id: int) -> Command:
	var entity_id: int = _get_entity_id()
	if entity_id < 0:
		return null
	return GrabItemCommand.new(player_id, entity_id)

func _get_entity_id() -> int:
	return _body.get_meta(&"entity_id", -1)

func _on_item_grabbed(_player_id: int, entity_id: int) -> void:
	if entity_id == _get_entity_id():
		enabled = false

func _on_items_released(_player_id: int, entity_ids: Array) -> void:
	if _get_entity_id() in entity_ids:
		enabled = true
