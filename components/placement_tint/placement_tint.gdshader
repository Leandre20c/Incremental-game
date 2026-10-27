shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never, shadows_disabled;

// Overlay tint drawn on top of a mesh (material_overlay), e.g. green/red placement preview.

uniform vec4 tint_color : source_color = vec4(0.3, 1.0, 0.4, 1.0);
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.25; // Faces looking at the camera
uniform float rim_alpha : hint_range(0.0, 1.0) = 0.85; // Faces seen edge-on
uniform float rim_power : hint_range(0.5, 8.0) = 2.0; // Higher = thinner rim
uniform float pulse_speed = 4.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.2;
// Pulls the overlay toward the camera, as a fraction of the distance, so it never z-fights with the mesh
uniform float depth_bias : hint_range(0.0, 0.05) = 0.005;

void vertex() {
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	POSITION.z *= 1.0 + depth_bias; // Reverse-Z: a larger depth is closer to the camera
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	ALBEDO = tint_color.rgb;
	ALPHA = clamp(mix(fill_alpha, rim_alpha, rim) * pulse, 0.0, 1.0);
}