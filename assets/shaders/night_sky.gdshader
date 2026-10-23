shader_type sky;

// PSX night sky: flat gradient, procedural stars, moon disc + halo,
// and a fog band at the horizon that matches the scene fog color exactly.
// Environment.fog_sky_affect must be 0: this shader handles its own fog.

uniform vec3 sky_top_color : source_color = vec3(0.015, 0.02, 0.045);
// Set by WeatherController from WeatherPreset.fog_color. Must equal the scene fog color.
uniform vec3 fog_color : source_color = vec3(0.1, 0.12, 0.16);
// Elevation (sine of the angle above horizon) where the fog band starts / ends
uniform float horizon_fog_start = -0.05;
uniform float horizon_fog_end = 0.35;

group_uniforms stars;
uniform float star_density = 60.0;
// Higher = fewer stars
uniform float star_threshold : hint_range(0.0, 1.0) = 0.9;
// In grid cells. Stars are never drawn smaller than star_min_pixels anyway
uniform float star_size : hint_range(0.01, 0.5) = 0.1;
// Minimum star radius in screen pixels. Below ~0.8, stars shimmer when the camera turns
uniform float star_min_pixels : hint_range(0.5, 3.0) = 1.0;
uniform float star_brightness = 1.2;
uniform float twinkle_speed = 2.0;

group_uniforms moon;
uniform vec3 moon_color : source_color = vec3(0.9, 0.92, 1.0);
// Angular radius in radians
uniform float moon_size : hint_range(0.0, 0.3) = 0.05;
uniform vec3 halo_color : source_color = vec3(0.35, 0.42, 0.55);
uniform float halo_strength = 0.5;
// Higher = tighter halo
uniform float halo_falloff = 20.0;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

// pixel_angle: angular size of one screen pixel (from fwidth), keeps stars >= 1 pixel
float stars(vec3 dir, float pixel_angle) {
	vec3 p = dir * star_density;
	vec3 base = floor(p);
	float pixel = pixel_angle * star_density; // One pixel, in grid cell units
	float radius = max(star_size, pixel * star_min_pixels);
	float result = 0.0;

	// Neighbor cells too: star centers are projected on the sphere and can leave their cell
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 cell = base + vec3(float(x), float(y), float(z));
				float h = hash13(cell);
				if (h < star_threshold) {
					continue;
				}
				// On the sphere: every star has the same apparent size
				vec3 center = normalize(cell + 0.25 + hash33(cell) * 0.5) * star_density;
				float d = length(p - center);
				// One-pixel soft edge: stable brightness while the camera turns
				float coverage = 1.0 - smoothstep(radius - pixel * 0.5, radius + pixel * 0.5, d);
				float twinkle = 0.6 + 0.4 * sin(TIME * twinkle_speed + h * 100.0);
				result = max(result, coverage * twinkle);
			}
		}
	}
	return result;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float clear = smoothstep(horizon_fog_start, horizon_fog_end, dir.y);
	float pixel_angle = length(fwidth(dir)); // Computed outside branches (derivatives)

	if (AT_CUBEMAP_PASS) {
		// Cheap version for the radiance cubemap (no stars, no animation)
		COLOR = mix(fog_color, sky_top_color, clear);
	} else {
		vec3 col = sky_top_color + vec3(stars(dir, pixel_angle)) * star_brightness;
		float halo = 0.0;

		if (LIGHT0_ENABLED) {
			float d = dot(dir, LIGHT0_DIRECTION);
			col = mix(col, moon_color, step(cos(moon_size), d));
			halo = pow(max(d, 0.0), halo_falloff) * halo_strength;
		}

		col = mix(fog_color, col, clear);
		// Halo added after the fog mix: the moon lights up the mist around it
		COLOR = col + halo_color * halo;
	}
}
