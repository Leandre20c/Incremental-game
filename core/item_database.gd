extends Node

const ITEMS_DIR: String = "res://data/"

var _definitions: Dictionary[StringName, ItemDefinition] = {}

func _ready() -> void:
	_scan_directory(ITEMS_DIR)

func get_definition(item_id: StringName) -> ItemDefinition:
	return _definitions.get(item_id)

func _scan_directory(path: String) -> void:
	for entry in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			_scan_directory(path + entry)
		elif entry.ends_with(".tres"):
			_register(load(path + entry) as ItemDefinition, path + entry)

func _register(definition: ItemDefinition, path: String) -> void:
	if definition == null:
		return # Not an item (other resource types live in data/ too)
	if definition.id.is_empty():
		push_warning("ItemDatabase: item without id at %s" % path)
		return
	if _definitions.has(definition.id):
		push_warning("ItemDatabase: duplicate id '%s' at %s" % [definition.id, path])
		return
	_definitions[definition.id] = definition

## Items listed in the buy menu, cheapest first (same order on every peer).
func get_buyable() -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for definition in _definitions.values():
		if definition.buyable:
			result.append(definition)
	result.sort_custom(func(a: ItemDefinition, b: ItemDefinition) -> bool:
		if a.buy_cost != b.buy_cost:
			return a.buy_cost < b.buy_cost
		return String(a.id) < String(b.id))
	return result
