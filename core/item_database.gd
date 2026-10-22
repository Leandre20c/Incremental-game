extends Node

const ITEMS_DIR: String = "res://data/items/"

var _definitions: Dictionary[StringName, ItemDefinition] = {}

func _ready() -> void:
	for file in ResourceLoader.list_directory(ITEMS_DIR):
		if not file.ends_with(".tres"):
			continue
		var definition: ItemDefinition = load(ITEMS_DIR + file) as ItemDefinition
		if definition:
			_definitions[definition.id] = definition

func get_definition(item_id: StringName) -> ItemDefinition:
	return _definitions.get(item_id)
