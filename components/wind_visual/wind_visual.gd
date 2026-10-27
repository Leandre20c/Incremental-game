class_name WindVisual
extends GPUParticles3D

## Air streaks showing where a WindZone blows. Child of the WindZone.
## Streaks start on the beam's near face and spread out along it until its end.
## Follows the zone: no streaks when the wind is off, faster streaks at higher power.

@export var streak_size: Vector2 = Vector2(0.02, 0.35) ## Width, length (m)
@export var streak_color: Color = Color(0.85, 0.9, 1.0, 0.25)
@export var streaks_per_second: float = 50.0

var _zone: WindZone

func _ready() -> void:
	_zone = get_parent() as WindZone
	assert(_zone != null, "WindVisual must be a child of a WindZone")
	_setup()

func _process(_delta: float) -> void:
	var power: float = _zone.get_power()
	var on: bool = _zone.enabled and power > 0.0
	if emitting != on:
		emitting = on # Off: no new streaks, the ones already out keep flying
	if on:
		speed_scale = power # Faster air, same distance travelled
	# Off: keep the last speed so the streaks finish their flight and fade out

func _setup() -> void:
	var near: Vector2 = _zone.near_size
	var far: Vector2 = _zone.far_size
	var travel: Vector3 = Vector3(_zone.far_offset.x, _zone.far_offset.y, -_zone.length)

	transform = Transform3D.IDENTITY # Emit from the zone origin, the beam's near face
	local_coords = true
	lifetime = travel.length() / maxf(_zone.wind_speed, 0.1)
	amount = maxi(4, roundi(streaks_per_second * lifetime))
	transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY

	var corners: PackedVector3Array = _zone.get_corners()
	var bounds: AABB = AABB(corners[0], Vector3.ZERO)
	for corner in corners:
		bounds = bounds.expand(corner)
	visibility_aabb = bounds.grow(0.5)

	# The beam opens differently in width and height: spread by the average of both angles
	var spread_x: float = rad_to_deg(atan((far.x - near.x) * 0.5 / _zone.length))
	var spread_y: float = rad_to_deg(atan((far.y - near.y) * 0.5 / _zone.length))

	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(near.x * 0.5, near.y * 0.5, 0.02)
	process.direction = travel.normalized()
	process.spread = maxf((spread_x + spread_y) * 0.5, 0.0)
	process.initial_velocity_min = _zone.wind_speed * 0.9
	process.initial_velocity_max = _zone.wind_speed * 1.1
	process.gravity = Vector3.ZERO
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.15, Color.WHITE)
	fade.add_point(0.7, Color.WHITE)
	var fade_texture: GradientTexture1D = GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture
	process_material = process

	var streak_material: StandardMaterial3D = StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.vertex_color_use_as_albedo = true # Lets the fade ramp drive the alpha
	streak_material.albedo_color = streak_color
	streak_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var streak: QuadMesh = QuadMesh.new()
	streak.size = streak_size
	streak.material = streak_material
	draw_pass_1 = streak
