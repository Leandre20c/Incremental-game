extends Node

## Pure, serializable game model. Single source of truth (save + network sync).
## Only Commands should call the mutating methods.

var _resources: Dictionary[StringName, int] = {}
var _world_items: Dictionary[int, Dictionary] = {}
var _next_entity_id: int = 1

var _hands: Dictionary[int, Dictionary] = {} # player_id -> {"item_id", "count"}
var _hand_capacity: int = 1

var _upgrade_levels: Dictionary[StringName, int] = {}

func _ready() -> void:
	CommandService.dispatch(BuyUpgradeCommand.new(1, &"faster_fishing"))
	CommandService.process_queue()
	print("No money: ", GameState.get_upgrade_level(&"faster_fishing")) # 0

	GameState.add_resource(&"money", 100)
	CommandService.dispatch(BuyUpgradeCommand.new(1, &"faster_fishing"))
	CommandService.dispatch(BuyUpgradeCommand.new(1, &"faster_fishing"))
	CommandService.process_queue()
	print("Level: ", GameState.get_upgrade_level(&"faster_fishing")) # 2
	print("Money: ", GameState.get_amount(&"money")) # 75 (100 - 10 - 15)
	
	var definition: UpgradeDefinition = UpgradeDatabase.get_definition(&"faster_fishing")
	print("Effects: ", definition.effects.size())
	for effect in definition.effects:
		print("  '", effect.stat_id, "' op=", effect.operation, " value=", effect.value_per_level)
	
	print("Fishing speed: ", Stats.apply(StatIds.FISHING_SPEED, 1.0)) # 1.5 (level 2)
	
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
	_world_items[entity_id] = {"item_id": item_id, "position": position}
	EventBus.world_item_spawned.emit(entity_id, item_id, position)
	return entity_id

func remove_world_item(entity_id: int) -> bool:
	if not _world_items.erase(entity_id):
		return false
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

#region Hands

func get_hand(player_id: int) -> Dictionary:
	return _hands.get(player_id, {"item_id": &"", "count": 0})

func get_hand_capacity() -> int:
	return _hand_capacity

func set_hand_capacity(capacity: int) -> void:
	_hand_capacity = maxi(1, capacity)
	EventBus.hand_capacity_changed.emit(_hand_capacity)

func can_hold(player_id: int, item_id: StringName) -> bool:
	var hand: Dictionary = get_hand(player_id)
	if hand["count"] == 0:
		return true
	return hand["item_id"] == item_id and hand["count"] < _hand_capacity

func add_to_hand(player_id: int, item_id: StringName) -> bool:
	if not can_hold(player_id, item_id):
		return false
	var count: int = get_hand(player_id)["count"] + 1
	_hands[player_id] = {"item_id": item_id, "count": count}
	EventBus.hand_changed.emit(player_id, item_id, count)
	return true

## Returns the removed item id, or &"" if the hand was empty.
func remove_from_hand(player_id: int) -> StringName:
	var hand: Dictionary = get_hand(player_id)
	if hand["count"] <= 0:
		return &""
	var item_id: StringName = hand["item_id"]
	var count: int = hand["count"] - 1
	if count == 0:
		_hands.erase(player_id)
	else:
		_hands[player_id] = {"item_id": item_id, "count": count}
	EventBus.hand_changed.emit(player_id, item_id, count)
	return item_id

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
