class_name PlayerPlacer
extends Node

## While the player holds a placeable item, tints it green or red and anchors it on click,
## with its current orientation, resting on the ground right under it.
## Red when: too tilted, no ground close under it, or overlapping a player or another item.
## Uses Input polling (like PlayerInteraction): mouse events may not reach the game SubViewport.

const TINT_SHADER: Shader = preload("res://components/placement_tint/placement_tint.gdshader")

@export var player_id: int = 1
@export var support_distance: float = 0.2 ## Max gap above the ground. Farther = floating
@export var sink_tolerance: float = 0.5 ## How deep the held item may sink into the ground and still snap onto it
@export_flags_3d_physics var support_mask: int = 2 ## What can hold an item up (Terrain)
@export_flags_3d_physics var blocking_mask: int = 5 ## What prevents placing (Player + Items)

@export_group("Tint")
@export var valid_color: Color = Color(0.3, 1.0, 0.4)
@export var invalid_color: Color = Color(1.0, 0.25, 0.25)

var _entity_id: int = -1 ## Held item, -1 if none
var _body: RigidBody3D ## Held placeable body, null if none
var _definition: ItemDefinition
var _meshes: Array[Node] = []
var _tint: ShaderMaterial

var _can_place: bool = false
var _place_position: Vector3 = Vector3.ZERO ## Body position once resting on the ground

func _ready() -> void:
	add_to_group(&"player_placer")
	_tint = ShaderMaterial.new()
	_tint.shader = TINT_SHADER

func can_place() -> bool:
	return _can_place

func _physics_process(_delta: float) -> void:
	_track_held_item()
	if _body == null:
		return

	_evaluate()
	_tint.set_shader_parameter("tint_color", valid_color if _can_place else invalid_color)
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = _tint

	if _can_place and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_just_pressed("place_held"):
		var rotation: Quaternion = _body.global_basis.get_rotation_quaternion()
		CommandService.dispatch(PlaceItemCommand.new(player_id, _entity_id, _place_position, rotation))

# --- Checks ----------------------------------------------------------------

## Updates _can_place and _place_position from the held body's current transform.
func _evaluate() -> void:
	_can_place = false
	if not _definition.accepts_rotation(_body.global_basis.get_rotation_quaternion()):
		return

	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	var exclude: Array[RID] = _get_held_rids()
	var shapes: Array[CollisionShape3D] = _get_shapes(_body)
	var lift: Vector3 = Vector3.UP * sink_tolerance
	var cast_length: float = sink_tolerance + support_distance

	# 1. Drop the item from slightly above onto the ground: works whether it hovers or sank in
	var travel: float = INF
	for shape_node in shapes:
		var query: PhysicsShapeQueryParameters3D = _make_query(shape_node, exclude, support_mask)
		query.transform.origin += lift
		query.motion = Vector3.DOWN * cast_length
		var result: PackedFloat32Array = space.cast_motion(query) # [safe, unsafe] fractions
		if result[1] >= 1.0:
			continue # No ground under this shape
		if result[1] <= 0.0:
			return # Starts inside something (under a desk, sunk too deep…)
		travel = minf(travel, result[0] * cast_length) # The first shape to touch stops the item
	if travel == INF:
		return # No ground under the item: floating

	var offset: Vector3 = lift + Vector3.DOWN * travel

	# 2. Something in the way at the final spot?
	for shape_node in shapes:
		var query: PhysicsShapeQueryParameters3D = _make_query(shape_node, exclude, blocking_mask)
		query.transform.origin += offset
		if not space.intersect_shape(query, 1).is_empty():
			return

	_place_position = _body.global_position + offset
	_can_place = true

func _make_query(shape_node: CollisionShape3D, exclude: Array[RID], mask: int) -> PhysicsShapeQueryParameters3D:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = mask
	query.exclude = exclude
	return query

func _get_shapes(body: RigidBody3D) -> Array[CollisionShape3D]:
	var shapes: Array[CollisionShape3D] = []
	for child in body.get_children():
		if child is CollisionShape3D and not child.disabled and child.shape != null:
			shapes.append(child)
	return shapes

## Everything in the player's hands (a stack must not block itself).
func _get_held_rids() -> Array[RID]:
	var rids: Array[RID] = []
	var spawner: WorldItemSpawner = _get_spawner()
	for entity_id in GameState.get_held(player_id):
		var view: CollisionObject3D = spawner.get_view(entity_id) as CollisionObject3D if spawner else null
		if view != null:
			rids.append(view.get_rid())
	return rids

# --- Held item -------------------------------------------------------------

## Watches what the player holds; removes the tint from an item that left the hands.
func _track_held_item() -> void:
	if _body != null and not is_instance_valid(_body):
		_reset()
	var held: Array = GameState.get_held(player_id)
	var entity_id: int = held.back() if not held.is_empty() else -1
	if entity_id == _entity_id:
		return

	_clear_tint()
	_reset()
	_entity_id = entity_id
	if entity_id < 0:
		return

	var definition: ItemDefinition = ItemDatabase.get_definition(GameState.get_world_item(entity_id).get("item_id", &""))
	var spawner: WorldItemSpawner = _get_spawner()
	var body: RigidBody3D = spawner.get_view(entity_id) as RigidBody3D if spawner else null
	if definition == null or not definition.placeable or body == null:
		return
	_definition = definition
	_body = body
	_meshes = body.find_children("*", "GeometryInstance3D", true, false)

func _clear_tint() -> void:
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = null

func _reset() -> void:
	_entity_id = -1
	_body = null
	_definition = null
	_meshes.clear()
	_can_place = false

func _get_spawner() -> WorldItemSpawner:
	return get_tree().get_first_node_in_group(&"world_item_spawner") as WorldItemSpawner
