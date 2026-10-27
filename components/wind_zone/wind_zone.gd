@tool
class_name WindZone
extends Area3D

## Pushes the bodies inside a long pyramid, like a spotlight beam: it starts small at the zone origin
## and opens along the local -Z axis. The shape is built from the "Shape" settings (visible in the editor).
## Like moving air: strong on still bodies, nothing once they move as fast as the wind.
## Heavier bodies are pushed less (the force is in newtons). Players are pushed too.
## The zone follows its parent: turn or tilt the machine and the wind turns with it.
## Physics only: GameState is not modified, so no command is dispatched.

@export var enabled: bool = true:
	set(value):
		enabled = value
		set_deferred("monitoring", value)
@export var wind_speed: float = 8.0 ## Air speed (m/s) right at the fan, at power 1. Bodies are never pushed faster
@export var force_stat: StatDefinition ## Upgradable grip of the air. Falls back to force if empty
@export var force: float = 3.0 ## Grip of the air: newtons per m/s of speed difference. Higher = reaches wind speed sooner
@export_range(0.0, 1.0) var min_falloff: float = 0.25 ## Part of the wind speed left at the end of the beam
@export var affect_players: bool = true

@export_group("Shape")
@export var length: float = 5.0: ## How far the beam goes (m)
	set(value):
		length = maxf(value, 0.1)
		_rebuild_shape()
@export var near_size: Vector2 = Vector2(0.9, 0.9): ## Width, height of the beam at the fan (m)
	set(value):
		near_size = value.max(Vector2(0.05, 0.05))
		_rebuild_shape()
@export var far_size: Vector2 = Vector2(3.0, 2.6): ## Width, height of the beam at its end (m)
	set(value):
		far_size = value.max(Vector2(0.05, 0.05))
		_rebuild_shape()
@export var far_offset: Vector2 = Vector2(0.0, -0.6): ## Moves the end of the beam (x right, y up). Shapes the area only, the wind still blows along -Z
	set(value):
		far_offset = value
		_rebuild_shape()

var _power: float = 1.0
var _shape_node: CollisionShape3D

func _ready() -> void:
	monitorable = false
	_rebuild_shape()

## For signal connections (e.g. Anchorable.anchor_changed).
func set_enabled(value: bool) -> void:
	enabled = value

## For signal connections (e.g. Powerable.power_changed). 0 disables the wind.
func set_power(value: float) -> void:
	_power = value
	enabled = value > 0.0

func get_power() -> float:
	return _power

## Direction the wind blows: the zone's forward axis in world space.
func get_wind_direction() -> Vector3:
	return -global_basis.z.normalized()

## Air speed right at the fan, power included.
func get_wind_speed() -> float:
	return wind_speed * _power

## The 8 corners of the beam in local space: near face (z = 0), then far face (z = -length).
func get_corners() -> PackedVector3Array:
	var corners: PackedVector3Array = []
	for face in [[near_size, Vector2.ZERO, 0.0], [far_size, far_offset, -length]]:
		var half: Vector2 = face[0] * 0.5
		var center: Vector2 = face[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				corners.append(Vector3(center.x + sx * half.x, center.y + sy * half.y, face[2]))
	return corners

## Builds the pyramid collision shape. Created by code, never saved in the scene.
func _rebuild_shape() -> void:
	if not is_inside_tree():
		return # _ready() builds it
	if _shape_node == null:
		_shape_node = CollisionShape3D.new()
		add_child(_shape_node) # No owner: not saved, rebuilt from the settings
	var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = get_corners()
	_shape_node.shape = shape

func _physics_process(delta: float) -> void:	
	if Engine.is_editor_hint():
		return # Shape preview only in the editor
	
	print("enabled=", enabled, " power=", _power, " monitoring=", monitoring, " bodies=", get_overlapping_bodies().size())
		
	if not enabled or not monitorable:
		return
	if not multiplayer.is_server():
		return # The host simulates physics, clients only receive positions

	
	var direction: Vector3 = get_wind_direction()
	var grip: float = _get_force()
	for body in get_overlapping_bodies():
		if body is RigidBody3D:
			_push_rigid(body as RigidBody3D, direction, grip)
		elif affect_players and body is PlayerController:
			_push_player(body as PlayerController, direction, grip, delta)

func _push_rigid(body: RigidBody3D, direction: Vector3, grip: float) -> void:
	if not _can_push(body):
		return
	var push: float = _push_force(body.global_position, body.linear_velocity, direction, grip)
	if push <= 0.0:
		return
	body.sleeping = false
	body.apply_central_force(direction * push)

func _push_player(player: PlayerController, direction: Vector3, grip: float, delta: float) -> void:
	var push: float = _push_force(player.global_position, player.velocity, direction, grip)
	if push > 0.0:
		player.push(direction * push / player.push_mass, delta)

## Newtons: grip × (air speed here − body speed along the wind). 0 once the body is as fast as the air.
func _push_force(position: Vector3, velocity: Vector3, direction: Vector3, grip: float) -> float:
	var distance: float = (position - global_position).dot(direction)
	var falloff: float = lerpf(1.0, min_falloff, clampf(distance / length, 0.0, 1.0))
	var air_speed: float = get_wind_speed() * falloff
	return grip * maxf(air_speed - velocity.dot(direction), 0.0)

func _can_push(body: RigidBody3D) -> bool:
	if body == get_parent() or body.freeze:
		return false # Never the fan itself, never anchored machines
	if body.has_meta(&"entity_id"):
		var item: Dictionary = GameState.get_world_item(body.get_meta(&"entity_id"))
		if not item.is_empty() and item["holder"] != 0:
			return false # Held items are moved by the grabber
	return true

func _get_force() -> float:
	if force_stat != null:
		return Stats.get_value(force_stat)
	return force
