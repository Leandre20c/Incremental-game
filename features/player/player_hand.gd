class_name PlayerHand
extends Node3D

## View of the player's hand + drop input. Never mutates state directly.

@export var player_id: int = 1
@export var stack_offset: Vector3 = Vector3(0.0, 0.08, 0.0)
@export var drop_distance: float = 1.2

func _ready() -> void:
	EventBus.hand_changed.connect(_on_hand_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop"):
		var camera: Camera3D = get_viewport().get_camera_3d()
		var _position: Vector3 = camera.global_position - camera.global_basis.z * drop_distance
		CommandService.dispatch(DropItemCommand.new(player_id, _position))

func _on_hand_changed(changed_player_id: int, item_id: StringName, count: int) -> void:
	if changed_player_id != player_id:
		return
	for child in get_children():
		child.queue_free()

	var definition: ItemDefinition = ItemDatabase.get_definition(item_id)
	if count <= 0 or definition == null or definition.world_scene == null:
		return

	for i in count:
		var view: Node3D = definition.world_scene.instantiate() as Node3D
		if view is RigidBody3D:
			view.freeze = true
			view.collision_layer = 0 # Not hittable by the interaction ray
			view.collision_mask = 0
		add_child(view)
		view.position = stack_offset * i
