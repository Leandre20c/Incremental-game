extends Node

## Downstream notifications only. Listeners react (UI, sound, VFX), they never mutate state.

signal resource_changed(resource_id: StringName, new_amount: int)
signal harvested(player_id: int, item_id: StringName, amount: int)
signal world_item_spawned(entity_id: int, item_id: StringName, position: Vector3)
signal world_item_removed(entity_id: int)

# Local UI requests (not simulation events)
signal menu_requested(player_id: int, menu_id: StringName)
signal menu_closed(player_id: int, menu_id: StringName)
signal machine_menu_requested(player_id: int, entity_id: int)

signal player_respawned(player_id: int, position: Vector3)
signal player_message(player_id: int, text: String)

# items
signal item_grabbed(player_id: int, entity_id: int)
signal items_released(player_id: int, entity_ids: Array)
signal tool_granted(player_id: int, tool_id: StringName)
signal tool_toggled(player_id: int, tool_id: StringName, active: bool)
signal item_sold(player_id: int, item_id: StringName, value: int)
signal item_power_changed(entity_id: int)

# Upgrades and money
signal upgrade_level_changed(upgrade_id: StringName, level: int)
signal upgrade_purchased(player_id: int, upgrade_id: StringName, level: int)

signal item_anchor_changed(entity_id: int, anchored: bool)
