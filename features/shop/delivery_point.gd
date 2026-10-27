class_name DeliveryPoint
extends Marker3D

## Where bought items appear. Put one in the level, a bit above the floor (dock, crane hook…).

const GROUP: StringName = &"delivery_point"

func _ready() -> void:
	add_to_group(GROUP)

## The delivery point of the level, or null if there is none.
static func find(tree: SceneTree) -> DeliveryPoint:
	return tree.get_first_node_in_group(GROUP) as DeliveryPoint
