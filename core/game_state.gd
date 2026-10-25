extends Node

## Pure, serializable game model. Single source of truth (save + network sync).
## Only Commands should call the mutating methods.

var _resources: Dictionary[StringName, int] = {}
var _world_items: Dictionary[int, Dictionary] = {}
var _next_entity_id: int = 1

var _held_by_player: Dictionary[int, Array] = {} # player_id -> [entity_id, ...]
var _hand_capacity: int = 1

var _upgrade_levels: Dictionary[StringName, int] = {}

var _tools: Dictionary[int, Dictionary] = {}

func _ready() -> void:
	CommandService.dispatch(BuyUpgradeCommand.new(1, &"faster_fishing"))
	CommandService.process_queue()
	print("No money: ", GameState.get_upgrade_level(&"faster_fishing")) # 0

	GameState.add_resource(&"money", 10000)
	
#region Resources

func get_amount(resource_id: StringName) -> int:
	return _resources.get(resource_id, 0)

func add_resource(resource_id: StringName, amount: int) -> void:
	_resources[resource_id] = get_amount(resource_id) + amount
	EventBus.resource_changed.emit(resource_id, _resources[resource_id])

func try_spend(resource_id: StringName, amount: int) -> bool:
	if get_amount(resource_id) < amount:
		return false
	add_resource(resource_id, -amount)
	return true

#endregion

#region World items

func spawn_world_item(item_id: StringName, position: Vector3) -> int:
	var entity_id: int = _next_entity_id
	_next_entity_id += 1
	_world_items[entity_id] = {"item_id": item_id, "position": position, "holder": 0}
	EventBus.world_item_spawned.emit(entity_id, item_id, position)
	return entity_id

func remove_world_item(entity_id: int) -> bool:
	var item: Dictionary = get_world_item(entity_id)
	if item.is_empty():
		return false
	var holder: int = item["holder"]
	if holder != 0:
		_held_by_player[holder] = get_held(holder).filter(func(id: int) -> bool: return id != entity_id)
	_world_items.erase(entity_id)
	EventBus.world_item_removed.emit(entity_id)
	return true

func get_world_item(entity_id: int) -> Dictionary:
	return _world_items.get(entity_id, {})

func get_world_item_count() -> int:
	return _world_items.size()

#endregion

#region Serialization

func to_dict() -> Dictionary:
	var resources: Dictionary = {}
	for resource_id in _resources:
		resources[String(resource_id)] = _resources[resource_id]

	var world_items: Dictionary = {}
	for entity_id in _world_items:
		var item: Dictionary = _world_items[entity_id]
		var p: Vector3 = item["position"]
		world_items[str(entity_id)] = {
			"item_id": String(item["item_id"]),
			"position": [p.x, p.y, p.z],
		}
	
	var upgrades: Dictionary = {}
	for upgrade_id in _upgrade_levels:
		upgrades[String(upgrade_id)] = _upgrade_levels[upgrade_id]
		
	return {
		"resources": resources,
		"world_items": world_items,
		"next_entity_id": _next_entity_id,
		"upgrades": upgrades,
	}

func from_dict(data: Dictionary) -> void:
	# Clear current world items so views are removed too
	for entity_id in _world_items.keys():
		remove_world_item(entity_id)

	_resources.clear()
	var resources: Dictionary = data.get("resources", {})
	for key in resources:
		_resources[StringName(key)] = int(resources[key])
		EventBus.resource_changed.emit(StringName(key), _resources[StringName(key)])

	var world_items: Dictionary = data.get("world_items", {})
	for key in world_items:
		var item: Dictionary = world_items[key]
		var p: Array = item.get("position", [0.0, 0.0, 0.0])
		var entity_id: int = int(key)
		var item_id: StringName = StringName(item.get("item_id", ""))
		var position: Vector3 = Vector3(p[0], p[1], p[2])
		_world_items[entity_id] = {"item_id": item_id, "position": position}
		EventBus.world_item_spawned.emit(entity_id, item_id, position)

	_next_entity_id = int(data.get("next_entity_id", 1))
	
	# Reset levels missing from the save, then apply the saved ones
	var upgrades: Dictionary = data.get("upgrades", {})
	for upgrade_id in _upgrade_levels.keys():
		if not upgrades.has(String(upgrade_id)):
			set_upgrade_level(upgrade_id, 0)
	for key in upgrades:
		set_upgrade_level(StringName(key), int(upgrades[key]))

#endregion 

#region Grab

func get_held(player_id: int) -> Array:
	return _held_by_player.get(player_id, [])

func get_hand_capacity() -> int:
	return _hand_capacity

func set_hand_capacity(capacity: int) -> void:
	_hand_capacity = maxi(1, capacity)
	EventBus.hand_capacity_changed.emit(_hand_capacity)

func can_grab(player_id: int, entity_id: int) -> bool:
	var item: Dictionary = get_world_item(entity_id)
	if item.is_empty() or item["holder"] != 0:
		return false
	var held: Array = get_held(player_id)
	if held.size() >= _hand_capacity:
		return false
	if held.is_empty():
		return true
	return get_world_item(held[0])["item_id"] == item["item_id"] # Same type only

func grab_item(player_id: int, entity_id: int) -> bool:
	if not can_grab(player_id, entity_id):
		return false
	_world_items[entity_id]["holder"] = player_id
	var held: Array = get_held(player_id).duplicate()
	held.append(entity_id)
	_held_by_player[player_id] = held
	EventBus.item_grabbed.emit(player_id, entity_id)
	return true

## Releases everything the player holds. Returns the released entity ids.
func release_all(player_id: int) -> Array:
	var held: Array = get_held(player_id)
	if held.is_empty():
		return []
	for entity_id in held:
		if _world_items.has(entity_id):
			_world_items[entity_id]["holder"] = 0
	_held_by_player.erase(player_id)
	EventBus.items_released.emit(player_id, held)
	return held
	
## For items authored in the level (crates…), not spawned at runtime.
## Does not emit world_item_spawned: the node already exists in the scene.
func register_placed_item(item_id: StringName, position: Vector3) -> int:
	var entity_id: int = _next_entity_id
	_next_entity_id += 1
	_world_items[entity_id] = {"item_id": item_id, "position": position, "holder": 0, "placed": true}
	return entity_id

#endregion

#region Upgrades

func get_upgrade_level(upgrade_id: StringName) -> int:
	return _upgrade_levels.get(upgrade_id, 0)

func set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	level = maxi(0, level)
	if get_upgrade_level(upgrade_id) == level:
		return
	if level == 0:
		_upgrade_levels.erase(upgrade_id)
	else:
		_upgrade_levels[upgrade_id] = level
	EventBus.upgrade_level_changed.emit(upgrade_id, level)

#endregion

#region Tools

func has_tool(player_id: int, tool_id: StringName) -> bool:
	return _tools.get(player_id, {}).has(tool_id)

func is_tool_active(player_id: int, tool_id: StringName) -> bool:
	return _tools.get(player_id, {}).get(tool_id, false)

func grant_tool(player_id: int, tool_id: StringName) -> bool:
	if has_tool(player_id, tool_id):
		return false
	if not _tools.has(player_id):
		_tools[player_id] = {}
	_tools[player_id][tool_id] = false
	EventBus.tool_granted.emit(player_id, tool_id)
	return true

func set_tool_active(player_id: int, tool_id: StringName, active: bool) -> bool:
	if not has_tool(player_id, tool_id):
		return false
	_tools[player_id][tool_id] = active
	EventBus.tool_toggled.emit(player_id, tool_id, active)
	return true

#endregion
