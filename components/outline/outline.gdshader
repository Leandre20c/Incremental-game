shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0.0, 0.2) = 0.03;
// Use for flat-shaded meshes (boxes) where normal extrusion leaves gaps at corners
uniform bool grow_from_center = false;

void vertex() {
	if (grow_from_center) {
		VERTEX *= 1.0 + outline_width;
	} else {
		VERTEX += NORMAL * outline_width;
	}
}

void fragment() {
	ALBEDO = outline_color.rgb;
} 