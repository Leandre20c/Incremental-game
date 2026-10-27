class_name PlaceItemCommand
extends Command

## Anchors the item a player is holding with the given position and orientation.
## Physical checks (touching the ground, overlaps) are done by the placer on the simulating peer.

var entity_id: int = -1
var position: Vector3 = Vector3.ZERO
var rotation: Quaternion = Quaternion.IDENTITY

func _init(p_player_id: int = 1, p_entity_id: int = -1, p_position: Vector3 = Vector3.ZERO, p_rotation: Quaternion = Quaternion.IDENTITY) -> void:
	super(p_player_id)
	entity_id = p_entity_id
	position = p_position
	rotation = p_rotation

func execute() -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty() or item["holder"] != player_id:
		return false # Only the player holding the item can place it
	var definition: ItemDefinition = ItemDatabase.get_definition(item["item_id"])
	if definition == null or not definition.placeable:
		return false
	if definition.snaps_to_grid and GameState.is_slot_taken(position, rotation):
		return false # Another grid piece is already there (other player, same frame…)
	GameState.release_all(player_id)
	return GameState.anchor_item(entity_id, position, rotation)

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "PlaceItemCommand"
	data["entity_id"] = entity_id
	data["position"] = [position.x, position.y, position.z]
	data["rotation"] = [rotation.x, rotation.y, rotation.z, rotation.w]
	return data

static func from_dict(data: Dictionary) -> PlaceItemCommand:
	var p: Array = data.get("position", [0.0, 0.0, 0.0])
	var r: Array = data.get("rotation", [0.0, 0.0, 0.0, 1.0])
	var cmd: PlaceItemCommand = PlaceItemCommand.new(
		data.get("player_id", 1), int(data.get("entity_id", -1)),
		Vector3(p[0], p[1], p[2]), Quaternion(r[0], r[1], r[2], r[3])
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
