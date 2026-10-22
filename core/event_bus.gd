extends Node

## Downstream notifications only. Listeners react (UI, sound, VFX), they never mutate state.

signal resource_changed(resource_id: StringName, new_amount: int)
signal harvested(player_id: int, item_id: StringName, amount: int)
signal world_item_spawned(entity_id: int, item_id: StringName, position: Vector3)
signal world_item_removed(entity_id: int)
