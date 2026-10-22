// PSX-style post process: color posterization + optional ordered (Bayer 4x4) dithering.
// Apply as the material of the SubViewportContainer that displays the 3D world.
shader_type canvas_item;

// Levels per channel. PS1 output was 15-bit color: 32 levels per channel.
uniform float color_levels : hint_range(2.0, 256.0, 1.0) = 32.0;
uniform bool dithering = true;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;

const mat4 BAYER_4X4 = mat4(
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 5.0)
);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 rgb = color.rgb;
	float steps = color_levels - 1.0;

	if (dithering) {
		// Use the low-res pixel coordinate so the pattern matches the game pixels, not screen pixels.
		ivec2 pixel = ivec2(UV / TEXTURE_PIXEL_SIZE) % 4;
		float threshold = BAYER_4X4[pixel.x][pixel.y] / 16.0 - 0.5;
		rgb += threshold * dither_strength / steps;
	}

	rgb = floor(clamp(rgb, 0.0, 1.0) * steps + 0.5) / steps;
	COLOR = vec4(rgb, color.a);
}
