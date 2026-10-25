class_name PlacedItem
extends Node

## Child of a hand-placed body (crate…). Registers it in GameState so it can be grabbed
## like any spawned item.

@export var item_id: StringName = &"crate"

func _ready() -> void:
	# Deferred: the WorldItemSpawner may not be ready yet when this node is
	_register.call_deferred()

func _register() -> void:
	var body: Node3D = get_parent() as Node3D
	var spawner: WorldItemSpawner = get_tree().get_first_node_in_group(&"world_item_spawner") as WorldItemSpawner
	if body == null or spawner == null:
		push_warning("PlacedItem: needs a Node3D parent and a WorldItemSpawner in the scene")
		return
	var entity_id: int = GameState.register_placed_item(item_id, body.global_position)
	spawner.adopt_view(entity_id, body)
