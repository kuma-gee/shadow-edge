shader_type canvas_item;
//render_mode light_only;

uniform float shadow_visibility : hint_range(0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV, 0.5);
	COLOR = color;
//	if(AT_LIGHT_PASS) {
//		// For all fragments in the light
////		COLOR = vec4(texture(TEXTURE, UV).rgb, 1.0);
//		vec4 color = texture(TEXTURE, UV, 0.5);
//		COLOR = color;
//	}
//	else {
//		// For all other fragments
////		COLOR = vec4(texture(TEXTURE, UV).rgb, 0.0);
//		vec4 color = texture(TEXTURE, UV, 0.5);
//		COLOR = color;
//	}
}