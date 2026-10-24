extends Node

## Registry of every UpgradeDefinition found under UPGRADES_DIR. Read-only at runtime.

const UPGRADES_DIR: String = "res://data/upgrades/"

var _definitions: Dictionary[StringName, UpgradeDefinition] = {}

func _ready() -> void:
	_scan_directory(UPGRADES_DIR)

func get_definition(upgrade_id: StringName) -> UpgradeDefinition:
	return _definitions.get(upgrade_id)

func get_all() -> Array[UpgradeDefinition]:
	var result: Array[UpgradeDefinition] = []
	result.assign(_definitions.values())
	return result

func _scan_directory(path: String) -> void:
	for entry in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			_scan_directory(path + entry)
		elif entry.ends_with(".tres"):
			_register(load(path + entry) as UpgradeDefinition, path + entry)

func _register(definition: UpgradeDefinition, path: String) -> void:
	if definition == null:
		return
	if definition.id.is_empty():
		push_warning("UpgradeDatabase: upgrade without id at %s" % path)
		return
	if _definitions.has(definition.id):
		push_warning("UpgradeDatabase: duplicate id '%s' at %s" % [definition.id, path])
		return
	_definitions[definition.id] = definition
