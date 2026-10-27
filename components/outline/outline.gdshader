shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0.0, 0.2) = 0.03;
// Use for flat-shaded meshes (boxes) where normal extrusion leaves gaps at corners
uniform bool grow_from_center = false;

// Cut-out meshes (grilles, leaves…): the outline gets the same holes as the mesh
uniform bool use_alpha_texture = false;
uniform sampler2D alpha_texture : source_color, filter_nearest;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy; // Same UV transform as the mesh's material
	if (grow_from_center) {
		VERTEX *= 1.0 + outline_width;
	} else {
		VERTEX += NORMAL * outline_width;
	}
}

void fragment() {
	if (use_alpha_texture && texture(alpha_texture, UV).a < alpha_threshold) {
		discard; // A hole in the mesh: no outline here either
	}
	ALBEDO = outline_color.rgb;
}