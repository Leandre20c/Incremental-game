extends Node

## Downstream notifications only. Listeners react (UI, sound, VFX), they never mutate state.

signal resource_changed(resource_id: StringName, new_amount: int)
signal harvested(player_id: int, item_id: StringName, amount: int)
signal world_item_spawned(entity_id: int, item_id: StringName, position: Vector3)
signal world_item_removed(entity_id: int)

# Local UI requests (not simulation events)
signal menu_requested(player_id: int, menu_id: StringName)

signal player_respawned(player_id: int, position: Vector3)
signal player_message(player_id: int, text: String)

signal item_sold(player_id: int, item_id: StringName, value: int)

# 
# Upgrades - might be useless
signal hand_changed(player_id: int, item_id: StringName, count: int)
signal hand_capacity_changed(capacity: int)

# Upgrades
signal upgrade_level_changed(upgrade_id: StringName, level: int)
signal upgrade_purchased(player_id: int, upgrade_id: StringName, level: int)
