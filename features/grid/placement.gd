class_name Placement
extends RefCounted

## Pure placement math, shared by the placement preview and PlaceItemCommand.
## Items are anchored with a free position + yaw: the grid is only a snapping aid.

const CELL_SIZE: float = 1.0
const GRID_ROTATION_STEP: float = PI / 2.0
const OVERLAP_MARGIN: float = 0.02 ## Lets items touch side by side

## Snaps a ground point so the footprint lines up with the grid cells.
static func snap_position(definition: ItemDefinition, point: Vector3, yaw: float) -> Vector3:
	var cells: Vector2i = definition.footprint
	if _is_quarter_turned(yaw):
		cells = Vector2i(cells.y, cells.x)
	return Vector3(_snap_axis(point.x, cells.x), point.y, _snap_axis(point.z, cells.y))

static func snap_yaw(yaw: float) -> float:
	return snappedf(yaw, GRID_ROTATION_STEP)

static func to_transform(position: Vector3, yaw: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), position)

## True if two anchored items would intersect.
static func overlaps(
	definition_a: ItemDefinition, position_a: Vector3, yaw_a: float,
	definition_b: ItemDefinition, position_b: Vector3, yaw_b: float
) -> bool:
	# Different floors never collide
	if position_a.y >= position_b.y + definition_b.footprint_height \
			or position_b.y >= position_a.y + definition_a.footprint_height:
		return false
	var polygon_a: PackedVector2Array = _footprint_polygon(definition_a, position_a, yaw_a)
	var polygon_b: PackedVector2Array = _footprint_polygon(definition_b, position_b, yaw_b)
	return not Geometry2D.intersect_polygons(polygon_a, polygon_b).is_empty()

## Odd sizes are centered on a cell, even sizes on a grid line.
static func _snap_axis(value: float, cells: int) -> float:
	if cells % 2 == 1:
		return (floorf(value / CELL_SIZE) + 0.5) * CELL_SIZE
	return roundf(value / CELL_SIZE) * CELL_SIZE

static func _is_quarter_turned(yaw: float) -> bool:
	return posmod(roundi(yaw / GRID_ROTATION_STEP), 2) == 1

## Footprint rectangle on the ground (x, z), rotated by yaw and shrunk by the margin.
static func _footprint_polygon(definition: ItemDefinition, position: Vector3, yaw: float) -> PackedVector2Array:
	var half: Vector2 = Vector2(definition.footprint) * CELL_SIZE * 0.5 - Vector2.ONE * OVERLAP_MARGIN
	var center: Vector2 = Vector2(position.x, position.z)
	var polygon: PackedVector2Array = []
	for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
		# Godot's yaw turns (x, z) the opposite way to Vector2.rotated()
		polygon.append(center + corner.rotated(-yaw))
	return polygon
