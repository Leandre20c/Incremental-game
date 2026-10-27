class_name PlayerPlacer
extends Node

## While the player holds a placeable item, tints it green or red and anchors it on click.
## Free mode: placed as held, dropped onto the ground right under it. Any angle, as long as it touches the ground.
## Grid mode (grid key, items with snaps_to_grid): the item jumps to the nearest BuildGrid spot
## (quarter turns, cell centers, grid planes) and must touch the ground or another placed piece.
## Red when: nothing holds it up, or something is in the way (a player or another item).
## Uses Input polling (like PlayerInteraction): mouse events may not reach the game SubViewport.

signal grid_mode_changed(use_grid: bool)

const TINT_SHADER: Shader = preload("res://components/placement_tint/placement_tint.gdshader")

@export var player_id: int = 1
@export var grabber: PlayerGrabber ## Needed for grid mode: gives the hold point and moves the item to its spot
@export var support_distance: float = 0.2 ## Free mode: max gap above the ground. Farther = floating
@export var sink_tolerance: float = 0.5 ## Free mode: how deep the held item may sink into the ground and still snap onto it
@export var attach_distance: float = 0.03 ## Grid mode: max gap to the ground or to another piece to count as attached
@export_flags_3d_physics var support_mask: int = 2 ## What can hold an item up (Terrain, placed floors and walls)
@export_flags_3d_physics var blocking_mask: int = 5 ## What prevents placing (Player + Items)

@export_group("Tint")
@export var valid_color: Color = Color(0.3, 1.0, 0.4)
@export var invalid_color: Color = Color(1.0, 0.25, 0.25)

var _use_grid: bool = true
var _entity_id: int = -1 ## Held item, -1 if none
var _body: RigidBody3D ## Held placeable body, null if none
var _definition: ItemDefinition
var _meshes: Array[Node] = []
var _tint: ShaderMaterial

var _can_place: bool = false
var _place_position: Vector3 = Vector3.ZERO ## Where the body goes once placed
var _place_rotation: Quaternion = Quaternion.IDENTITY

func _ready() -> void:
	add_to_group(&"player_placer")
	_tint = ShaderMaterial.new()
	_tint.shader = TINT_SHADER

func can_place() -> bool:
	return _can_place

func is_grid_enabled() -> bool:
	return _use_grid

## True if the held item can use the grid (the grid key does something).
func can_snap() -> bool:
	return _definition != null and _definition.snaps_to_grid

func _physics_process(_delta: float) -> void:
	_track_held_item()
	if _body == null:
		return

	var captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if captured and can_snap() and Input.is_action_just_pressed("toggle_grid"):
		_use_grid = not _use_grid
		grid_mode_changed.emit(_use_grid)

	var grid: BuildGrid = BuildGrid.find(get_tree())
	if _use_grid and can_snap() and grid != null and grabber != null and GameState.get_held(player_id).size() == 1:
		_evaluate_grid(grid)
	else:
		_release_snap()
		_evaluate_free()

	_tint.set_shader_parameter("tint_color", valid_color if _can_place else invalid_color)
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = _tint

	if _can_place and captured and Input.is_action_just_pressed("place_held"):
		CommandService.dispatch(PlaceItemCommand.new(player_id, _entity_id, _place_position, _place_rotation))

# --- Free mode -------------------------------------------------------------

## Drops the held item, as it is, onto the ground under it.
func _evaluate_free() -> void:
	_can_place = false
	_place_rotation = _body.global_basis.get_rotation_quaternion()

	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	var exclude: Array[RID] = _get_held_rids()
	var shapes: Array[CollisionShape3D] = _get_shapes(_body)
	var lift: Vector3 = Vector3.UP * sink_tolerance
	var cast_length: float = sink_tolerance + support_distance

	# 1. Drop the item from slightly above onto the ground: works whether it hovers or sank in
	var travel: float = INF
	for shape_node in shapes:
		var query: PhysicsShapeQueryParameters3D = _make_query(shape_node.shape, shape_node.global_transform, exclude, support_mask)
		query.transform.origin += lift
		query.motion = Vector3.DOWN * cast_length
		var result: PackedFloat32Array = space.cast_motion(query) # [safe, unsafe] fractions
		if result[1] >= 1.0:
			continue # No ground under this shape
		if result[1] <= 0.0:
			return # Starts inside something (under a desk, sunk too deep…)
		travel = minf(travel, result[0] * cast_length) # The first shape to touch stops the item
	if travel == INF:
		return # No surface touches the ground: floating

	var offset: Vector3 = lift + Vector3.DOWN * travel

	# 2. Something in the way at the final spot?
	for shape_node in shapes:
		var transform: Transform3D = shape_node.global_transform
		transform.origin += offset
		if _overlaps(space, shape_node.shape, transform, exclude, blocking_mask):
			return

	_place_position = _body.global_position + offset
	_can_place = true

# --- Grid mode -------------------------------------------------------------

## Snaps the held item to the grid spot nearest to the hold point, then checks that spot.
func _evaluate_grid(grid: BuildGrid) -> void:
	_can_place = false
	var snap: Transform3D = grid.snap_transform(grabber.get_hold_transform(), _definition.grid_thickness)
	grabber.set_snap(snap)
	_place_position = snap.origin
	_place_rotation = snap.basis.get_rotation_quaternion()

	if GameState.is_slot_taken(_place_position, _place_rotation):
		return # Another piece is already exactly there

	var space: PhysicsDirectSpaceState3D = _body.get_world_3d().direct_space_state
	var exclude: Array[RID] = _get_held_rids()
	var body_at_snap: Transform3D = Transform3D(snap.basis * Basis.from_scale(_body.global_basis.get_scale()), snap.origin)
	var attached: bool = false
	for shape_node in _get_shapes(_body):
		# Same shape, moved with the body to its grid spot
		var transform: Transform3D = body_at_snap * (_body.global_transform.affine_inverse() * shape_node.global_transform)
		if _overlaps(space, shape_node.shape, transform, exclude, blocking_mask):
			return # A player or an item is in the way
		if not attached:
			attached = _touches(space, shape_node.shape, transform, exclude)
	_can_place = attached

## True if the shape touches the ground or a placed piece: tested a little bigger than it is.
func _touches(space: PhysicsDirectSpaceState3D, shape: Shape3D, transform: Transform3D, exclude: Array[RID]) -> bool:
	var query: PhysicsShapeQueryParameters3D = _make_query(shape, transform, exclude, support_mask)
	query.margin = attach_distance
	return not space.intersect_shape(query, 1).is_empty()

func _release_snap() -> void:
	if grabber != null:
		grabber.clear_snap()

# --- Queries ---------------------------------------------------------------

func _overlaps(space: PhysicsDirectSpaceState3D, shape: Shape3D, transform: Transform3D, exclude: Array[RID], mask: int) -> bool:
	return not space.intersect_shape(_make_query(shape, transform, exclude, mask), 1).is_empty()

func _make_query(shape: Shape3D, transform: Transform3D, exclude: Array[RID], mask: int) -> PhysicsShapeQueryParameters3D:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = transform
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
	_release_snap()
	_entity_id = -1
	_body = null
	_definition = null
	_meshes.clear()
	_can_place = false

func _get_spawner() -> WorldItemSpawner:
	return get_tree().get_first_node_in_group(&"world_item_spawner") as WorldItemSpawner
