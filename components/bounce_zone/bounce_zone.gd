class_name BounceZone
extends Area3D

## Launches bodies entering it along the zone's local +Y axis, i.e. the surface normal.
## The zone follows its parent: tilt the machine and the bounce tilts with it.
## Physics only: GameState is not modified, so no command is dispatched.

signal bounced(body: Node3D)

@export var enabled: bool = true:
	set(value):
		enabled = value
		set_deferred("monitoring", value)
@export var bounce_speed_stat: StatDefinition ## Upgradable speed (m/s). Falls back to bounce_speed if empty
@export var bounce_speed: float = 8.0
@export_range(0.0, 1.0) var keep_tangent_velocity: float = 0.5 ## 1 = keeps sideways speed, 0 = goes straight along the normal
@export var cooldown: float = 0.2 ## Seconds before the same body can bounce again
@export var affect_players: bool = true

@export_group("Mass")
@export var reference_mass: float = 1.0 ## Bodies this light or lighter get the full speed
@export_range(0.0, 1.0) var mass_falloff: float = 0.5 ## 0 = mass ignored, 1 = speed ∝ 1/mass
@export_range(0.0, 1.0) var min_speed_factor: float = 0.3 ## Very heavy bodies still get at least this

var _power: float = 1.0
var _pending: Array[Node3D] = []
var _last_bounce_ms: Dictionary[int, int] = {} # instance_id -> ticks

func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)

## For signal connections (e.g. Anchorable.anchor_changed).
func set_enabled(value: bool) -> void:
	enabled = value

## For signal connections (e.g. Powerable.power_changed). 0 disables the zone.
func set_power(value: float) -> void:
	_power = value
	enabled = value > 0.0

## Direction bodies are launched in: the zone's up axis in world space.
func get_bounce_normal() -> Vector3:
	return global_basis.y.normalized()

func _on_body_entered(body: Node3D) -> void:
	# Never change velocities inside a physics callback: apply on the next tick
	if not body in _pending:
		_pending.append(body)

func _physics_process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var bodies: Array[Node3D] = _pending.duplicate()
	_pending.clear()

	if not multiplayer.is_server():
		return # The host simulates physics, clients only receive positions

	var now: int = Time.get_ticks_msec()
	_prune_cooldowns(now)
	for body in bodies:
		if is_instance_valid(body) and _can_bounce(body, now):
			_bounce(body)
			_last_bounce_ms[body.get_instance_id()] = now

func _can_bounce(body: Node3D, now: int) -> bool:
	if body == get_parent():
		return false # Never bounce the machine itself

	var last: int = _last_bounce_ms.get(body.get_instance_id(), -1000000)
	if now - last < int(cooldown * 1000.0):
		return false

	if body is RigidBody3D:
		if (body as RigidBody3D).freeze:
			return false
		# Items held by a player are moved by the grabber, not by the world
		if body.has_meta(&"entity_id"):
			var item: Dictionary = GameState.get_world_item(body.get_meta(&"entity_id"))
			if not item.is_empty() and item["holder"] != 0:
				return false
		return true

	return affect_players and body is PlayerController

func _bounce(body: Node3D) -> void:
	var normal: Vector3 = get_bounce_normal()
	var speed: float = _get_bounce_speed() * _power

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		speed *= _mass_factor(rigid.mass)
		rigid.linear_velocity = _launch_velocity(rigid.linear_velocity, normal, speed)
		rigid.sleeping = false
	elif body is PlayerController:
		var player: PlayerController = body as PlayerController
		player.launch(_launch_velocity(player.velocity, normal, speed))

	bounced.emit(body)

## Replaces the speed along the normal, keeps part of the sideways speed.
func _launch_velocity(velocity: Vector3, normal: Vector3, speed: float) -> Vector3:
	var tangent: Vector3 = velocity - normal * velocity.dot(normal)
	return tangent * keep_tangent_velocity + normal * speed

func _get_bounce_speed() -> float:
	if bounce_speed_stat != null:
		return Stats.get_value(bounce_speed_stat)
	return bounce_speed

func _mass_factor(mass: float) -> float:
	return clampf(pow(reference_mass / mass, mass_falloff), min_speed_factor, 1.0)

func _prune_cooldowns(now: int) -> void:
	var cooldown_ms: int = int(cooldown * 1000.0)
	for id in _last_bounce_ms.keys():
		if now - _last_bounce_ms[id] > cooldown_ms:
			_last_bounce_ms.erase(id)
