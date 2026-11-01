class_name SpawnLaunch
extends Resource

## How a spawned item is thrown. Direction is local to the spawn point:
## rotate the Marker3D in the editor to aim.

@export var direction: Vector3 = Vector3.UP
@export var speed: float = 4.0
@export var speed_variation: float = 0.0 ## Random +/- added to speed
@export_range(0.0, 90.0) var spread_degrees: float = 0.0 ## Random cone around direction

## Returns a world-space velocity. basis = orientation of the spawn point.
func sample(basis: Basis) -> Vector3:
	var aim: Vector3 = (basis.orthonormalized() * direction).normalized()
	if aim == Vector3.ZERO:
		return Vector3.ZERO

	# Tilt by a random angle inside the cone, then spin around the aim axis
	var reference: Vector3 = Vector3.UP if absf(aim.y) < 0.99 else Vector3.RIGHT
	var tilt_axis: Vector3 = aim.cross(reference).normalized()
	var result: Vector3 = aim.rotated(tilt_axis, deg_to_rad(randf() * spread_degrees))
	result = result.rotated(aim, randf() * TAU)

	return result * maxf(speed + randf_range(-speed_variation, speed_variation), 0.0)
