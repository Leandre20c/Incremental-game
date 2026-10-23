class_name RainEmitter
extends GPUParticles3D

## View only: PSX-style rain that follows a target (usually the player).
## Drops are emitted in world space, so they keep falling straight when the target moves.
## Add a GPUParticlesCollisionHeightField3D (follow_camera_enabled = true) to stop
## drops on roofs and floors.

@export var follow_target: Node3D
@export var area_size: Vector2 = Vector2(24.0, 24.0)
## Emitter height above the target.
@export var spawn_height: float = 12.0
## How far a drop falls before dying.
@export var fall_distance: float = 30.0
@export var fall_speed: float = 18.0
@export var max_drops: int = 1500
## Keep width >= ~1 low-res pixel (about 0.06 m at 10 m with 240p), else drops shimmer.
@export var drop_size: Vector2 = Vector2(0.06, 0.7)
@export var drop_color: Color = Color(0.7, 0.8, 0.9, 0.45)
@export_range(0.0, 1.0) var intensity: float = 1.0:
	set(value):
		intensity = value
		amount_ratio = value # No particle restart, unlike changing amount
		emitting = value > 0.0

func _ready() -> void:
	top_level = true
	local_coords = false
	amount = max_drops
	amount_ratio = intensity
	lifetime = fall_distance / fall_speed
	visibility_aabb = AABB(
		Vector3(-area_size.x, -fall_distance, -area_size.y),
		Vector3(area_size.x * 2.0, fall_distance + 2.0, area_size.y * 2.0)
	)
	process_material = _build_process_material()
	draw_pass_1 = _build_mesh()
	emitting = intensity > 0.0
	_follow()

func _process(_delta: float) -> void:
	_follow()

func _follow() -> void:
	if follow_target:
		global_position = follow_target.global_position + Vector3.UP * spawn_height

func _build_process_material() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(area_size.x * 0.5, 0.5, area_size.y * 0.5)
	mat.direction = Vector3.DOWN
	mat.spread = 2.0
	mat.initial_velocity_min = fall_speed * 0.9
	mat.initial_velocity_max = fall_speed * 1.1
	mat.gravity = Vector3.ZERO # Constant speed, drops are already at terminal velocity
	mat.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	return mat

func _build_mesh() -> QuadMesh:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = drop_color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y # Always vertical, faces camera
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.disable_receive_shadows = true
	# Fog stays enabled: distant drops fade into the night

	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = drop_size
	mesh.material = mat
	return mesh
