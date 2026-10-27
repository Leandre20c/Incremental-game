class_name BuildGrid
extends Node3D

## The build grid of the level. Put it on the floor, at a corner of the platform:
## its position is a grid corner, its rotation orients the grid, cells are cell_size wide.
## Grid pieces (floors, walls, roofs, ramps) are one cell wide and snap to its cells and lines.

const GROUP: StringName = &"build_grid"

@export var cell_size: float = 1.0
@export_range(15.0, 90.0, 15.0) var rotation_step_degrees: float = 45.0 ## Rotations snap to multiples of this angle

func _ready() -> void:
	add_to_group(GROUP)

## The build grid of the level, or null if there is none.
static func find(tree: SceneTree) -> BuildGrid:
	return tree.get_first_node_in_group(GROUP) as BuildGrid

## Snaps a held transform to the grid, for a piece of one cell by `thickness`:
## - rotation: yaw, pitch and roll rounded to rotation_step_degrees;
## - along each grid axis, from the space the piece takes on that axis:
##   about a cell or more: centered on a cell; less (thin side, slope): its side rests on the nearest grid line.
## Flat: floor or roof on a level. Standing: wall on a cell edge. At 45°: ramp from a level, diagonal wall…
func snap_transform(world: Transform3D, thickness: float) -> Transform3D:
	var grid: Transform3D = global_transform.orthonormalized()
	var local: Transform3D = grid.affine_inverse() * world
	var basis: Basis = snap_basis(local.basis, deg_to_rad(rotation_step_degrees))
	var extents: Vector3 = _half_extents(basis, Vector3(cell_size, thickness, cell_size) * 0.5)
	var origin: Vector3 = Vector3.ZERO
	for i in 3:
		var p: float = local.origin[i]
		if extents[i] >= cell_size * 0.5 - 0.001:
			origin[i] = (floorf(p / cell_size) + 0.5) * cell_size # Centered on a cell
		else:
			origin[i] = roundf((p - extents[i]) / cell_size) * cell_size + extents[i] # Side on a grid line
	return grid * Transform3D(basis, origin)

## Nearest rotation whose yaw, pitch and roll are multiples of `step` (radians).
static func snap_basis(basis: Basis, step: float = PI / 2.0) -> Basis:
	var euler: Vector3 = basis.orthonormalized().get_euler(EULER_ORDER_YXZ)
	for i in 3:
		euler[i] = roundf(euler[i] / step) * step
	return Basis.from_euler(euler, EULER_ORDER_YXZ)

## Half size of the box the rotated piece takes on each grid axis.
static func _half_extents(basis: Basis, half_size: Vector3) -> Vector3:
	return basis.x.abs() * half_size.x + basis.y.abs() * half_size.y + basis.z.abs() * half_size.z
