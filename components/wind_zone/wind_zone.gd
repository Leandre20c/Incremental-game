class_name WindZone
extends Area3D

## Continuously pushes the bodies inside it along the zone's local -Z axis (its forward).
## The zone follows its parent: turn or tilt the machine and the wind turns with it.
## Physics only: GameState is not modified, so no command is dispatched.

@export var enabled: bool = true:
	set(value):
		enabled = value
		set_deferred("monitoring", value)
@export var force_stat: StatDefinition ## Upgradable push force (N). Falls back to force if empty
@export var force: float = 6.0
@export var wind_speed: float = 6.0 ## Bodies already moving this fast along the wind are no longer pushed
@export var reach: float = 4.0 ## Distance (m) from the zone origin over which the wind fades
@export_range(0.0, 1.0) var min_falloff: float = 0.25 ## Part of the force left at the end of the reach

var _power: float = 1.0

func _ready() -> void:
	monitorable = false

## For signal connections (e.g. Anchorable.anchor_changed).
func set_enabled(value: bool) -> void:
	enabled = value

## For signal connections (e.g. Powerable.power_changed). 0 disables the wind.
func set_power(value: float) -> void:
	_power = value
	enabled = value > 0.0

## Direction the wind blows: the zone's forward axis in world space.
func get_wind_direction() -> Vector3:
	return -global_basis.z.normalized()

func _physics_process(_delta: float) -> void:
	if not enabled or not monitoring:
		return
	if not multiplayer.is_server():
		return # The host simulates physics, clients only receive positions

	var direction: Vector3 = get_wind_direction()
	var push: float = _get_force() * _power
	for body in get_overlapping_bodies():
		var rigid: RigidBody3D = body as RigidBody3D
		if rigid == null or not _can_push(rigid):
			continue
		var strength: float = _distance_factor(rigid, direction) * _speed_factor(rigid, direction)
		if strength <= 0.0:
			continue
		rigid.sleeping = false
		rigid.apply_central_force(direction * push * strength)

func _can_push(body: RigidBody3D) -> bool:
	if body == get_parent() or body.freeze:
		return false # Never the fan itself, never anchored machines
	if body.has_meta(&"entity_id"):
		var item: Dictionary = GameState.get_world_item(body.get_meta(&"entity_id"))
		if not item.is_empty() and item["holder"] != 0:
			return false # Held items are moved by the grabber
	return true

## 1 at the fan, fades to min_falloff at the end of the reach.
func _distance_factor(body: RigidBody3D, direction: Vector3) -> float:
	var distance: float = (body.global_position - global_position).dot(direction)
	return lerpf(1.0, min_falloff, clampf(distance / reach, 0.0, 1.0))

## 1 for a still body, 0 once it moves as fast as the wind: like real air, it cannot push faster than itself.
func _speed_factor(body: RigidBody3D, direction: Vector3) -> float:
	if wind_speed <= 0.0:
		return 1.0
	return clampf(1.0 - body.linear_velocity.dot(direction) / wind_speed, 0.0, 1.0)

func _get_force() -> float:
	if force_stat != null:
		return Stats.get_value(force_stat)
	return force
