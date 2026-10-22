class_name WorldItemSpawner
extends Node3D

## View only: mirrors GameState world items as 3D nodes.

@export var launch_speed: float = 3.0

var _views: Dictionary[int, Node3D] = {}

func _ready() -> void:
	EventBus.world_item_spawned.connect(_on_world_item_spawned)
	EventBus.world_item_removed.connect(_on_world_item_removed)

func _on_world_item_spawned(entity_id: int, item_id: StringName, item_position: Vector3) -> void:
	var definition: ItemDefinition = ItemDatabase.get_definition(item_id)
	if definition == null or definition.world_scene == null or not definition.world_scene.can_instantiate():
		push_warning("WorldItemSpawner: no valid scene for item '%s'" % item_id)
		return

	var view: Node3D = definition.world_scene.instantiate() as Node3D
	if view == null:
		push_warning("WorldItemSpawner: scene root for '%s' is not a Node3D" % item_id)
		return

	add_child(view)
	view.global_position = item_position
	view.set_meta(&"entity_id", entity_id)
	_views[entity_id] = view

	# Cosmetic only: the hop is not part of the simulation
	if view is RigidBody3D:
		var direction: Vector3 = Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5)).normalized()
		view.linear_velocity = direction * launch_speed

func _on_world_item_removed(entity_id: int) -> void:
	var view: Node3D = _views.get(entity_id)
	if view:
		view.queue_free()
	_views.erase(entity_id)
