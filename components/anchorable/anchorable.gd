class_name Anchorable
extends Node

## Child of a world item RigidBody3D. When the item is anchored in GameState,
## freezes it at its placed transform so players and items can no longer push it.
## Grabbing it again unfreezes it.

signal anchor_changed(anchored: bool)

var _body: RigidBody3D

func _ready() -> void:
	_body = get_parent() as RigidBody3D
	assert(_body != null, "Anchorable must be a child of a RigidBody3D")
	_body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC # Frozen = behaves like a StaticBody3D
	EventBus.item_anchor_changed.connect(_on_item_anchor_changed)
	_sync.call_deferred() # The spawner sets the entity_id meta right after add_child

func is_anchored() -> bool:
	return _body.freeze

func _sync() -> void:
	var item: Dictionary = GameState.get_world_item(_get_entity_id())
	if item.get("anchored", false):
		_apply(true)

func _on_item_anchor_changed(entity_id: int, anchored: bool) -> void:
	if entity_id == _get_entity_id():
		_apply(anchored)

func _apply(anchored: bool) -> void:
	if anchored:
		var item: Dictionary = GameState.get_world_item(_get_entity_id())
		var scale: Vector3 = _body.global_basis.get_scale() # Keep the scene's scale, if any
		_body.freeze = true
		_body.linear_velocity = Vector3.ZERO
		_body.angular_velocity = Vector3.ZERO
		_body.global_transform = Transform3D(Basis(item["rotation"]) * Basis.from_scale(scale), item["position"])
		_body.reset_physics_interpolation()
	else:
		_body.freeze = false
		_body.sleeping = false
	anchor_changed.emit(anchored)

func _get_entity_id() -> int:
	return _body.get_meta(&"entity_id", -1)
