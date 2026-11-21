shader_type spatial;
// Skin for Jack Carter (isolated test, GL Compatibility safe).
// Keeps the original albedo texture. Adds: roughness derived from the albedo
// brightness (stubble / hair / dark detail stays matte, lit skin gets a soft
// sheen), wrapped diffuse lighting (softer shadow edge, a cheap stand-in for
// subsurface scattering, which Compatibility does not support) and a gentle
// rim. No extra textures, one texture sample.
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float saturation : hint_range(0.5, 1.5) = 1.0;
uniform float roughness_lit : hint_range(0.0, 1.0) = 0.52;
uniform float roughness_dark : hint_range(0.0, 1.0) = 0.82;
uniform float dark_threshold : hint_range(0.0, 1.0) = 0.2;
uniform float specular_amount : hint_range(0.0, 1.0) = 0.38;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.25;
uniform float rim_tint : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec3 color = texture(albedo_tex, UV).rgb * tint.rgb;
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, saturation);
	ALBEDO = color;
	ROUGHNESS = mix(roughness_dark, roughness_lit, smoothstep(dark_threshold * 0.5, dark_threshold * 1.5 + 0.05, luma));
	SPECULAR = specular_amount;
	RIM = rim_amount;
	RIM_TINT = rim_tint;
}
